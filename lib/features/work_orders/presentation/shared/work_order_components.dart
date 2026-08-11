part of '../work_order_page.dart';

class _Shell extends StatelessWidget {
  const _Shell({
    required this.kicker,
    required this.title,
    required this.child,
    this.actions = const [],
    this.actionsBelowTitle = false,
    this.showPageHeader = true,
  });

  final String kicker;
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool actionsBelowTitle;
  final bool showPageHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            constraints.maxWidth > 1180 ? 1180.0 : constraints.maxWidth;
        final pagePadding = constraints.maxWidth < 700 ? 16.0 : 24.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showPageHeader)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        child: _PageHeader(
                          kicker: kicker,
                          title: title,
                          actions: actions,
                          actionsBelowTitle: actionsBelowTitle,
                        ),
                      )
                    else if (actions.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: pagePadding),
                        child: _PageActions(
                          actions: actions,
                          wrap: actionsBelowTitle,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        showPageHeader || actions.isNotEmpty ? 4 : 20,
                        pagePadding,
                        32,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageActions extends StatelessWidget {
  const _PageActions({required this.actions, required this.wrap});

  final List<Widget> actions;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: wrap
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.value);

  final Enum value;

  @override
  Widget build(BuildContext context) {
    final label = (value as WorkOrderStatus).label;
    final color = statusColor(context, value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withValues(alpha: .1),
                foregroundColor: scheme.primary,
                child: Icon(icon, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  const _MetricSummaryCard({
    required this.metrics,
  });

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 820 ? 4 : 2;
            const gap = 10.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: metrics
                  .map((metric) => SizedBox(width: width, child: metric))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 38,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
