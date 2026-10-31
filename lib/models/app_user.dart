enum UserRole { admin, employee }

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;

  AppUser({
    required this.id,
    required String username,
    required String fullName,
    required String email,
    required this.role,
  }) : username = username.trim().toLowerCase(),
       fullName = fullName.trim(),
       email = email.trim().toLowerCase() {
    if (id.isEmpty ||
        this.username.isEmpty ||
        this.fullName.isEmpty ||
        this.email.isEmpty) {
      throw ArgumentError('Thông tin tài khoản chưa đầy đủ.');
    }
  }

  bool get isAdmin => role == UserRole.admin;

  String get roleLabel => isAdmin ? 'Admin' : 'Nhân viên';

  AppUser update({
    required String username,
    required String fullName,
    required String email,
  }) => AppUser(
    id: id,
    username: username,
    fullName: fullName,
    email: email,
    role: role,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.name,
  };

  factory AppUser.fromApiJson(Map<String, dynamic> json) {
    final role = json['role'];

    if (role != 'admin' && role != 'employee') {
      throw const FormatException('Vai trò tài khoản không hợp lệ.');
    }

    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(role as String),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser.fromApiJson(json);
}

List<AppUser> demoUsers() => [
  AppUser(
    id: 'admin_aivee',
    username: 'aiviee',
    fullName: 'Trương Thu Thảo',
    email: 'truongaivy2863@gmail.com',
    role: UserRole.admin,
  ),
  AppUser(
    id: 'employee_huythong',
    username: 'huythong',
    fullName: 'Đặng Huy Thông',
    email: 'dnghuythong05@gmail.com',
    role: UserRole.employee,
  ),
];
