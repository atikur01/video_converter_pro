import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversion_settings.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing app settings persistence
/// Stores user preferences and default conversion settings
class SettingsRepository {
  static const String _themeKey = 'theme_mode';
  static const String _defaultQualityKey = 'default_quality';
  static const String _defaultFormatKey = 'default_format';
  static const String _autoBitrateKey = 'auto_bitrate';
  static const String _saveLocationKey = 'save_location';
  static const String _showNotificationsKey = 'show_notifications';
  static const String _hapticFeedbackKey = 'haptic_feedback';
  static const String _lastUsedSettingsKey = 'last_used_settings';

  SharedPreferences? _prefs;

  /// Initialize the repository
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ Theme Settings ============

  /// Get current theme mode (0 = system, 1 = light, 2 = dark)
  Future<int> getThemeMode() async {
    final p = await prefs;
    return p.getInt(_themeKey) ?? 2; // Default to dark
  }

  /// Set theme mode
  Future<void> setThemeMode(int mode) async {
    final p = await prefs;
    await p.setInt(_themeKey, mode);
  }

  // ============ Default Quality Settings ============

  /// Get default quality preset index (0 = High, 1 = Balanced, 2 = Fast)
  Future<int> getDefaultQuality() async {
    final p = await prefs;
    return p.getInt(_defaultQualityKey) ?? AppConstants.defaultQualityIndex;
  }

  /// Set default quality preset
  Future<void> setDefaultQuality(int quality) async {
    final p = await prefs;
    await p.setInt(_defaultQualityKey, quality);
  }

  // ============ Default Format Settings ============

  /// Get default output format
  Future<String> getDefaultFormat() async {
    final p = await prefs;
    return p.getString(_defaultFormatKey) ?? AppConstants.defaultFormat;
  }

  /// Set default output format
  Future<void> setDefaultFormat(String format) async {
    final p = await prefs;
    await p.setString(_defaultFormatKey, format);
  }

  // ============ Auto Bitrate Settings ============

  /// Get auto bitrate preference
  Future<bool> getAutoBitrate() async {
    final p = await prefs;
    return p.getBool(_autoBitrateKey) ?? true;
  }

  /// Set auto bitrate preference
  Future<void> setAutoBitrate(bool auto) async {
    final p = await prefs;
    await p.setBool(_autoBitrateKey, auto);
  }

  // ============ Save Location Settings ============

  /// Get custom save location (null = default)
  Future<String?> getSaveLocation() async {
    final p = await prefs;
    return p.getString(_saveLocationKey);
  }

  /// Set custom save location
  Future<void> setSaveLocation(String? path) async {
    final p = await prefs;
    if (path != null) {
      await p.setString(_saveLocationKey, path);
    } else {
      await p.remove(_saveLocationKey);
    }
  }

  // ============ Notification Settings ============

  /// Get notification preference
  Future<bool> getShowNotifications() async {
    final p = await prefs;
    return p.getBool(_showNotificationsKey) ?? true;
  }

  /// Set notification preference
  Future<void> setShowNotifications(bool show) async {
    final p = await prefs;
    await p.setBool(_showNotificationsKey, show);
  }

  // ============ Haptic Feedback Settings ============

  /// Get haptic feedback preference
  Future<bool> getHapticFeedback() async {
    final p = await prefs;
    return p.getBool(_hapticFeedbackKey) ?? true;
  }

  /// Set haptic feedback preference
  Future<void> setHapticFeedback(bool enabled) async {
    final p = await prefs;
    await p.setBool(_hapticFeedbackKey, enabled);
  }

  // ============ Last Used Settings ============

  /// Get last used conversion settings
  Future<ConversionSettings?> getLastUsedSettings() async {
    final p = await prefs;
    final json = p.getString(_lastUsedSettingsKey);
    if (json == null) return null;

    try {
      return ConversionSettings.fromJson(
        Map<String, dynamic>.from(
          Uri.splitQueryString(json).map((k, v) => MapEntry(k, _parseValue(v))),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save last used conversion settings
  Future<void> saveLastUsedSettings(ConversionSettings settings) async {
    final p = await prefs;
    final json = settings
        .toJson()
        .entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    await p.setString(_lastUsedSettingsKey, json);
  }

  /// Helper to parse stored values
  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;
    final doubleVal = double.tryParse(value);
    if (doubleVal != null) return doubleVal;
    return value;
  }

  // ============ Cache Management ============

  /// Get cache size in bytes (placeholder - actual implementation depends on your caching strategy)
  Future<int> getCacheSize() async {
    // This would typically scan the cache directory
    // For now, return 0 as placeholder
    return 0;
  }

  /// Clear app cache
  Future<void> clearCache() async {
    // Implementation would clear temporary files
    // This is a placeholder
  }

  /// Clear all settings (reset to defaults)
  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_themeKey);
    await p.remove(_defaultQualityKey);
    await p.remove(_defaultFormatKey);
    await p.remove(_autoBitrateKey);
    await p.remove(_saveLocationKey);
    await p.remove(_showNotificationsKey);
    await p.remove(_hapticFeedbackKey);
    await p.remove(_lastUsedSettingsKey);
  }

  /// Get all settings as a map (for debugging)
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'themeMode': await getThemeMode(),
      'defaultQuality': await getDefaultQuality(),
      'defaultFormat': await getDefaultFormat(),
      'autoBitrate': await getAutoBitrate(),
      'saveLocation': await getSaveLocation(),
      'showNotifications': await getShowNotifications(),
      'hapticFeedback': await getHapticFeedback(),
    };
  }
}
