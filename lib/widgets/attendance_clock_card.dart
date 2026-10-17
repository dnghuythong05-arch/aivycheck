import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../theme/app_theme.dart';

class AttendanceClockCard extends StatelessWidget {
  final DateTime now;

  const AttendanceClockCard({super.key, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AiVieTheme.of(context);
    final timeText = formatAttendanceTime(now, showSeconds: true);

    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Semantics(
                    label: 'Đồng hồ kim, $timeText',
                    image: true,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _AnalogClockPainter(
                          now: now,
                          faceColor: colors.surface,
                          borderColor: colors.border,
                          handColor: colors.text,
                          primaryColor: colors.primary,
                          tickColor: colors.muted,
                          numberStyle:
                              (theme.textTheme.bodySmall ?? const TextStyle())
                                  .copyWith(
                                    color: colors.muted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Giờ hiện tại',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timeText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime now;
  final Color faceColor;
  final Color borderColor;
  final Color handColor;
  final Color primaryColor;
  final Color tickColor;
  final TextStyle numberStyle;

  const _AnalogClockPainter({
    required this.now,
    required this.faceColor,
    required this.borderColor,
    required this.handColor,
    required this.primaryColor,
    required this.tickColor,
    required this.numberStyle,
  });

  Offset pointOnClock(Offset center, double distance, double angle) {
    return Offset(
      center.dx + math.sin(angle) * distance,
      center.dy - math.cos(angle) * distance,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.shortestSide / 2 - 2;

    if (radius <= 0) return;

    canvas.drawCircle(center, radius, Paint()..color = faceColor);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (var index = 0; index < 60; index++) {
      final isHour = index % 5 == 0;
      final angle = index * math.pi / 30;

      final tickPaint = Paint()
        ..color = isHour ? primaryColor : tickColor.withValues(alpha: 0.6)
        ..strokeWidth = isHour ? 2 : 1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        pointOnClock(center, radius * (isHour ? 0.80 : 0.86), angle),
        pointOnClock(center, radius * 0.91, angle),
        tickPaint,
      );
    }

    for (final hour in [12, 3, 6, 9]) {
      final position = pointOnClock(
        center,
        radius * 0.64,
        (hour % 12) * math.pi / 6,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: '$hour', style: numberStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      textPainter.dispose();
    }

    final seconds = now.second.toDouble();
    final minutes = now.minute + seconds / 60;
    final hours = (now.hour % 12) + minutes / 60;

    void drawHand({
      required double angle,
      required double length,
      required double width,
      required Color color,
      double tail = 0,
    }) {
      final handPaint = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        pointOnClock(center, -tail, angle),
        pointOnClock(center, length, angle),
        handPaint,
      );
    }

    drawHand(
      angle: hours * math.pi / 6,
      length: radius * 0.45,
      width: 5,
      color: handColor,
      tail: radius * 0.07,
    );

    drawHand(
      angle: minutes * math.pi / 30,
      length: radius * 0.67,
      width: 3.5,
      color: handColor,
      tail: radius * 0.10,
    );

    drawHand(
      angle: seconds * math.pi / 30,
      length: radius * 0.80,
      width: 1.5,
      color: primaryColor,
      tail: radius * 0.17,
    );

    canvas.drawCircle(center, 5, Paint()..color = primaryColor);

    canvas.drawCircle(center, 2, Paint()..color = faceColor);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.now != now ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.handColor != handColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.numberStyle != numberStyle;
  }
}
