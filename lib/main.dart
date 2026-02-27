import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientasi ke portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BananaFreshnessApp());
}

class BananaFreshnessApp extends StatelessWidget {
  const BananaFreshnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BanaSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.premiumTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AppTheme {
  // Palet Warna Premium (Dark & Neon)
  static const Color primary = Color(0xFFFFD54F); // Neon Banana Yellow
  static const Color primaryDark = Color(0xFFFBC02D);
  static const Color fresh = Color(0xFF00E676); // Neon Green (Layak)
  static const Color rotten = Color(0xFFFF5252); // Neon Red (Tidak Layak)

  // Backgrounds
  static const Color bgDark = Color(0xFF121212); // Deep Space Black
  static const Color surface = Color(0xFF1E1E1E); // Elevated Dark
  static const Color cardBg = Color(0xFF242424);

  // Texts
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFAAAAAA);

  static ThemeData get premiumTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          surface: bgDark,
          primary: primary,
          secondary: fresh,
        ),
        scaffoldBackgroundColor: bgDark,
        fontFamily: 'Inter', // Modern font if available, fallback to default
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textLight,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
          iconTheme: IconThemeData(color: primary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: bgDark,
            elevation: 8,
            shadowColor: primary.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: cardBg,
          elevation: 8,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      );
}
