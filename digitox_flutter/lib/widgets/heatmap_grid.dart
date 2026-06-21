import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/data_provider.dart';

class HeatmapGrid extends StatelessWidget {
  final List<HeatmapEntry> data;
  final String filter;

  const HeatmapGrid({super.key, required this.data, this.filter = 'All'});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('12AM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('4AM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('8AM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('12PM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('4PM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('8PM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text('12AM', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: data.map((d) {
            return Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: _getColorForLevel(d.level),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Low', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
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
            const Text('High', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(int level) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getColorForLevel(level),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColorForLevel(int level) {
    if (level == 0) return AppTheme.surfaceActive;
    
    if (filter == 'Distraction') {
      switch (level) {
        case 1: return const Color(0x33FF6B6B);
        case 2: return const Color(0x66FF6B6B);
        case 3: return const Color(0x99FF6B6B);
        case 4: return const Color(0xFFFF6B6B);
      }
    } else if (filter == 'Focus') {
      switch (level) {
        case 1: return const Color(0x3300B894);
        case 2: return const Color(0x6600B894);
        case 3: return const Color(0x9900B894);
        case 4: return const Color(0xFF00B894);
      }
    } else {
      switch (level) {
        case 1: return const Color(0x336C5CE7);
        case 2: return const Color(0x666C5CE7);
        case 3: return const Color(0x996C5CE7);
        case 4: return const Color(0xFF6C5CE7);
      }
    }
    return AppTheme.surfaceActive;
  }
}
