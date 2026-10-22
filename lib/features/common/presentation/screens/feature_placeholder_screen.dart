import 'package:flutter/material.dart';

/// Placeholder generik untuk fitur yang UI-nya belum dibangun.
/// Memungkinkan routing tervalidasi tanpa membuat 9 screen penuh.
class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).disabledColor),
              const SizedBox(height: 12),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
