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

本地开发模式下，`POST /v1/purchases/verify` 会接受 App 传来的测试交易信息并生成一次性专业版授权。服务启动时会自动创建 MariaDB 表。正式环境必须关闭 `ALLOW_TEST_PURCHASES`，并在 `src/store-verifier.js` 中接入 Apple App Store Server API 和 Google Play Developer API。

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

可使用 `npm run generate-keys` 生成 Ed25519 私钥。服务端用私钥签名授权 payload，Flutter 端通过构建参数配置公钥：

```text
--dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=...
```

签名是防止本地授权缓存被直接修改的保护层，不等于可以阻止对客户端代码的逆向修改。

## 正式环境注意事项

- 必须使用 HTTPS。
- `ALLOW_TEST_PURCHASES` 必须为 `false`。
- Apple webhook 必须验证 App Store Server Notifications V2 的签名。
- Google webhook 必须通过 Real-time Developer Notifications 收到事件后，再调用 Google API 查询真实状态。
- 购买记录使用 MariaDB；请配置定期备份、最小权限数据库用户和连接池上限。

系统架构、MariaDB 表结构和完整部署步骤见 [ARCHITECTURE-AND-DEPLOYMENT.md](ARCHITECTURE-AND-DEPLOYMENT.md)。
