import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/attendance_history_item.dart';

class HistoryScreen extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime now;
  final VoidCallback onBackHome;
  final Future<void> Function(AttendanceRecord)? onDeleteRecord;
  final bool busy;
  final String title;
  final String subtitle;
  final Widget? leadingContent;
  final VoidCallback? onRefresh;
  final String? error;

  const HistoryScreen({
    super.key,
    required this.records,
    required this.now,
    required this.onBackHome,
    this.onDeleteRecord,
    this.busy = false,
    this.title = 'Lịch sử chấm công',
    this.subtitle = 'Các lượt chấm công của bạn',
    this.leadingContent,
    this.onRefresh,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppHeader(title: title, subtitle: subtitle, onBack: onBackHome),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AiVieTheme.contentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leadingContent != null) leadingContent!,
                if (onRefresh != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: TextButton.icon(
                        onPressed: busy ? null : onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tải lại lịch sử'),
                      ),
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(error!, style: TextStyle(color: colors.error)),
                  ),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              error != null
                                  ? 'Chưa tải được lịch sử. Hãy thử lại.'
                                  : 'Chưa có dữ liệu chấm công',
                              textAlign: TextAlign.center,
                              style: AiVieTheme.secondary(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: records.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final record = records[index];

                            final canDelete =
                                !busy &&
                                onDeleteRecord != null &&
                                record.checkOut != null;

                            return AttendanceHistoryItem(
                              record: record,
                              now: now,
                              onDelete: canDelete
                                  ? () => onDeleteRecord!(record)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
