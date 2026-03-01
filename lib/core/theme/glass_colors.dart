import 'package:flutter/material.dart';

class GlassColors extends ThemeExtension<GlassColors> {
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color shimmer;

  const GlassColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.shimmer,
  });

  static const light = GlassColors(
    cardBackground: Color(0x33FFFFFF),
    cardBorder: Color(0x55FFFFFF),
    cardShadow: Color(0x1A000000),
    shimmer: Color(0x22FFFFFF),
  );

  static const dark = GlassColors(
    cardBackground: Color(0x22FFFFFF),
    cardBorder: Color(0x33FFFFFF),
    cardShadow: Color(0x33000000),
    shimmer: Color(0x11FFFFFF),
  );

  @override
  GlassColors copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? cardShadow,
    Color? shimmer,
  }) {
    return GlassColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      shimmer: shimmer ?? this.shimmer,
    );
  }

  @override
  GlassColors lerp(ThemeExtension<GlassColors>? other, double t) {
    if (other is! GlassColors) return this;
    return GlassColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      shimmer: Color.lerp(shimmer, other.shimmer, t)!,
    );
  }
}
