import 'package:flutter/material.dart';

import '../models/work_shift.dart';
import '../theme/app_theme.dart';

class ShiftCard extends StatelessWidget {
  final WorkShift? shift;
  final VoidCallback onTap;

  const ShiftCard({super.key, required this.shift, required this.onTap});

  String clock(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String date(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final selected = shift;

    final sameDay =
        selected == null ||
        (selected.start.year == selected.end.year &&
            selected.start.month == selected.end.month &&
            selected.start.day == selected.end.day);

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
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
                    child: Text(
                      'Ca đang chọn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bấm vào thẻ này để mở Lịch làm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  selected.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${clock(selected.start)} – ${clock(selected.end)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sameDay
                      ? date(selected.start)
                      : '${date(selected.start)} → ${date(selected.end)}',
                  style: TextStyle(fontSize: 14, color: colors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
