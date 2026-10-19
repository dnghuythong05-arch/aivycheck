import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String note;
  final Color iconColor;
  final Color backgroundColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;

    return Expanded(
      child: Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: typography.headlineSmall?.copyWith(
                      fontSize: 28,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AiVieTheme.secondary(context, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
