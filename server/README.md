# 专业版授权服务

这是维修工单助手的最小授权服务。它只处理应用专业版购买凭证和授权状态，不接收工单、客户、照片或签名数据。授权记录使用 MariaDB 持久化。

## 本地运行

需要 Node.js 20 或更高版本和 MariaDB 10.6 或更高版本。开发模式允许使用测试购买，但测试开关不能用于正式环境：

```powershell
cd server
npm install
$env:STORE_DRIVER='mariadb'
$env:DB_HOST='127.0.0.1'
$env:DB_PORT='3306'
$env:DB_NAME='repair_license'
$env:DB_USER='repair_license'
$env:DB_PASSWORD='change-me'
$env:ALLOW_TEST_PURCHASES='true'
npm start
```

服务地址默认为 `http://localhost:8787`，健康检查：

```text
GET /healthz
```

本地开发模式下，`POST /v1/purchases/verify` 会接受 App 传来的测试交易信息并生成一次性专业版授权。服务启动时会自动创建 MariaDB 表。正式环境必须关闭 `ALLOW_TEST_PURCHASES`。Android 购买验证已通过 Google 服务账号调用 Google Play Developer API 的 `purchases.products.get`，并会在首次验证成功后调用 `acknowledge`。

自动化测试使用显式的 `STORE_DRIVER=memory` 内存替身，不会连接或修改 MariaDB；生产环境禁止使用该驱动。

## 主要接口

```text
POST /v1/purchases/verify
POST /v1/purchases/restore
POST /v1/webhooks/apple
POST /v1/webhooks/google
```

由于当前不添加用户注册，购买记录使用平台、商品 ID 和交易标识关联。跨设备恢复仍需 App 从 Apple/Google 获取历史交易后调用恢复接口。

## 授权签名

首次部署服务端时，在 `server` 根目录执行以下命令生成一对 Ed25519 授权签名密钥：

```powershell
cd I:\pro\gongdan\server
npm install
npm run generate-keys
```

Linux 服务器上执行：

```bash
cd /opt/repair-license/server
npm install --omit=dev
npm run generate-keys
```

命令会输出：

```text
ENTITLEMENT_PRIVATE_KEY_BASE64=...
ENTITLEMENT_PUBLIC_KEY_BASE64=...
```

配置规则：

- 将 `ENTITLEMENT_PRIVATE_KEY_BASE64` 的完整值配置到服务端环境变量（例如 `/etc/repair-license.env`），只允许服务端读取；
- 将 `ENTITLEMENT_PUBLIC_KEY_BASE64` 的值用于 Flutter 构建参数：

当前 `play.cosdk.com` 服务对应的公钥为：

```text
VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
```

Flutter 构建时使用：

```text
--dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
```

- 两个值都不要提交到 Git、写入公开文档或发送到客户端以外的公开位置；
- 生成后应安全备份这对密钥，后续部署继续使用同一对密钥；不要在每次部署时重新生成，否则已经安装的 App 无法验证旧的离线授权缓存；
- 如果私钥泄露，应立即生成新密钥、更新服务端环境变量，并重新构建发布 App。旧版本 App 将无法验证新签发的授权，因此密钥轮换需要安排版本升级。

签名是防止本地授权缓存被直接修改的保护层，不等于可以阻止对客户端代码的逆向修改。

## Google Play Developer API 配置

1. 在 Google Cloud 项目启用 Google Play Android Developer API；
2. 创建服务账号并生成 JSON 密钥；
3. 在 Google Play Console 的“用户和权限”中添加服务账号邮箱，授予读取订单/购买状态所需权限；
4. 将 JSON 文件转换为单行 Base64，配置到 `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64`；
5. 确认 `ANDROID_PACKAGE_NAME=com.cosdk.repairdesk` 和商品 ID `repair_pro_lifetime` 与 Play Console 一致。

服务端会使用服务账号 JWT 换取 OAuth access token，并调用：

```text
GET  https://androidpublisher.googleapis.com/androidpublisher/v3/
     applications/{packageName}/purchases/products/{productId}/tokens/{token}
POST .../tokens/{token}:acknowledge
```

服务端只保存订单号和购买 token 的关联，不保存服务账号 JSON。服务账号 JSON、数据库密码和 Ed25519 私钥必须通过受限环境变量或密钥管理服务注入。

## 正式环境注意事项

- 必须使用 HTTPS。
- `ALLOW_TEST_PURCHASES` 必须为 `false`。
- Apple webhook 必须验证 App Store Server Notifications V2 的签名。
- Google webhook 必须通过 Real-time Developer Notifications 收到事件后，再调用 Google API 查询真实状态；当前 Webhook 签名校验仍需补充。
- 购买记录使用 MariaDB；请配置定期备份、最小权限数据库用户和连接池上限。

系统架构、MariaDB 表结构和完整部署步骤见 [ARCHITECTURE-AND-DEPLOYMENT.md](ARCHITECTURE-AND-DEPLOYMENT.md)。
