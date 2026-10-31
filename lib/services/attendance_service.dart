import 'dart:math';

import '../gps/gps_service.dart';
import '../models/attendance_record.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AttendanceService {
  final AuthService auth;
  final Map<String, String> _pending = {};
  final Random _random = Random.secure();

  AttendanceService(this.auth);

  AttendanceRecord _read(Object? value, String userId) {
    try {
      final json = Map<String, dynamic>.from(value as Map);

      if (json['userId'] != userId ||
          json['id'] is! String ||
          (json['id'] as String).isEmpty) {
        throw const FormatException();
      }

      return AttendanceRecord.fromJson(json);
    } catch (_) {
      throw const ApiException('Dữ liệu chấm công backend trả về chưa hợp lệ.');
    }
  }

  Future<List<AttendanceRecord>> list(String userId) async {
    final result = await auth.authorizedRequest(
      'GET',
      '/api/attendance?userId=${Uri.encodeComponent(userId)}',
    );

    final rows = result?['records'];

    if (rows is! List) {
      throw const ApiException('Danh sách chấm công chưa hợp lệ.');
    }

    final records = rows.map((row) => _read(row, userId)).toList();

    if (records.map((row) => row.shiftId).toSet().length != records.length ||
        records.where((row) => row.checkOut == null).length > 1) {
      throw const ApiException('Dữ liệu chấm công bị trùng. Hãy tải lại.');
    }

    return records;
  }

  Future<AttendanceRecord> submit({
    required String userId,
    required String shiftId,
    required bool checkingIn,
    required GpsCheckResult gps,
  }) async {
    final key = '$userId:$shiftId:$checkingIn';

    final requestId = _pending.putIfAbsent(
      key,
      () => List.generate(
        24,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );

    try {
      final result = await auth.authorizedRequest(
        'POST',
        '/api/attendance/${checkingIn ? 'check-in' : 'check-out'}',
        body: {
          'shiftId': shiftId,
          'requestId': requestId,
          'faceVerified': true,
          'gps': {
            'latitude': gps.position.latitude,
            'longitude': gps.position.longitude,
            'accuracy': gps.position.accuracy,
            'capturedAt': gps.position.timestamp.toUtc().toIso8601String(),
          },
        },
      );

      final record = _read(result, userId);

      if (record.shiftId != shiftId ||
          (!checkingIn && record.checkOut == null)) {
        throw const ApiException('Kết quả chấm công không khớp ca đã chọn.');
      }

      _pending.remove(key);

      return record;
    } on ApiException catch (error) {
      final status = error.statusCode;

      if (status != null && status >= 400 && status < 500) {
        _pending.remove(key);
      }

      rethrow;
    }
  }

  Future<void> delete(String shiftId) async {
    await auth.authorizedRequest(
      'DELETE',
      '/api/attendance/${Uri.encodeComponent(shiftId)}',
    );
  }
}
