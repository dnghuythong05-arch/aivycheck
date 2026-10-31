import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../theme/app_theme.dart';

class AttendanceStatus {
  static String workLabel(AttendanceRecord? record) => record == null
      ? 'Chưa chấm công'
      : record.checkOut == null
      ? 'Đang làm việc'
      : 'Đã hoàn thành';

  static Color workColor(BuildContext context, AttendanceRecord? record) {
    final colors = AiVieTheme.of(context);

    if (record == null) return colors.muted;

    return record.checkOut == null ? colors.success : colors.primary;
  }

  static String timingLabel(AttendanceRecord record) =>
      record.isLate ? 'Đi trễ: ${record.lateAmountText}' : 'Đúng giờ';

  static Color timingColor(BuildContext context, AttendanceRecord? record) {
    final colors = AiVieTheme.of(context);

    if (record == null) return colors.muted;

    return record.isLate ? colors.warning : colors.success;
  }
}

class AttendanceStatusText extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle? style;

  const AttendanceStatusText({
    super.key,
    required this.label,
    required this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    ),
  );
}

class AttendanceStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AttendanceStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: AttendanceStatusText(
      label: label,
      color: color,
      style: Theme.of(context).textTheme.labelMedium,
    ),
  );
}
