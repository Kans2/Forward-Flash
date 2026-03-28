import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/preset.dart';
import 'services/sim_detection_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Request phone permissions needed for USSD dialling and SIM detection
  await Permission.phone.request();

  // Init Hive
  await Hive.initFlutter();
  await PresetRepository.instance.init();

  // Detect SIM slots
  await SimDetectionService.instance.init();

  runApp(const CallForwardApp());
}

class CallForwardApp extends StatelessWidget {
  const CallForwardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallForward',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = const Color(0xFF1A73E8); // Google-blue seed

    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F8FF),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
    );
  }
}
