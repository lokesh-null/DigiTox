import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular gauge widget for the Dopamine Debt Score.
/// Renders a semi-circular arc with gradient coloring based on severity.
class DopamineGauge extends StatelessWidget {
  final int score;
  final String severity;
  final String label;

  const DopamineGauge({
    super.key,
    required this.score,
    required this.severity,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc painter
          CustomPaint(
            size: const Size(200, 120),
            painter: _GaugePainter(
              score: score,
              severity: severity,
            ),
          ),
          // Score text in center
          Positioned(
            bottom: 20,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => _gradientForSeverity(severity).createShader(bounds),
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: _colorForSeverity(severity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _colorForSeverity(severity),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForSeverity(String severity) {
    switch (severity) {
      case 'low': return AppTheme.secondary;
      case 'moderate': return AppTheme.warning;
      case 'high': return const Color(0xFFFF8C00);
      case 'critical': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  static LinearGradient _gradientForSeverity(String severity) {
    switch (severity) {
      case 'low':
        return const LinearGradient(colors: [Color(0xFF00CEC9), Color(0xFF55EFC4)]);
      case 'moderate':
        return const LinearGradient(colors: [Color(0xFFFDCB6E), Color(0xFFE17055)]);
      case 'high':
        return const LinearGradient(colors: [Color(0xFFE17055), Color(0xFFFF6B6B)]);
      case 'critical':
        return const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFD63031)]);
      default:
        return const LinearGradient(colors: [Color(0xFF636E72), Color(0xFFB2BEC3)]);
    }
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final String severity;

  _GaugePainter({required this.score, required this.severity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Score arc
    final sweepAngle = (score / 100) * pi;
    final scoreRect = Rect.fromCircle(center: center, radius: radius);

    // Create gradient shader
    final gradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: _gradientColors(),
    );

    final scorePaint = Paint()
      ..shader = gradient.createShader(scoreRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(scoreRect, pi, sweepAngle, false, scorePaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (i / 10) * pi;
      final innerRadius = radius - 18;
      final outerRadius = radius - 14;
      final start = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  List<Color> _gradientColors() {
    return const [
      Color(0xFF00CEC9), // Green (0)
      Color(0xFF55EFC4), // Light green (25)
      Color(0xFFFDCB6E), // Yellow (50)
      Color(0xFFE17055), // Orange (75)
      Color(0xFFFF6B6B), // Red (100)
    ];
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
