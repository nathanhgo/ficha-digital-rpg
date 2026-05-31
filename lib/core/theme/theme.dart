import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SteampunkTheme {
  // Paleta de Cores
  static const Color leatherBark = Color(0xFF251810);     // Fundo Escuro Escuro (Couro)
  static const Color castIron = Color(0xFF1E1611);        // Superfícies secundárias (Ferro Fundido)
  static const Color agedParchment = Color(0xFFE8D8B0);   // Superfícies de leitura (Pergaminho)
  static const Color copper = Color(0xFFCD7F32);          // Destaque de Engrenagens/Metal (Cobre)
  static const Color brassGlow = Color(0xFFE68A00);       // Destaque Quente / Vigor (Latão/Fogo)
  static const Color inkBlack = Color(0xFF1C130C);        // Escrita do Pergaminho (Tinta preta)
  static const Color bloodRed = Color(0xFFA62B2B);        // Alertas de Perigo / Vida Baixa (Vermelho Sangue)

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: leatherBark,
      primaryColor: copper,
      colorScheme: const ColorScheme.dark(
        primary: copper,
        secondary: brassGlow,
        surface: castIron,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: bloodRed,
      ),
      
      // Estilo do AppBar (Steampunk/Medieval)
      appBarTheme: AppBarTheme(
        backgroundColor: castIron,
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: copper),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Tipografia Geral
      textTheme: TextTheme(
        // Títulos Principais
        displayLarge: GoogleFonts.cinzel(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // Corpo do texto (Livro de regras) - Mais brilhante/claro
        bodyLarge: GoogleFonts.ebGaramond(
          fontSize: 18,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.ebGaramond(
          fontSize: 16,
          color: Colors.white70,
        ),
        // Estatísticas e Valores Numéricos (Painel)
        labelLarge: GoogleFonts.specialElite(
          fontSize: 16,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.specialElite(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),

      // Estilo de botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: copper,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: castIron, width: 2),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Estilo dos inputs de formulário
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: castIron,
        labelStyle: GoogleFonts.ebGaramond(color: copper),
        floatingLabelStyle: GoogleFonts.ebGaramond(color: copper, fontSize: 18),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: copper, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: brassGlow, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: bloodRed, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: bloodRed, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        hintStyle: GoogleFonts.ebGaramond(color: Colors.white30),
      ),

      // Estilo de Cards
      cardTheme: CardThemeData(
        color: castIron,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: copper, width: 1),
        ),
      ),
    );
  }
}
