import 'package:flutter/material.dart';

import '../application/entitlement_controller.dart';
import '../domain/entities/entitlement.dart';

class ProPage extends StatelessWidget {
  const ProPage({required this.controller, this.compact = false, super.key});

  final EntitlementController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final entitlement = controller.entitlement;
          final busy = entitlement.state == EntitlementState.purchasing ||
              entitlement.state == EntitlementState.pending;
          final isPro = entitlement.isPro;
          final isPreview = controller.isPreviewPro;
          final features = [
            _ProFeatureRow(
              icon: Icons.all_inclusive,
              title: '无限工单',
              description: '免费版最多创建 5 张工单',
            ),
            _ProFeatureRow(
              icon: Icons.people_outline,
              title: '无限客户档案',
              description: '普通版最多设置 3 个客户档案',
            ),
            _ProFeatureRow(
              icon: Icons.category_outlined,
              title: '自定义项目模板',
              description: '维护自己的服务项目、价格和保修规则',
            ),
            _ProFeatureRow(
              icon: Icons.insights_outlined,
              title: '统计复盘',
              description: '查看工单、收入和待收款趋势',
            ),
          ];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF155EEF),
                          Color(0xFF4338CA),
                          Color(0xFF7C3AED),
                        ],
                        stops: [0, .52, 1],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 16 : 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(alpha: .2),
                            foregroundColor: Colors.white,
                            child: Icon(
                              isPro
                                  ? Icons.verified_outlined
                                  : Icons.auto_awesome,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPreview
                                      ? '专业版预览'
                                      : isPro
                                          ? '专业版已激活'
                                          : '升级专业版',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  isPreview
                                      ? 'Release APK 已开放全部专业功能；该预览授权不会保存，正式 AAB 需购买。'
                                      : isPro
                                          ? '本设备可以在没有网络时继续使用专业功能。'
                                          : '一次购买，解锁现场维修工作流中的完整工具。',
                                  style: const TextStyle(
                                    color: Color(0xE6FFFFFF),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...features,
                if (!isPro) ...[
                  const SizedBox(height: 16),
                  Text(
                    controller.product?.price ?? '价格由应用商店显示',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '一次性买断 · 无自动续费',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy || !controller.storeAvailable
                        ? null
                        : controller.purchase,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(busy ? '正在处理…' : '购买专业版'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : controller.restorePurchases,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('恢复购买'),
                  ),
                  if (!controller.storeAvailable && controller.isInitialized)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '当前无法连接应用商店，请检查网络或稍后重试。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  '购买通过系统应用商店完成。专业版授权只保存在设备安全存储中，不会上传工单、客户、照片或签名数据。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _ProFeatureRow extends StatelessWidget {
  const _ProFeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: .1),
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, size: 20),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(description),
          trailing: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
      );
}
