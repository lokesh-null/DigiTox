import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimeSplitBar extends StatelessWidget {
  final double productivePercent;
  final double neutralPercent;
  final double addictivePercent;

  const TimeSplitBar({
    super.key,
    required this.productivePercent,
    required this.neutralPercent,
    required this.addictivePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppTheme.surfaceActive,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                if (productivePercent > 0)
                  Expanded(
                    flex: (productivePercent * 100).toInt(),
                    child: Container(color: AppTheme.secondary),
                  ),
                if (neutralPercent > 0)
                  Expanded(
                    flex: (neutralPercent * 100).toInt(),
                    child: Container(color: AppTheme.warning.withOpacity(0.7)),
                  ),
                if (addictivePercent > 0)
                  Expanded(
                    flex: (addictivePercent * 100).toInt(),
                    child: Container(color: AppTheme.danger),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _LegendItem(color: AppTheme.secondary, label: 'Productive ${productivePercent.toStringAsFixed(0)}%'),
            _LegendItem(color: AppTheme.warning.withOpacity(0.7), label: 'Neutral ${neutralPercent.toStringAsFixed(0)}%'),
            _LegendItem(color: AppTheme.danger, label: 'Addictive ${addictivePercent.toStringAsFixed(0)}%'),
          ],
        )
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
