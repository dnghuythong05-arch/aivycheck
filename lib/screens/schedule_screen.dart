import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/shift_list_card.dart';
import 'shift_editor_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final AttendanceSession session;

  const ScheduleScreen({super.key, required this.session});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool busy = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> editShift([WorkShift? shift]) async {
    if (busy || !widget.session.isAdmin) return;

    final result = await Navigator.push<WorkShift>(
      context,
      MaterialPageRoute(
        builder: (_) => ShiftEditorScreen(
          shiftId: shift?.id ?? widget.session.createShiftId(),
          initialShift: shift,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() => busy = true);
    final error = await widget.session.saveShift(result);
    if (!mounted) return;

    setState(() => busy = false);
    if (error != null) showMessage(error);
  }

  Future<void> deleteShift(WorkShift shift) async {
    if (busy || !widget.session.isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ca làm?'),
        content: Text('Xóa ca “${shift.name}”?'),
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
    setState(() => busy = true);
    final error = await widget.session.deleteShift(shift.id);
    if (!mounted) return;

    setState(() => busy = false);
    showMessage(error ?? 'Đã xóa ca làm.');
  }

  Future<void> selectShift(
    WorkShift shift, {
    bool openAttendance = false,
  }) async {
    if (busy) return;
    setState(() => busy = true);
    final error = await widget.session.selectShift(shift.id);
    if (!mounted) return;

    setState(() => busy = false);
    if (error != null) {
      showMessage(error);
      return;
    }
    if (openAttendance) Navigator.pop<int>(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    final shifts = widget.session.shifts;
    final canManage = widget.session.isAdmin;
    final canAttend = widget.session.isOwnSession;

    return Scaffold(
      appBar: AppHeader(
        title: 'Lịch làm',
        subtitle: widget.session.account!.fullName,
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AiVieTheme.contentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (busy) const LinearProgressIndicator(minHeight: 2),
                if (canManage)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Align(
                      alignment: Alignment.center,
                      child: FilledButton.icon(
                        onPressed: busy ? null : () => editShift(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Tạo ca làm'),
                      ),
                    ),
                  ),
                Expanded(
                  child: shifts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              canManage
                                  ? 'Chưa có ca. Hãy tạo ca làm.'
                                  : 'Bạn chưa được giao ca làm.',
                              textAlign: TextAlign.center,
                              style: AiVieTheme.secondary(context),
                            ),
                          ),
                        )
                      : AbsorbPointer(
                          absorbing: busy,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              canManage ? 0 : 24,
                              24,
                              24,
                            ),
                            itemCount: shifts.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final shift = shifts[index];
                              final record = widget.session.recordFor(shift.id);

                              return ShiftListCard(
                                shift: shift,
                                record: record,
                                selected:
                                    shift.id == widget.session.selectedShiftId,
                                canManage: canManage,
                                canAttend: canAttend,
                                onEdit: () => editShift(shift),
                                onDelete: () => deleteShift(shift),
                                onSelect: () => selectShift(shift),
                                onAttendance: () {
                                  if (record?.checkOut != null) {
                                    Navigator.pop<int>(context, 2);
                                  } else {
                                    selectShift(shift, openAttendance: true);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
