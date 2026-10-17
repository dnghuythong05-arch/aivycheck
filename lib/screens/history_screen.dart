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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Chưa có dữ liệu chấm công',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: records.length,
                          separatorBuilder: (_, index) {
                            return const SizedBox(height: 12);
                          },
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
