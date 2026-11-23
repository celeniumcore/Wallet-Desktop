import 'package:flutter/material.dart';

/// Dark premium palette — restored to pre-sticky-note desktop design.
/// Inspired by wallet-design v12/v13 boards.
class CenTheme {
  // Surface
  static const bg = Color(0xFF070A08);       // deepest background
  static const bg1 = Color(0xFF0E1310);      // sidebar / top layers
  static const bg2 = Color(0xFF11170F);      // elevated surface
  static const card = Color(0xFF11170F);     // card surface
  static const elevated = Color(0xFF171E16); // input/inner elevated
  static const line = Color(0xFF252E25);     // subtle border
  static const lineStrong = Color(0xFF344034);

  // Ink
  static const txt = Color(0xFFF2F4EE);      // primary text
  static const sub = Color(0xFF9AA696);      // secondary text
  static const muted = Color(0xFF828F80);    // muted text

  // Accent
  static const acid = Color(0xFFC9D98F);     // primary CTA / accent
  static const green = Color(0xFF79C77F);    // success / in
  static const red = Color(0xFFE06C75);      // error / out
  static const warn = Color(0xFFE0B878);     // backup warning
  static const cardWarn = Color(0xFF181510); // warm card surface for warnings

  // Type — the 20 Nov board pairs a squarish display face with a grotesk body
  // and a mono for amounts/addresses.
  static const fontBody = 'Sora';
  static const fontDisplay = 'Chakra Petch';
  static const fontMono = 'JetBrains Mono';

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = txt,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontDisplay,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = sub,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: fontMono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = sub,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontBody,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontBody,
    scaffoldBackgroundColor: bg,
    cardColor: card,
    dividerColor: line,
    colorScheme: const ColorScheme.dark(
      primary: acid,
      secondary: acid,
      surface: card,
      error: red,
      onPrimary: Color(0xFF0B120B),
      onSecondary: Color(0xFF0B120B),
      onSurface: txt,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: txt,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: elevated,
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      labelStyle: const TextStyle(color: sub),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: acid, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: red),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: acid,
        foregroundColor: const Color(0xFF0B120B),
        disabledBackgroundColor: const Color(0x44C9D98F),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: txt,
        side: const BorderSide(color: lineStrong),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: acid),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bg2,
      side: const BorderSide(color: line),
      labelStyle: const TextStyle(color: sub, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    iconTheme: const IconThemeData(color: sub),
    listTileTheme: const ListTileThemeData(
      iconColor: sub,
      textColor: txt,
    ),
  );

  static ButtonStyle get primaryBtn => FilledButton.styleFrom(
    backgroundColor: acid,
    foregroundColor: const Color(0xFF0B120B),
    disabledBackgroundColor: const Color(0x44C9D98F),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  static InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
  );
}
