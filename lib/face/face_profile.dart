class FaceException implements Exception {
  final String message;

  const FaceException(this.message);

  @override
  String toString() => message;
}

class FaceCancelled implements Exception {
  const FaceCancelled();
}

class FacePhotoPreview {
  static const maxDataUrlLength = 60000;

  final String name;
  final String key;
  final String dataUrl;

  FacePhotoPreview({
    required this.name,
    required this.key,
    required this.dataUrl,
  }) {
    if (name.isEmpty ||
        name.length > 255 ||
        key.length > 512 ||
        dataUrl.length > maxDataUrlLength ||
        !RegExp(
          r'^data:image/jpeg;base64,[A-Za-z0-9+/]+={0,2}$',
        ).hasMatch(dataUrl)) {
      throw const FaceException('Ảnh xem trước không hợp lệ.');
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'key': key,
    'dataUrl': dataUrl,
  };

  factory FacePhotoPreview.fromJson(Map<String, dynamic> json) {
    return FacePhotoPreview(
      name: json['name'] as String,
      key: json['key'] as String,
      dataUrl: json['dataUrl'] as String,
    );
  }
}

class FaceProfile {
  static const modelId = 'human-3.3.6-faceres';

  static const legacyPreprocessing = 'legacy-v1';
  static const currentPreprocessing = 'equalized-v1';

  static const maxReferencePhotos = 10;

  final List<List<double>> samples;
  final List<FacePhotoPreview> photos;
  final DateTime registeredAt;
  final String preprocessing;

  FaceProfile({
    required List<List<double>> samples,
    List<FacePhotoPreview> photos = const [],
    required this.registeredAt,
    this.preprocessing = legacyPreprocessing,
  }) : samples = List.unmodifiable(
         samples.map((sample) => List<double>.unmodifiable(sample)),
       ),
       photos = List.unmodifiable(photos) {
    if (samples.isEmpty ||
        samples.length > maxReferencePhotos ||
        samples.any(
          (sample) =>
              sample.length != 1024 ||
              sample.any((number) => !number.isFinite) ||
              !sample.any((number) => number != 0),
        ) ||
        (photos.isNotEmpty && photos.length != samples.length)) {
      throw const FaceException('Mẫu khuôn mặt không hợp lệ.');
    }
  }

  Map<String, dynamic> toJson() => {
    'model': modelId,
    'preprocessing': preprocessing,
    'samples': samples,
    'photos': photos.map((photo) => photo.toJson()).toList(),
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory FaceProfile.fromJson(Map<String, dynamic> json) {
    if (json['model'] != modelId) {
      throw const FaceException(
        'Mẫu khuôn mặt dùng mô hình khác. Hãy đăng ký lại.',
      );
    }

    return FaceProfile(
      samples: (json['samples'] as List)
          .map(
            (row) => (row as List)
                .map((number) => (number as num).toDouble())
                .toList(),
          )
          .toList(),
      photos: (json['photos'] as List? ?? const [])
          .map(
            (photo) => FacePhotoPreview.fromJson(
              Map<String, dynamic>.from(photo as Map),
            ),
          )
          .toList(),
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      preprocessing: json['preprocessing'] as String? ?? legacyPreprocessing,
    );
  }
}

typedef FaceVerifier = Future<bool> Function(String name, FaceProfile profile);
