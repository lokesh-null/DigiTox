import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/app_classifier.dart';

class AppUsageItem extends StatelessWidget {
  final String appName;
  final String emoji;
  final String category;
  final Color color;
  final int minutes;
  final int maxMinutes;
  final String formattedTime;

  const AppUsageItem({
    super.key,
    required this.appName,
    required this.emoji,
    required this.category,
    required this.color,
    required this.minutes,
    required this.maxMinutes,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    double percent = maxMinutes > 0 ? minutes / maxMinutes : 0;
    Color barColor;
    if (AppClassifier.isAddictive(category)) {
      barColor = AppTheme.danger;
    } else if (AppClassifier.isProductive(category)) {
      barColor = AppTheme.secondary;
    } else {
      barColor = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Text(
            formattedTime,
            style: TextStyle(
              color: barColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
