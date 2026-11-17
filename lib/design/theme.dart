import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

const String kFontFamily = 'ReadexPro';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SatrColors.dark : SatrColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.brand,
    onPrimary: c.bg,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.bg,
    surface: c.bg,
    onSurface: c.text,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface2,
    surfaceContainerHighest: c.surface2,
    onSurfaceVariant: c.textMuted,
    outline: c.line,
    outlineVariant: c.line,
    tertiary: c.success,
    onTertiary: c.bg,
  );

  TextStyle t(double size, FontWeight w) => TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: w,
        height: TypeScale.lineHeight,
        color: c.text,
      );

  final textTheme = TextTheme(
    displayLarge: t(TypeScale.xxl, FontWeight.w700),
    displayMedium: t(TypeScale.xl, FontWeight.w700),
    headlineMedium: t(TypeScale.l, FontWeight.w700),
    titleLarge: t(TypeScale.m, FontWeight.w700),
    titleMedium: t(TypeScale.body, FontWeight.w500),
    titleSmall: t(TypeScale.s, FontWeight.w500),
    bodyLarge: t(TypeScale.body, FontWeight.w400),
    bodyMedium: t(TypeScale.s, FontWeight.w400),
    bodySmall: t(TypeScale.xs, FontWeight.w400).copyWith(color: c.textMuted),
    labelLarge: t(TypeScale.body, FontWeight.w500),
    labelMedium: t(TypeScale.s, FontWeight.w500),
    labelSmall: t(TypeScale.xs, FontWeight.w500),
  );

  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control));
  const minSize = Size(kTouchTarget, kTouchTarget);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: kFontFamily,
    textTheme: textTheme,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: t(TypeScale.m, FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surface2,
        disabledForegroundColor: c.textMuted,
        minimumSize: const Size(kTouchTarget, 52),
        shape: controlShape,
        textStyle: t(TypeScale.body, FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.m),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.line),
        minimumSize: const Size(kTouchTarget, 48),
        shape: controlShape,
        textStyle: t(TypeScale.s, FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: minSize,
        shape: controlShape,
        textStyle: t(TypeScale.s, FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: minSize, foregroundColor: c.text),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      modalBackgroundColor: c.bg,
      showDragHandle: true,
      dragHandleColor: c.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
      titleTextStyle: t(TypeScale.m, FontWeight.w700),
      contentTextStyle: t(TypeScale.body, FontWeight.w400),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.text, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: c.danger),
      ),
      labelStyle: t(TypeScale.s, FontWeight.w400).copyWith(color: c.textMuted),
      hintStyle: t(TypeScale.s, FontWeight.w400).copyWith(color: c.textMuted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      indicatorColor: c.accent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => t(
            TypeScale.xs,
            s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ).copyWith(color: s.contains(WidgetState.selected) ? c.text : c.textMuted)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accent,
      labelStyle: t(TypeScale.s, FontWeight.w500),
      secondaryLabelStyle: t(TypeScale.s, FontWeight.w500).copyWith(color: c.onAccent),
      side: BorderSide(color: c.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control)),
      checkmarkColor: c.onAccent,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.accent : c.bg),
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onAccent : c.text),
        side: WidgetStatePropertyAll(BorderSide(color: c.line)),
        minimumSize: const WidgetStatePropertyAll(Size(kTouchTarget, kTouchTarget)),
        shape: WidgetStatePropertyAll(controlShape),
        textStyle: WidgetStatePropertyAll(t(TypeScale.s, FontWeight.w500)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.text,
      inactiveTrackColor: c.surface2,
      thumbColor: c.accent,
      overlayColor: c.accent.withValues(alpha: 0.2),
      valueIndicatorColor: c.brand,
      valueIndicatorTextStyle: t(TypeScale.s, FontWeight.w500).copyWith(color: c.bg),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textMuted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surface2),
      trackOutlineColor: WidgetStatePropertyAll(c.line),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(c.onAccent),
      side: BorderSide(color: c.textMuted, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.text : c.textMuted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surface2,
      circularTrackColor: c.surface2,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.brand,
      contentTextStyle: t(TypeScale.s, FontWeight.w500).copyWith(color: c.bg),
      actionTextColor: c.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control)),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: Space.s,
      iconColor: c.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control)),
      textStyle: t(TypeScale.s, FontWeight.w400),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(8)),
      textStyle: t(TypeScale.xs, FontWeight.w500).copyWith(color: c.bg),
    ),
  );
}
