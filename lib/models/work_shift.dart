class WorkShift {
  final String id;
  final String name;
  final DateTime start;
  final DateTime end;

  WorkShift({
    required this.id,
    required String name,
    required this.start,
    required this.end,
  }) : name = name.trim() {
    if (id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('Ca phải có mã và tên.');
    }
    if (!end.isAfter(start)) {
      throw ArgumentError('Giờ kết thúc phải sau giờ bắt đầu.');
    }
  }

  bool get isRemote =>
      id.startsWith('shift_db_') || id.startsWith('shift_import_');

  WorkShift withId(String value) =>
      WorkShift(id: value, name: name, start: start, end: end);

  bool get isOvernight => !sameAttendanceDay(start, end);

  WorkShift snapshot() => WorkShift(id: id, name: name, start: start, end: end);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
  };

  factory WorkShift.fromJson(Map<String, dynamic> json) {
    return WorkShift(
      id: json['id'] as String,
      name: json['name'] as String,
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
    );
  }
}

bool sameAttendanceDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
