import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api;

  AppUser? _user;
  String? _token;
  DateTime? _expiresAt;
  Timer? _expiryTimer;
  Future<Map<String, dynamic>?> authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    checkExpiry();

    final token = _token;

    if (token == null) {
      throw const ApiException('Hãy đăng nhập lại.', statusCode: 401);
    }

    try {
      final result = await _api.request(method, path, token: token, body: body);

      if (_token != token) {
        throw const ApiException(
          'Phiên đăng nhập đã thay đổi.',
          statusCode: 401,
        );
      }

      return result;
    } on ApiException catch (error) {
      if (error.statusCode == 401 && _token == token) {
        _clear();
      }

      rethrow;
    }
  }

  AuthService({ApiClient? api}) : _api = api ?? ApiClient();

  AppUser? get currentUser => _user;

  void checkExpiry() {
    final expiry = _expiresAt;

    if (expiry != null && !DateTime.now().toUtc().isBefore(expiry)) {
      _clear();
    }
  }

  Future<void> signIn(String username, String password) async {
    if (_token != null) {
      throw const ApiException('Hãy đăng xuất trước khi đổi tài khoản.');
    }

    String? issuedToken;

    try {
      final result = await _api.request(
        'POST',
        '/api/auth/login',
        body: {'username': username.trim().toLowerCase(), 'password': password},
      );

      final token = result?['access_token'];

      if (token is! String || token.length != 43) {
        throw const FormatException('Token không hợp lệ.');
      }

      issuedToken = token;

      final expiresAt = DateTime.parse(result!['expires_at'] as String).toUtc();

      final loginUser = AppUser.fromApiJson(
        Map<String, dynamic>.from(result['user'] as Map),
      );

      if (result['token_type'] != 'bearer' ||
          !DateTime.now().toUtc().isBefore(expiresAt)) {
        throw const FormatException('Phiên không hợp lệ.');
      }

      final profile = await _api.request('GET', '/api/auth/me', token: token);

      final user = AppUser.fromApiJson(profile!);

      if (user.id != loginUser.id) {
        throw const FormatException('Thông tin phiên không khớp.');
      }

      final remaining = expiresAt.difference(DateTime.now().toUtc());

      if (remaining <= Duration.zero) {
        throw const FormatException('Phiên đã hết hạn.');
      }

      _token = token;
      _user = user;
      _expiresAt = expiresAt;
      _expiryTimer = Timer(remaining, _clear);

      notifyListeners();
    } catch (error) {
      // Nếu login đã tạo phiên nhưng /me thất bại,
      // thu hồi phiên vừa tạo.
      if (issuedToken != null) {
        try {
          await _api.request('POST', '/api/auth/logout', token: issuedToken);
        } catch (_) {
          // Chưa mở quyền truy cập vào ứng dụng.
          // Phiên vẫn có thời hạn ở backend.
        }
      }

      if (error is ApiException) rethrow;

      throw const ApiException('Dữ liệu đăng nhập backend trả về chưa hợp lệ.');
    }
  }

  Future<void> refreshUser() async {
    checkExpiry();

    final token = _token;

    if (token == null) {
      throw const ApiException('Hãy đăng nhập lại.', statusCode: 401);
    }

    try {
      final profile = await _api.request('GET', '/api/auth/me', token: token);

      if (_token != token) return;

      final user = AppUser.fromApiJson(profile!);

      if (user.id != _user?.id) {
        _clear();

        throw const ApiException(
          'Thông tin phiên không khớp. Hãy đăng nhập lại.',
        );
      }

      _user = user;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.statusCode == 401 && _token == token) {
        _clear();
      }

      rethrow;
    } on FormatException {
      throw const ApiException(
        'Thông tin tài khoản backend trả về chưa hợp lệ.',
      );
    } on TypeError {
      throw const ApiException(
        'Thông tin tài khoản backend trả về chưa hợp lệ.',
      );
    } on ArgumentError {
      throw const ApiException(
        'Thông tin tài khoản backend trả về chưa hợp lệ.',
      );
    }
  }

  Future<void> signOut() async {
    final token = _token;

    if (token == null) {
      _clear();
      return;
    }

    try {
      await _api.request('POST', '/api/auth/logout', token: token);
    } on ApiException catch (error) {
      // Phiên đã bị thu hồi hoặc hết hạn:
      // vẫn xóa trạng thái đăng nhập trên Flutter.
      if (error.statusCode != 401) rethrow;
    }

    if (_token == token) {
      _clear();
    }
  }

  void _clear() {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    _token = null;
    _expiresAt = null;
    _user = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _token = null;
    _user = null;
    _expiresAt = null;

    _expiryTimer?.cancel();
    _api.close();

    super.dispose();
  }
}
