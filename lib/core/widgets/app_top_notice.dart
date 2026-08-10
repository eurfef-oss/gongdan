import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a transient notice above the root overlay, including above dialogs.
///
/// The previous SnackBar-based notices were rendered by the page Scaffold and
/// could therefore appear behind a modal dialog. Keeping the notice in the
/// root overlay makes save/import feedback visible wherever the action starts.
void showTopNotice(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final value = message.trim();
  if (value.isEmpty) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final scheme = Theme.of(overlayContext).colorScheme;
      final background = error ? scheme.errorContainer : scheme.inverseSurface;
      final foreground =
          error ? scheme.onErrorContainer : scheme.onInverseSurface;
      return Positioned(
        top: MediaQuery.paddingOf(overlayContext).top + 10,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: SafeArea(
            top: false,
            child: Center(
              child: Material(
                color: background,
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: .28),
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          error
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          size: 18,
                          color: foreground,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Timer(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}
