import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Card standar TahanDulu: rounded 16–20px + soft shadow + padding 16.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.large = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: large ? AppRadius.cardLarge : AppRadius.card,
        boxShadow: large ? AppShadows.cardLarge : AppShadows.card,
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: large ? AppRadius.cardLarge : AppRadius.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: large ? AppRadius.cardLarge : AppRadius.card,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
