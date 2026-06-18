import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatCardType { productive, addictive, streak, score }

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final StatCardType type;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.type,
  });

  Color getValueColor() {
    switch (type) {
      case StatCardType.productive: return AppTheme.secondary;
      case StatCardType.addictive: return AppTheme.danger;
      case StatCardType.streak: return AppTheme.warning;
      case StatCardType.score: return AppTheme.primaryLight;
    }
  }

  LinearGradient getTopBarGradient() {
    switch (type) {
      case StatCardType.productive: return AppTheme.gradientSecondary;
      case StatCardType.addictive: return AppTheme.gradientDanger;
      case StatCardType.streak: return AppTheme.gradientWarm;
      case StatCardType.score: return AppTheme.gradientPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: getTopBarGradient(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: getValueColor(),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
