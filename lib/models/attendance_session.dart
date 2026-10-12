import '../face/face_profile.dart';
import '../face/face_service.dart';
import '../face/face_store.dart';
import '../gps/gps_config.dart';
import '../services/attendance_store.dart';

import 'app_user.dart';
import 'attendance_record.dart';
import 'work_shift.dart';

class _AttendanceData {
  bool loaded = false;
  bool saving = false;

  List<AppUser> users = demoUsers();
  List<WorkShift> shifts = [];
  List<AttendanceRecord> records = [];

  Map<String, String> shiftOwners = {};
  Map<String, String> recordOwners = {};
  Map<String, String> selectedIds = {};

  GpsConfig gps = GpsConfig();

  int nextId = 0;
  int nextUserId = 0;
}

class AttendanceSession {
  final AttendanceStore _store;
  final FaceStore _faceStore;
  final FaceVerifier _faceVerifier;
  final _AttendanceData _data;

  _FacePermit? _facePermit;

  String? _actorId;
  String? _targetId;

  AttendanceSession({
    AttendanceStore? store,
    FaceStore? faceStore,
    FaceVerifier? faceVerifier,
  }) : _store = store ?? AttendanceStore(),
       _faceStore = faceStore ?? FaceStore(),
       _faceVerifier = faceVerifier ?? FaceService.verify,
       _data = _AttendanceData();

  AttendanceSession._(
    this._store,
    this._data,
    this._actorId,
    this._targetId,
    this._faceStore,
    this._faceVerifier,
  );

  AppUser? _findUser(String? id) {
    for (final user in _data.users) {
      if (user.id == id) return user;
    }

    return null;
  }

  AppUser? get currentUser => _findUser(_actorId);

  AppUser? get account => _findUser(_targetId);

  bool get isAdmin => currentUser?.isAdmin == true;

  bool get isOwnSession => _actorId != null && _actorId == _targetId;

  GpsConfig get gpsConfig => _data.gps;

  List<AppUser> get employees {
    if (!isAdmin) return const [];

    final result = _data.users.where((user) => !user.isAdmin).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return List.unmodifiable(result);
  }

  List<WorkShift> get shifts => List.unmodifiable(
    _data.shifts.where((shift) => _data.shiftOwners[shift.id] == _targetId),
  );

  List<AttendanceRecord> get records {
    final result =
        _data.records
            .where((record) => _data.recordOwners[record.shiftId] == _targetId)
            .toList()
          ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

    return List.unmodifiable(result);
  }

  String? get selectedShiftId => _data.selectedIds[_targetId];

  String createShiftId() => 'shift_${++_data.nextId}';

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

    final userIds = users.map((user) => user.id).toSet();

    if (userIds.length != users.length ||
        users.map((user) => user.username).toSet().length != users.length ||
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

  String? signIn(String username, String password) {
    clearFaceVerification();

    final error = _storageUnavailable;

    if (error != null) return error;

    final login = username.trim().toLowerCase();

    for (final user in _data.users) {
      if (user.username == login && user.acceptsPassword(password)) {
        _actorId = user.id;
        _targetId = user.id;

        return null;
      }
    }

    return 'Tài khoản hoặc mật khẩu chưa đúng.';
  }

  void signOut() {
    clearFaceVerification();

    _actorId = null;
    _targetId = null;
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
      _actorId,
      userId,
      _faceStore,
      _faceVerifier,
    );
  }

  void clearFaceVerification() => _facePermit = null;
  Future<Set<String>> registeredIds() async {
    if (!isAdmin) return <String>{};

    final profiles = await _faceStore.readAll();

    return profiles.keys.toSet();
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
      final existingProfile = await _faceStore.read(userId);

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
        if (profile == null) {
          await _faceStore.delete(userId);
        } else {
          await _faceStore.save(userId, profile);
        }

        clearFaceVerification();

        return null;
      } finally {
        _data.saving = false;
      }
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
      final profile = await _faceStore.read(user.id);

      if (profile == null) {
        return 'Tài khoản chưa có mẫu khuôn mặt. '
            'Hãy nhờ Admin đăng ký.';
      }

      final matched = await _faceVerifier(user.fullName, profile);

      final pendingError = _unavailable;

      if (pendingError != null) return pendingError;

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

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(login)) {
      return 'Tài khoản chỉ dùng chữ, '
          'số và dấu gạch dưới.';
    }

    if (name.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      return 'Hãy nhập họ tên và email hợp lệ.';
    }

    if (_data.users.any((user) => user.id != id && user.username == login)) {
      return 'Tên tài khoản đã được sử dụng.';
    }

    if (_data.users.any((user) => user.id != id && user.email == mail)) {
      return 'Email đã được sử dụng.';
    }

    final next = [..._data.users];
    var nextNumber = _data.nextUserId;

    if (id == null) {
      if (password.isEmpty) return 'Hãy nhập mật khẩu.';

      String newId;

      do {
        newId = 'employee_${++nextNumber}';
      } while (_findUser(newId) != null);

      next.add(
        AppUser(
          id: newId,
          username: login,
          fullName: name,
          email: mail,
          password: password,
          role: UserRole.employee,
        ),
      );
    } else {
      final index = next.indexWhere((user) => user.id == id);

      if (index == -1 || next[index].isAdmin) {
        return 'Không tìm thấy tài khoản nhân viên.';
      }

      next[index] = next[index].update(
        username: login,
        fullName: name,
        email: mail,
        password: password,
      );
    }

    return _commit(users: next, nextUserId: nextNumber);
  }

  Future<String?> saveShift(WorkShift shift) async {
    final error = _unavailable;

    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được tạo hoặc sửa ca.';
    }

    final next = [..._data.shifts];

    final index = next.indexWhere((item) => item.id == shift.id);

    if (index != -1 && _data.shiftOwners[shift.id] != _targetId) {
      return 'Ca này thuộc tài khoản khác.';
    }

    if (index == -1 &&
        _data.records.any((record) => record.shiftId == shift.id)) {
      return 'Mã ca đã có trong lịch sử.';
    }

    if (index == -1) {
      next.add(shift);
    } else {
      next[index] = shift;
    }

    final owners = {..._data.shiftOwners};

    owners[shift.id] = _targetId!;

    final selected = {..._data.selectedIds};

    selected.putIfAbsent(_targetId!, () => shift.id);

    return _commit(shifts: next, shiftOwners: owners, selectedIds: selected);
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

    final selected = {..._data.selectedIds};

    if (selected[_targetId] == id) {
      selected.remove(_targetId);
    }

    final owners = {..._data.shiftOwners}..remove(id);

    return _commit(
      shifts: _data.shifts.where((shift) => shift.id != id).toList(),
      shiftOwners: owners,
      selectedIds: selected,
    );
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

    return _commit(gps: config);
  }

  Future<String?> checkIn(DateTime now) async {
    final error = _unavailable;

    if (error != null) return error;

    if (!isOwnSession) {
      return 'Không thể chấm công thay nhân viên.';
    }

    final shift = selectedShift;

    if (shift == null) {
      return 'Hãy chọn ca được giao trong Lịch làm.';
    }

    if (selectedRecord != null) {
      return 'Ca này đã có lượt chấm công.';
    }

    if (activeRecord != null) {
      return 'Bạn còn một ca chưa CHECK OUT.';
    }

    final validDay =
        sameAttendanceDay(now, shift.start) ||
        (shift.isOvernight && sameAttendanceDay(now, shift.end));

    if (!validDay) {
      return 'Hãy chọn ca có ngày làm '
          'phù hợp với hôm nay.';
    }

    final faceError = _consumeFaceVerification(checkingIn: true);

    if (faceError != null) return faceError;

    return _commit(
      records: [
        AttendanceRecord(shiftSnapshot: shift.snapshot(), checkIn: now),
        ..._data.records,
      ],
      recordOwners: {..._data.recordOwners, shift.id: _targetId!},
    );
  }

  Future<String?> checkOut(DateTime now) async {
    final error = _unavailable;

    if (error != null) return error;

    if (!isOwnSession) {
      return 'Không thể chấm công thay nhân viên.';
    }

    final record = selectedRecord;

    if (record == null) {
      return 'Bạn chưa CHECK IN ca này.';
    }

    if (record.checkOut != null) {
      return 'Ca này đã hoàn thành.';
    }

    if (now.isBefore(record.checkIn)) {
      return 'Giờ thiết bị đang trước giờ CHECK IN. '
          'Hãy kiểm tra lại.';
    }

    final faceError = _consumeFaceVerification(checkingIn: false);

    if (faceError != null) return faceError;

    final next = [..._data.records];

    final index = next.indexWhere((item) => item.shiftId == record.shiftId);

    next[index] = record.finish(now);

    return _commit(records: next);
  }

  Future<String?> deleteRecord(String shiftId) async {
    final error = _unavailable;

    if (error != null) return error;

    if (!isAdmin) {
      return 'Chỉ Admin được xóa lịch sử.';
    }

    final record = recordFor(shiftId);

    if (record == null) {
      return 'Không tìm thấy lượt chấm công.';
    }

    if (record.checkOut == null) {
      return 'Hãy CHECK OUT ca đang làm '
          'trước khi xóa lịch sử.';
    }

    final owners = {..._data.recordOwners}..remove(shiftId);

    return _commit(
      records: _data.records.where((item) => item.shiftId != shiftId).toList(),
      recordOwners: owners,
    );
  }
}

class _FacePermit {
  final String userId;
  final String shiftId;
  final bool checkingIn;

  final Stopwatch watch = Stopwatch()..start();

  _FacePermit(this.userId, this.shiftId, this.checkingIn);
}
