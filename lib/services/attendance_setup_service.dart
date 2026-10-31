import '../face/face_profile.dart';
import '../gps/gps_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AttendanceSetupService {
  final AuthService auth;

  AttendanceSetupService(this.auth);

  GpsConfig _readGps(Map<String, dynamic>? result) {
    try {
      final json = Map<String, dynamic>.from(result!['gps'] as Map);

      if (!json.containsKey('latitude') ||
          !json.containsKey('longitude') ||
          json['radiusMeters'] is! num) {
        throw const FormatException();
      }

      return GpsConfig.fromJson(json);
    } catch (_) {
      throw const ApiException('Dữ liệu địa điểm backend trả về chưa hợp lệ.');
    }
  }

  Future<GpsConfig> loadGps() async =>
      _readGps(await auth.authorizedRequest('GET', '/api/settings/gps'));

  Future<GpsConfig> saveGps(GpsConfig config, {bool importing = false}) async =>
      _readGps(
        await auth.authorizedRequest(
          importing ? 'POST' : 'PUT',
          importing ? '/api/settings/gps/import' : '/api/settings/gps',
          body: config.toJson(),
        ),
      );

  Future<GpsConfig> clearGps() async =>
      _readGps(await auth.authorizedRequest('DELETE', '/api/settings/gps'));

  FaceProfile? _readFace(Map<String, dynamic>? result, String userId) {
    try {
      if (result == null ||
          result['userId'] != userId ||
          !result.containsKey('profile')) {
        throw const FormatException();
      }

      final value = result['profile'];

      return value == null
          ? null
          : FaceProfile.fromJson(Map<String, dynamic>.from(value as Map));
    } catch (_) {
      throw const ApiException('Dữ liệu khuôn mặt backend trả về chưa hợp lệ.');
    }
  }

  Future<FaceProfile?> loadFace(String userId) async {
    final path = userId == auth.currentUser?.id
        ? '/api/faces/me'
        : '/api/faces/${Uri.encodeComponent(userId)}';

    return _readFace(await auth.authorizedRequest('GET', path), userId);
  }

  Future<Set<String>> registeredIds() async {
    final result = await auth.authorizedRequest('GET', '/api/faces');
    final ids = result?['userIds'];

    if (ids is! List ||
        ids.any((id) => id is! String || id.isEmpty) ||
        ids.toSet().length != ids.length) {
      throw const ApiException(
        'Danh sách khuôn mặt backend trả về chưa hợp lệ.',
      );
    }

    return ids.cast<String>().toSet();
  }

  Future<FaceProfile?> saveFace(
    String userId,
    FaceProfile? profile, {
    bool importing = false,
  }) async {
    final path = '/api/faces/${Uri.encodeComponent(userId)}';

    final result = await auth.authorizedRequest(
      profile == null
          ? 'DELETE'
          : importing
          ? 'POST'
          : 'PUT',
      importing ? '$path/import' : path,
      body: profile == null
          ? null
          : {
              ...profile.toJson(),
              'registeredAt': profile.registeredAt.toUtc().toIso8601String(),
            },
    );

    return _readFace(result, userId);
  }
}
