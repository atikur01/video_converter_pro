import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../services/haptic_service.dart';

import '../../services/file_service.dart';

/// Theme mode options
enum AppThemeMode { system, light, dark }

/// Provider for managing app settings
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();
  final HapticService _hapticService = HapticService();
  final FileService _fileService = FileService();

  // ============ State ============
  AppThemeMode _themeMode = AppThemeMode.dark;
  int _defaultQuality =
      AppConstants.defaultQualityIndex; // 0=High, 1=Balanced, 2=Fast
  String _defaultFormat = AppConstants.defaultFormat;
  bool _autoBitrate = true;
  String? _saveLocation;
  bool _showNotifications = true;
  bool _hapticFeedback = true;
  bool _isLoading = false;
  int _cacheSize = 0;

  // ============ Getters ============
  AppThemeMode get themeMode => _themeMode;
  int get defaultQuality => _defaultQuality;
  String get defaultFormat => _defaultFormat;
  bool get autoBitrate => _autoBitrate;
  String? get saveLocation => _saveLocation;
  bool get showNotifications => _showNotifications;
  bool get hapticFeedback => _hapticFeedback;
  bool get isLoading => _isLoading;
  int get cacheSize => _cacheSize;

  /// Get ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Get formatted cache size
  String get formattedCacheSize {
    return _fileService.formatFileSize(_cacheSize);
  }

  // ============ Initialization ============

  /// Initialize settings from storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.init();

      final themeModeIndex = await _repository.getThemeMode();
      _themeMode = AppThemeMode.values[themeModeIndex.clamp(0, 2)];

      _defaultQuality = await _repository.getDefaultQuality();
      _defaultFormat = await _repository.getDefaultFormat();
      _autoBitrate = await _repository.getAutoBitrate();
      _saveLocation = await _repository.getSaveLocation();
      _showNotifications = await _repository.getShowNotifications();
      _hapticFeedback = await _repository.getHapticFeedback();

      // Configure haptic service
      _hapticService.setEnabled(_hapticFeedback);

      // Get cache size
      await _updateCacheSize();
    } catch (e) {
      // Use defaults on error
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============ Theme Settings ============

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _repository.setThemeMode(mode.index);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  // ============ Quality Settings ============

  /// Set default quality preset
  Future<void> setDefaultQuality(int quality) async {
    _defaultQuality = quality.clamp(0, 2);
    await _repository.setDefaultQuality(_defaultQuality);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Get quality name
  String get defaultQualityName {
    switch (_defaultQuality) {
      case 0:
        return 'High Quality';
      case 1:
        return 'Balanced';
      case 2:
        return 'Fast';
      default:
        return 'Balanced';
    }
  }

  // ============ Format Settings ============

  /// Set default output format
  Future<void> setDefaultFormat(String format) async {
    _defaultFormat = format;
    await _repository.setDefaultFormat(format);
    _hapticService.selectionClick();
    notifyListeners();
  }

  // ============ Bitrate Settings ============

  /// Set auto bitrate preference
  Future<void> setAutoBitrate(bool auto) async {
    _autoBitrate = auto;
    await _repository.setAutoBitrate(auto);
    _hapticService.selectionClick();
    notifyListeners();
  }

  // ============ Save Location ============

  /// Set custom save location
  Future<void> setSaveLocation(String? path) async {
    _saveLocation = path;
    await _repository.setSaveLocation(path);
    _hapticService.lightImpact();
    notifyListeners();
  }

  /// Reset to default save location
  Future<void> resetSaveLocation() async {
    await setSaveLocation(null);
  }

  // ============ Notification Settings ============

  /// Set notification preference
  Future<void> setShowNotifications(bool show) async {
    _showNotifications = show;
    await _repository.setShowNotifications(show);
    _hapticService.selectionClick();
    notifyListeners();
  }

  // ============ Haptic Settings ============

  /// Set haptic feedback preference
  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedback = enabled;
    _hapticService.setEnabled(enabled);
    await _repository.setHapticFeedback(enabled);

    if (enabled) {
      _hapticService.lightImpact();
    }

    notifyListeners();
  }

  // ============ Cache Management ============

  /// Update cache size
  Future<void> _updateCacheSize() async {
    _cacheSize = await _fileService.getOutputDirectorySize();
    notifyListeners();
  }

  /// Refresh cache size
  Future<void> refreshCacheSize() async {
    await _updateCacheSize();
  }

  /// Clear cache (output directory)
  Future<void> clearCache() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fileService.clearOutputDirectory();
      _cacheSize = 0;
      _hapticService.success();
    } catch (e) {
      _hapticService.error();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============ Reset ============

  /// Reset all settings to defaults
  Future<void> resetAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.clearAll();

      // Reset to defaults
      _themeMode = AppThemeMode.dark;
      _defaultQuality = AppConstants.defaultQualityIndex;
      _defaultFormat = AppConstants.defaultFormat;
      _autoBitrate = true;
      _saveLocation = null;
      _showNotifications = true;
      _hapticFeedback = true;

      _hapticService.setEnabled(true);
      _hapticService.success();
    } catch (e) {
      _hapticService.error();
    }

    _isLoading = false;
    notifyListeners();
  }
}
