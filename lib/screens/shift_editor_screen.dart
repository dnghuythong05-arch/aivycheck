import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/work_shift.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/flexible_time_picker.dart';

class ShiftEditorScreen extends StatefulWidget {
  final String shiftId;
  final WorkShift? initialShift;

  const ShiftEditorScreen({
    super.key,
    required this.shiftId,
    this.initialShift,
  });

  @override
  State<ShiftEditorScreen> createState() => _ShiftEditorScreenState();
}

class _ShiftEditorScreenState extends State<ShiftEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late DateTime date;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  bool endsNextDay = false;
  String? timeError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialShift;
    final now = DateTime.now();
    final start = initial?.start ?? now;
    final end = initial?.end ?? now.add(const Duration(hours: 1));

    nameController = TextEditingController(text: initial?.name ?? '');
    date = DateTime(start.year, start.month, start.day);
    startTime = TimeOfDay.fromDateTime(start);
    endTime = TimeOfDay.fromDateTime(end);
    endsNextDay = !sameAttendanceDay(start, end);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'CHỌN NGÀY LÀM',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (!mounted || picked == null) return;
    setState(() {
      date = picked;
      timeError = null;
    });
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showFlexibleTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      title: isStart ? 'Giờ bắt đầu' : 'Giờ kết thúc',
    );

    if (!mounted || picked == null) return;
    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
      timeError = null;
    });
  }

  String timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  void save() {
    if (!formKey.currentState!.validate()) return;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      date.year,
      date.month,
      date.day + (endsNextDay ? 1 : 0),
      endTime.hour,
      endTime.minute,
    );

    if (!end.isAfter(start)) {
      setState(() {
        timeError =
            'Giờ kết thúc phải sau giờ bắt đầu. '
            'Nếu ca qua đêm, bật kết thúc ngày hôm sau.';
      });
      return;
    }

    Navigator.pop(
      context,
      WorkShift(
        id: widget.shiftId,
        name: nameController.text,
        start: start,
        end: end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final editing = widget.initialShift != null;

    return Scaffold(
      appBar: AppHeader(
        title: editing ? 'Chỉnh ca làm' : 'Tạo ca làm',
        subtitle: 'Tên ca, ngày làm và thời gian',
        onBack: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            maxLength: 40,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Tên ca làm',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Cần nhập tên ca làm.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: pickDate,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 20,
                            ),
                            label: Text(
                              'Ngày làm: ${formatAttendanceDate(date)}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => pickTime(true),
                            icon: const Icon(Icons.login_rounded, size: 20),
                            label: Text('Bắt đầu: ${timeText(startTime)}'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => pickTime(false),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: Text('Kết thúc: ${timeText(endTime)}'),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kết thúc ngày hôm sau',
                                      style: typography.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bật khi ca đi qua 00:00.',
                                      style: AiVieTheme.secondary(
                                        context,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Switch.adaptive(
                                value: endsNextDay,
                                onChanged: (value) => setState(() {
                                  endsNextDay = value;
                                  timeError = null;
                                }),
                              ),
                            ],
                          ),
                          if (timeError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              timeError!,
                              style: typography.bodyMedium?.copyWith(
                                color: colors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: save,
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: const Text('Lưu ca'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
