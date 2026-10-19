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
  final String fullName;
  final bool isAdmin;
  final bool showSalary;

  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenSalary;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenEmployees;

  const EmployeeHomeScreen({
    super.key,
    required this.shift,
    required this.record,
    required this.now,
    required this.fullName,
    required this.onOpenAttendance,
    required this.onOpenSchedule,
    required this.onOpenSalary,
    required this.onOpenProfile,
    required this.onOpenEmployees,
    this.isAdmin = false,
    this.showSalary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;

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
                    Text(
                      'Xin chào, $fullName',
                      style: typography.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chúc bạn một ngày làm việc hiệu quả.',
                      style: AiVieTheme.secondary(context),
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
                      style: AiVieTheme.secondary(context, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Text('Thao tác nhanh', style: typography.titleMedium),
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
                        if (isAdmin || showSalary) ...[
                          const SizedBox(width: 12),
                          QuickActionItem(
                            icon: isAdmin
                                ? Icons.people_outline_rounded
                                : Icons.account_balance_wallet_outlined,
                            title: isAdmin ? 'Nhân viên' : 'Bảng lương',
                            iconColor: colors.primary,
                            iconBackground: colors.surfaceTint,
                            onTap: isAdmin ? onOpenEmployees : onOpenSalary,
                          ),
                        ],
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
