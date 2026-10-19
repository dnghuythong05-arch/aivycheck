import 'dart:async';

import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final AttendanceSession session;

  const EmployeeDetailsScreen({super.key, required this.session});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  Timer? timer;
  DateTime now = DateTime.now();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> openSchedule() async {
    if (busy || !widget.session.isAdmin) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(session: widget.session),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> deleteRecord(AttendanceRecord record) async {
    if (busy || !widget.session.isAdmin) return;
    setState(() => busy = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa lượt chấm công?'),
          content: Text(
            'Nhân viên: ${widget.session.account!.fullName}\n'
            'Ca: ${record.shiftSnapshot.name}\n\n'
            'Ca được giao vẫn được giữ lại.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;
      final error = await widget.session.deleteRecord(record.shiftId);
      if (!mounted) return;

      setState(() {});
      final colors = AiVieTheme.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Đã xóa lượt chấm công.',
            style: TextStyle(
              color: error == null ? colors.success : colors.error,
            ),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.account!;
    final typography = Theme.of(context).textTheme;
    final canManage = widget.session.isAdmin;

    return HistoryScreen(
      title: user.fullName,
      subtitle: 'Ca và lịch sử chấm công',
      records: widget.session.records,
      now: now,
      busy: busy,
      onBackHome: () => Navigator.pop(context),
      onDeleteRecord: canManage ? deleteRecord : null,
      leadingContent: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email, style: AiVieTheme.secondary(context)),
                    const SizedBox(height: 8),
                    Text(
                      'Đã giao ${widget.session.shifts.length} ca',
                      style: typography.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: busy ? null : openSchedule,
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  label: const Text('Giao / quản lý ca làm'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
