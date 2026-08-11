# 发布检查清单

## 代码与测试

- [x] `dart format lib test` 已执行
- [x] `flutter analyze` 无问题
- [x] `flutter test --no-pub` 全部通过（31 项）
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

- [ ] 应用标识和签名正确
- [ ] 版本号和构建号已提高
- [x] 默认 Release APK 构建成功（当前使用 Debug 签名，仅供内部测试）
- [x] Debug APK 构建成功（仅作为显式调试变体）
- [ ] Release AAB 构建成功（本次按要求不构建）
- [ ] 真机全新安装和升级通过
- [x] 已记录产物大小和 SHA-256
- [x] 已更新版本说明和相关文档

## 本次 Release 验证记录（2026-08-11）

默认使用 `flutter build apk --release`，使用本机缓存的 Gradle 9.1.0、JDK 17 和 Android SDK 36 完成 Release APK 构建。当前固定 SDK 路径为：

- Flutter SDK：`I:\sdk\flutter`
- Android SDK：`I:\sdk\android-sdk`
- JDK 17：`I:\sdk\jdk17\jdk-17.0.19+10`
- Gradle Wrapper：`android\gradle\wrapper`

当前版本为 `1.0.0+1`：

| 产物 | 大小 | SHA-256 |
| --- | ---: | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 57,903,867 bytes（55.22 MB） | `7F5BF093CF2EA94570893491C1E2CA353C05C3F8AF582DCB644AA397507B2684` |

Release 变体当前使用 Flutter 模板的 debug signing config，正式商店发布前仍需替换为独立签名并完成真机安装、升级和分享验证。

说明：当前 Release APK 为 55.22 MB，使用 Debug 签名，仅供内部安装测试；正式商店发布前需配置正式签名，并完成真机安装、升级和 AAB 验证。
