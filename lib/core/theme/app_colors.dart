import 'package:flutter/material.dart';

/// Premium color palette for Video Converter Pro
/// AMOLED-optimized dark theme with gradient accents
class AppColors {
  // ============ Background Colors ============
  /// Pure black for AMOLED screens - saves battery
  static const Color background = Color(0xFF000000);

  /// Slightly elevated surface for cards
  static const Color surface = Color(0xFF0A0A0A);

  /// Card background with slight transparency
  static const Color cardBackground = Color(0xFF121212);

  /// Elevated card for selected/active states
  static const Color cardBackgroundElevated = Color(0xFF1A1A1A);

  // ============ Primary Gradient Colors ============
  /// Vibrant cyan - primary accent
  static const Color primaryCyan = Color(0xFF00D9FF);

  /// Electric blue - gradient end
  static const Color primaryBlue = Color(0xFF0066FF);

  /// Primary gradient for buttons and accents
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Secondary Gradient Colors ============
  /// Vivid purple
  static const Color secondaryPurple = Color(0xFF8B5CF6);

  /// Hot pink
  static const Color secondaryPink = Color(0xFFEC4899);

  /// Secondary gradient for variety
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryPurple, secondaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Accent Gradient ============
  /// Orange accent
  static const Color accentOrange = Color(0xFFFF6B35);

  /// Yellow accent
  static const Color accentYellow = Color(0xFFFFD93D);

  /// Warm gradient for progress/actions
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Text Colors ============
  /// Primary text - white with slight opacity
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - muted white
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Tertiary text - very muted
  static const Color textTertiary = Color(0xFF707070);

  /// Disabled text
  static const Color textDisabled = Color(0xFF404040);

  // ============ State Colors ============
  /// Success green
  static const Color success = Color(0xFF10B981);

  /// Warning amber
  static const Color warning = Color(0xFFF59E0B);

  /// Error red
  static const Color error = Color(0xFFEF4444);

  /// Info blue
  static const Color info = Color(0xFF3B82F6);

  // ============ Glassmorphism Colors ============
  /// Glass overlay for cards
  static const Color glassOverlay = Color(0x1AFFFFFF);

  /// Glass border
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Glass highlight
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ============ Border Colors ============
  /// Subtle border
  static const Color border = Color(0xFF2A2A2A);

  /// Active border
  static const Color borderActive = Color(0xFF404040);

  // ============ Shadow Colors ============
  /// Primary glow shadow
  static const Color shadowPrimary = Color(0x4000D9FF);

  /// Secondary glow shadow
  static const Color shadowSecondary = Color(0x408B5CF6);

  /// Dark shadow
  static const Color shadowDark = Color(0x80000000);

  // ============ Icon Colors ============
  /// Active icon color
  static const Color iconActive = primaryCyan;

  /// Inactive icon color
  static const Color iconInactive = Color(0xFF606060);

  // ============ Gradient Helpers ============
  /// Get shimmer gradient for skeleton loading
  static LinearGradient get shimmerGradient => const LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  /// Progress ring gradient
  static const SweepGradient progressGradient = SweepGradient(
    colors: [primaryCyan, primaryBlue, secondaryPurple, primaryCyan],
    stops: [0.0, 0.33, 0.66, 1.0],
  );
}
