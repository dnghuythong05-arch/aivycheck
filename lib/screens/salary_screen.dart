import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/salary_period_card.dart';

class SalaryScreen extends StatelessWidget {
  final String employeeName;
  final VoidCallback? onBackHome;

  const SalaryScreen({super.key, required this.employeeName, this.onBackHome});

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppHeader(
        title: 'Bảng lương',
        subtitle: 'Thông tin lương của bạn',
        onBack: onBackHome,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AiVieTheme.contentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmployeeInformation(name: employeeName),
                  const SizedBox(height: 24),
                  const SalaryPeriodCard(
                    period: '01/09/2026 – 30/09/2026',
                    hourlyRate: 27000,
                    totalHours: 200,
                    totalShifts: 26,
                  ),
                  const SizedBox(height: 20),
                  const SalaryPeriodCard(
                    period: '01/08/2026 – 31/08/2026',
                    hourlyRate: 27000,
                    totalHours: 150,
                    totalShifts: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeInformation extends StatelessWidget {
  final String name;

  const _EmployeeInformation({required this.name});

  String get displayName => name.trim().isEmpty ? 'Nhân viên' : name.trim();

  String get avatarLetter =>
      displayName.split(RegExp(r'\s+')).last.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colors.primarySoft,
          child: Text(
            avatarLetter,
            style: typography.titleLarge?.copyWith(color: colors.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: typography.titleLarge),
              const SizedBox(height: 4),
              Text('Nhân viên', style: AiVieTheme.secondary(context)),
            ],
          ),
        ),
      ],
    );
  }
}
