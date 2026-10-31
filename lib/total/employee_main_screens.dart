import 'dart:async';

import 'package:flutter/material.dart';

import '../face/face_registration_dialog.dart';
import '../gps/gps_service.dart';
import '../gps/gps_settings_screen.dart';
import '../gps/gps_status_bar.dart';
import '../models/attendance_record.dart';
import '../models/attendance_session.dart';
import '../models/curved_bottom_nav.dart';
import '../services/api_client.dart';
import '../screens/attendance_screen.dart';
import '../screens/employee_screen.dart';
import '../screens/history_screen.dart';
import '../screens/manage_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/salary_screen.dart';
import '../screens/schedule_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'login_screens.dart';

class EmployeeMainScreen extends StatefulWidget {
  final AttendanceSession? session;

  const EmployeeMainScreen({super.key, this.session});

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen>
    with WidgetsBindingObserver {
  late final AttendanceSession session;

  Timer? refreshTimer;

  int currentIndex = 0;
  DateTime now = DateTime.now();

  bool loading = true;
  bool gpsBusy = false;
  bool attendanceBusy = false;
  bool historyBusy = false;
  bool logoutBusy = false;
  bool redirecting = false;
  bool refreshingAuth = false;
  bool directoryBusy = false;

  String? loadError;

  String gpsTitle = 'Vị trí chấm công';
  String gpsMessage = 'Chưa kiểm tra vị trí.';
  String? gpsDetails;

  GpsNoticeType gpsNoticeType = GpsNoticeType.info;

  bool get canViewSalary =>
      !session.isAdmin &&
      session.isOwnSession &&
      session.currentUser?.id == 'employee_huythong';

  int get profileIndex => session.isAdmin || canViewSalary ? 4 : 3;

  bool get blocked =>
      attendanceBusy ||
      historyBusy ||
      logoutBusy ||
      directoryBusy ||
      refreshingAuth;

  @override
  void initState() {
    super.initState();

    session = widget.session ?? AttendanceSession();

    WidgetsBinding.instance.addObserver(this);
    session.auth.addListener(authChanged);

    refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      session.auth.checkExpiry();

      if (mounted && !redirecting) {
        setState(() => now = DateTime.now());
      }
    });

    loadSession();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();

    session.auth.removeListener(authChanged);
    session.auth.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      session.auth.checkExpiry();

      if (!redirecting) {
        unawaited(refreshAuthentication());
      }
    }
  }

  Future<void> refreshAuthentication() async {
    if (refreshingAuth || loading || blocked || gpsBusy) {
      return;
    }

    setState(() => refreshingAuth = true);

    try {
      await session.refreshUser();

      final gpsError = await session.loadGpsConfig();

      if (gpsError != null) {
        throw ApiException(gpsError);
      }

      final error = await session.loadShifts();

      if (error != null) {
        throw ApiException(error);
      }

      if (mounted && !redirecting) {
        setState(() {});
      }
    } on ApiException catch (error) {
      if (mounted && !redirecting) {
        feedback(error.message);
      }
    } finally {
      if (mounted && !redirecting) {
        setState(() => refreshingAuth = false);
      } else {
        refreshingAuth = false;
      }
    }
  }

  void authChanged() {
    if (!mounted || redirecting) return;

    if (session.currentUser == null) {
      openLogin();
    } else {
      AppHeader.setAdminVisible(session.isAdmin);
      setState(() {});
    }
  }

  void openLogin() {
    if (!mounted || redirecting) return;

    redirecting = true;
    AppHeader.setAdminVisible(false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> loadSession() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      await session.load();
      await session.refreshUser();

      if (session.isAdmin) {
        final error = await session.loadEmployees();

        if (error != null) {
          throw ApiException(error);
        }

        final migrationError = await session.migrateLocalShifts();

        if (migrationError != null) {
          throw ApiException(migrationError);
        }

        final setupError = await session.migrateLocalSetup();

        if (setupError != null) {
          throw ApiException(setupError);
        }
      }

      final gpsError = await session.loadGpsConfig();

      if (gpsError != null) {
        throw ApiException(gpsError);
      }

      final shiftError = await session.loadShifts();

      if (shiftError != null) {
        throw ApiException(shiftError);
      }

      if (!mounted || redirecting) return;

      AppHeader.setAdminVisible(session.isAdmin);
      setState(() => loading = false);
    } catch (error) {
      if (!mounted || redirecting) return;

      if (session.currentUser == null) {
        openLogin();
        return;
      }

      setState(() {
        loading = false;
        loadError = error is ApiException
            ? error.message
            : 'Chưa đọc được dữ liệu. Hãy thử lại.';
      });
    }
  }

  void feedback(String message, {bool success = false}) {
    if (!mounted) return;

    final colors = AiVieTheme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: success ? colors.success : colors.error,
            ),
          ),
          backgroundColor: colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
        ),
      );
  }

  Future<void> changeTab(int index) async {
    if (blocked || index < 0 || index > profileIndex) {
      return;
    }

    if (session.isAdmin && index == 3 && currentIndex != 3) {
      if (!await refreshEmployees()) return;
    }

    if ((index == 0 || index == 1 || index == 2) && currentIndex != index) {
      setState(() => directoryBusy = true);

      final error = await session.loadShifts();

      if (!mounted || redirecting) return;

      setState(() => directoryBusy = false);

      if (error != null) {
        feedback(error);
        return;
      }
    }

    if (!mounted || redirecting) return;

    final enteringAttendance = index == 1 && currentIndex != 1;

    setState(() {
      currentIndex = index;
      now = DateTime.now();
    });

    if (enteringAttendance) {
      unawaited(verifyGps());
    }
  }

  Future<bool> refreshEmployees() async {
    if (blocked || !session.isAdmin || !mounted) {
      return false;
    }

    setState(() => directoryBusy = true);

    try {
      final error = await session.loadEmployees();

      if (!mounted || redirecting) return false;

      if (error != null) {
        feedback(error);
        return false;
      }

      setState(() {});

      return true;
    } finally {
      if (mounted && !redirecting) {
        setState(() => directoryBusy = false);
      }
    }
  }

  Future<void> openSchedule() async {
    if (blocked) return;

    final target = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ScheduleScreen(session: session)),
    );

    if (!mounted) return;

    setState(() {
      now = DateTime.now();

      if (target != null && target >= 0 && target <= profileIndex) {
        currentIndex = target;
      }
    });

    if (currentIndex == 1) {
      unawaited(verifyGps());
    }
  }

  void openSalary() {
    if (!canViewSalary) return;
    changeTab(3);
  }

  Future<void> refreshHistory() async {
    if (blocked || gpsBusy) return;

    setState(() => historyBusy = true);

    try {
      final error = await session.loadShifts();

      if (!mounted || redirecting) return;

      setState(() => now = DateTime.now());

      if (error != null) feedback(error);
    } finally {
      if (mounted && !redirecting) {
        setState(() => historyBusy = false);
      }
    }
  }

  void openEmployees() {
    if (!session.isAdmin) return;
    changeTab(3);
  }

  Future<void> clearPlace() async {
    if (blocked ||
        gpsBusy ||
        !session.isAdmin ||
        !session.gpsConfig.hasCenter) {
      return;
    }

    setState(() => gpsBusy = true);

    try {
      final error = await session.clearGpsConfig();

      if (!mounted) return;

      if (error != null) {
        feedback(error);
        return;
      }

      setState(() {
        gpsTitle = 'Chưa có địa điểm chấm công';
        gpsMessage = 'Hãy mở Địa điểm chấm công để thiết lập lại.';
        gpsDetails = null;
        gpsNoticeType = GpsNoticeType.info;
      });

      feedback('Đã xóa địa điểm chấm công.', success: true);
    } catch (_) {
      if (mounted) {
        feedback('Chưa xóa được địa điểm. Hãy thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => gpsBusy = false);
      }
    }
  }

  Future<void> openGpsSettings() async {
    if (blocked || gpsBusy || !session.isAdmin) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GpsSettingsScreen(session: session)),
    );

    if (!mounted) return;

    if (currentIndex == 1) {
      unawaited(verifyGps());
    }
  }

  Future<void> openFaceRegistration() async {
    if (blocked || gpsBusy || !session.isAdmin) return;

    if (!await refreshEmployees()) return;

    if (!mounted || redirecting) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FaceRegistrationDialog(session: session),
    );

    if (!mounted) return;

    setState(() => now = DateTime.now());
  }

  Future<GpsCheckResult?> verifyGps({bool refreshConfig = true}) async {
    if (gpsBusy || !mounted) return null;

    setState(() {
      gpsBusy = true;
      gpsTitle = 'Đang kiểm tra vị trí…';
      gpsMessage = 'Vui lòng chờ một chút.';
      gpsDetails = null;
      gpsNoticeType = GpsNoticeType.info;
    });

    try {
      final gpsError = refreshConfig ? await session.loadGpsConfig() : null;

      if (gpsError != null) {
        throw GpsException(
          gpsError,
          title: 'Chưa tải được địa điểm',
          kind: GpsFailure.unavailable,
          noticeType: GpsNoticeType.error,
        );
      }

      final result = await GpsService.check(session.gpsConfig);

      if (!mounted) return null;

      setState(() {
        gpsTitle = 'Trong khu vực chấm công';
        gpsMessage = 'Bạn có thể CHECK IN/OUT.';
        gpsDetails = result.details;
        gpsNoticeType = GpsNoticeType.success;
      });

      return result;
    } on GpsException catch (error) {
      if (!mounted) return null;

      setState(() {
        gpsTitle = error.title;

        gpsMessage = error.kind == GpsFailure.notConfigured && session.isAdmin
            ? 'Hãy mở Địa điểm chấm công để thiết lập.'
            : error.message;

        gpsDetails = error.details;
        gpsNoticeType = error.noticeType;
      });

      return null;
    } catch (_) {
      if (!mounted) return null;

      setState(() {
        gpsTitle = 'Chưa xác định rõ vị trí';
        gpsMessage = 'Hãy thử cập nhật vị trí.';
        gpsDetails = null;
        gpsNoticeType = GpsNoticeType.warning;
      });

      return null;
    } finally {
      if (mounted) {
        setState(() => gpsBusy = false);
      }
    }
  }

  Future<void> handleAttendance() async {
    if (blocked || gpsBusy) return;

    setState(() => attendanceBusy = true);

    try {
      final requestedShiftId = session.selectedShiftId;
      final requestedCheckingIn = session.selectedRecord == null;

      final refreshError = await session.loadShifts();

      if (!mounted) return;

      if (refreshError != null) {
        feedback(refreshError);
        return;
      }

      if (requestedShiftId != session.selectedShiftId ||
          requestedCheckingIn != (session.selectedRecord == null)) {
        setState(() {});

        feedback(
          'Trạng thái ca đã thay đổi. '
          'Hãy kiểm tra rồi bấm lại.',
        );

        return;
      }

      final gpsError = await session.loadGpsConfig();

      if (!mounted) return;

      if (gpsError != null) {
        feedback(gpsError);
        return;
      }

      if (!session.gpsConfig.hasCenter) {
        await verifyGps(refreshConfig: false);

        if (mounted) {
          feedback(
            'Admin cần thiết lập và lưu địa điểm '
            'chấm công trước.',
          );
        }

        return;
      }

      if (session.selectedShift == null) {
        feedback('Hãy chọn ca được giao trong Lịch làm.');
        return;
      }

      if (session.selectedRecord?.checkOut != null) {
        feedback('Ca này đã hoàn thành.');
        return;
      }

      final faceError = await session.verifyOwnFace();

      if (!mounted) return;

      if (faceError != null) {
        feedback(faceError);
        return;
      }

      final result = await verifyGps(refreshConfig: false);

      if (!mounted || result == null) return;

      final time = DateTime.now();
      final checkingIn = session.selectedRecord == null;

      final error = checkingIn
          ? await session.checkIn(time, gps: result)
          : await session.checkOut(time, gps: result);

      if (!mounted) return;

      setState(() => now = time);

      if (error != null) {
        feedback(error);
        return;
      }

      final record = session.selectedRecord!;

      feedback(
        checkingIn
            ? 'CHECK IN thành công · '
                  '${record.isLate ? 'Đi trễ ${record.lateAmountText}' : 'Đúng giờ'}'
            : 'CHECK OUT thành công · '
                  '${record.workTimeText(time)}',
        success: true,
      );
    } catch (_) {
      if (mounted) {
        feedback('Chưa ghi nhận được chấm công. Hãy thử lại.');
      }
    } finally {
      session.clearFaceVerification();

      if (mounted) {
        setState(() => attendanceBusy = false);
      }
    }
  }

  Future<void> deleteHistoryRecord(AttendanceRecord record) async {
    if (blocked || !session.isAdmin) return;

    setState(() => historyBusy = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa lượt chấm công?'),
          content: Text(
            'Ca: ${record.shiftSnapshot.name}\n'
            'Ca trong Lịch làm vẫn được giữ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (!mounted || confirmed != true) return;

      final error = await session.deleteRecord(record.shiftId);

      if (!mounted) return;

      setState(() {});

      feedback(error ?? 'Đã xóa lượt chấm công.', success: error == null);
    } finally {
      if (mounted) {
        setState(() => historyBusy = false);
      }
    }
  }

  Future<void> logout() async {
    if (blocked) return;

    setState(() => logoutBusy = true);

    try {
      final error = await session.signOut();

      if (!mounted || redirecting) return;

      if (error != null) {
        feedback(error);
        return;
      }

      openLogin();
    } finally {
      if (mounted && !redirecting) {
        setState(() => logoutBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loadSession,
                child: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: logoutBusy ? null : logout,
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      );
    }

    final user = session.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    final record = session.selectedRecord;
    final shift = record?.shiftSnapshot ?? session.selectedShift;

    final screens = <Widget>[
      EmployeeHomeScreen(
        fullName: user.fullName,
        shift: shift,
        record: record,
        now: now,
        isAdmin: session.isAdmin,
        showSalary: canViewSalary,
        onOpenAttendance: () => changeTab(1),
        onOpenSchedule: openSchedule,
        onOpenSalary: openSalary,
        onOpenEmployees: openEmployees,
        onOpenProfile: () => changeTab(profileIndex),
      ),
      AttendanceScreen(
        shift: shift,
        record: record,
        now: now,
        busy: attendanceBusy || gpsBusy,
        onAttendance: handleAttendance,
        onOpenSchedule: openSchedule,
        onBackHome: () => changeTab(0),
        onRegisterFace: session.isAdmin ? openFaceRegistration : null,
      ),
      HistoryScreen(
        records: session.records,
        now: now,
        busy: historyBusy,
        onRefresh: refreshHistory,
        error: session.historyError,
        onBackHome: () => changeTab(0),
        onDeleteRecord: session.isAdmin ? deleteHistoryRecord : null,
      ),
      if (session.isAdmin)
        EmployeesScreen(session: session, onBackHome: () => changeTab(0)),
      if (canViewSalary)
        SalaryScreen(
          employeeName: user.fullName,
          onBackHome: () => changeTab(0),
        ),
      ProfileScreen(
        user: user,
        onBackHome: () => changeTab(0),
        onLogout: logout,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AbsorbPointer(
        absorbing: blocked,
        child: IndexedStack(index: currentIndex, children: screens),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentIndex == 1)
            Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AiVieTheme.contentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                  child: GpsStatusBar(
                    draggable: true,
                    config: session.gpsConfig,
                    title: gpsTitle,
                    message: gpsMessage,
                    details: gpsDetails,
                    noticeType: gpsNoticeType,
                    busy: gpsBusy || blocked,
                    onRetry: blocked ? null : () => verifyGps(),
                    onOpenSettings: session.isAdmin ? openGpsSettings : null,
                    onClearPlace: session.isAdmin ? clearPlace : null,
                  ),
                ),
              ),
            ),
          CurvedBottomNav(
            isAdmin: session.isAdmin,
            showSalary: canViewSalary,
            selectedIndex: currentIndex,
            onDestinationSelected: changeTab,
          ),
        ],
      ),
    );
  }
}
