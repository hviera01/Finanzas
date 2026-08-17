import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const fondo = Color(0xFFF6F7F5);
  static const fondoOscuro = Color(0xFF10201C);
  static const primario = Color(0xFF0E6E5C); // verde azulado profundo
  static const primarioClaro = Color(0xFF16A085);
  static const acento = Color(0xFFE0A324); // ámbar cálido
  static const peligro = Color(0xFFC5482B);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieOscura = Color(0xFF16302A);
  static const texto = Color(0xFF122420);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primario,
        brightness: Brightness.light,
        primary: AppColors.primario,
        secondary: AppColors.acento,
        surface: AppColors.superficie,
        error: AppColors.peligro,
      ),
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.texto,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
      ),
    );
  }
}
