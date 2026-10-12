import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';

class ShiftListCard extends StatelessWidget {
  final WorkShift shift;
  final AttendanceRecord? record;
  final bool selected;
  final bool canManage;
  final bool canAttend;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSelect;
  final VoidCallback onAttendance;

  const ShiftListCard({
    super.key,
    required this.shift,
    required this.record,
    required this.selected,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    required this.onAttendance,
    this.canManage = true,
    this.canAttend = true,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final completed = record?.checkOut != null;
    final working = record != null && !completed;
    final showSelection = selected && canAttend;

    final status = completed
        ? 'Đã hoàn thành'
        : working
        ? 'Đang làm'
        : 'Chưa chấm công';

    final statusColor = completed
        ? const Color(0xFF15803D)
        : working
        ? const Color(0xFFB45309)
        : AiVieTheme.muted;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showSelection ? AiVieTheme.primary : AiVieTheme.border,
          width: showSelection ? 2 : 1,
        ),
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
                if (canManage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Chỉnh ca',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AiVieTheme.muted,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Xóa ca',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(formatShiftRange(shift), style: typography.titleMedium),
            const SizedBox(height: 4),
            Text(
              formatAttendanceDate(shift.start),
              style: typography.bodyMedium?.copyWith(color: AiVieTheme.muted),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: typography.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (canAttend) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              OutlinedButton.icon(
                onPressed: selected ? null : onSelect,
                icon: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                label: Text(selected ? 'Đang chọn' : 'Chọn ca làm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AiVieTheme.primary,
                  disabledForegroundColor: AiVieTheme.primary,
                  backgroundColor: selected
                      ? AiVieTheme.primary.withValues(alpha: 0.06)
                      : null,
                  side: const BorderSide(color: AiVieTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onAttendance,
                icon: Icon(
                  completed ? Icons.history_rounded : Icons.login_rounded,
                  size: 20,
                ),
                label: Text(completed ? 'Xem lịch sử' : 'Chấm công'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
