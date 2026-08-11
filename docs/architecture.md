# 架构说明

## 依赖方向

```text
presentation → application → domain
       data ───────────────→ domain
bootstrap 负责创建实现并注入 application
```

- `domain` 不依赖其他业务层；
- `data` 实现 `domain` 的仓库接口；
- `application` 依赖仓库接口，不依赖具体存储；
- `presentation` 监听控制器并发送用户意图；
- `bootstrap` 是唯一依赖装配位置。

## 当前工单模块结构

```text
features/work_orders/
├── domain/entities/             客户、工单、付款、附件、设置及应用数据实体
├── data/                        本地 JSON 文件仓库与 SharedPreferences 迁移入口
├── application/
│   ├── controllers/             Order、Customer、Template、Settings、Backup 控制器
│   ├── services/                BackupService 与 WorkOrderExportService
│   ├── work_order_store.dart    控制器共享状态与持久化协调
│   └── work_order_controller.dart 兼容旧调用方的轻量入口
├── services/                    DocumentService 及文件/分享/单据能力接口
└── presentation/
    ├── shell/                   页面导航和应用壳层
    ├── dashboard/               概览
    ├── orders/                  工单
    ├── customers/               客户
    ├── templates/               项目模板
    ├── statistics/              统计
    ├── settings/                设置与回收站
    ├── dialogs/                 按业务流程拆分的编辑、付款、签名和预览弹窗
    └── shared/                  页面通用组件与辅助方法
```

页面入口 `work_order_page.dart` 和弹窗入口 `work_order_dialogs.dart` 仅保留兼容性转发，业务实现位于对应子目录。平台能力由 `bootstrap.dart` 创建并注入，Presentation 层不直接依赖 `FilePicker` 或 `SharePlus`。

## 数据版本

持久化 JSON 当前版本为 v3。读取旧数据时按顺序执行 `v1 → v2 → v3` migration；来自旧版 `SharedPreferences` 的快照先经过同一套迁移，再写入应用私有目录。未知的更高版本会被拒绝，避免静默丢失字段。

## 数据操作顺序

1. UI 提交用户意图；
2. Controller 校验并调用 Repository；
3. Repository 持久化核心数据；
4. Controller 更新公开状态；
5. UI 根据 loading、success、failure 状态重建。

平台、网络、文件等外部能力应放在 `services` 或 feature 的 data 层，通过接口隔离。次要外部操作失败时，不应把已成功的核心数据保存显示成失败。

## 扩展建议

- 路由增多时增加 `app/router/`；
- 全局设置增多时增加 `app/preferences/`；
- 通用组件放入 `shared/widgets/`；
- 通用平台能力放入 `core/services/`；
- 数据结构升级时增加明确的 schema version 和 migration；
- 团队或状态复杂度增长后再评估 Riverpod、Bloc 等方案。

## 专业版授权模块

专业版授权是独立于工单收款的业务模块，采用“在线激活一次，之后本地离线使用”的模型：

```text
Flutter App
  ├── InAppPurchaseBillingGateway
  ├── RemotePurchaseVerifier ──HTTPS──→ Node license server
  └── LocalEntitlementRepository ──→ flutter_secure_storage
```

- `in_app_purchase` 只负责调用 Apple App Store / Google Play 和接收购买事件；
- 服务端负责验证平台购买凭证、幂等保存交易、生成专业版授权和处理退款/撤销通知；
- 本地授权快照不进入工单 JSON，也不进入用户业务备份；
- 工单、客户、照片和签名继续只保存在本地，登录和云同步不在本阶段范围内；
- `FeatureAccessService` 是所有专业功能的统一权限入口，页面不应直接判断商品或购买回调；
- 一次性商品没有到期时间，但重新安装、清除数据或更换设备时需要通过商店恢复购买。

根目录 `server/` 是 Node.js 授权服务。开发期使用 JSON 文件存储并支持显式开启的测试购买；正式环境必须关闭测试开关、使用 HTTPS、接入 Apple/Google 真实验证，并将存储替换为可靠数据库。

详细的商品权限、接口、构建参数和未完成事项见[专业版内购与离线授权实现说明](monetization-implementation.md)。
