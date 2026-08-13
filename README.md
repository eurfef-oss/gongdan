# 维修工单助手

面向个体维修师傅和小型维修店的离线优先工单工具。客户、设备、报价、维修记录、签名、照片、收款和保修集中在一张工单里完成。

## 当前能力

- 本地离线保存客户、项目模板、工单、照片索引、签名和收款记录；
- 工单状态流转：完整新建自动进入待确认，确认报价后直接进入维修中，再到待收款和已完成；未完整工单保留草稿，历史已确认状态继续兼容；
- 数量、单价、优惠和部分收款金额计算；
- 报价单与维修凭证预览、PNG / PDF 保存到本地和系统分享；
- 报价确认金额留痕，修改已确认报价后自动要求重新确认；
- 维修前 / 维修中 / 维修后照片分类；
- 客户电子签名和保修期限记录；
- 工单搜索、状态 / 收款 / 创建日期 / 服务日期 / 客户 / 设备类型筛选；
- 普通版最多创建 10 张工单和 10 个客户档案；专业版按购买授权解锁无限数量；
- 已完成、已取消工单禁止编辑；工单支持移入回收站和还原；工单详情页顶部“更多操作”菜单提供取消工单和移入回收站入口；
- 项目模板支持内置类型和自定义类型维护，使用中的类型禁止删除，未使用类型可删除；顶部管理操作独立成行，窄屏下可自动换行；
- 专业版提供内部成本录入、成本类型设置和项目统计中的成本利润分析；成本类型设置从内部成本页的三级页面进入，成本数据不会出现在客户单据中；
- 概览设置提供独立二级页面，支持拖动模块排序和控制显示；数据概览中的四项指标作为合并卡片使用一个开关；工单进度卡片展示待确认、维修中（含已确认）、待收款和已完成且每项单独一行，不展示草稿与已取消；工单、客户、项目模板页滚动时会收起顶部说明区域；
- 数据备份页提供完整 JSON 备份、JSON 恢复以及工单 CSV 导入导出；
- 应用私有目录 JSON 主存储、旧 SharedPreferences 数据迁移和存储异常内存兜底；
- Material 3、浅色 / 深色模式和中英文本地化基础设施。

专业版收费功能按“非消耗型一次性买断 + 本地离线授权缓存”实现。授权不上传工单业务数据，购买验证服务位于根目录 `server/`，授权记录使用 MariaDB；当前已完成 Flutter 页面、设置入口、专业权限拦截和 Android Google Play 真实购买验证，生产服务账号和商店联调仍需配置。

## 目录

```text
lib/
├── app/                         应用根组件
├── core/
│   ├── errors/                  统一错误模型
│   ├── result/                  成功/失败结果模型
│   └── theme/                   浅色与深色主题
├── features/
│   ├── monetization/            专业版授权与内购
│   └── work_orders/             工单助手业务模块
│       ├── application/         状态与流程编排
│       ├── data/                数据实现
│       ├── domain/              实体和仓库接口
│       ├── services/            单据导出等外部能力
│       └── presentation/        页面与组件
├── l10n/                        中英文资源和生成文件
├── bootstrap.dart               初始化与依赖装配
└── main.dart                    唯一入口
server/                           Node.js 专业版授权服务
```

工单模块已按职责进一步拆分：

```text
features/work_orders/
├── application/controllers/     Order、Customer、Template、Settings、Backup
├── application/services/        备份与工单导出
├── domain/entities/             独立领域实体与 v1 → v2 → v3 数据迁移
├── services/                    文件选择、分享、单据生成等平台能力接口
└── presentation/
    ├── dashboard/ orders/ customers/ templates/
    ├── statistics/ settings/ shell/
    ├── dialogs/                 按业务流程拆分的弹窗
    └── shared/                  共用组件与辅助方法
```

`work_order_page.dart`、`work_order_dialogs.dart` 和旧的 `work_order_controller.dart` 仅作为兼容入口；具体页面、弹窗和状态逻辑位于对应子模块。平台服务由 `bootstrap.dart` 注入，页面层不直接调用文件选择器或系统分享 API。

## 本地开发

Flutter SDK 使用 `I:\sdk\flutter` 时：

```bash
I:\sdk\flutter\bin\flutter.bat pub get --offline
I:\sdk\flutter\bin\cache\dart-sdk\bin\dart.exe format lib test
I:\sdk\flutter\bin\cache\dart-sdk\bin\dart.exe analyze
I:\sdk\flutter\bin\cache\dart-sdk\bin\dart.exe test
```

如果修改了 ARB 文件，执行 `flutter gen-l10n` 生成本地化 Dart 文件。

### 专业版授权服务

需要 Node.js 20 或更高版本。开发期可启动测试授权服务：

```powershell
cd server
$env:ALLOW_TEST_PURCHASES='true'
npm start
```

服务端的正式验证、密钥和上线前检查见[专业版内购与离线授权实现说明](docs/monetization-implementation.md)。

### SDK 与构建工具路径

当前 Windows 构建环境使用以下固定路径：

| 工具 | 路径 |
| --- | --- |
| Flutter SDK | `I:\sdk\flutter` |
| Android SDK | `I:\sdk\android-sdk` |
| JDK 17 | `I:\sdk\jdk17\jdk-17.0.19+10` |
| Gradle Wrapper | `android\gradle\wrapper` |

## APK 构建（内部 Release 预览包）

Release APK 用于内部安装和验收，默认开启专业版预览：可以直接看到和使用专业版功能，但这是临时预览授权，不代表真实购买，也不会写入授权缓存。正式商店包必须使用下面的 AAB 构建规则。

```powershell
$env:FLUTTER_SUPPRESS_ANALYTICS='true'
$env:DART_SUPPRESS_ANALYTICS='true'
$env:ANDROID_HOME='I:\sdk\android-sdk'
$env:ANDROID_SDK_ROOT='I:\sdk\android-sdk'
$env:JAVA_HOME='I:\sdk\jdk17\jdk-17.0.19+10'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'I:\sdk\flutter\bin\flutter.bat' build apk --release `
  --dart-define=ENABLE_RELEASE_PRO_PREVIEW=true
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。`ENABLE_RELEASE_PRO_PREVIEW=true` 只允许在内部 Release APK 命令中使用；它不保存授权、不调用真实购买，也不能随 AAB 上传。当前 Release APK 适合内部安装测试；正式上架前必须配置独立的正式签名。调试包使用 `flutter build apk --debug` 显式构建。

## AAB 构建（Google Play）

AAB 是正式商店包，专业版功能默认必须通过 Google Play 购买并完成服务端验证。AAB 构建命令禁止传入 `ENABLE_RELEASE_PRO_PREVIEW=true`，否则会把内部预览规则带入正式包。

```powershell
& 'I:\sdk\flutter\bin\flutter.bat' build appbundle --release
```

产物位于 `build/app/outputs/bundle/release/app-release-<versionName>+<versionCode>.aab`（例如 `app-release-1.0.1+8.aab`，同时保留 Flutter 默认产物 `app-release.aab`）。具体版本、构建号、产物大小和 SHA-256 统一记录在[发布检查清单](docs/release-checklist.md)，本文件不重复维护具体构建记录。

## 版本号与构建号

每次 APK 或 AAB 打包前必须执行以下流程：

1. 查看 Google Play Console 已使用的最大 `versionCode`；
2. 修改 `pubspec.yaml` 的 `version`，使 `+` 后的版本代码严格大于该最大值和[发布检查清单](docs/release-checklist.md)中登记的版本代码；
3. 完成打包后只更新[发布检查清单](docs/release-checklist.md)中的版本与构建记录；
4. 如果商店提示版本代码已使用，立即递增版本代码并更新文档后再打包，不能重复使用旧代码。

## 工程约定

业务模块沿用 `domain → data → application → presentation` 分层：

- UI 不直接读写本地存储；
- domain 不依赖 Flutter UI；
- 本地数据默认只保存在设备，不上传业务服务器；
- 专业版授权快照保存在平台安全存储，不进入工单 JSON 备份；
- 专业版购买服务只处理商店交易和授权，不接收客户、工单、照片或签名数据；
- 备份可能包含客户姓名、电话、地址、照片和签名，分享前请确认接收方；
- 新增核心流程需补充成功、失败和边界测试。

## 发布前

- Android application ID 当前为 `com.cosdk.repairdesk`；正式发布前配置独立签名；
- 不提交 keystore、密钥或密码；
- 按“版本号与构建号”规则确认 `versionCode` 严格递增；
- 完成格式化、分析、测试和正式构建；
- 内部 Release APK 命令必须带 `--dart-define=ENABLE_RELEASE_PRO_PREVIEW=true`；正式 AAB 禁止带该参数；调试构建需显式使用 `flutter build apk --debug`；
- 验证命令：`flutter analyze`、`flutter test --no-pub`；
- 当前自动化测试基线：Flutter 38 项、Node 7 项全部通过；
- 真机验证安装、升级、深色模式、语言、大字体和系统安全区；
- 保存正式产物的 SHA-256 和版本说明。

产品需求与交付基线见：

- [维修工单助手 PRD](维修工单助手_PRD_v1.0.md)
- [项目开发与交付指南](project-development-delivery-guide.md)
- [发布检查清单](docs/release-checklist.md)
