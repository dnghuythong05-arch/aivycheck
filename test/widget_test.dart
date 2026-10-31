import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aivycheck/gps/gps_service.dart';
import 'package:aivycheck/services/api_client.dart';
import 'package:aivycheck/services/attendance_service.dart';
import 'package:aivycheck/services/auth_service.dart';

const user = <String, dynamic>{
  'id': 'employee_huythong',
  'username': 'huythong',
  'fullName': 'Employee CI',
  'email': 'employee-ci@example.com',
  'role': 'employee',
};

Map<String, dynamic> savedRecord({String userId = 'employee_huythong'}) => {
  'id': 'attendance_ci',
  'userId': userId,
  'shiftSnapshot': {
    'id': 'shift_db_ci',
    'name': 'Ca CI',
    'start': '2026-10-31T01:00:00Z',
    'end': '2026-10-31T10:00:00Z',
  },
  'checkIn': '2026-10-31T01:30:00Z',
  'checkOut': null,
};

http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<AuthService> signedIn(
  Future<http.Response> Function(http.Request) handler,
) async {
  final auth = AuthService(
    api: ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return jsonResponse({
            'access_token': List.filled(43, 't').join(),
            'token_type': 'bearer',
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(hours: 1))
                .toIso8601String(),
            'user': user,
          });
        }

        if (request.url.path == '/api/auth/me') {
          return jsonResponse(user);
        }

        return handler(request);
      }),
    ),
  );

  addTearDown(auth.dispose);

  await auth.signIn('huythong', 'ci-password');

  return auth;
}

GpsCheckResult currentGps() => GpsCheckResult(
  position: Position(
    latitude: 10,
    longitude: 106,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  ),
  distanceMeters: 0,
  radiusMeters: 200,
);

void main() {
  test('Đọc lịch sử đúng tài khoản và giữ nguyên thời điểm UTC', () async {
    final auth = await signedIn((request) async {
      expect(request.url.queryParameters['userId'], user['id']);

      expect(request.headers['Authorization'], startsWith('Bearer '));

      return jsonResponse({
        'records': [savedRecord()],
      });
    });

    final records = await AttendanceService(auth).list(user['id'] as String);

    expect(records.single.shiftId, 'shift_db_ci');

    expect(
      records.single.checkIn.isAtSameMomentAs(
        DateTime.utc(2026, 10, 31, 1, 30),
      ),
      isTrue,
    );

    expect(records.single.checkOut, isNull);
  });

  test('Không nhận lịch sử trả nhầm tài khoản', () async {
    final auth = await signedIn(
      (_) async => jsonResponse({
        'records': [savedRecord(userId: 'employee_other')],
      }),
    );

    await expectLater(
      AttendanceService(auth).list(user['id'] as String),
      throwsA(isA<ApiException>()),
    );
  });

  test('Backend trả 401 thì thu hồi trạng thái đăng nhập frontend', () async {
    final auth = await signedIn(
      (_) async => jsonResponse({'detail': 'Expired'}, 401),
    );

    await expectLater(
      AttendanceService(auth).list(user['id'] as String),
      throwsA(isA<ApiException>()),
    );

    expect(auth.currentUser, isNull);
  });

  test('Gửi lại sau lỗi backend dùng cùng requestId, '
      'không gửi giờ IN từ máy khách', () async {
    final bodies = <Map<String, dynamic>>[];

    final auth = await signedIn((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/attendance/check-in');

      bodies.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));

      if (bodies.length == 1) {
        return jsonResponse({'detail': 'Unavailable'}, 503);
      }

      return jsonResponse(savedRecord());
    });

    final service = AttendanceService(auth);
    final gps = currentGps();

    Future<dynamic> submit() => service.submit(
      userId: user['id'] as String,
      shiftId: 'shift_db_ci',
      checkingIn: true,
      gps: gps,
    );

    await expectLater(submit(), throwsA(isA<ApiException>()));

    final record = await submit();

    expect(record.shiftId, 'shift_db_ci');
    expect(bodies[0]['requestId'], bodies[1]['requestId']);
    expect(bodies[1].containsKey('checkIn'), isFalse);
    expect(bodies[1].containsKey('userId'), isFalse);
    expect(bodies[1]['gps']['accuracy'], 10);
  });
}
