import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// A reusable fixed app bar for pages that are entered from another page.
class AppBackBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBackBar({
    required this.title,
    required this.onBack,
    this.actions = const [],
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: onBack,
        tooltip: context.tr('返回'),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      centerTitle: false,
      actions: actions,
    );
  }
}
