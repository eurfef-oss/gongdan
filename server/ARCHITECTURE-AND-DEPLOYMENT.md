# 专业版授权服务：系统架构与部署

## 1. 适用范围

本服务只处理一次性专业版买断的购买验证、授权签发、恢复购买和商店通知，不处理用户注册，也不接收工单、客户、照片或签名数据。

当前商品 ID：`repair_pro_lifetime`。

服务端使用 Node.js 20+，授权数据使用 MariaDB 持久化。App 本地仍使用平台安全存储缓存已签发的授权，因此网络中断时可以继续使用已经激活的专业版功能。

## 2. 系统架构

```text
┌──────────────────────┐
│ Flutter App           │
│ in_app_purchase       │
│ flutter_secure_storage│
└──────────┬───────────┘
           │ HTTPS
           ▼
┌──────────────────────┐       ┌──────────────────────┐
│ Nginx / TLS           │──────▶│ Node.js License API  │
│ play.cosdk.com        │       │ port 8787             │
└──────────────────────┘       └──────────┬───────────┘
                                          │ MariaDB
                                          ▼
                                 ┌──────────────────────┐
                                 │ purchases            │
                                 │ entitlements         │
                                 │ webhook_events       │
                                 └──────────────────────┘

Apple App Store / Google Play
          │ 购买凭证与服务器通知
          └──────────────▶ Node.js License API
```

### 2.1 服务端模块

```text
server/
├── src/
│   ├── config.js              环境变量和运行配置
│   ├── server.js              HTTP 路由和请求处理
│   ├── store-verifier.js      Apple/Google 凭证验证边界
│   ├── entitlement.js         授权 payload 和 Ed25519 签名
│   ├── mariadb-store.js       MariaDB 连接、建表和授权数据访问
│   └── generate-keys.js       生成授权签名密钥
├── test/                      Node 测试
├── package.json
└── ARCHITECTURE-AND-DEPLOYMENT.md
```

### 2.2 请求流程

```text
购买或恢复购买
  → App 接收商店 purchaseStream
  → App 将平台验证数据提交 /v1/purchases/verify
  → Node 调用 Apple/Google 验证器
  → MariaDB 以交易标识幂等保存购买记录
  → Node 生成专业版授权并使用 Ed25519 私钥签名
  → App 校验签名并写入安全存储
  → App 完成商店交易
```

退款、撤销和重复通知通过 `webhook_events` 去重。正式环境必须先验证 Apple/Google 通知签名，再修改授权状态。

### 2.3 MariaDB 数据表

| 表 | 用途 |
| --- | --- |
| `purchases` | 平台、商品 ID、Google 订单号、购买 token、验证来源和交易状态；交易身份唯一 |
| `entitlements` | 授权状态、专业版功能集合、激活时间和签发时间 |
| `webhook_events` | Apple/Google 通知事件 ID 和 payload 哈希，用于幂等去重 |

数据库不保存工单业务数据。授权签名私钥也不进入数据库，只放在服务端环境变量或密钥管理服务中。

## 3. API

```text
GET  /healthz
POST /v1/purchases/verify
POST /v1/purchases/restore
POST /v1/webhooks/apple
POST /v1/webhooks/google
```

`/v1/purchases/verify` 和 `/v1/purchases/restore` 都要求 App 提交平台购买数据。由于当前没有用户账号，跨设备恢复依赖 Apple/Google 返回的历史购买记录，不依赖服务端用户 ID。

## 4. 部署步骤

以下示例以 Ubuntu 22.04/24.04、Node.js 20+、MariaDB 10.6+、Nginx 和域名 `play.cosdk.com` 为例。

### 4.1 创建系统用户和目录

```bash
sudo adduser --system --group repair-license
sudo mkdir -p /opt/repair-license/server
sudo mkdir -p /var/lib/repair-license
sudo chown -R repair-license:repair-license /opt/repair-license /var/lib/repair-license
```

将本目录上传到 `/opt/repair-license/server`。

### 4.2 创建 MariaDB 数据库

```sql
CREATE DATABASE repair_license
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'repair_license'@'127.0.0.1'
  IDENTIFIED BY '替换为随机高强度密码';

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX
  ON repair_license.* TO 'repair_license'@'127.0.0.1';

FLUSH PRIVILEGES;
```

服务启动时会自动创建所需数据表。数据库用户不需要远程访问权限，Node 和 MariaDB 放在同一台服务器时应使用 `127.0.0.1` 或 Unix socket。

### 4.3 安装 Node 依赖

```bash
cd /opt/repair-license/server
sudo -u repair-license npm install --omit=dev
```

### 4.4 配置环境变量

创建 `/etc/repair-license.env`：

```env
NODE_ENV=production
PORT=8787
PRODUCT_ID=repair_pro_lifetime
ALLOW_TEST_PURCHASES=false

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=repair_license
DB_USER=repair_license
DB_PASSWORD=替换为数据库密码
DB_CONNECTION_LIMIT=10

ANDROID_PACKAGE_NAME=com.cosdk.repairdesk
IOS_BUNDLE_ID=com.cosdk.repairdesk
ENTITLEMENT_PRIVATE_KEY_BASE64=服务端私钥

GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64=Google 服务账号 JSON 的 Base64
GOOGLE_PLAY_REQUEST_TIMEOUT_MS=10000
GOOGLE_PLAY_ACKNOWLEDGE_PURCHASES=true
```

Linux 服务器生成 Base64 示例：

```bash
base64 -w 0 google-play-service-account.json
```

Windows PowerShell 示例：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('.\\google-play-service-account.json'))
```

```bash
sudo chmod 600 /etc/repair-license.env
```

### 4.5 生成授权签名密钥

首次部署时，在服务端项目根目录执行：

```bash
cd /opt/repair-license/server
npm run generate-keys
```

命令会输出一对 Ed25519 密钥：

```text
ENTITLEMENT_PRIVATE_KEY_BASE64=...
ENTITLEMENT_PUBLIC_KEY_BASE64=...
```

将输出值按以下方式使用：

1. 将 `ENTITLEMENT_PRIVATE_KEY_BASE64` 的完整值写入 `/etc/repair-license.env`，只放在服务端，不要放入 Flutter 项目；
2. 将 `ENTITLEMENT_PUBLIC_KEY_BASE64` 的值作为 Flutter 构建参数：

   ```powershell
   flutter build appbundle --release `
     --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
     --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
   ```

   当前 `play.cosdk.com` 服务对应的公钥为：

   ```text
   VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
   ```

3. 将这对密钥备份到受限的密码管理器或密钥管理服务中；
4. 后续重启服务、更新 Node.js 代码或重新部署时继续使用同一对密钥，不要重复生成，否则已安装 App 的离线授权缓存可能无法通过签名验证。

密钥不得提交到 Git、写入公开文档或放入 `server.zip`。如果私钥泄露，应生成新密钥并重新构建发布 App；密钥轮换期间旧版本 App 无法验证新签发的授权，需要安排版本升级。

### 4.6 配置 systemd

创建 `/etc/systemd/system/repair-license.service`：

```ini
[Unit]
Description=Repair Work Order License Server
After=network.target mariadb.service

[Service]
Type=simple
User=repair-license
Group=repair-license
WorkingDirectory=/opt/repair-license/server
EnvironmentFile=/etc/repair-license.env
ExecStart=/usr/bin/node src/server.js
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict

[Install]
WantedBy=multi-user.target
```

启动并查看状态：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now repair-license
sudo systemctl status repair-license
sudo journalctl -u repair-license -f
```

### 4.7 配置 Nginx 和 HTTPS

Node 只监听内部端口，公网只开放 80/443。Nginx 示例：

```nginx
server {
    listen 80;
    server_name play.cosdk.com;

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

配置证书：

```bash
sudo certbot --nginx -d play.cosdk.com
```

检查服务：

```bash
curl https://play.cosdk.com/healthz
```

### 4.8 编译 App

```powershell
flutter build apk --release `
  --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
  --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
```

仅用于本地 Debug 流程验证时，可以额外使用 `--dart-define=ENABLE_LOCAL_TEST_PURCHASE=true`。该开关不会启用真实商店购买，Release 构建不可用；正式 Google Play 测试必须通过内部测试轨道安装并去掉该参数。

如果正式包的 Bundle ID 或 Android application ID 不同，还要同步修改服务端环境变量和 App 的 `APP_IDENTIFIER` 构建参数。

## 5. 联调与上线检查

开发联调可以临时设置 `ALLOW_TEST_PURCHASES=true`，但只能用于隔离的测试环境。正式环境必须满足：

- `ALLOW_TEST_PURCHASES=false`；
- 使用 HTTPS，Node 端口不直接暴露公网；
- 完成 Apple App Store Server API 验证（当前仍未实现）；
- 在 Google Cloud 启用 Google Play Android Developer API，并为服务账号配置 Play Console 权限；
- 配置 `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64`，完成 Google Play 内部测试购买；
- 验证 Apple App Store Server Notifications V2 和 Google RTDN；
- 数据库每日备份，并定期验证恢复；
- 授权私钥放入密钥管理服务或受限环境变量；
- 购买、恢复、离线、退款、撤销和重新安装流程通过真实商店测试；
- 当前 JSON 存储中的开发数据若需保留，必须在切换前单独完成迁移；本项目不自动迁移旧 JSON 文件。

当前 `store-verifier.js` 的 Google Play 验证已实现；Apple App Store 验证和 Apple/Google Webhook 签名校验仍需完成后，才可以将双平台服务用于正式收费。
