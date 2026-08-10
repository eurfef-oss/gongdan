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
- 已完成、已取消工单禁止编辑；工单支持移入回收站和还原；
- 项目模板支持内置类型和自定义类型维护，使用中的类型禁止删除，未使用类型可删除；
- 概览卡片支持显示 / 隐藏和拖动排序；工单进度卡片展示待确认、维修中（含已确认）、待收款和已完成，不展示草稿与已取消；工单、客户、项目模板页滚动时会收起顶部说明区域；
- JSON 完整备份恢复、CSV 工单导出；
- 应用私有目录 JSON 主存储、旧 SharedPreferences 数据迁移和存储异常内存兜底；
- Material 3、浅色 / 深色模式和中英文本地化基础设施。

## 目录

```text
lib/
├── app/                         应用根组件
├── core/
│   ├── errors/                  统一错误模型
│   ├── result/                  成功/失败结果模型
│   └── theme/                   浅色与深色主题
├── features/
│   └── work_orders/             工单助手业务模块
│       ├── application/         状态与流程编排
│       ├── data/                数据实现
│       ├── domain/              实体和仓库接口
│       ├── services/            单据导出等外部能力
│       └── presentation/        页面与组件
├── l10n/                        中英文资源和生成文件
├── bootstrap.dart               初始化与依赖装配
└── main.dart                    唯一入口
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

## APK 构建（默认 Release）

本项目默认构建 Release APK。使用 Flutter 命令打包时显式指定 `--release`；只有需要调试 Dart 代码时才使用 `--debug`。

```powershell
$env:FLUTTER_SUPPRESS_ANALYTICS='true'
$env:DART_SUPPRESS_ANALYTICS='true'
& 'I:\sdk\flutter\bin\flutter.bat' build apk --release
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。当前 Release 构建仍使用 Android 模板的 Debug 签名，适合内部安装测试；正式上架前必须配置独立的正式签名。调试包使用 `flutter build apk --debug` 显式构建。

## 工程约定

业务模块沿用 `domain → data → application → presentation` 分层：

- UI 不直接读写本地存储；
- domain 不依赖 Flutter UI；
- 本地数据默认只保存在设备，不上传业务服务器；
- 备份可能包含客户姓名、电话、地址、照片和签名，分享前请确认接收方；
- 新增核心流程需补充成功、失败和边界测试。

## 发布前

- Android application ID 当前为 `com.example.repairworkorderassistant`；正式发布前配置独立签名；
- 不提交 keystore、密钥或密码；
- 提高版本号和构建号；
- 完成格式化、分析、测试和正式构建；
- 默认构建命令：`flutter build apk --release`；调试构建需显式使用 `flutter build apk --debug`；
- 验证命令：`flutter analyze`、`flutter test --no-pub`；
- 当前自动化测试基线：24 项全部通过；
- 真机验证安装、升级、深色模式、语言、大字体和系统安全区；
- 保存正式产物的 SHA-256 和版本说明。

产品需求与交付基线见：

- [维修工单助手 PRD](维修工单助手_PRD_v1.0.md)
- [项目开发与交付指南](project-development-delivery-guide.md)
- [发布检查清单](docs/release-checklist.md)
