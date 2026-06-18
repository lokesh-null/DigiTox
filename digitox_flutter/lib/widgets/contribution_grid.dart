import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ContributionGrid extends StatelessWidget {
  final List<int> data;

  const ContributionGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 28,
            itemBuilder: (context, index) {
              int level = data[index];
              return Container(
                decoration: BoxDecoration(
                  color: _getColorForLevel(level),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Less', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
            Row(
              children: [
                _buildLegendItem(0),
                const SizedBox(width: 3),
                _buildLegendItem(1),
                const SizedBox(width: 3),
                _buildLegendItem(2),
                const SizedBox(width: 3),
                _buildLegendItem(3),
                const SizedBox(width: 3),
                _buildLegendItem(4),
              ],
            ),
            const Text('More', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(int level) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getColorForLevel(level),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0: return AppTheme.surfaceActive;
      case 1: return const Color(0x3300B894); // 0.2
      case 2: return const Color(0x6600B894); // 0.4
      case 3: return const Color(0x9900B894); // 0.6
      case 4: return const Color(0xCC00B894); // 0.8
      default: return AppTheme.surfaceActive;
    }
  }
}
