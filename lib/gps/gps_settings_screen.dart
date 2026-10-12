import 'package:flutter/material.dart';

import '../models/attendance_session.dart';
import 'gps_config.dart';
import 'gps_service.dart';
import 'gps_status_bar.dart';

class GpsSettingsScreen extends StatefulWidget {
  final AttendanceSession session;

  const GpsSettingsScreen({super.key, required this.session});

  @override
  State<GpsSettingsScreen> createState() => _GpsSettingsScreenState();
}

class _GpsSettingsScreenState extends State<GpsSettingsScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController radiusController;

  bool busy = false;

  String title = 'Chưa có địa điểm chấm công';
  String message = 'Nhập phạm vi rồi bấm “Lấy vị trí và lưu địa điểm”.';
  String? details;

  GpsNoticeType noticeType = GpsNoticeType.info;

  @override
  void initState() {
    super.initState();

    final config = widget.session.gpsConfig;

    radiusController = TextEditingController(
      text: gpsMetersText(config.radiusMeters),
    );

    if (config.hasCenter) {
      title = 'Đã lưu địa điểm';
      message = 'Có thể kiểm tra vị trí hoặc cập nhật phạm vi.';
      details = coordinates(config);
    }
  }

  String coordinates(GpsConfig config) =>
      'Tọa độ đã lưu: '
      '${config.latitude!.toStringAsFixed(6)}, '
      '${config.longitude!.toStringAsFixed(6)}';

  double? get enteredRadius =>
      double.tryParse(radiusController.text.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    radiusController.dispose();
    super.dispose();
  }

  void showNotice(
    String newTitle,
    String newMessage, {
    GpsNoticeType type = GpsNoticeType.info,
    String? newDetails,
  }) {
    if (!mounted) return;

    setState(() {
      title = newTitle;
      message = newMessage;
      noticeType = type;
      details = newDetails;
    });
  }

  Future<void> runTask(Future<void> Function() task) async {
    if (busy || !widget.session.isAdmin) return;

    setState(() {
      busy = true;
      title = 'Đang xử lý';
      message = 'Vui lòng chờ một chút.';
      noticeType = GpsNoticeType.info;
      details = null;
    });

    try {
      await task();
    } on GpsException catch (error) {
      showNotice(
        error.title,
        error.message,
        type: error.noticeType,
        newDetails: error.details,
      );
    } catch (error, stack) {
      debugPrint('Lỗi thiết lập địa điểm: $error\n$stack');

      showNotice(
        'Chưa thực hiện được',
        'Hãy thử lại.',
        type: GpsNoticeType.error,
      );
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> persist(GpsConfig config) async {
    final error = await widget.session.saveGpsConfig(config);

    if (error != null) {
      throw GpsException(
        error,
        title: 'Chưa lưu được địa điểm',
        noticeType: GpsNoticeType.error,
      );
    }
  }

  Future<void> chooseAndSavePlace() async {
    if (busy || !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final radius = enteredRadius!;

    await runTask(() async {
      final position = await GpsService.getPosition();

      if (!mounted) return;

      final config = GpsConfig(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: radius,
      );

      // Chỉ thông báo thành công sau khi session lưu xong.
      await persist(config);

      if (!mounted) return;

      showNotice(
        'Đã lưu địa điểm chấm công',
        'Địa điểm đã được lưu. '
            'Bấm “Kiểm tra vị trí của tôi” để thử.',
        type: GpsNoticeType.success,
        newDetails:
            '${coordinates(config)}\n'
            'Độ chính xác lúc thiết lập: khoảng '
            '${gpsMetersText(position.accuracy)} m.\n'
            'Phạm vi đã lưu: '
            '${gpsMetersText(config.radiusMeters)} m.',
      );
    });
  }

  Future<void> saveRadius() async {
    if (busy || !(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final saved = widget.session.gpsConfig;

    if (!saved.hasCenter) {
      showNotice(
        'Chưa có địa điểm',
        'Bấm “Lấy vị trí và lưu địa điểm” trước.',
        type: GpsNoticeType.warning,
      );
      return;
    }

    final config = GpsConfig(
      latitude: saved.latitude,
      longitude: saved.longitude,
      radiusMeters: enteredRadius!,
    );

    await runTask(() async {
      await persist(config);

      showNotice(
        'Đã lưu phạm vi',
        'Phạm vi chấm công: '
            '${gpsMetersText(config.radiusMeters)} m.',
        type: GpsNoticeType.success,
        newDetails: coordinates(config),
      );
    });
  }

  Future<void> checkMyPosition() async {
    await runTask(() async {
      final result = await GpsService.check(widget.session.gpsConfig);

      showNotice(
        'Trong khu vực chấm công',
        result.message,
        type: GpsNoticeType.success,
        newDetails: result.details,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.session.gpsConfig;
    final canEdit = widget.session.isAdmin;

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Địa điểm chấm công')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Thiết lập địa điểm',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đứng tại nơi làm việc khi lấy vị trí. '
                    'Lấy lại vị trí sẽ thay thế địa điểm đã lưu.',
                    style: TextStyle(color: Color(0xFF6B7280), height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    config.hasCenter
                        ? coordinates(config)
                        : 'Chưa có tọa độ được lưu.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: radiusController,
                    enabled: canEdit && !busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Phạm vi chấm công (mét)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (_) {
                      final value = enteredRadius;

                      if (value == null ||
                          !value.isFinite ||
                          value < 1 ||
                          value > 5000) {
                        return 'Nhập phạm vi từ 1 đến 5.000 mét.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: canEdit && !busy ? chooseAndSavePlace : null,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Lấy vị trí và lưu địa điểm'),
                    style: FilledButton.styleFrom(
                      shape: buttonShape,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: canEdit && !busy && config.hasCenter
                        ? saveRadius
                        : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu thay đổi phạm vi'),
                    style: OutlinedButton.styleFrom(
                      shape: buttonShape,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: canEdit && !busy && config.hasCenter
                        ? checkMyPosition
                        : null,
                    icon: const Icon(Icons.location_searching_rounded),
                    label: const Text('Kiểm tra vị trí của tôi'),
                    style: OutlinedButton.styleFrom(
                      shape: buttonShape,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chỉ chấp nhận sai số tối đa '
                    '${gpsMetersText(GpsService.maxAccuracyMeters)} m. '
                    'Khi chấm công, khoảng cách cộng sai số '
                    'phải nằm trong phạm vi.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                  if (!canEdit) ...[
                    const SizedBox(height: 12),
                    const Text('Chỉ Admin được thay đổi thiết lập GPS.'),
                  ],
                  const SizedBox(height: 20),
                  GpsStatusBar(
                    config: config,
                    title: title,
                    message: message,
                    details: null,
                    noticeType: noticeType,
                    busy: busy,
                    showActions: false,
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      details!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
