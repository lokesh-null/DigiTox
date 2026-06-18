import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge widget displaying the user's Focus Identity level,
/// XP progress bar, and streak count.
class IdentityBadge extends StatelessWidget {
  final int level;
  final String title;
  final String emoji;
  final int totalXP;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final double progressPercent;
  final int streak;
  final bool compact;

  const IdentityBadge({
    super.key,
    required this.level,
    required this.title,
    required this.emoji,
    required this.totalXP,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    required this.progressPercent,
    required this.streak,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _levelColor().withValues(alpha: 0.15),
            _levelColor().withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _levelColor().withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          // Badge icon and title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _levelColor().withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _levelColor().withValues(alpha: 0.5)),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(color: _levelColor(), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // XP count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalXP XP',
                    style: TextStyle(color: _levelColor(), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (streak > 0)
                    Text(
                      '🔥 $streak day streak',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$xpForCurrentLevel / $xpForNextLevel XP',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: _levelColor(), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_levelColor(), _levelColor().withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _levelColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lv.$level $title', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$totalXP XP', style: TextStyle(fontSize: 10, color: _levelColor())),
          ],
        ),
      ],
    );
  }

  Color _levelColor() {
    if (level <= 2) return const Color(0xFF55EFC4);
    if (level <= 4) return const Color(0xFF00CEC9);
    if (level <= 6) return AppTheme.primary;
    if (level <= 8) return const Color(0xFFFDCB6E);
    return const Color(0xFFFF6B6B);
  }
}
