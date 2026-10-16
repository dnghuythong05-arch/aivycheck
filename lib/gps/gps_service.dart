import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'gps_config.dart';

enum GpsNoticeType { info, success, warning, error }

enum GpsFailure { notConfigured, permission, uncertain, outside, unavailable }

String gpsMetersText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class GpsException implements Exception {
  final String title;
  final String message;
  final String? details;
  final GpsNoticeType noticeType;
  final GpsFailure kind;

  const GpsException(
    this.message, {
    this.title = 'Chưa xác định rõ vị trí',
    this.details,
    this.noticeType = GpsNoticeType.warning,
    this.kind = GpsFailure.uncertain,
  });

  @override
  String toString() => message;
}

class GpsCheckResult {
  final Position position;
  final double distanceMeters;
  final double radiusMeters;

  const GpsCheckResult({
    required this.position,
    required this.distanceMeters,
    required this.radiusMeters,
  });

  String get message => 'Bạn có thể CHECK IN/OUT.';

  String get details =>
      'Cách địa điểm làm việc: ${gpsMetersText(distanceMeters)} m.\n'
      'Độ chính xác ước tính: khoảng '
      '${gpsMetersText(position.accuracy)} m.\n'
      'Phạm vi chấm công: ${gpsMetersText(radiusMeters)} m.';
}

class GpsService {
  static const double maxAccuracyMeters = 150;

  static const Duration _positionWaitLimit = Duration(seconds: 10);

  static bool _isValidPosition(Position position) {
    return position.latitude.isFinite &&
        position.longitude.isFinite &&
        position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180 &&
        position.accuracy.isFinite &&
        position.accuracy >= 0;
  }

  static GpsCheckResult _toCheckResult(Position position, GpsConfig config) {
    final distance = Geolocator.distanceBetween(
      config.latitude!,
      config.longitude!,
      position.latitude,
      position.longitude,
    );

    return GpsCheckResult(
      position: position,
      distanceMeters: distance,
      radiusMeters: config.radiusMeters,
    );
  }

  static GpsException _checkFailure(GpsCheckResult result) {
    if (result.distanceMeters > result.radiusMeters) {
      return GpsException(
        'Hãy đến địa điểm làm việc để chấm công.',
        title: 'Ngoài khu vực chấm công',
        details: result.details,
        noticeType: GpsNoticeType.error,
        kind: GpsFailure.outside,
      );
    }

    return GpsException(
      'Hãy thử cập nhật vị trí.',
      title: 'Chưa xác định rõ vị trí',
      details: result.details,
    );
  }

  static Future<Position> _waitForAccuratePosition({GpsConfig? config}) async {
    final completer = Completer<Position>();

    StreamSubscription<Position>? subscription;
    Timer? timer;

    // Mẫu có accuracy tốt nhất trong lượt hiện tại.
    Position? bestPosition;

    // Trong các mẫu có accuracy đạt giới hạn, giữ mẫu có
    // khoảng cách + accuracy nhỏ nhất để giải thích khi thất bại.
    GpsCheckResult? bestCheckResult;

    var receivedInvalidPosition = false;

    void finishWithoutGoodPosition() {
      if (completer.isCompleted) return;

      final bestCheck = bestCheckResult;

      if (bestCheck != null) {
        completer.completeError(_checkFailure(bestCheck));
        return;
      }

      final best = bestPosition;

      if (best != null) {
        completer.completeError(
          GpsException(
            'Vị trí vẫn chưa đủ chính xác. Hãy thử cập nhật lại.',
            details:
                'Độ chính xác tốt nhất nhận được: khoảng '
                '${gpsMetersText(best.accuracy)} m.\n'
                'Sai số tối đa được chấp nhận: '
                '${gpsMetersText(maxAccuracyMeters)} m.',
          ),
        );
        return;
      }

      if (receivedInvalidPosition) {
        completer.completeError(
          const GpsException(
            'Hãy thử cập nhật vị trí.',
            details: 'Thiết bị chưa cung cấp dữ liệu vị trí hợp lệ.',
          ),
        );
        return;
      }

      completer.completeError(TimeoutException('Chưa nhận được vị trí.'));
    }

    try {
      timer = Timer(_positionWaitLimit, finishWithoutGoodPosition);

      subscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          ).listen(
            (position) {
              if (completer.isCompleted) return;

              if (!_isValidPosition(position)) {
                receivedInvalidPosition = true;
                return;
              }

              final best = bestPosition;

              if (best == null || position.accuracy < best.accuracy) {
                bestPosition = position;
              }

              // Accuracy chưa đạt: tiếp tục chờ.
              if (position.accuracy > maxAccuracyMeters) {
                return;
              }

              final currentConfig = config;

              // Lấy vị trí để thiết lập địa điểm:
              // chưa có tâm để kiểm tra khoảng cách.
              if (currentConfig == null) {
                completer.complete(position);
                return;
              }

              // Kiểm tra chấm công: xét đủ điều kiện ngay trong
              // lượt chờ, thay vì kết thúc chỉ vì accuracy đạt.
              final result = _toCheckResult(position, currentConfig);

              if (!result.distanceMeters.isFinite) {
                completer.completeError(
                  const GpsException(
                    'Hãy nhờ Admin kiểm tra lại địa điểm chấm công.',
                    title: 'Địa điểm chấm công chưa hợp lệ',
                    kind: GpsFailure.notConfigured,
                  ),
                );
                return;
              }

              final previous = bestCheckResult;

              final total = result.distanceMeters + position.accuracy;

              if (previous == null ||
                  total <
                      previous.distanceMeters + previous.position.accuracy) {
                bestCheckResult = result;
              }

              if (result.distanceMeters > result.radiusMeters ||
                  !(total <= result.radiusMeters)) {
                return;
              }

              completer.complete(position);
            },
            onError: (Object error, StackTrace stackTrace) {
              if (completer.isCompleted) return;

              completer.completeError(error, stackTrace);
            },
            onDone: finishWithoutGoodPosition,
            cancelOnError: true,
          );

      return await completer.future;
    } finally {
      timer?.cancel();
      await subscription?.cancel();
    }
  }

  static Future<Position> _getPosition({GpsConfig? config}) async {
    try {
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const GpsException(
            'Hãy bật dịch vụ vị trí trong cài đặt thiết bị.',
            title: 'Chưa bật vị trí',
            kind: GpsFailure.unavailable,
          );
        }

        var permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw const GpsException(
            'Hãy cho phép ứng dụng sử dụng vị trí.',
            title: 'Chưa được cấp quyền vị trí',
            kind: GpsFailure.permission,
          );
        }
      }

      return await _waitForAccuratePosition(config: config);
    } on GpsException {
      rethrow;
    } on PermissionDeniedException {
      throw GpsException(
        kIsWeb
            ? 'Hãy cho phép website sử dụng vị trí trong Chrome '
                  'và kiểm tra quyền vị trí trong Windows.'
            : 'Hãy cho phép ứng dụng sử dụng vị trí.',
        title: 'Chưa được cấp quyền vị trí',
        kind: GpsFailure.permission,
      );
    } on LocationServiceDisabledException {
      throw GpsException(
        kIsWeb
            ? 'Hãy bật dịch vụ vị trí trong Windows.'
            : 'Hãy bật dịch vụ vị trí trong cài đặt thiết bị.',
        title: 'Chưa bật vị trí',
        kind: GpsFailure.unavailable,
      );
    } on TimeoutException {
      throw GpsException(
        'Hãy thử cập nhật vị trí.',
        details:
            'Chưa nhận được vị trí trong thời gian chờ '
            'tối đa ${_positionWaitLimit.inSeconds} giây.',
      );
    } catch (_) {
      throw const GpsException(
        'Hãy kiểm tra quyền vị trí, sau đó thử lại.',
        title: 'Chưa lấy được vị trí',
        kind: GpsFailure.unavailable,
      );
    }
  }

  static Future<Position> getPosition() {
    return _getPosition();
  }

  static Future<GpsCheckResult> check(GpsConfig config) async {
    if (!config.hasCenter) {
      throw const GpsException(
        'Admin cần thiết lập địa điểm trước khi chấm công.',
        title: 'Chưa có địa điểm chấm công',
        kind: GpsFailure.notConfigured,
      );
    }

    final position = await _getPosition(config: config);

    return _toCheckResult(position, config);
  }
}
