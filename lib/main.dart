import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Native app is portrait-first; the website remains fully responsive.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Prevent screenshots (Android only)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase initialization (uncomment after setup)
  // await FirebaseService.initialize();

  runApp(const DivineWallApp());
}

class DivineWallApp extends StatefulWidget {
  const DivineWallApp({super.key});

  @override
  State<DivineWallApp> createState() => _DivineWallAppState();
}

class _DivineWallAppState extends State<DivineWallApp> {
  static const _themeKey = 'kubar.theme.dark.v1';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _darkMode = prefs.getBool(_themeKey) ?? false);
  }

  Future<void> _toggleTheme() async {
    setState(() => _darkMode = !_darkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuber Vastu',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppTheme.bgDark,
        colorScheme: const ColorScheme.light(
          primary: AppTheme.gold,
          surface: AppTheme.bgPanel,
          onPrimary: AppTheme.cream,
          onSurface: AppTheme.cream,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButtonStyle(),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppTheme.secondaryButtonStyle(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.gold,
            textStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.bgPanel,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          labelStyle: AppTheme.uiText(size: 12, color: AppTheme.muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppTheme.gold.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.gold, width: 1.4),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.bgPanel,
          foregroundColor: AppTheme.cream,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppTheme.bgPanel,
          contentTextStyle: TextStyle(color: AppTheme.cream),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF15110C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD8B564),
          surface: Color(0xFF211A12),
          onPrimary: Color(0xFF211A12),
          onSurface: Color(0xFFF9EBD0),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(
        destination: HomeShell(
          darkMode: _darkMode,
          onThemeToggle: _toggleTheme,
        ),
      ),
    );
  }
}
