import 'work_shift.dart';

enum AttendanceState { notCheckedIn, working, completed }

class AttendanceRecord {
  final WorkShift shiftSnapshot;
  final DateTime checkIn;
  final DateTime? checkOut;

  AttendanceRecord({
    required this.shiftSnapshot,
    required this.checkIn,
    this.checkOut,
  }) {
    if (checkOut != null && checkOut!.isBefore(checkIn)) {
      throw ArgumentError('Giờ ra không được trước giờ vào.');
    }
  }

  String get shiftId => shiftSnapshot.id;
  Map<String, dynamic> toJson() => {
    'shiftSnapshot': shiftSnapshot.toJson(),
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut?.toIso8601String(),
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      shiftSnapshot: WorkShift.fromJson(
        Map<String, dynamic>.from(json['shiftSnapshot'] as Map),
      ),
      checkIn: DateTime.parse(json['checkIn'] as String).toLocal(),
      checkOut: json['checkOut'] == null
          ? null
          : DateTime.parse(json['checkOut'] as String).toLocal(),
    );
  }
  AttendanceState get state =>
      checkOut == null ? AttendanceState.working : AttendanceState.completed;

  bool get isLate => checkIn.isAfter(shiftSnapshot.start);

  int get lateMinutes {
    final minutes = checkIn.difference(shiftSnapshot.start).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  String get lateAmountText {
    if (!isLate) return '0 phút';
    if (lateMinutes == 0) return 'Dưới 1 phút';
    return '$lateMinutes phút';
  }

  String get statusText {
    if (!isLate) return 'Đúng giờ';
    if (lateMinutes == 0) return 'Đã ghi nhận';
    return 'Trễ $lateMinutes phút';
  }

  Duration elapsed(DateTime now) {
    final duration = (checkOut ?? now).difference(checkIn);
    return duration.isNegative ? Duration.zero : duration;
  }

  String workTimeText(DateTime now) {
    final seconds = elapsed(now).inSeconds;
    return '${seconds ~/ 3600} giờ '
        '${seconds ~/ 60 % 60} phút ${seconds % 60} giây';
  }

  String workClockText(DateTime now) {
    final seconds = elapsed(now).inSeconds;
    return '${_twoDigits(seconds ~/ 3600)}:'
        '${_twoDigits(seconds ~/ 60 % 60)}:${_twoDigits(seconds % 60)}';
  }

  AttendanceRecord finish(DateTime time) {
    if (checkOut != null) throw StateError('Ca đã hoàn thành.');
    return AttendanceRecord(
      shiftSnapshot: shiftSnapshot,
      checkIn: checkIn,
      checkOut: time,
    );
  }
}

String _twoDigits(int number) => number.toString().padLeft(2, '0');

String formatAttendanceTime(DateTime? time, {bool showSeconds = false}) {
  if (time == null) return showSeconds ? '--:--:--' : '--:--';
  final text = '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
  return showSeconds ? '$text:${_twoDigits(time.second)}' : text;
}

String formatAttendanceDate(DateTime date) {
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
}

String formatShiftRange(WorkShift shift) {
  final range =
      '${formatAttendanceTime(shift.start)} – '
      '${formatAttendanceTime(shift.end)}';
  return shift.isOvernight ? '$range (+1 ngày)' : range;
}
