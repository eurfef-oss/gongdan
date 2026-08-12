# 发布检查清单

## 代码与测试

- [x] `dart format lib test` 已执行
- [x] `flutter analyze` 无问题
- [x] `flutter test --no-pub` 全部通过（32 项）
- [x] 关键失败和边界场景有测试（部分收款、关闭限制、字段清空、报价重新确认、PDF 编码、回收站、自定义类型、概览卡片设置）

## 本次功能变更记录（2026-08-11）

- [x] 数据备份页调整为完整 JSON、恢复 JSON、导出工单 CSV、导入工单 CSV 的操作顺序；
- [x] 项目模板页顶部“管理类型”和“新建模板”按钮独立成行，并支持窄屏换行；
- [x] 工单详情页顶部新增“更多操作”菜单，集中提供“取消工单”和“移入回收站”入口；
- [x] 专业版页面、设置入口、专业功能权限拦截和本地离线授权缓存接入；
- [x] Node 授权服务开发期验证、恢复、幂等和授权签名链路接入；

## 体验

- [ ] 中文、英文和长文本无溢出
- [ ] 浅色、深色和系统跟随正常
- [ ] 小屏、横屏和大字体正常
- [ ] 键盘、底部安全区和滚动正常
- [ ] 空状态、错误状态和无权限状态清晰

## 安全与数据

- [ ] 密钥、签名和密码未进入仓库
- [ ] 日志不包含敏感信息
- [x] 数据升级和迁移已验证（v1 → v2 → v3，含 SharedPreferences → 应用私有 JSON 文件）
- [x] 导入文件进行内容校验
- [ ] 隐私政策与实际数据行为一致

## 构建与发布

- [x] 应用标识和 Release 上传签名正确
- [x] 版本号和构建号已提高（当前为 `1.0.1+3`）
- [x] Release AAB 构建成功并通过签名校验
- [x] Debug APK 构建成功（仅作为显式调试变体）
- [ ] 真机全新安装和升级通过
- [x] 已记录产物大小和 SHA-256
- [x] 已更新版本说明和相关文档

## 本次 Release 验证记录（2026-08-12）

使用 Flutter、Gradle、JDK 17 和 Android SDK 完成正式 AAB 构建。构建命令包含生产授权服务地址和对应的 Ed25519 公钥，未启用 `ENABLE_LOCAL_TEST_PURCHASE`。当前固定 SDK 路径为：

- Flutter SDK：`I:\sdk\flutter`
- Android SDK：`I:\sdk\android-sdk`
- JDK 17：`I:\sdk\jdk17\jdk-17.0.19+10`
- Gradle Wrapper：`android\gradle\wrapper`

当前版本为 `1.0.1+3`：

| 产物 | 大小 | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/bundle/release/app-release.aab` | 59,605,730 bytes（56.8 MB） | `92DADCBCBB797BADBAA5B134A7A0BD640A723334DDCBC8080FCE3C2781157C76` |

校验结果：

- 包名：`com.cosdk.repairdesk`；
- 签名证书：`CN=RepairDesk, OU=cosdk, O=cosdk, C=CN`；
- 签名校验：`jarsigner -verify` 通过；
- 服务端：`https://play.cosdk.com/healthz` 返回 HTTP 200，`testPurchasesEnabled=false`，商品 ID 为 `repair_pro_lifetime`；
- 构建参数：`ENTITLEMENT_SERVER_URL=https://play.cosdk.com`，使用已登记的公钥，未启用本地测试购买。

仍需在 Google Play 内部测试轨道完成 AAB 上传、测试账号安装、真实购买、恢复购买、离线使用和重新安装验证。
