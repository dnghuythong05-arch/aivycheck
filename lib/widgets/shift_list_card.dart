import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import 'attendance_status.dart';

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
    final colors = AiVieTheme.of(context);
    final completed = record?.checkOut != null;
    final showSelection = selected && canAttend;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showSelection ? colors.primary : colors.border,
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
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colors.muted,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Xóa ca',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 22,
                      color: colors.error,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(formatShiftRange(shift), style: typography.bodyLarge),
            const SizedBox(height: 4),
            Text(
              formatAttendanceDate(shift.start),
              style: AiVieTheme.secondary(context),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AttendanceStatusBadge(
                  label: AttendanceStatus.workLabel(record),
                  color: AttendanceStatus.workColor(context, record),
                ),
                if (record != null)
                  AttendanceStatusBadge(
                    label: AttendanceStatus.timingLabel(record!),
                    color: AttendanceStatus.timingColor(context, record),
                  ),
              ],
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
                  foregroundColor: colors.primary,
                  disabledForegroundColor: colors.primary,
                  backgroundColor: selected ? colors.primarySoft : null,
                  side: BorderSide(color: colors.primary),
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
