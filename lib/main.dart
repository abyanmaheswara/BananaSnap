import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BanaSnapApp());
}

class BanaSnapApp extends StatelessWidget {
  const BanaSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BanaSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Otomatis ikuti HP user
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AppTheme {
  // CSS Var Colors refined for a Premium Mobile feel
  static const Color yellow =
      Color(0xFFFFC107); // Richer amber instead of screaming yellow
  static const Color yellowDark = Color(0xFFFF9800); // Orange tint for depth
  static const Color green = Color(0xFF4ADE80); // Vibrant, modern emerald-green
  static const Color greenDark = Color(0xFF16A34A);
  static const Color red = Color(0xFFFB7185); // Softer, modern rose-red
  static const Color redDark = Color(0xFFE11D48);
  static const Color bgCream =
      Color(0xFFF8FAFC); // Slate-tinted very clean white
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // Slate-900 for crisp text
  static const Color textGrey = Color(0xFF64748B); // Slate-500

  // Alias untuk backward compat
  static const Color primary = yellow;
  static const Color primaryDark = yellowDark;
  static const Color fresh = green;
  static const Color rotten = red;
  static const Color bgLight = bgCream;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFFF0F0F0), // Sesuai body background HTML
        colorScheme: ColorScheme.fromSeed(seedColor: yellow),
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.fredoka(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
          iconTheme: const IconThemeData(color: textDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            foregroundColor: textDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle:
                GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        cardTheme: const CardThemeData(
          color: cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24))),
        ),
      );

  // --- DARK THEME ---
  static const Color scaffoldDark =
      Color(0xFF09090B); // Pure modern dark (Zinc-950)
  static const Color cardDark = Color(0xFF18181B); // Zinc-900 for elevation
  static const Color textLight = Color(0xFFF8FAFC);

  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yellow,
        brightness: Brightness.dark,
        surface: cardDark,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          color: textLight,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: textLight),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor:
              textDark, // Keep text dark on yellow buttons for readability
          elevation: 4,
          shadowColor: yellow.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle:
              GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardDark,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: yellow,
        unselectedItemColor: textGrey,
      ));
}
