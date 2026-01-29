import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Service for haptic feedback
/// Provides premium tactile feedback for user interactions
class HapticService {
  /// Singleton instance
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;
  bool? _hasVibrator;

  /// Set haptic feedback enabled state
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if device has vibrator
  Future<bool> get hasVibrator async {
    _hasVibrator ??= await Vibration.hasVibrator();
    return _hasVibrator ?? false;
  }

  /// Light impact - for subtle UI feedback
  Future<void> lightImpact() async {
    if (!_isEnabled) return;

    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail if haptics not available
    }
  }

  /// Medium impact - for button presses
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;

    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail
    }
  }

  /// Heavy impact - for significant actions
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;

    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail
    }
  }

  /// Selection changed - for picker/slider changes
  Future<void> selectionClick() async {
    if (!_isEnabled) return;

    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail
    }
  }

  /// Success feedback - for completed actions
  Future<void> success() async {
    if (!_isEnabled) return;

    try {
      if (await hasVibrator) {
        await Vibration.vibrate(duration: 50, amplitude: 128);
        await Future.delayed(const Duration(milliseconds: 100));
        await Vibration.vibrate(duration: 50, amplitude: 200);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Error feedback - for failed actions
  Future<void> error() async {
    if (!_isEnabled) return;

    try {
      if (await hasVibrator) {
        await Vibration.vibrate(duration: 100, amplitude: 255);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 100, amplitude: 255);
        await Future.delayed(const Duration(milliseconds: 80));
        await Vibration.vibrate(duration: 100, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Warning feedback
  Future<void> warning() async {
    if (!_isEnabled) return;

    try {
      if (await hasVibrator) {
        await Vibration.vibrate(duration: 200, amplitude: 180);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Custom vibration pattern
  Future<void> pattern(List<int> patternList, {List<int>? amplitudes}) async {
    if (!_isEnabled) return;

    try {
      if (await hasVibrator) {
        await Vibration.vibrate(
          pattern: patternList,
          intensities: amplitudes ?? [],
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      // Silently fail
    }
  }
}
