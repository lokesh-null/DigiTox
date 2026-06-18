import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

class HabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;

  const HabitItem({
    super.key,
    required this.habit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: habit.completedToday ? AppTheme.success : Colors.transparent,
                border: Border.all(
                  color: habit.completedToday ? AppTheme.success : AppTheme.textTertiary,
                  width: 2,
                ),
                shape: BoxShape.circle,
                boxShadow: habit.completedToday ? [BoxShadow(color: AppTheme.successGlow, blurRadius: 8)] : [],
              ),
              child: habit.completedToday 
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    decoration: habit.completedToday ? TextDecoration.lineThrough : null,
                    color: habit.completedToday ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🔥 ${habit.streak} day streak',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          Text(habit.emoji, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
