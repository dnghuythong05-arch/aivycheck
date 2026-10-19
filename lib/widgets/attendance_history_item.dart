import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../theme/app_theme.dart';

class AttendanceHistoryItem extends StatelessWidget {
  final AttendanceRecord record;
  final DateTime now;
  final VoidCallback? onDelete;

  const AttendanceHistoryItem({
    super.key,
    required this.record,
    required this.now,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final shift = record.shiftSnapshot;
    final completed = record.checkOut != null;
    final statusColor = record.isLate ? colors.warning : colors.success;

    return Card(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.historyBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(shift.name, style: typography.titleLarge)),
                if (completed && onDelete != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Xóa lượt chấm công',
                    onPressed: onDelete,
                    style: IconButton.styleFrom(foregroundColor: colors.error),
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày ca: ${formatAttendanceDate(shift.start)}',
              style: AiVieTheme.secondary(context),
            ),
            const SizedBox(height: 4),
            Text(
              'Ca làm: ${formatShiftRange(shift)}',
              style: AiVieTheme.secondary(context),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.statusText,
                    style: typography.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  completed ? 'Đã hoàn thành' : 'Đang làm',
                  style: typography.bodySmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            _HistoryTimeRow(
              label: 'Check in',
              value: formatAttendanceTime(record.checkIn, showSeconds: true),
            ),
            const SizedBox(height: 12),
            _HistoryTimeRow(
              label: 'Check out',
              value: formatAttendanceTime(record.checkOut, showSeconds: true),
            ),
            const SizedBox(height: 12),
            _HistoryTimeRow(
              label: 'Giờ làm',
              value: record.workTimeText(now),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTimeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _HistoryTimeRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AiVieTheme.secondary(context))),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
