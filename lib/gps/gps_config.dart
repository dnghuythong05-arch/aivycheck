class GpsConfig {
  static const double defaultRadiusMeters = 200;

  final double? latitude;
  final double? longitude;
  final double radiusMeters;

  GpsConfig({
    this.latitude,
    this.longitude,
    this.radiusMeters = defaultRadiusMeters,
  }) {
    if (!radiusMeters.isFinite || radiusMeters < 1 || radiusMeters > 5000) {
      throw ArgumentError('Phạm vi phải từ 1 đến 5.000 mét.');
    }

    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Địa điểm phải có đủ hai tọa độ.');
    }

    final lat = latitude;
    final lng = longitude;

    if (lat != null && (!lat.isFinite || lat < -90 || lat > 90)) {
      throw ArgumentError('Tọa độ vĩ độ không hợp lệ.');
    }

    if (lng != null && (!lng.isFinite || lng < -180 || lng > 180)) {
      throw ArgumentError('Tọa độ kinh độ không hợp lệ.');
    }
  }

  bool get hasCenter => latitude != null && longitude != null;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory GpsConfig.fromJson(Map<String, dynamic> json) {
    return GpsConfig(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusMeters:
          (json['radiusMeters'] as num?)?.toDouble() ?? defaultRadiusMeters,
    );
  }
}
