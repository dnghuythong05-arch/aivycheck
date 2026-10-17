import 'package:flutter/material.dart';

import '../home/quick_card.dart';
import '../home/shift_card.dart';
import '../home/stat_card.dart';
import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class EmployeeHomeScreen extends StatelessWidget {
  final WorkShift? shift;
  final AttendanceRecord? record;
  final DateTime now;

  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenSalary;
  final VoidCallback onOpenProfile;

  final String fullName;

  const EmployeeHomeScreen({
    super.key,
    required this.shift,
    required this.record,
    required this.now,
    required this.onOpenAttendance,
    required this.onOpenSchedule,
    required this.onOpenSalary,
    required this.onOpenProfile,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AiVieTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const AppHeader(
        title: 'Trang chủ',
        subtitle: 'Theo dõi ca làm và chấm công',
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AiVieTheme.contentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, $fullName',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chúc bạn một ngày làm việc hiệu quả.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ShiftCard(shift: shift, onTap: onOpenSchedule),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StatCard(
                            icon: Icons.check_rounded,
                            title: 'CHECK IN',
                            value: formatAttendanceTime(
                              record?.checkIn,
                              showSeconds: true,
                            ),
                            note: record == null
                                ? 'Chưa vào ca'
                                : 'Đã ghi nhận',
                            iconColor: colors.success,
                            backgroundColor: colors.surface,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            icon: Icons.access_time_rounded,
                            title: 'Đi trễ',
                            value: record?.lateAmountText ?? '--',
                            note: record == null
                                ? 'Chưa vào ca'
                                : record!.isLate
                                ? 'Đi trễ'
                                : 'Đúng giờ',
                            iconColor: colors.warning,
                            backgroundColor: colors.surface,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            icon: Icons.timer_outlined,
                            title: 'Giờ làm việc',
                            value: record?.workClockText(now) ?? '--:--:--',
                            note: record == null
                                ? 'Chưa vào ca'
                                : record!.checkOut == null
                                ? 'Đang làm'
                                : 'Đã kết thúc',
                            iconColor: colors.primary,
                            backgroundColor: colors.surface,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thời gian hiển thị theo giờ : phút : giây',
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                    const SizedBox(height: 24),
                    Text('Thao tác nhanh', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        QuickActionItem(
                          icon: Icons.location_on_outlined,
                          title: 'CHECK IN/OUT',
                          iconColor: colors.primary,
                          iconBackground: colors.surfaceTint,
                          onTap: onOpenAttendance,
                        ),
                        const SizedBox(width: 12),
                        QuickActionItem(
                          icon: Icons.event_note_outlined,
                          title: 'Lịch làm',
                          iconColor: colors.primary,
                          iconBackground: colors.surfaceTint,
                          onTap: onOpenSchedule,
                        ),
                        const SizedBox(width: 12),
                        QuickActionItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Bảng lương',
                          iconColor: colors.primary,
                          iconBackground: colors.surfaceTint,
                          onTap: onOpenSalary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
