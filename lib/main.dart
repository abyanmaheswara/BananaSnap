import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  // CSS Var Colors from HTML
  static const Color yellow = Color(0xFFFFD93D);
  static const Color yellowDark = Color(0xFFF5A623);
  static const Color green = Color(0xFF6BCB77);
  static const Color greenDark = Color(0xFF4CAF61);
  static const Color red = Color(0xFFFF6B6B);
  static const Color redDark = Color(0xFFFF4757);
  static const Color bgCream = Color(0xFFFFF8E1);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textGrey = Color(0xFF888888);

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
}
