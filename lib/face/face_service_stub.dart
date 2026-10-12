import 'face_profile.dart';

class FaceService {
  static Future<FaceProfile?> enroll(
    String name, {
    FaceProfile? existingProfile,
  }) async {
    throw const FaceException('Hãy mở Flutter web bằng Chrome để dùng webcam.');
  }

  static Future<bool> verify(String name, FaceProfile profile) async {
    throw const FaceException('Hãy mở Flutter web bằng Chrome để dùng webcam.');
  }
}
