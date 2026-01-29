import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/conversion_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home_screen.dart';

/// Video Converter Pro - Premium Video Conversion App
///
/// A modern, feature-rich video converter with a premium dark AMOLED UI,
/// built with Flutter and FFmpeg for high-quality video processing.
///
/// Features:
/// - Video format conversion (MP4, MKV, AVI, MOV, WEBM, FLV)
/// - Video to audio extraction (MP3, AAC, WAV, M4A)
/// - Resolution presets (4K, 1080p, 720p, 480p)
/// - Frame rate control (24fps, 30fps, 60fps)
/// - Bitrate control (Auto + Manual)
/// - Batch conversion
/// - Conversion history
/// - Premium glassmorphism UI
/// - Smooth animations

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await AppTheme.setPreferredOrientations();

  // Set system UI overlay style for immersive experience
  AppTheme.setSystemUIOverlayStyle();

  // Run the app
  runApp(const VideoConverterProApp());
}

/// Main application widget
class VideoConverterProApp extends StatelessWidget {
  const VideoConverterProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Settings provider - manages app preferences
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),

        // Conversion provider - manages video conversion state
        ChangeNotifierProvider(create: (_) => ConversionProvider()),

        // History provider - manages conversion history
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            // App info
            title: 'Video Converter Pro',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.materialThemeMode,

            // Home screen
            home: const HomeScreen(),

            // Global scroll behavior (for smooth scrolling)
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),

            // Builder for global configurations
            builder: (context, child) {
              // Set system UI colors
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.black,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
              );

              return MediaQuery(
                // Disable text scaling for consistent UI
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
