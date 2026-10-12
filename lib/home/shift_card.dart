import 'package:flutter/material.dart';

import '../models/work_shift.dart';

class ShiftCard extends StatelessWidget {
  final WorkShift? shift;
  final VoidCallback onTap;

  const ShiftCard({super.key, required this.shift, required this.onTap});

  String clock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String date(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/'
      '${time.month.toString().padLeft(2, '0')}/'
      '${time.year}';

  @override
  Widget build(BuildContext context) {
    final selected = shift;

    final sameDay =
        selected == null ||
        (selected.start.year == selected.end.year &&
            selected.start.month == selected.end.month &&
            selected.start.day == selected.end.day);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ca đang chọn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                ],
              ),
              const SizedBox(height: 20),
              if (selected == null)
                const SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          'Chưa chọn ca làm việc',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bấm vào thẻ này để mở Lịch làm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  selected.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${clock(selected.start)} – ${clock(selected.end)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sameDay
                      ? date(selected.start)
                      : '${date(selected.start)} → ${date(selected.end)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
