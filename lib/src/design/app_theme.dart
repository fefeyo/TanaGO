import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_palette.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.forest,
    primary: AppPalette.forest,
    onPrimary: AppPalette.paper,
    primaryContainer: AppPalette.pistachio,
    onPrimaryContainer: AppPalette.ink,
    secondaryContainer: AppPalette.peach,
    onSecondaryContainer: AppPalette.peachInk,
    tertiaryContainer: AppPalette.butter,
    onTertiaryContainer: AppPalette.amberInk,
    surface: AppPalette.milk,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.muted,
    outlineVariant: AppPalette.line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));
  return base.copyWith(
    scaffoldBackgroundColor: AppPalette.milk,
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium:
          base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: AppPalette.muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppPalette.milk,
      foregroundColor: AppPalette.forest,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.ink,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: shape.copyWith(side: const BorderSide(color: AppPalette.line)),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.pistachio,
        foregroundColor: AppPalette.ink,
        disabledBackgroundColor: AppPalette.line,
        disabledForegroundColor: AppPalette.muted,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: base.textTheme.labelLarge
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppPalette.line),
        shape: const StadiumBorder(),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.pistachio,
      foregroundColor: AppPalette.ink,
      elevation: 2,
      shape: shape,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppPalette.muted, width: 1.6),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppPalette.forest,
      linearTrackColor: AppPalette.softGreen,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.paper,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppPalette.forest, width: 2),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minVerticalPadding: 12,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppPalette.milk,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.paper,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppPalette.pistachio,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppPalette.softGreen,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        color: AppPalette.forest,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
      backgroundColor: AppPalette.forest,
    ),
    dividerTheme: const DividerThemeData(color: AppPalette.line, thickness: 1),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
      iconColor: AppPalette.forest,
    ),
  );
}
