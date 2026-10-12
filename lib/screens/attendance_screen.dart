import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/attendance_clock_card.dart';
import '../widgets/attendance_shift_card.dart';

class AttendanceScreen extends StatelessWidget {
  final WorkShift? shift;
  final AttendanceRecord? record;
  final DateTime now;
  final VoidCallback onAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onBackHome;
  final VoidCallback? onRegisterFace;
  final bool busy;

  const AttendanceScreen({
    super.key,
    required this.shift,
    required this.record,
    required this.now,
    required this.onAttendance,
    required this.onOpenSchedule,
    required this.onBackHome,
    this.onRegisterFace,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Chấm công',
        subtitle: 'Ghi nhận giờ vào và giờ ra',
        onBack: onBackHome,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AiVieTheme.contentWidth,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shiftCard = AttendanceShiftCard(
                    shift: shift,
                    record: record,
                    now: now,
                    busy: busy,
                    onAttendance: onAttendance,
                    onOpenSchedule: onOpenSchedule,
                    onRegisterFace: onRegisterFace,
                  );

                  if (constraints.maxWidth >= 760) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: AttendanceClockCard(now: now),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: shiftCard),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AttendanceClockCard(now: now),
                      const SizedBox(height: 20),
                      shiftCard,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
