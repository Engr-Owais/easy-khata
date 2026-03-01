import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/glass_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.width,
    this.height,
    this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final glassColors = Theme.of(context).extension<GlassColors>() ?? GlassColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = gradientColors ??
        (isDark
            ? [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ]
            : [
                Colors.white.withValues(alpha: 0.5),
                Colors.white.withValues(alpha: 0.2),
              ]);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: glassColors.cardBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glassColors.cardShadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
