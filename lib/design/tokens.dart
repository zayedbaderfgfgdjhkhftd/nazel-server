import 'package:material_ui/material_ui.dart';

/// Colour tokens (spec section 7.2).
@immutable
class SatrColors extends ThemeExtension<SatrColors> {
  const SatrColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.textMuted,
    required this.brand,
    required this.accent,
    required this.onAccent,
    required this.line,
    required this.danger,
    required this.success,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color textMuted;
  final Color brand;
  final Color accent;
  final Color onAccent;
  final Color line;
  final Color danger;
  final Color success;

  static const light = SatrColors(
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF3F4F6),
    surface2: Color(0xFFE5E7EB),
    text: Color(0xFF14171C),
    textMuted: Color(0xFF4B5563),
    brand: Color(0xFF121417),
    accent: Color(0xFFFFD23F),
    onAccent: Color(0xFF121417),
    line: Color(0xFFC5CAD1),
    danger: Color(0xFFB42318),
    success: Color(0xFF067647),
  );

  static const dark = SatrColors(
    bg: Color(0xFF121417),
    surface: Color(0xFF1A1D21),
    surface2: Color(0xFF24282E),
    text: Color(0xFFF3F4F6),
    textMuted: Color(0xFFA1A8B3),
    brand: Color(0xFFF3F4F6),
    accent: Color(0xFFFFD23F),
    onAccent: Color(0xFF121417),
    line: Color(0xFF3A3F46),
    danger: Color(0xFFF97066),
    success: Color(0xFF47CD89),
  );

  static SatrColors of(BuildContext context) =>
      Theme.of(context).extension<SatrColors>() ?? light;

  @override
  SatrColors copyWith() => this;

  @override
  SatrColors lerp(ThemeExtension<SatrColors>? other, double t) =>
      other is SatrColors && t > 0.5 ? other : this;
}

/// 4-px spacing grid.
class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii: controls, cards, sheets.
class Radii {
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 24;
}

/// Type scale: 12 / 14 / 16 / 20 / 24 / 32 / 40. Arabic line height >= 1.6.
class TypeScale {
  static const double xs = 12;
  static const double s = 14;
  static const double body = 16;
  static const double m = 20;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double lineHeight = 1.6;
}

/// Motion: 150-250 ms, ease-out; disabled when the OS asks for less motion.
class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Curve curve = Curves.easeOut;

  static Duration of(BuildContext context, [Duration d = normal]) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

/// Minimum touch target.
const double kTouchTarget = 44;

/// Max content width on tablets/desktop.
const double kMaxContentWidth = 1100;
