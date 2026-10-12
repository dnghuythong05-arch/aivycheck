import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'face_profile.dart';

class FaceStore {
  static const storageKey = 'aivycheck_faces_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<Map<String, FaceProfile>> readAll() async {
    final text = await _preferences.getString(storageKey);

    if (text == null) return {};

    final json = Map<String, dynamic>.from(jsonDecode(text) as Map);

    if (json['version'] != 1) {
      throw const FaceException(
        'Phiên bản dữ liệu khuôn mặt chưa được hỗ trợ.',
      );
    }

    final profiles = Map<String, dynamic>.from(json['profiles'] as Map);

    return profiles.map(
      (id, value) => MapEntry(
        id,
        FaceProfile.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<FaceProfile?> read(String userId) async {
    final profiles = await readAll();

    return profiles[userId];
  }

  Future<void> save(String userId, FaceProfile profile) async {
    final profiles = await readAll();

    profiles[userId] = profile;

    await _preferences.setString(
      storageKey,
      jsonEncode({
        'version': 1,
        'profiles': profiles.map((id, value) => MapEntry(id, value.toJson())),
      }),
    );
  }

  Future<void> delete(String userId) async {
    final profiles = await readAll();

    if (profiles.remove(userId) == null) return;

    await _preferences.setString(
      storageKey,
      jsonEncode({
        'version': 1,
        'profiles': profiles.map((id, value) => MapEntry(id, value.toJson())),
      }),
    );
  }
}
