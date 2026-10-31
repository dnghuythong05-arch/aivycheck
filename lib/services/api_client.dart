import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final http.Client _client;
  final Duration timeout;

  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 15)})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Accept'] = 'application/json';

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = switch (response.statusCode) {
          401 => 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
          403 => 'Tài khoản không có quyền thực hiện thao tác này.',
          422 => 'Thông tin gửi lên chưa hợp lệ.',
          >= 500 => 'Backend chưa xử lý được dữ liệu. Hãy thử lại.',
          _ => 'Chưa thực hiện được yêu cầu. Hãy thử lại.',
        };

        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));

          if (response.statusCode < 500 && data is Map) {
            final detail = data['detail'];

            if (detail is String && detail.isNotEmpty) {
              message = detail;
            }
          }
        } on FormatException {
          // Giữ thông báo chung nếu backend không trả JSON.
        }

        throw ApiException(message, statusCode: response.statusCode);
      }

      if (response.statusCode == 204) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Response không phải JSON object.');
      }

      return data;
    } on TimeoutException {
      throw const ApiException('Backend phản hồi quá lâu. Hãy thử lại.');
    } on http.ClientException {
      throw const ApiException(
        'Chưa kết nối được backend. Hãy kiểm tra terminal chạy API.',
      );
    } on FormatException {
      throw const ApiException('Dữ liệu backend trả về chưa hợp lệ.');
    }
  }

  void close() => _client.close();
}
