# 专业版内购与离线授权实现说明

更新时间：2026-08-11
适用范围：一次性专业版买断，不添加用户注册，不上传工单业务数据

## 1. 目标和边界

专业版是用户向应用购买的数字功能解锁，和维修客户向维修师傅支付的工单费用是两个独立的钱域。

本方案只实现：

- Apple App Store / Google Play 非消耗型商品 `repair_pro_lifetime`；
- 服务端验证购买凭证并生成授权；
- App 使用平台安全存储缓存授权；
- 无网络时继续使用已激活的专业版；
- 更换设备或清除数据后通过商店恢复购买。

本方案暂不实现：

- 用户注册、登录和账号绑定；
- 云同步工单、客户、照片或签名；
- 维修客户在线支付；
- 自动续费订阅。

## 2. 专业版功能权限

| 功能 | 免费版 | 专业版 |
| --- | --- | --- |
| 新建工单 | 最多 30 张 | 无限 |
| 客户和基础报价 | 支持 | 支持 |
| 自定义项目模板 | 不支持新增和维护 | 支持 |
| 统计复盘 | 不支持 | 支持 |
| PDF / PNG 单据导出 | 不支持 | 支持 |
| 客户电子签名 | 不支持 | 支持 |
| 维修照片附件 | 查看已有内容 | 支持新增和维护 |
| 本地 JSON / CSV 备份 | 支持 | 支持 |

历史数据不能因为未购买专业版而被删除或锁死。达到免费工单上限后，只阻止新增工单。

## 3. 购买和缓存流程

```text
应用启动
  ├─ 先订阅商店购买事件
  ├─ 从安全存储加载授权快照
  └─ 继续进入离线工作台

用户购买
  ├─ App Store / Google Play 发起非消耗型购买
  ├─ purchaseStream 返回 purchased / restored
  ├─ App 将平台验证数据提交授权服务
  ├─ 服务端验证成功并返回授权快照
  ├─ App 写入安全存储
  └─ 完成商店交易
```

一次性买断没有到期时间。已激活的本地快照在离线时继续有效；联网时可以通过恢复购买或新的平台回调校正退款、撤销状态。

授权缓存不是工单 JSON 的一部分，也不应进入 JSON 备份文件。清除应用数据后必须从商店恢复购买。

## 4. Flutter 端结构

```text
lib/features/monetization/
├── domain/
│   ├── entities/entitlement.dart
│   └── repositories/entitlement_repository.dart
├── data/
│   ├── billing_gateway.dart
│   ├── local_entitlement_repository.dart
│   └── purchase_verifier.dart
├── application/
│   └── entitlement_controller.dart
└── presentation/
    └── pro_page.dart
```

职责约定：

- `Entitlement` 保存授权状态和专业版功能集合；
- `BillingGateway` 隔离 `in_app_purchase`；
- `LocalEntitlementRepository` 使用 `flutter_secure_storage`；
- `RemotePurchaseVerifier` 调用 Node 授权服务并校验 Ed25519 签名；
- `EntitlementController` 编排购买、恢复、验证、缓存和错误状态；
- 页面通过 `FeatureAccessService` 判断权限，不直接读取商店或本地存储。

## 5. Node 授权服务

服务端位于根目录 `server/`，当前使用 Node.js 原生 HTTP 和开发期 JSON 文件存储。

```text
server/
├── src/config.js
├── src/entitlement.js
├── src/server.js
├── src/store.js
├── src/store-verifier.js
└── src/generate-keys.js
```

接口：

```text
GET  /healthz
POST /v1/purchases/verify
POST /v1/purchases/restore
POST /v1/webhooks/apple
POST /v1/webhooks/google
```

当前不添加账号，因此购买记录使用平台、商品 ID 和交易标识关联。服务端不保存工单内容。

开发模式可以设置 `ALLOW_TEST_PURCHASES=true` 生成测试授权。正式环境必须关闭该开关，并在 `src/store-verifier.js` 接入真实的 Apple App Store Server API 和 Google Play Developer API。

## 6. 构建参数

App 通过构建参数指定授权服务和授权公钥：

```powershell
flutter build apk --release `
  --dart-define=ENTITLEMENT_SERVER_URL=https://license.example.com `
  --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=...
```

开发时可以只设置服务地址并允许无签名响应；Release 构建必须配置公钥并要求签名授权。

服务端生成 Ed25519 密钥：

```powershell
cd server
npm run generate-keys
```

私钥只放在服务端环境变量中，公钥才可以编译进 App。私钥、商店服务账号和真实凭证不能提交到仓库。

## 7. 当前实现状态

- [x] 创建 Node 授权服务目录、健康检查、验证和恢复接口骨架；
- [x] 创建开发期 JSON 授权存储和交易幂等结构；
- [x] 创建 Flutter 专业版实体、权限规则、安全存储仓库；
- [x] 创建商店网关、购买事件转换和远程验证客户端；
- [x] 加入 `in_app_purchase`、`flutter_secure_storage`、`cryptography` 和 `http` 依赖；
- [x] 将专业版页面和设置入口接入应用壳层；
- [x] 将模板、统计、单据导出、签名、照片和工单数量限制接入权限判断；
- [ ] 完成 Node 服务端真实 Apple / Google 凭证验证；
- [ ] 配置商店商品、生产 HTTPS、Webhook 和正式签名密钥；
- [ ] 补充购买、恢复、离线、退款和撤销测试。

当前代码已完成开发测试链路：Flutter 静态分析和 31 项 Flutter 测试已通过，Node 授权服务的 4 项测试（含启动级集成测试）已通过；真实商店购买、退款/撤销回调和生产环境凭证验证仍需在商店测试环境及正式服务端配置完成后验证。

## 8. 上线前必须完成

1. 在 App Store Connect 和 Google Play Console 创建非消耗型商品 `repair_pro_lifetime`；
2. 为正式包配置正确的 Bundle ID、Android application ID 和签名；
3. 服务端使用 PostgreSQL 等可靠数据库替换开发期 JSON 文件；
4. 接入并验证 Apple / Google 服务器通知；
5. 关闭测试购买和无签名授权；
6. 使用真实测试账号完成购买、恢复、退款和重新安装回归。
