import 'package:flutter/material.dart';

import '../models/work_shift.dart';
import '../theme/app_theme.dart';

class ShiftCard extends StatelessWidget {
  final WorkShift? shift;
  final VoidCallback onTap;

  const ShiftCard({super.key, required this.shift, required this.onTap});

  String clock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String date(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/'
      '${time.month.toString().padLeft(2, '0')}/${time.year}';

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;
    final selected = shift;

    final sameDay =
        selected == null ||
        (selected.start.year == selected.end.year &&
            selected.start.month == selected.end.month &&
            selected.start.day == selected.end.day);

    return Card(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: colors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Ca đang chọn', style: typography.titleMedium),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.muted),
                ],
              ),
              const SizedBox(height: 20),
              if (selected == null)
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          'Chưa chọn ca làm việc',
                          style: AiVieTheme.secondary(context, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bấm vào thẻ này để mở Lịch làm.',
                          textAlign: TextAlign.center,
                          style: AiVieTheme.secondary(context),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(selected.name, style: typography.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '${clock(selected.start)} – ${clock(selected.end)}',
                  style: typography.bodyLarge?.copyWith(
                    fontSize: 22,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sameDay
                      ? date(selected.start)
                      : '${date(selected.start)} → ${date(selected.end)}',
                  style: AiVieTheme.secondary(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
