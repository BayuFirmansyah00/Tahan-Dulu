import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/glass.dart';

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
      decoration: Glass.panel(context, radius: large ? AppRadius.cardLarge : AppRadius.card),
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
