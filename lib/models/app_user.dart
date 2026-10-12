enum UserRole { admin, employee }

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;
  final String _password;

  AppUser({
    required this.id,
    required String username,
    required String fullName,
    required String email,
    required String password,
    required this.role,
  }) : username = username.trim().toLowerCase(),
       fullName = fullName.trim(),
       email = email.trim().toLowerCase(),
       _password = password {
    if (id.isEmpty ||
        this.username.isEmpty ||
        this.fullName.isEmpty ||
        this.email.isEmpty ||
        password.isEmpty) {
      throw ArgumentError('Thông tin tài khoản chưa đầy đủ.');
    }
  }

  bool get isAdmin => role == UserRole.admin;

  String get roleLabel => isAdmin ? 'Admin' : 'Nhân viên';

  bool acceptsPassword(String password) => _password == password;

  AppUser update({
    required String username,
    required String fullName,
    required String email,
    String? password,
  }) {
    return AppUser(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      password: password == null || password.isEmpty ? _password : password,
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'password': _password,
    'role': role.name,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: UserRole.values.byName(json['role'] as String),
    );
  }
}

List<AppUser> demoUsers() => [
  AppUser(
    id: 'admin_aivee',
    username: 'aiviee',
    password: '123',
    fullName: 'Trương Thu Thảo',
    email: 'truongaivy2863@gmail.com',
    role: UserRole.admin,
  ),
  AppUser(
    id: 'employee_huythong',
    username: 'huythong',
    password: '123',
    fullName: 'Đặng Huy Thông',
    email: 'dnghuythong05@gmail.com',
    role: UserRole.employee,
  ),
];
