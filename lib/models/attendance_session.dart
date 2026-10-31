import '../face/face_profile.dart';
import '../face/face_service.dart';
import '../face/face_store.dart';
import '../gps/gps_config.dart';
import '../gps/gps_service.dart';
import '../services/attendance_service.dart';
import '../services/attendance_store.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/employee_service.dart';
import '../services/shift_service.dart';
import '../services/attendance_setup_service.dart';

import 'app_user.dart';
import 'attendance_record.dart';
import 'work_shift.dart';

class _AttendanceData {
  bool loaded = false;
  bool saving = false;

  List<AppUser> users = demoUsers();
  Set<String>? employeeIds;
  final Map<String, Set<String>> remoteShiftIds = {};

  List<WorkShift> shifts = [];

  // Giữ dữ liệu local cũ, không dùng làm lịch sử backend.
  List<AttendanceRecord> records = [];
  final Map<String, List<AttendanceRecord>> backendRecords = {};
  final Map<String, String> historyErrors = {};

  Map<String, String> shiftOwners = {};
  Map<String, String> recordOwners = {};
  Map<String, String> selectedIds = {};

  GpsConfig gps = GpsConfig();
  bool gpsLoaded = false;

  int nextId = 0;
  int nextUserId = 0;
}

class AttendanceSession {
  final AttendanceStore _store;
  final FaceStore _faceStore;
  final FaceVerifier _faceVerifier;
  final _AttendanceData _data;

  _FacePermit? _facePermit;

  final AuthService auth;

  late final EmployeeService _employeeService = EmployeeService(auth);
  late final ShiftService _shiftService = ShiftService(auth);
  late final AttendanceService _attendanceService = AttendanceService(auth);

  late final AttendanceSetupService _setupService = AttendanceSetupService(
    auth,
  );

  String? get _actorId => currentUser?.id;
  String? _targetId;

  AttendanceSession({
    AttendanceStore? store,
    FaceStore? faceStore,
    FaceVerifier? faceVerifier,
    AuthService? auth,
  }) : auth = auth ?? AuthService(),
       _store = store ?? AttendanceStore(),
       _faceStore = faceStore ?? FaceStore(),
       _faceVerifier = faceVerifier ?? FaceService.verify,
       _data = _AttendanceData();

  AttendanceSession._(
    this._store,
    this._data,
    this.auth,
    this._targetId,
    this._faceStore,
    this._faceVerifier,
  );

  AppUser? _findUser(String? id) {
    final actor = currentUser;

    if (actor != null && actor.id == id) return actor;

    for (final user in _data.users) {
      if (user.id == id) return user;
    }

    return null;
  }

  AppUser? get currentUser => auth.currentUser;

  AppUser? get account => isOwnSession ? currentUser : _findUser(_targetId);

  bool get isAdmin => currentUser?.isAdmin == true;

  bool get isOwnSession => _actorId != null && _actorId == _targetId;

  GpsConfig get gpsConfig => _data.gps;

  String? get _gpsUnavailable => !_data.gpsLoaded
      ? 'Chưa tải được địa điểm từ backend. Hãy thử cập nhật vị trí.'
      : gpsConfig.hasCenter
      ? null
      : 'Chưa có địa điểm chấm công. '
            'Hãy nhờ Admin thiết lập địa điểm trước.';

  List<AppUser> get employees {
    if (!isAdmin) return const [];

    final result =
        _data.users
            .where(
              (user) =>
                  !user.isAdmin &&
                  (_data.employeeIds?.contains(user.id) ?? false),
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return List.unmodifiable(result);
  }

  List<WorkShift> get shifts {
    final visible = _data.remoteShiftIds[_targetId] ?? const <String>{};

    final result = _data.shifts
        .where(
          (shift) =>
              _data.shiftOwners[shift.id] == _targetId &&
              visible.contains(shift.id),
        )
        .toList();

    final active = activeRecord;

    if (active != null && !result.any((shift) => shift.id == active.shiftId)) {
      result.add(active.shiftSnapshot);
    }

    result.sort((a, b) => a.start.compareTo(b.start));

    return List.unmodifiable(result);
  }

  List<AttendanceRecord> get records {
    final result = [...?_data.backendRecords[_targetId]]
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

    return List.unmodifiable(result);
  }

  String? get historyError => _data.historyErrors[_targetId];

  Future<String?> loadRecords() async {
    clearFaceVerification();

    final error = _unavailable;
    if (error != null) return error;

    final actorId = _actorId;
    final targetId = _targetId!;

    try {
      final rows = await _attendanceService.list(targetId);

      if (_actorId != actorId || _targetId != targetId || currentUser == null) {
        return 'Phiên đăng nhập đã thay đổi. Hãy mở lại lịch sử.';
      }

      _data.backendRecords[targetId] = rows;
      _data.historyErrors.remove(targetId);

      final active = activeRecord;

      if (active != null) {
        _data.selectedIds[targetId] = active.shiftId;
      }

      return null;
    } on ApiException catch (error) {
      if (_actorId == actorId && _targetId == targetId) {
        _data.historyErrors[targetId] = error.message;
      }

      return error.message;
    }
  }

  String? get selectedShiftId => _data.selectedIds[_targetId];

  String createShiftId() =>
      'draft_${DateTime.now().microsecondsSinceEpoch}_${++_data.nextId}';

  WorkShift? get selectedShift {
    for (final shift in shifts) {
      if (shift.id == selectedShiftId) return shift;
    }

    return null;
  }

  AttendanceRecord? recordFor(String shiftId) {
    for (final record in records) {
      if (record.shiftId == shiftId) return record;
    }

    return null;
  }

  AttendanceRecord? get selectedRecord {
    final id = selectedShiftId;
    return id == null ? null : recordFor(id);
  }

  AttendanceRecord? get activeRecord {
    for (final record in records) {
      if (record.checkOut == null) return record;
    }

    return null;
  }

  String? get _storageUnavailable {
    if (!_data.loaded) return 'Dữ liệu chưa tải xong.';
    if (_data.saving) return 'Đang lưu dữ liệu, vui lòng chờ.';

    return null;
  }

  String? get _unavailable {
    final error = _storageUnavailable;

    if (error != null) return error;

    if (currentUser == null || account == null) {
      return 'Hãy đăng nhập lại.';
    }

    return null;
  }

  Future<void> load() async {
    clearFaceVerification();

    _data.remoteShiftIds.clear();
    _data.backendRecords.clear();
    _data.historyErrors.clear();
    _data.gpsLoaded = false;

    final json = await _store.read();

    if (json == null) {
      _data.loaded = true;
      return;
    }

    final version = json['version'];

    if (version != 1 && version != 2) {
      throw StateError('Phiên bản dữ liệu không được hỗ trợ.');
    }

    final users = version == 1
        ? demoUsers()
        : (json['users'] as List).map((item) {
            return AppUser.fromJson(Map<String, dynamic>.from(item as Map));
          }).toList();

    for (var i = 0; i < users.length; i++) {
      final user = users[i];

      if (user.id == 'admin_aivee' && user.username == 'aivee') {
        users[i] = user.update(
          username: 'aiviee',
          fullName: user.fullName,
          email: user.email,
        );
      }
    }

    final shifts = (json['shifts'] as List).map((item) {
      return WorkShift.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();

    final records = (json['records'] as List).map((item) {
      return AttendanceRecord.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();

    const legacyOwner = 'employee_huythong';

    final shiftOwners = version == 1
        ? {for (final shift in shifts) shift.id: legacyOwner}
        : Map<String, String>.from(json['shiftOwners'] as Map);

    final recordOwners = version == 1
        ? {for (final record in records) record.shiftId: legacyOwner}
        : Map<String, String>.from(json['recordOwners'] as Map);

    final selectedIds = version == 1
        ? <String, String>{
            if (json['selectedShiftId'] != null)
              legacyOwner: json['selectedShiftId'] as String,
          }
        : Map<String, String>.from(json['selectedIds'] as Map);

    final gps = json['gps'] == null
        ? GpsConfig()
        : GpsConfig.fromJson(Map<String, dynamic>.from(json['gps'] as Map));

    final actor = currentUser;

    if (actor != null) {
      users.removeWhere((user) => user.id == actor.id);
      users.add(actor);
    }

    final userIds = users.map((user) => user.id).toSet();

    if (userIds.length != users.length ||
        !users.any((user) => user.isAdmin) ||
        shifts.map((shift) => shift.id).toSet().length != shifts.length ||
        records.map((record) => record.shiftId).toSet().length !=
            records.length) {
      throw StateError('Dữ liệu tài khoản hoặc ca bị trùng.');
    }

    for (final shift in shifts) {
      if (!userIds.contains(shiftOwners[shift.id])) {
        throw StateError('Ca chưa được gắn với tài khoản hợp lệ.');
      }
    }

    for (final record in records) {
      if (!userIds.contains(recordOwners[record.shiftId])) {
        throw StateError('Lịch sử chưa có tài khoản hợp lệ.');
      }
    }

    selectedIds.removeWhere(
      (userId, shiftId) =>
          !userIds.contains(userId) ||
          !shifts.any(
            (shift) => shift.id == shiftId && shiftOwners[shift.id] == userId,
          ),
    );

    for (final user in users) {
      final active = records
          .where(
            (record) =>
                recordOwners[record.shiftId] == user.id &&
                record.checkOut == null,
          )
          .toList();

      if (active.length > 1) {
        throw StateError('Một tài khoản có nhiều ca đang làm.');
      }

      if (active.isNotEmpty) {
        final id = active.first.shiftId;

        if (!shifts.any(
          (shift) => shift.id == id && shiftOwners[id] == user.id,
        )) {
          throw StateError('Ca đang làm không hợp lệ.');
        }

        selectedIds[user.id] = id;
      }
    }

    var nextId = (json['nextId'] as int?) ?? 0;

    for (final id in [
      ...shifts.map((shift) => shift.id),
      ...records.map((record) => record.shiftId),
    ]) {
      final number = int.tryParse(id.replaceFirst('shift_', '')) ?? 0;

      if (number > nextId) nextId = number;
    }

    _data.users = users;
    _data.shifts = shifts;
    _data.records = records;
    _data.shiftOwners = shiftOwners;
    _data.recordOwners = recordOwners;
    _data.selectedIds = selectedIds;
    _data.gps = gps;
    _data.nextId = nextId;
    _data.nextUserId = (json['nextUserId'] as int?) ?? 0;
    _data.loaded = true;
  }

  Future<String?> signIn(String username, String password) async {
    clearFaceVerification();

    final error = _storageUnavailable;
    if (error != null) return error;

    try {
      await auth.signIn(username, password);

      _targetId = currentUser!.id;
      _mergeUsers([currentUser!]);

      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> refreshUser() => auth.refreshUser();

  Future<String?> signOut() async {
    clearFaceVerification();

    try {
      await auth.signOut();
      _targetId = null;

      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  AttendanceSession forEmployee(String userId) {
    if (!isAdmin) {
      throw StateError('Chỉ Admin được quản lý nhân viên.');
    }

    final user = _findUser(userId);

    if (user == null || user.isAdmin) {
      throw StateError('Không tìm thấy nhân viên.');
    }

    return AttendanceSession._(
      _store,
      _data,
      auth,
      userId,
      _faceStore,
      _faceVerifier,
    );
  }

  void clearFaceVerification() => _facePermit = null;

  Future<Set<String>> registeredIds() async {
    if (!isAdmin) return <String>{};

    return _setupService.registeredIds();
  }

  Future<String?> migrateLocalSetup() async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin || !isOwnSession) {
      return 'Chỉ Admin được chuyển thiết lập cũ.';
    }

    final actorId = _actorId;
    final allowed = {...?_data.employeeIds, actorId!};

    final localGps = _data.gps;

    _data.saving = true;

    try {
      if (localGps.hasCenter) {
        await _setupService.saveGps(localGps, importing: true);
      }

      final profiles = await _faceStore.readAll();

      for (final entry in profiles.entries) {
        if (!isAdmin || _actorId != actorId) {
          return 'Phiên quản lý đã thay đổi. '
              'Hãy đăng nhập lại.';
        }

        if (allowed.contains(entry.key)) {
          await _setupService.saveFace(entry.key, entry.value, importing: true);
        }
      }

      return null;
    } on ApiException catch (error) {
      return error.message;
    } on FaceException catch (error) {
      return error.message;
    } catch (_) {
      return 'Chưa chuyển được thiết lập cũ. Hãy thử lại.';
    } finally {
      _data.saving = false;
    }
  }

  Future<String?> loadGpsConfig() async {
    clearFaceVerification();

    final error = _unavailable;
    if (error != null) return error;

    final actorId = _actorId;

    try {
      final config = await _setupService.loadGps();

      if (_actorId != actorId || currentUser == null) {
        return 'Phiên đăng nhập đã thay đổi. Hãy mở lại.';
      }

      _data.gps = config;
      _data.gpsLoaded = true;

      return null;
    } on ApiException catch (error) {
      _data.gpsLoaded = false;
      return error.message;
    }
  }

  Future<String?> registerFace(String userId) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được đăng ký khuôn mặt.';
    }

    final user = _findUser(userId);

    if (user == null) return 'Không tìm thấy tài khoản.';

    final actorId = _actorId;

    try {
      final existingProfile = await _setupService.loadFace(userId);

      final readError = _unavailable;
      if (readError != null) return readError;

      if (!isAdmin || _actorId != actorId || _findUser(userId) == null) {
        return 'Phiên quản lý đã thay đổi. Hãy mở lại.';
      }

      final profile = await FaceService.enroll(
        user.fullName,
        existingProfile: existingProfile,
      );

      final pendingError = _unavailable;
      if (pendingError != null) return pendingError;

      if (!isAdmin || _actorId != actorId || _findUser(userId) == null) {
        return 'Phiên quản lý đã thay đổi. Hãy mở lại.';
      }

      _data.saving = true;

      try {
        await _setupService.saveFace(userId, profile);
        clearFaceVerification();

        return null;
      } finally {
        _data.saving = false;
      }
    } on ApiException catch (error) {
      return error.message;
    } on FaceCancelled {
      return 'Đã hủy đăng ký khuôn mặt.';
    } on FaceException catch (error) {
      return error.message;
    } catch (_) {
      return 'Chưa lưu được khuôn mặt. Hãy thử lại.';
    }
  }

  Future<String?> verifyOwnFace() async {
    clearFaceVerification();

    final error = _unavailable;
    if (error != null) return error;

    if (!isOwnSession) {
      return 'Không thể chấm công thay nhân viên.';
    }

    final gpsError = _gpsUnavailable;
    if (gpsError != null) return gpsError;

    final user = currentUser!;
    final shiftId = selectedShiftId;

    if (shiftId == null || selectedShift == null) {
      return 'Hãy chọn ca được giao trong Lịch làm.';
    }

    if (selectedRecord?.checkOut != null) {
      return 'Ca này đã hoàn thành.';
    }

    final checkingIn = selectedRecord == null;

    try {
      final profile = await _setupService.loadFace(user.id);

      if (profile == null) {
        return 'Tài khoản chưa có mẫu khuôn mặt. '
            'Hãy nhờ Admin đăng ký.';
      }

      final matched = await _faceVerifier(user.fullName, profile);

      final pendingError = _unavailable;
      if (pendingError != null) return pendingError;

      final pendingGpsError = _gpsUnavailable;
      if (pendingGpsError != null) return pendingGpsError;

      if (!isOwnSession ||
          _actorId != user.id ||
          selectedShiftId != shiftId ||
          (selectedRecord == null) != checkingIn ||
          selectedRecord?.checkOut != null) {
        return 'Tài khoản hoặc ca đã thay đổi. '
            'Hãy xác minh lại.';
      }

      if (!matched) {
        return 'Khuôn mặt không khớp '
            'với tài khoản đang đăng nhập.';
      }

      _facePermit = _FacePermit(user.id, shiftId, checkingIn);

      return null;
    } on ApiException catch (error) {
      return error.message;
    } on FaceCancelled {
      return 'Đã hủy xác minh khuôn mặt.';
    } on FaceException catch (error) {
      return error.message;
    } catch (_) {
      return 'Chưa xác minh được khuôn mặt. Hãy thử lại.';
    }
  }

  String? _consumeFaceVerification({required bool checkingIn}) {
    final permit = _facePermit;
    clearFaceVerification();

    if (permit == null ||
        permit.watch.elapsed > const Duration(seconds: 90) ||
        permit.userId != _actorId ||
        permit.userId != _targetId ||
        permit.shiftId != selectedShiftId ||
        permit.checkingIn != checkingIn) {
      return 'Hãy xác minh khuôn mặt lại '
          'trước khi chấm công.';
    }

    return null;
  }

  Future<String?> _commit({
    List<AppUser>? users,
    List<WorkShift>? shifts,
    List<AttendanceRecord>? records,
    Map<String, String>? shiftOwners,
    Map<String, String>? recordOwners,
    Map<String, String>? selectedIds,
    GpsConfig? gps,
    int? nextUserId,
  }) async {
    final nextUsers = users ?? [..._data.users];
    final nextShifts = shifts ?? [..._data.shifts];
    final nextRecords = records ?? [..._data.records];
    final nextShiftOwners = shiftOwners ?? {..._data.shiftOwners};
    final nextRecordOwners = recordOwners ?? {..._data.recordOwners};
    final nextSelected = selectedIds ?? {..._data.selectedIds};
    final nextGps = gps ?? _data.gps;
    final nextUserNumber = nextUserId ?? _data.nextUserId;

    _data.saving = true;

    try {
      await _store.write({
        'version': 2,
        'nextId': _data.nextId,
        'nextUserId': nextUserNumber,
        'users': nextUsers.map((user) => user.toJson()).toList(),
        'shifts': nextShifts.map((shift) => shift.toJson()).toList(),
        'records': nextRecords.map((record) => record.toJson()).toList(),
        'shiftOwners': nextShiftOwners,
        'recordOwners': nextRecordOwners,
        'selectedIds': nextSelected,
        'gps': nextGps.toJson(),
      });

      _data.users = nextUsers;
      _data.shifts = nextShifts;
      _data.records = nextRecords;
      _data.shiftOwners = nextShiftOwners;
      _data.recordOwners = nextRecordOwners;
      _data.selectedIds = nextSelected;
      _data.gps = nextGps;
      _data.nextUserId = nextUserNumber;

      return null;
    } catch (_) {
      return 'Không lưu được dữ liệu. Hãy thử lại.';
    } finally {
      _data.saving = false;
    }
  }

  void _mergeUsers(Iterable<AppUser> users) {
    final registry = {for (final user in _data.users) user.id: user};

    for (final user in users) {
      registry[user.id] = user;
    }

    _data.users = registry.values.toList();
  }

  Future<String?> loadEmployees() async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được xem danh sách nhân viên.';
    }

    final actorId = _actorId;

    try {
      final users = await _employeeService.list();

      if (!isAdmin || _actorId != actorId) {
        return 'Phiên quản lý đã thay đổi. Hãy đăng nhập lại.';
      }

      _mergeUsers(users);
      _data.employeeIds = users.map((user) => user.id).toSet();

      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> saveEmployee({
    String? id,
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được quản lý tài khoản.';
    }

    final login = username.trim().toLowerCase();
    final mail = email.trim().toLowerCase();
    final name = fullName.trim();

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(login) || login.length > 64) {
      return 'Tài khoản tối đa 64 ký tự, '
          'chỉ dùng chữ, số và dấu gạch dưới.';
    }

    if (name.isEmpty ||
        name.length > 120 ||
        mail.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      return 'Hãy nhập họ tên tối đa 120 ký tự '
          'và email hợp lệ.';
    }

    if ((id == null && password.isEmpty) || password.length > 128) {
      return 'Hãy nhập mật khẩu từ 1 đến 128 ký tự.';
    }

    final actorId = _actorId;
    _data.saving = true;

    try {
      final user = await _employeeService.save(
        id: id,
        username: login,
        fullName: name,
        email: mail,
        password: password,
      );

      if (!isAdmin || _actorId != actorId) {
        return 'Phiên quản lý đã thay đổi. Hãy đăng nhập lại.';
      }

      _mergeUsers([user]);

      _data.employeeIds = {...?_data.employeeIds, user.id};

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }

  void _mergeShifts(Iterable<ShiftAssignment> assignments) {
    final registry = {for (final shift in _data.shifts) shift.id: shift};

    for (final item in assignments) {
      registry[item.shift.id] = item.shift;
      _data.shiftOwners[item.shift.id] = item.userId;
    }

    _data.shifts = registry.values.toList();
  }

  Future<String?> migrateLocalShifts() async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin || !isOwnSession) {
      return 'Chỉ Admin được chuyển ca cũ.';
    }

    final actorId = _actorId;
    final allowed = {...?_data.employeeIds, actorId!};

    final old = <String, WorkShift>{};
    final owners = <String, String>{};
    final archived = <String>{};

    for (final shift in _data.shifts) {
      final owner = _data.shiftOwners[shift.id];

      if (!shift.isRemote &&
          !shift.id.startsWith('draft_') &&
          allowed.contains(owner)) {
        old[shift.id] = shift;
        owners[shift.id] = owner!;
      }
    }

    for (final record in _data.records) {
      final shift = record.shiftSnapshot;
      final owner = _data.recordOwners[shift.id];

      if (!shift.isRemote &&
          allowed.contains(owner) &&
          !old.containsKey(shift.id)) {
        old[shift.id] = shift;
        owners[shift.id] = owner!;
        archived.add(shift.id);
      }
    }

    if (old.isEmpty) return null;

    _data.saving = true;

    try {
      final mapping = await _shiftService.importLegacy([
        for (final entry in old.entries)
          {
            'legacyId': entry.key,
            'userId': owners[entry.key],
            'name': entry.value.name,
            'start': entry.value.start.toUtc().toIso8601String(),
            'end': entry.value.end.toUtc().toIso8601String(),
            'isDeleted': archived.contains(entry.key),
          },
      ]);

      if (!isAdmin || _actorId != actorId) {
        return 'Phiên quản lý đã thay đổi. Hãy đăng nhập lại.';
      }

      String remap(String id) => mapping[id]?.shift.id ?? id;

      final nextShifts = <String, WorkShift>{};

      for (final shift in _data.shifts) {
        final next = mapping[shift.id]?.shift ?? shift;
        nextShifts[next.id] = next;
      }

      for (final item in mapping.values) {
        nextShifts[item.shift.id] = item.shift;
      }

      final shiftOwners = {
        for (final entry in _data.shiftOwners.entries)
          remap(entry.key): entry.value,
        for (final item in mapping.values) item.shift.id: item.userId,
      };

      final nextRecords = _data.records
          .map(
            (record) => AttendanceRecord(
              shiftSnapshot: record.shiftSnapshot.withId(remap(record.shiftId)),
              checkIn: record.checkIn,
              checkOut: record.checkOut,
            ),
          )
          .toList();

      final saved = await _commit(
        shifts: nextShifts.values.toList(),
        records: nextRecords,
        shiftOwners: shiftOwners,
        recordOwners: {
          for (final entry in _data.recordOwners.entries)
            remap(entry.key): entry.value,
        },
        selectedIds: {
          for (final entry in _data.selectedIds.entries)
            entry.key: remap(entry.value),
        },
      );

      return saved == null
          ? null
          : 'Ca đã được chuyển lên máy chủ nhưng chưa cập nhật '
                'được dữ liệu local. Hãy thử lại.';
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }

  Future<String?> loadShifts() async {
    clearFaceVerification();

    final error = _unavailable;
    if (error != null) return error;

    final actorId = _actorId;
    final targetId = _targetId!;
    final all = isAdmin && isOwnSession;

    try {
      final rows = await _shiftService.list(userId: all ? null : targetId);

      if (_actorId != actorId || _targetId != targetId || currentUser == null) {
        return 'Phiên đăng nhập đã thay đổi. Hãy mở lại lịch.';
      }

      final recordError = await loadRecords();

      if (recordError != null) return recordError;

      if (_actorId != actorId || _targetId != targetId || currentUser == null) {
        return 'Phiên đăng nhập đã thay đổi. Hãy mở lại lịch.';
      }

      _mergeShifts(rows);

      final targets = all ? {...?_data.employeeIds, actorId!} : {targetId};

      for (final id in targets) {
        _data.remoteShiftIds[id] = rows
            .where((row) => row.userId == id)
            .map((row) => row.shift.id)
            .toSet();

        final active = _data.backendRecords[id]
            ?.where((record) => record.checkOut == null)
            .firstOrNull;

        if (active != null) {
          _data.selectedIds[id] = active.shiftId;
        } else if (!(_data.remoteShiftIds[id]?.contains(
              _data.selectedIds[id],
            ) ??
            false)) {
          _data.selectedIds.remove(id);
        }
      }

      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> saveShift(WorkShift shift) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được tạo hoặc sửa ca.';
    }

    if (!shift.id.startsWith('draft_') &&
        !(_data.remoteShiftIds[_targetId]?.contains(shift.id) ?? false)) {
      return 'Ca chưa có trên máy chủ hoặc đã bị xóa. '
          'Hãy tải lại lịch.';
    }

    final actorId = _actorId;
    final targetId = _targetId!;

    _data.saving = true;

    try {
      final item = await _shiftService.save(shift, targetId);

      if (_actorId != actorId || _targetId != targetId || !isAdmin) {
        return 'Phiên quản lý đã thay đổi. Hãy mở lại.';
      }

      _mergeShifts([item]);

      _data.remoteShiftIds[targetId] = {
        ...?_data.remoteShiftIds[targetId],
        item.shift.id,
      };

      _data.selectedIds.putIfAbsent(targetId, () => item.shift.id);

      await _commit();

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }

  Future<String?> deleteShift(String id) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) return 'Chỉ Admin được xóa ca.';

    if (!shifts.any((shift) => shift.id == id)) {
      return 'Không tìm thấy ca này.';
    }

    if (activeRecord?.shiftId == id) {
      return 'Hãy CHECK OUT ca đang làm trước khi xóa.';
    }

    final actorId = _actorId;
    final targetId = _targetId!;

    _data.saving = true;

    try {
      await _shiftService.delete(id);

      if (_actorId != actorId || _targetId != targetId || !isAdmin) {
        return 'Phiên quản lý đã thay đổi. Hãy mở lại.';
      }

      _data.remoteShiftIds[targetId]?.remove(id);

      if (_data.selectedIds[targetId] == id) {
        _data.selectedIds.remove(targetId);
      }

      await _commit();
      clearFaceVerification();

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }

  Future<String?> selectShift(String id) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isOwnSession) {
      return 'Không thể chọn ca thay nhân viên.';
    }

    if (!shifts.any((shift) => shift.id == id)) {
      return 'Không tìm thấy ca này.';
    }

    if (activeRecord != null && activeRecord!.shiftId != id) {
      return 'Hãy CHECK OUT ca đang làm '
          'trước khi chọn ca khác.';
    }

    if (selectedShiftId == id) return null;

    return _commit(selectedIds: {..._data.selectedIds, _targetId!: id});
  }

  Future<String?> saveGpsConfig(GpsConfig config) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được đổi địa điểm chấm công.';
    }

    if (!config.hasCenter) {
      return 'Hãy chọn địa điểm chấm công.';
    }

    return _writeGps(() => _setupService.saveGps(config));
  }

  Future<String?> clearGpsConfig() async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được xóa địa điểm chấm công.';
    }

    return _writeGps(_setupService.clearGps);
  }

  Future<String?> _writeGps(Future<GpsConfig> Function() request) async {
    final actorId = _actorId;
    _data.saving = true;

    try {
      final config = await request();

      if (!isAdmin || _actorId != actorId) {
        return 'Phiên quản lý đã thay đổi. Hãy đăng nhập lại.';
      }

      _data.gps = config;
      _data.gpsLoaded = true;

      clearFaceVerification();

      await _commit();

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }

  Future<String?> checkIn(DateTime now, {required GpsCheckResult gps}) =>
      _submitAttendance(checkingIn: true, gps: gps);

  Future<String?> checkOut(DateTime now, {required GpsCheckResult gps}) =>
      _submitAttendance(checkingIn: false, gps: gps);

  Future<String?> _submitAttendance({
    required bool checkingIn,
    required GpsCheckResult gps,
  }) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isOwnSession) {
      return 'Không thể chấm công thay nhân viên.';
    }

    final gpsError = _gpsUnavailable;
    if (gpsError != null) return gpsError;

    final shiftId = selectedShiftId;

    if (shiftId == null || selectedShift == null) {
      return 'Hãy chọn ca được giao trong Lịch làm.';
    }

    final faceError = _consumeFaceVerification(checkingIn: checkingIn);

    if (faceError != null) return faceError;

    final actorId = _actorId!;

    _data.saving = true;
    String? failure;

    try {
      final record = await _attendanceService.submit(
        userId: actorId,
        shiftId: shiftId,
        checkingIn: checkingIn,
        gps: gps,
      );

      if (_actorId != actorId || _targetId != actorId) {
        return 'Phiên đăng nhập đã thay đổi. '
            'Hãy tải lại lịch sử.';
      }

      final rows = [...?_data.backendRecords[actorId]]
        ..removeWhere((item) => item.shiftId == record.shiftId)
        ..add(record);

      _data.backendRecords[actorId] = rows;
      _data.historyErrors.remove(actorId);

      return null;
    } on ApiException catch (error) {
      failure = error.message;
    } finally {
      _data.saving = false;
    }

    // Có thể máy chủ đã lưu nhưng phản hồi bị mất.
    if (_actorId == actorId && _targetId == actorId) {
      await loadRecords();
    }

    return failure;
  }

  Future<String?> deleteRecord(String shiftId) async {
    final error = _unavailable;
    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được xóa lịch sử.';
    }

    final actorId = _actorId;
    final targetId = _targetId!;

    _data.saving = true;

    try {
      await _attendanceService.delete(shiftId);

      if (!isAdmin || _actorId != actorId || _targetId != targetId) {
        return 'Phiên quản lý đã thay đổi. '
            'Hãy tải lại lịch sử.';
      }

      _data.backendRecords[targetId]?.removeWhere(
        (row) => row.shiftId == shiftId,
      );

      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _data.saving = false;
    }
  }
}

class _FacePermit {
  final String userId;
  final String shiftId;
  final bool checkingIn;

  final Stopwatch watch = Stopwatch()..start();

  _FacePermit(this.userId, this.shiftId, this.checkingIn);
}
