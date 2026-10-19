import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SalaryPeriodCard extends StatelessWidget {
  final String period;
  final int hourlyRate;
  final int totalHours;
  final int totalShifts;

  const SalaryPeriodCard({
    super.key,
    required this.period,
    required this.hourlyRate,
    required this.totalHours,
    required this.totalShifts,
  });

  int get salary => hourlyRate * totalHours;

  String formatMoney(int value) {
    final text = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _SalaryRow(label: 'Kỳ lương', value: period, highlighted: true),
                const Divider(height: 1),
                _SalaryRow(
                  label: 'Mức lương',
                  value: '${formatMoney(hourlyRate)}/giờ',
                ),
                const Divider(height: 1),
                _SalaryRow(
                  label: 'Tổng số giờ',
                  value: '$totalHours giờ',
                  highlighted: true,
                ),
                const Divider(height: 1),
                _SalaryRow(label: 'Tổng số ca', value: '$totalShifts ca'),
                const Divider(height: 1),
                _SalaryRow(
                  label: 'Lương theo giờ làm việc',
                  value: formatMoney(salary),
                  highlighted: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: _SalaryTotal(amount: formatMoney(salary)),
          ),
        ],
      ),
    );
  }
}

class _SalaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _SalaryRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AiVieTheme.of(context);
    final typography = Theme.of(context).textTheme;
    final valueStyle = typography.bodyLarge?.copyWith(
      color: highlighted ? colors.primary : colors.text,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: typography.bodyLarge),
                const SizedBox(height: 6),
                Text(value, style: valueStyle),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: Text(label, style: typography.bodyLarge)),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: valueStyle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SalaryTotal extends StatelessWidget {
  final String amount;

  const _SalaryTotal({required this.amount});

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final colors = AiVieTheme.of(context);
    final amountStyle = typography.headlineSmall?.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w700,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thực nhận', style: typography.titleMedium),
              const SizedBox(height: 8),
              Text(amount, style: amountStyle),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: Text('Thực nhận', style: typography.titleMedium)),
            const SizedBox(width: 24),
            Flexible(
              child: Text(
                amount,
                textAlign: TextAlign.right,
                style: amountStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}
