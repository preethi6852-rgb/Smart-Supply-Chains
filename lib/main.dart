import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ── Warm Brown Palette ────────────────────────────────────────────
  static const _bgPrimary   = Color(0xFFE1CBB1); // Grain Brown     – canvas
  static const _bgCard      = Color(0xFF976F47); // Cape Palliser   – card surface
  static const _bgAccent    = Color(0xFF7B5836); // Brown Derby     – hover / accent
  static const _textSecond  = Color(0xFF4B3828); // Smoked Brown    – icons / secondary
  static const _textPrimary = Color(0xFF422A14); // Dark Brown      – headings / body

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Supply Chain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _bgPrimary,
        colorScheme: const ColorScheme.light(
          primary:          _bgAccent,
          onPrimary:        _bgPrimary,
          secondary:        _bgCard,
          onSecondary:      _bgPrimary,
          surface:          _bgPrimary,
          onSurface:        _textPrimary,
          surfaceContainer: _bgCard,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',

        // ── Elevated Button ─────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _textPrimary,
            foregroundColor: _bgPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Outlined Button ─────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _bgAccent,
            side: const BorderSide(color: _bgAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),

        // ── Text Button ─────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _bgAccent,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),

        // ── AppBar ──────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: _textPrimary,
          foregroundColor: _bgPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: _bgPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          iconTheme: IconThemeData(color: _bgPrimary),
        ),

        // ── Card ────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: _bgCard,
          elevation: 0,
          shadowColor: Color(0x1A422A14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ── Input Decoration ────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFD4B897),
          labelStyle: const TextStyle(
            color: _textSecond,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: _textSecond,
            fontSize: 13,
          ),
          prefixIconColor: _textSecond,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0x404B3828),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: _bgAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B3A3A)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B3A3A), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),

        // ── FAB ─────────────────────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _textPrimary,
          foregroundColor: _bgPrimary,
          elevation: 0,
          shape: CircleBorder(),
        ),

        // ── Divider ─────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: Color(0x264B3828),
          thickness: 0.5,
        ),

        // ── Icon ────────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: _textSecond,
          size: 22,
        ),

        // ── Text ────────────────────────────────────────────────────
        textTheme: const TextTheme(
          bodyLarge:   TextStyle(color: _textPrimary, fontSize: 15, height: 1.5),
          bodyMedium:  TextStyle(color: _textPrimary, fontSize: 13, height: 1.5),
          bodySmall:   TextStyle(color: _textSecond,  fontSize: 12, height: 1.4),
          titleLarge:  TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleSmall:  TextStyle(color: _textSecond,  fontSize: 13, fontWeight: FontWeight.w500),
          labelLarge:  TextStyle(color: _bgPrimary,   fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: _textSecond,  fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4),
          labelSmall:  TextStyle(color: _textSecond,  fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.6),
        ),

        // ── Chip ────────────────────────────────────────────────────
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFD4B897),
          labelStyle: TextStyle(color: _textPrimary, fontSize: 12),
          side: BorderSide(color: Color(0x404B3828)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),

        // ── Bottom Navigation Bar ────────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:      _bgPrimary,
          selectedItemColor:    _bgAccent,
          unselectedItemColor:  _textSecond,
          elevation:            0,
          type:                 BottomNavigationBarType.fixed,
          selectedLabelStyle:   TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // ── Progress Indicator ───────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _bgAccent,
          linearTrackColor: Color(0xFFD4B897),
        ),

        // ── Snack Bar ────────────────────────────────────────────────
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: _bgAccent,
          contentTextStyle: TextStyle(color: _bgPrimary, fontSize: 13),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          elevation: 0,
        ),

        // ── Dialog ──────────────────────────────────────────────────
        dialogTheme: const DialogThemeData(
          backgroundColor: _bgPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          titleTextStyle: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(
            color: _textSecond,
            fontSize: 14,
            height: 1.6,
          ),
        ),

        // ── List Tile ───────────────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          iconColor: _textSecond,
          textColor: _textPrimary,
          subtitleTextStyle: TextStyle(color: _textSecond, fontSize: 12),
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),

        // ── Switch ──────────────────────────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? _bgAccent
                : _textSecond,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Color(0x597B5836)
                : Color(0x334B3828),
          ),
        ),
      ),

      // ── Auth Gate ─────────────────────────────────────────────────
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7B5836),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}