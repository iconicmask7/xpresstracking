import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A glassmorphism-styled card with blur and border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.color,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ??
        (isDark
            ? AppColors.darkCard.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.75));
    final borderColor = isDark
        ? AppColors.darkCardBorder.withValues(alpha: 0.7)
        : AppColors.lightCardBorder.withValues(alpha: 0.8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shimmer skeleton loader for list items
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: const AlwaysStoppedAnimation(0),
      builder: (_, __) => Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard
              : const Color(0xFFEEF0FF),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
