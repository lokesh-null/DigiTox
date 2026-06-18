import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSmall;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceLg),
    this.borderRadius = AppTheme.radiusLg,
    this.isSmall = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: isSmall ? const EdgeInsets.all(AppTheme.spaceMd) : padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusMd : borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusMd : borderRadius),
        hoverColor: AppTheme.surfaceHover,
        child: card,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(isSmall ? AppTheme.radiusMd : borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: card,
      ),
    );
  }
}
