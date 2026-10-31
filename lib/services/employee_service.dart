import '../models/app_user.dart';
import 'api_client.dart';
import 'auth_service.dart';

class EmployeeService {
  final AuthService auth;

  EmployeeService(this.auth);

  Future<void> delete(String userId) async {
    await auth.authorizedRequest(
      'DELETE',
      '/api/users/employees/${Uri.encodeComponent(userId)}',
    );
  }

  AppUser _readUser(Object? data) {
    try {
      final user = AppUser.fromApiJson(Map<String, dynamic>.from(data as Map));

      if (user.isAdmin) {
        throw const FormatException();
      }

      return user;
    } catch (_) {
      throw const ApiException(
        'Thông tin nhân viên backend trả về chưa hợp lệ.',
      );
    }
  }

  Future<List<AppUser>> list() async {
    final result = await auth.authorizedRequest('GET', '/api/users/employees');

    final rows = result?['users'];

    if (rows is! List) {
      throw const ApiException(
        'Danh sách nhân viên backend trả về chưa hợp lệ.',
      );
    }

    final users = rows.map(_readUser).toList();

    if (users.map((user) => user.id).toSet().length != users.length) {
      throw const ApiException('Danh sách nhân viên có ID bị trùng.');
    }

    return users;
  }

  Future<AppUser> save({
    String? id,
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = _readUser(
      await auth.authorizedRequest(
        id == null ? 'POST' : 'PUT',
        id == null
            ? '/api/users/employees'
            : '/api/users/employees/${Uri.encodeComponent(id)}',
        body: {
          'username': username.trim().toLowerCase(),
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          if (id == null || password.isNotEmpty) 'password': password,
        },
      ),
    );

    if (id != null && user.id != id) {
      throw const ApiException('ID nhân viên trả về không khớp. Hãy tải lại.');
    }

    return user;
  }
}
