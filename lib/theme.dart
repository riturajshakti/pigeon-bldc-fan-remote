import 'package:flutter/material.dart';

class FanColors extends ThemeExtension<FanColors> {
  const FanColors({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.outline,
    required this.onSurface,
    required this.onMuted,
    required this.accent,
    required this.onAccent,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color outline;
  final Color onSurface;
  final Color onMuted;
  final Color accent;
  final Color onAccent;

  static const dark = FanColors(
    bg: Color(0xFF140708),
    surface: Color(0xFF241011),
    surfaceHi: Color(0xFF42201F),
    outline: Color(0xFF5C2C2D),
    onSurface: Color(0xFFFDEDED),
    onMuted: Color(0xFFC9A3A4),
    accent: Color(0xFFE02424),
    onAccent: Color(0xFFFFFFFF),
  );

  static const light = FanColors(
    bg: Color(0xFFFDF2F2),
    surface: Color(0xFFFFFFFF),
    surfaceHi: Color(0xFFF7C9C9),
    outline: Color(0xFFE89A9A),
    onSurface: Color(0xFF3B0A0A),
    onMuted: Color(0xFF8B5F5F),
    accent: Color(0xFFC81E1E),
    onAccent: Color(0xFFFFFFFF),
  );

  @override
  FanColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceHi,
    Color? outline,
    Color? onSurface,
    Color? onMuted,
    Color? accent,
    Color? onAccent,
  }) {
    return FanColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      outline: outline ?? this.outline,
      onSurface: onSurface ?? this.onSurface,
      onMuted: onMuted ?? this.onMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  FanColors lerp(FanColors? other, double t) {
    if (other == null) return this;
    return FanColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHi: Color.lerp(surfaceHi, other.surfaceHi, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onMuted: Color.lerp(onMuted, other.onMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final fan = brightness == Brightness.dark ? FanColors.dark : FanColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: fan.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: fan.accent,
      brightness: brightness,
      primary: fan.accent,
      onPrimary: fan.onAccent,
      surface: fan.surface,
      onSurface: fan.onSurface,
      outline: fan.outline,
    ),
    extensions: [fan],
  );
}

extension FanColorsContext on BuildContext {
  FanColors get fan => Theme.of(this).extension<FanColors>()!;
}
