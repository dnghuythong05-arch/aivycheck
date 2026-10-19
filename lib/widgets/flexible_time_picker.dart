import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Future<TimeOfDay?> showFlexibleTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required String title,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _TimePickerDialog(initialTime: initialTime, title: title),
  );
}

class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const _TimePickerDialog({required this.initialTime, required this.title});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  final formKey = GlobalKey<FormState>();
  late int hour;
  late int minute;
  late final TextEditingController hourText;
  late final TextEditingController minuteText;
  late final FixedExtentScrollController hourWheel;
  late final FixedExtentScrollController minuteWheel;
  bool entering = false;

  String two(int value) => value.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    hour = widget.initialTime.hour;
    minute = widget.initialTime.minute;
    hourText = TextEditingController(text: two(hour));
    minuteText = TextEditingController(text: two(minute));
    hourWheel = FixedExtentScrollController(initialItem: hour);
    minuteWheel = FixedExtentScrollController(initialItem: minute);
  }

  @override
  void dispose() {
    hourText.dispose();
    minuteText.dispose();
    hourWheel.dispose();
    minuteWheel.dispose();
    super.dispose();
  }

  bool readInput() {
    if (!(formKey.currentState?.validate() ?? false)) return false;
    hour = int.parse(hourText.text);
    minute = int.parse(minuteText.text);
    return true;
  }

  void readWheels() {
    if (hourWheel.hasClients) hour = hourWheel.selectedItem % 24;
    if (minuteWheel.hasClients) minute = minuteWheel.selectedItem % 60;
  }

  void changeMode() {
    if (entering) {
      if (!readInput()) return;
      FocusScope.of(context).unfocus();
      setState(() => entering = false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (hourWheel.hasClients) hourWheel.jumpToItem(hour);
        if (minuteWheel.hasClients) minuteWheel.jumpToItem(minute);
      });
    } else {
      readWheels();
      hourText.text = two(hour);
      minuteText.text = two(minute);
      setState(() => entering = true);
    }
  }

  void choose() {
    if (entering) {
      if (!readInput()) return;
    } else {
      readWheels();
    }
    Navigator.pop(context, TimeOfDay(hour: hour, minute: minute));
  }

  Widget input(TextEditingController controller, String label, int maximum) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 2,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 28),
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null || number < 0 || number > maximum) {
          return '0–$maximum';
        }
        return null;
      },
    );
  }

  Widget wheel({
    required String label,
    required int count,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
  }) {
    final colors = AiVieTheme.of(context);

    return Column(
      children: [
        Text(label, style: AiVieTheme.secondary(context)),
        const SizedBox(height: 8),
        Expanded(
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 44,
            looping: true,
            useMagnifier: true,
            magnification: 1.05,
            backgroundColor: Colors.transparent,
            selectionOverlay: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            onSelectedItemChanged: onChanged,
            children: List.generate(
              count,
              (index) => Center(
                child: Text(
                  two(index),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 27),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final separatorStyle = typography.bodyLarge?.copyWith(
      fontSize: 24,
      color: colors.muted,
    );

    return AlertDialog(
      scrollable: true,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Text(widget.title, style: typography.titleLarge),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entering)
              Form(
                key: formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: input(hourText, 'Giờ', 23)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                      child: Text(':', style: separatorStyle),
                    ),
                    Expanded(child: input(minuteText, 'Phút', 59)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: wheel(
                        label: 'Giờ',
                        count: 24,
                        controller: hourWheel,
                        onChanged: (value) => hour = value,
                      ),
                    ),
                    Text(':', style: separatorStyle),
                    Expanded(
                      child: wheel(
                        label: 'Phút',
                        count: 60,
                        controller: minuteWheel,
                        onChanged: (value) => minute = value,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: changeMode,
              icon: Icon(
                entering ? Icons.swap_vert_rounded : Icons.keyboard_outlined,
                size: 20,
              ),
              label: Text(entering ? 'Cuộn chọn' : 'Nhập giờ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: choose, child: const Text('Chọn')),
      ],
    );
  }
}
