import '../models/work_shift.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ShiftAssignment {
  final WorkShift shift;
  final String userId;
  final bool isDeleted;

  ShiftAssignment(this.shift, this.userId, this.isDeleted);
}

class ShiftService {
  final AuthService auth;

  ShiftService(this.auth);

  ShiftAssignment _read(Object? value) {
    try {
      final json = Map<String, dynamic>.from(value as Map);
      final userId = json['userId'] as String;
      final shift = WorkShift.fromJson(json);
      final deleted = json['isDeleted'] as bool;

      if (userId.isEmpty || !shift.isRemote) {
        throw const FormatException();
      }

      return ShiftAssignment(shift, userId, deleted);
    } catch (_) {
      throw const ApiException('Dữ liệu ca làm backend trả về chưa hợp lệ.');
    }
  }

  Future<List<ShiftAssignment>> list({String? userId}) async {
    final path = userId == null
        ? '/api/shifts'
        : '/api/shifts?userId=${Uri.encodeQueryComponent(userId)}';

    final result = await auth.authorizedRequest('GET', path);
    final rows = result?['shifts'];

    if (rows is! List) {
      throw const ApiException('Danh sách ca làm chưa hợp lệ.');
    }

    final items = rows.map(_read).toList();

    if (items.map((item) => item.shift.id).toSet().length != items.length ||
        items.any(
          (item) => item.isDeleted || (userId != null && item.userId != userId),
        )) {
      throw const ApiException('Danh sách ca làm không khớp tài khoản.');
    }

    return items;
  }

  Future<ShiftAssignment> save(WorkShift shift, String userId) async {
    final creating = shift.id.startsWith('draft_');

    final result = await auth.authorizedRequest(
      creating ? 'POST' : 'PUT',
      creating ? '/api/shifts' : '/api/shifts/${Uri.encodeComponent(shift.id)}',
      body: {
        if (creating) 'userId': userId,
        'name': shift.name,
        'start': shift.start.toUtc().toIso8601String(),
        'end': shift.end.toUtc().toIso8601String(),
      },
    );

    final item = _read(result);

    if (item.userId != userId ||
        item.isDeleted ||
        (!creating && item.shift.id != shift.id)) {
      throw const ApiException('Ca làm trả về không khớp. Hãy tải lại lịch.');
    }

    return item;
  }

  Future<void> delete(String id) async {
    await auth.authorizedRequest(
      'DELETE',
      '/api/shifts/${Uri.encodeComponent(id)}',
    );
  }

  Future<Map<String, ShiftAssignment>> importLegacy(
    List<Map<String, dynamic>> entries,
  ) async {
    final mappings = <String, ShiftAssignment>{};

    for (var offset = 0; offset < entries.length; offset += 200) {
      final batch = entries.skip(offset).take(200).toList();

      final expected = {
        for (final entry in batch) entry['legacyId'] as String: entry['userId'],
      };

      final result = await auth.authorizedRequest(
        'POST',
        '/api/shifts/import',
        body: {'shifts': batch},
      );

      final rows = result?['mappings'];

      if (rows is! List || rows.length != batch.length) {
        throw const ApiException(
          'Chưa chuyển đủ ca cũ lên backend. Hãy thử lại.',
        );
      }

      try {
        for (final value in rows) {
          final row = Map<String, dynamic>.from(value as Map);
          final key = row['legacyId'] as String;
          final item = _read(row['shift']);

          if (expected[key] != item.userId || mappings.containsKey(key)) {
            throw const FormatException();
          }

          mappings[key] = item;
        }
      } catch (_) {
        throw const ApiException(
          'Kết quả chuyển ca cũ chưa hợp lệ. Hãy thử lại.',
        );
      }
    }

    return mappings;
  }
}
