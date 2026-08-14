# 专业版内购与离线授权实现说明

更新时间：2026-08-14
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
| 新建工单 | 最多 10 张 | 无限 |
| 客户档案 | 最多 10 个 | 无限 |
| 基础报价 | 支持 | 支持 |
| 自定义项目模板 | 不支持新增和维护 | 支持 |
| 统计复盘 | 不支持 | 支持 |
| 内部成本录入与成本利润统计 | 不支持 | 支持 |
| PDF / PNG 单据导出 | 支持 | 支持 |
| 客户电子签名 | 支持 | 支持 |
| 维修照片附件 | 支持新增和维护 | 支持新增和维护 |
| 本地 JSON / CSV 备份 | 支持 | 支持 |

历史数据不能因为未购买专业版而被删除或锁死。普通版达到 10 张工单或 10 个客户档案上限后，只阻止新增对应数据；专业版按购买授权解锁对应功能。

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

### 3.1 购买失败但商店显示“已拥有”

`repair_pro_lifetime` 是一次性买断商品，不是自动续费订阅。若 Google Play 已显示“已拥有”，但 App 因服务端验证失败没有解锁，不要再次购买：

1. 完全退出并重新打开 App；
2. 进入专业版页面，点击“恢复购买”；
3. App 会重新提交 Google Play 购买 token，服务端验证成功后签发授权并完成交易；
4. 若仍失败，先查看服务端错误，再修复服务端配置或代码后重复“恢复购买”。

购买验证失败时，App 会保留平台交易等待后续重试，不应通过清除应用数据或重复付款来处理。专业版页面在“恢复购买”按钮下方会提示这一路径。

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

服务端位于根目录 `server/`，使用 Node.js 原生 HTTP 和 MariaDB 持久化授权记录；自动化测试使用内存替身。

```text
server/
├── src/config.js
├── src/entitlement.js
├── src/server.js
├── src/mariadb-store.js
├── src/memory-store.js
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

开发模式可以设置 `ALLOW_TEST_PURCHASES=true` 生成测试授权。正式环境必须关闭该开关。Android 已接入 Google Play Developer API 的真实购买查询和购买确认；Apple App Store Server API 尚未实现。

Google Play `ProductPurchase.orderId` 按 API 定义是可选字段。服务端在确认 `purchaseState=0` 后，如果响应没有 `orderId`，会使用包名、商品 ID 和已由 Google 验证的购买 token 生成稳定的服务端交易标识；不会信任客户端提交的订单号。

## 6. 构建参数与 APK/AAB 规则

App 通过构建参数指定授权服务和授权公钥：

```powershell
flutter build apk --release `
  --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
  --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
```

### 6.1 内部 Release APK：专业版预览

Release APK 是内部预览包。为了让验收人员可以直接看到和使用完整专业版功能，内部 APK 必须额外传入：

```powershell
flutter build apk --release `
  --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
  --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0 `
  --dart-define=ENABLE_RELEASE_PRO_PREVIEW=true
```

该预览授权只在当前进程内存中生效，不读取或写入真实授权缓存，不调用应用商店，不调用购买验证服务。页面会标记为“专业版预览”。它仅适用于内部 Release APK，不是购买凭证，也不能作为正式授权依据。

### 6.2 正式 Release AAB：必须购买专业版

AAB 是 Google Play 正式商店包，构建时不传 `ENABLE_RELEASE_PRO_PREVIEW`：

```powershell
flutter build appbundle --release `
  --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
  --dart-define=ENTITLEMENT_PUBLIC_KEY_BASE64=VMldFKpeLYde9nrAXCWIqAinjieV8zed51G2pZy3NT0
```

未购买或未恢复到有效授权时，AAB 必须按免费版权限运行；购买、恢复购买和服务端签名验证仍走正常流程。发布前应检查最终 AAB 的构建参数和页面行为，确认没有带入 `ENABLE_RELEASE_PRO_PREVIEW=true`。

开发时可以只设置服务地址并允许无签名响应；Release 构建必须配置公钥并要求签名授权。

为了在尚未接入真实 Apple 凭证验证时测试 App 内页面和离线缓存，Debug 构建可以显式开启本地测试购买：

```powershell
flutter build apk --debug `
  --dart-define=ENTITLEMENT_SERVER_URL=https://play.cosdk.com `
  --dart-define=ENABLE_LOCAL_TEST_PURCHASE=true
```

该模式下点击“购买专业版”或“恢复购买”会直接生成并缓存本地测试授权，不会调用真实商店，也不会写入服务端；`kDebugMode` 会确保 Release 构建不会启用此开关。正式测试 Google Play 购买时必须去掉该参数，并通过 Google Play 内部测试轨道安装。不要把 `ENABLE_LOCAL_TEST_PURCHASE` 或 `ENABLE_RELEASE_PRO_PREVIEW` 传给正式 AAB。

服务端生成 Ed25519 密钥：

```powershell
cd server
npm run generate-keys
```

私钥只放在服务端环境变量中，公钥才可以编译进 App。私钥、商店服务账号和真实凭证不能提交到仓库。

## 7. 当前实现状态

- [x] 创建 Node 授权服务目录、健康检查、验证和恢复接口骨架；
- [x] 创建 MariaDB 授权存储、自动建表和交易幂等结构；
- [x] 创建 Flutter 专业版实体、权限规则、安全存储仓库；
- [x] 创建商店网关、购买事件转换和远程验证客户端；
- [x] 加入 `in_app_purchase`、`flutter_secure_storage`、`cryptography` 和 `http` 依赖；
- [x] 将专业版页面和设置入口接入应用壳层；
- [x] 将模板、统计和工单数量限制接入权限判断；
- [x] PDF/PNG 单据导出、客户签名和照片附件对所有版本开放，不受专业版权限限制；
- [x] 完成 Node 服务端 Google Play Developer API 购买凭证验证和购买确认；
- [ ] 完成 Node 服务端真实 Apple 凭证验证；
- [x] 配置 Google Play 商品、生产 HTTPS 和 Android 正式上传签名；
- [ ] 完成 Apple 商品、Webhook 和 Apple 正式签名配置；
- [x] 补充 Google Play 购买状态、购买确认、未配置凭证和离线缓存测试；
- [ ] 补充真实商店购买、恢复、退款和撤销测试。

当前代码已完成开发测试链路。Release AAB 的版本号、版本代码、产物信息和 Google Play 版本代码占用记录统一见[发布检查清单](release-checklist.md)，本文件不重复维护具体构建记录。已修复 Android 商品查询的 `GooglePlayProductDetails` 泛型运行时错误、取消支付后按钮持续显示“正在处理”的问题，以及部分有效购买响应缺少 `orderId` 时无法恢复的问题；服务端生产健康检查和 Google Play API 鉴权联调已完成，真实商店购买、恢复、退款/撤销回调和内部测试轨道验证仍需完成。

## 8. 上线前必须完成

1. 在 App Store Connect 和 Google Play Console 创建非消耗型商品 `repair_pro_lifetime`；
2. 为正式包配置正确的 Bundle ID、Android application ID 和签名；
3. 为 MariaDB 配置定期备份、监控和故障恢复演练；
4. 接入并验证 Apple / Google 服务器通知；
5. 关闭测试购买和无签名授权；
6. 使用真实测试账号完成购买、恢复、退款和重新安装回归。
