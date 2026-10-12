import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../theme/app_theme.dart';

class AttendanceClockCard extends StatelessWidget {
  final DateTime now;

  const AttendanceClockCard({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AiVieTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AiVieTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Giờ hiện tại',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AiVieTheme.muted,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatAttendanceTime(now, showSeconds: true),
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
