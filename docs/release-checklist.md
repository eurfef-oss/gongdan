# 发布检查清单

## 版本与构建登记（唯一记录）

- `pubspec.yaml`：`1.0.1+11`；
- `versionName`：`1.0.1`；
- `versionCode`：`11`；
- 已确认 Google Play 不可复用的版本代码：`5`、`6`、`7`、`8`；
- 下一次用于商店上传的版本代码必须高于 Google Play Console 已使用的最大值；本次按要求使用 `11`，后续如已上传则继续递增。

| 产物 | 构建日期 | 大小 | SHA-256 |
| --- | --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 2026-08-17 | 62,840,347 bytes（59.93 MB） | `B1DCA566BA9C421660B9536A32158ABABCA1AC7CDA8F9C9074B00CD19C727537` |
| `build/app/outputs/bundle/release/app-release-1.0.1+11.aab` | 2026-08-17 | 62,924,024 bytes（60.01 MB） | `FEAADA5B6359879624F194C15708CBE6444EE4D23D9393E273B5A7EE3048E462` |

版本代码记录：

| versionName | versionCode | 状态 | 备注 |
| --- | ---: | --- | --- |
| `1.0.1` | `5` | 已占用 | Google Play 提示版本代码已使用 |
| `1.0.1` | `6` | 已占用 | Google Play 提示版本代码已使用 |
| `1.0.1` | `7` | 已占用 | Google Play 提示版本代码已使用 |
| `1.0.1` | `8` | 已占用 | Google Play 提示版本代码已使用 |
| `1.0.1` | `9` | 历史构建 | 此前 Release AAB 已构建 |
| `1.0.1` | `11` | 当前记录 | Release AAB 已构建，产物文件名包含版本名和版本代码 |

## APK/AAB 专业版授权规则

- 内部 Release APK 必须使用 `--dart-define=ENABLE_RELEASE_PRO_PREVIEW=true`，用于直接验收专业版功能；预览授权只驻留内存，不写入授权缓存，也不代表真实购买。
- 正式 Release AAB 禁止使用 `ENABLE_RELEASE_PRO_PREVIEW=true`；未购买时必须显示免费版权限，购买、恢复购买和服务端验证按正式流程执行。
- [x] 已检查正式 AAB 构建命令未包含 `ENABLE_RELEASE_PRO_PREVIEW=true` 或 `ENABLE_LOCAL_TEST_PURCHASE=true`

## 代码与测试

- [x] `dart format lib test` 已执行
- [x] `flutter analyze` 无问题
- [x] `flutter test --no-pub` 全部通过（51 项）
- [x] 关键失败和边界场景有测试（部分收款、关闭限制、字段清空、报价重新确认、PDF 编码、回收站、自定义类型、概览卡片设置）

## 本次功能变更记录（2026-08-11）

- [x] 数据备份页调整为完整 JSON、恢复 JSON、导出工单 CSV、导入工单 CSV 的操作顺序；
- [x] 项目模板页顶部“管理类型”和“新建模板”按钮独立成行，并支持窄屏换行；
- [x] 工单详情页顶部新增“更多操作”菜单，集中提供“取消工单”和“移入回收站”入口；
- [x] 专业版页面、设置入口、专业功能权限拦截和本地离线授权缓存接入；
- [x] Node 授权服务开发期验证、恢复、幂等和授权签名链路接入；

## 本次功能变更记录（2026-08-13）

- [x] 普通版工单和客户档案数量上限由 5/3 调整为 10/10，专业版继续按授权解锁无限数量；
- [x] 内部成本录入、成本类型设置和成本利润统计纳入专业版权限；
- [x] 成本类型设置从设置二级入口移除，改为内部成本页面下的三级页面；
- [x] 内部成本列表将单号、设备名称、应收金额和成本记录数量分行显示，避免窄屏内容截断；

## 本次功能变更记录（2026-08-14）

- [x] 概览中的 4 张数据指标卡片改为单列显示，避免英文模式下指标名称在两列布局中被截断；
- [x] 统计页“工单总数”等 7 张数据指标卡片改为单列显示；
- [x] 默认项目模板保留为可直接使用的模板，英文模式下显示英文名称；新建/编辑工单底部操作区在窄屏下自动换行；
- [x] 首次数据改为空白门店资料、客户、工单和付款记录，移除载入演示数据功能；
- [x] 设置页将内部成本入口归入“工作台工具”分类；

## 本次联调修复记录（2026-08-14）

- [x] 统一正式 Android 包名为 `com.cosdk.repairdesk`，并同步服务端 `ANDROID_PACKAGE_NAME`；
- [x] Google Play 服务账号已绑定 `RepairDesk / com.cosdk.repairdesk`，具备购买查询和订单管理权限；
- [x] Google Play Android Developer API 鉴权联调通过；无效 token 测试返回 `422 invalid_purchase`；
- [x] 服务端兼容 Google Play 有效购买响应缺少 `orderId` 的情况，使用已验证 token 生成稳定内部交易标识；
- [x] 专业版页面补充“购买失败但显示已拥有时点击恢复购买”的操作提示；
- [ ] 将新的服务端验证器部署到生产服务器，并使用原真实订单完成一次恢复购买和解锁验证；

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
- [x] 打包前已核对商店已使用的最大版本代码（具体版本见本页“版本与构建登记”）
- [x] Release AAB 构建成功并通过签名校验
- [x] 内部 Release APK 已使用专业版预览参数重新构建（产物见上表）
- [x] Debug APK 构建成功（仅作为显式调试变体）
- [ ] 真机全新安装和升级通过
- [x] 已记录产物大小和 SHA-256
- [x] 已更新版本说明和相关文档

## 本次 Release 验证记录（2026-08-17）

使用 Flutter、Gradle、JDK 17 和 Android SDK 完成正式 AAB 构建。构建命令包含生产授权服务地址和对应的 Ed25519 公钥，未启用 `ENABLE_LOCAL_TEST_PURCHASE` 或 `ENABLE_RELEASE_PRO_PREVIEW`。内部 Release APK 另行使用 `ENABLE_RELEASE_PRO_PREVIEW=true` 构建，只用于专业版功能验收。当前固定 SDK 路径为：

- Flutter SDK：`I:\sdk\flutter`
- Android SDK：`I:\sdk\android-sdk`
- JDK 17：`I:\sdk\jdk17\jdk-17.0.19+10`
- Gradle Wrapper：`android\gradle\wrapper`

校验结果：

- 包名：`com.cosdk.repairdesk`；
- 签名证书：`CN=RepairDesk, OU=cosdk, O=cosdk, C=CN`；
- 签名校验：`jarsigner -verify` 通过；
- 服务端：`https://play.cosdk.com/healthz` 返回 HTTP 200，`testPurchasesEnabled=false`，商品 ID 为 `repair_pro_lifetime`；
- 构建参数：`ENTITLEMENT_SERVER_URL=https://play.cosdk.com`，使用已登记的公钥，未启用本地测试购买。
- 购买商品查询修复：移除 Android 商品列表的 `firstWhere(orElse:)` 泛型回退，改为精确商品 ID 匹配，避免 `GooglePlayProductDetails` 运行时类型错误；
- 购买取消修复：处理 Google Play 取消支付时可能返回的空商品 ID，并加入购买窗口超时兜底，未付款返回后按钮会恢复可点击；
- Flutter 验证：`flutter analyze` 无问题，51 项测试全部通过。
- 内部 APK：使用 `--dart-define=ENABLE_RELEASE_PRO_PREVIEW=true` 重新构建成功；预览授权仅用于内部验收，不写入购买缓存。
- APK 校验：文件大小 `62,840,347` bytes，SHA-256 为 `B1DCA566BA9C421660B9536A32158ABABCA1AC7CDA8F9C9074B00CD19C727537`，Android `versionCode=11`，Android `apksigner` v2 校验通过；包名为 `com.cosdk.repairdesk`。
- 正式 AAB：不含专业版预览开关，构建成功；文件名为 `app-release-1.0.1+11.aab`，文件大小 `62,924,024` bytes，SHA-256 为 `FEAADA5B6359879624F194C15708CBE6444EE4D23D9393E273B5A7EE3048E462`，Release manifest `versionCode=11`，`jarsigner -verify` 通过。

## 本次功能变更记录（2026-08-17）

- [x] 首次进入按系统语言默认中文或英文，已有语言设置不被覆盖；
- [x] 欢迎页改为可左右滑动的功能 Banner，每项功能配套插画；
- [x] 欢迎页采用自适应高度布局，按钮在小屏可视区域内直接点击，无需向下滑动；
- [x] 语言设置中增加“打开欢迎页”入口，便于调试首次安装流程；
- [x] 三张欢迎页配图按 App 图标和宣传图风格重绘，并统一为绿色背景；
- [x] Google Play 版本代码提升为 `11`，完成新的 Release APK/AAB 构建；

仍需在 Google Play 内部测试轨道完成 AAB 上传、测试账号安装、真实购买、恢复购买、离线使用和重新安装验证。
