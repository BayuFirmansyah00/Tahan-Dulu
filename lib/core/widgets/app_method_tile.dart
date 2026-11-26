import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_card.dart';

class AppMethodTile extends StatelessWidget {
  const AppMethodTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.onTap,
    required this.accent,
  });
  final String title;
  final String subtitle;
  final String assetPath;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      large: true,
      onTap: onTap,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withValues(alpha: .12),
                theme.colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                assetPath,
                width: 44,
                height: 44,
                cacheWidth: kReleaseMode
                    ? (44 * MediaQuery.devicePixelRatioOf(context)).ceil()
                    : null,
                cacheHeight: kReleaseMode
                    ? (44 * MediaQuery.devicePixelRatioOf(context)).ceil()
                    : null,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.edit_note, size: 44),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
