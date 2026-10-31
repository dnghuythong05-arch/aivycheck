import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import 'attendance_status.dart';

class AttendanceShiftCard extends StatelessWidget {
  final WorkShift? shift;
  final AttendanceRecord? record;
  final DateTime now;
  final bool busy;
  final VoidCallback onAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback? onRegisterFace;

  const AttendanceShiftCard({
    super.key,
    required this.shift,
    required this.record,
    required this.now,
    required this.busy,
    required this.onAttendance,
    required this.onOpenSchedule,
    this.onRegisterFace,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final currentShift = shift;
    final currentRecord = record;
    final working = currentRecord != null && currentRecord.checkOut == null;
    final completed = currentRecord?.checkOut != null;

    final buttonLabel = busy
        ? 'ĐANG KIỂM TRA…'
        : completed
        ? 'HOÀN THÀNH'
        : working
        ? 'CHECK OUT'
        : 'CHECK IN';

    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ca đang chọn',
              style: AiVieTheme.secondary(context, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              currentShift?.name ?? 'Chưa chọn ca làm',
              style: typography.titleLarge,
            ),
            if (currentShift != null) ...[
              const SizedBox(height: 12),
              Text(
                formatShiftRange(currentShift),
                style: typography.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                formatAttendanceDate(currentShift.start),
                style: AiVieTheme.secondary(context),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            if (currentRecord == null)
              Text(
                currentShift == null
                    ? 'Mở Lịch làm để chọn ca được giao.'
                    : 'Bạn chưa chấm công ca này.',
                style: AiVieTheme.secondary(context),
              )
            else ...[
              AttendanceStatusText(
                label: AttendanceStatus.workLabel(currentRecord),
                color: AttendanceStatus.workColor(context, currentRecord),
                style: typography.titleMedium,
              ),
              const SizedBox(height: 6),
              AttendanceStatusText(
                label: AttendanceStatus.timingLabel(currentRecord),
                color: AttendanceStatus.timingColor(context, currentRecord),
              ),
              const SizedBox(height: 18),
              _AttendanceTimeRow(
                label: 'Check in',
                value: formatAttendanceTime(
                  currentRecord.checkIn,
                  showSeconds: true,
                ),
              ),
              const SizedBox(height: 10),
              _AttendanceTimeRow(
                label: 'Check out',
                value: formatAttendanceTime(
                  currentRecord.checkOut,
                  showSeconds: true,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                currentRecord.workTimeText(now),
                style: typography.titleMedium,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy || currentShift == null || completed
                  ? null
                  : onAttendance,
              icon: Icon(
                completed
                    ? Icons.check_rounded
                    : working
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                size: 20,
              ),
              label: Text(buttonLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : onOpenSchedule,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: const Text('Mở lịch làm'),
            ),
            if (onRegisterFace != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: busy ? null : onRegisterFace,
                icon: const Icon(Icons.face_outlined, size: 20),
                label: const Text('Đăng ký khuôn mặt'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceTimeRow extends StatelessWidget {
  final String label;
  final String value;

  const _AttendanceTimeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AiVieTheme.secondary(context))),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
