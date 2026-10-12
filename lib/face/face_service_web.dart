import 'dart:convert';
import 'dart:js_interop';

import 'face_profile.dart';

@JS('aivyFaceRun')
external JSPromise<JSString> _runFace(
  JSString name,
  JSString references,
  JSString options,
);

class FaceService {
  static Future<Map<String, dynamic>> _run(
    String name,
    List<List<double>> references, {
    FaceProfile? existingProfile,
  }) async {
    final response = await _runFace(
      name.toJS,
      jsonEncode(references).toJS,
      jsonEncode({'apiVersion': 2, 'profile': existingProfile?.toJson()}).toJS,
    ).toDart;

    final json = Map<String, dynamic>.from(jsonDecode(response.toDart) as Map);

    if (json['status'] == 'cancelled') {
      throw const FaceCancelled();
    }

    if (json['status'] != 'ok') {
      throw FaceException(
        json['message'] as String? ?? 'Chưa xử lý được khuôn mặt.',
      );
    }

    return json;
  }

  static void _checkProcessor(Map<String, dynamic> result) {
    if (result['apiVersion'] != 2 ||
        result['preprocessing'] != FaceProfile.currentPreprocessing) {
      throw const FaceException(
        'Bộ xử lý khuôn mặt chưa được cập nhật. '
        'Hãy dừng app, chạy lại và tải lại trang.',
      );
    }
  }

  static Future<FaceProfile?> enroll(
    String name, {
    FaceProfile? existingProfile,
  }) async {
    final result = await _run(name, const [], existingProfile: existingProfile);

    _checkProcessor(result);

    if (result['cleared'] == true) return null;

    final profile = FaceProfile.fromJson({
      ...result,
      'registeredAt': DateTime.now().toIso8601String(),
    });

    if (profile.photos.length != profile.samples.length) {
      throw const FaceException('Chưa tạo đủ ảnh xem trước. Hãy thử lại.');
    }

    return profile;
  }

  static Future<bool> verify(String name, FaceProfile profile) async {
    if (profile.preprocessing != FaceProfile.currentPreprocessing) {
      throw const FaceException(
        'Mẫu khuôn mặt cần được cập nhật một lần. '
        'Hãy nhờ Admin đăng ký lại ảnh cho tài khoản này.',
      );
    }

    final result = await _run(name, profile.samples);

    _checkProcessor(result);

    return result['matched'] == true;
  }
}
