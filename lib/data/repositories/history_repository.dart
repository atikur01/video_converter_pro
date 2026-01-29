import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversion_history.dart';

/// Repository for managing conversion history persistence
/// Uses SharedPreferences for local storage
class HistoryRepository {
  static const String _historyKey = 'conversion_history';
  static const int _maxHistoryItems = 100;

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

  /// Get all history entries, sorted by date (newest first)
  Future<List<ConversionHistory>> getAll() async {
    final p = await prefs;
    final jsonList = p.getStringList(_historyKey) ?? [];

    final history = <ConversionHistory>[];
    for (final jsonStr in jsonList) {
      try {
        history.add(ConversionHistory.fromJsonString(jsonStr));
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    // Sort by completion date, newest first
    history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return history;
  }

  /// Get recent history entries (limited)
  Future<List<ConversionHistory>> getRecent({int limit = 10}) async {
    final all = await getAll();
    return all.take(limit).toList();
  }

  /// Get history for a specific video file
  Future<List<ConversionHistory>> getForVideo(String sourceVideoId) async {
    final all = await getAll();
    return all.where((h) => h.sourceFile.id == sourceVideoId).toList();
  }

  /// Add a new history entry
  Future<void> add(ConversionHistory entry) async {
    final p = await prefs;
    final jsonList = p.getStringList(_historyKey) ?? [];

    // Add new entry at the beginning
    jsonList.insert(0, entry.toJsonString());

    // Limit the number of stored entries
    if (jsonList.length > _maxHistoryItems) {
      jsonList.removeRange(_maxHistoryItems, jsonList.length);
    }

    await p.setStringList(_historyKey, jsonList);
  }

  /// Update an existing history entry
  Future<void> update(ConversionHistory entry) async {
    final all = await getAll();
    final index = all.indexWhere((h) => h.id == entry.id);

    if (index != -1) {
      all[index] = entry;
      await _saveAll(all);
    }
  }

  /// Delete a history entry by ID
  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((h) => h.id == id);
    await _saveAll(all);
  }

  /// Delete multiple history entries
  Future<void> deleteMultiple(List<String> ids) async {
    final all = await getAll();
    all.removeWhere((h) => ids.contains(h.id));
    await _saveAll(all);
  }

  /// Clear all history
  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_historyKey);
  }

  /// Get total count of history entries
  Future<int> getCount() async {
    final all = await getAll();
    return all.length;
  }

  /// Get total size of all converted files (in bytes)
  Future<int> getTotalOutputSize() async {
    final all = await getAll();
    return all.fold<int>(0, (sum, h) => sum + h.outputSizeBytes);
  }

  /// Check if an output file exists in history
  Future<bool> hasOutputFile(String outputPath) async {
    final all = await getAll();
    return all.any((h) => h.outputPath == outputPath);
  }

  /// Get statistics
  Future<HistoryStats> getStats() async {
    final all = await getAll();

    if (all.isEmpty) {
      return HistoryStats.empty();
    }

    final totalInputSize = all.fold<int>(
      0,
      (sum, h) => sum + h.sourceFile.sizeInBytes,
    );
    final totalOutputSize = all.fold<int>(
      0,
      (sum, h) => sum + h.outputSizeBytes,
    );
    final totalDuration = all.fold<int>(
      0,
      (sum, h) => sum + h.conversionDurationMs,
    );
    final successCount = all.where((h) => h.isSuccessful).length;

    return HistoryStats(
      totalConversions: all.length,
      successfulConversions: successCount,
      totalInputSize: totalInputSize,
      totalOutputSize: totalOutputSize,
      totalConversionTime: Duration(milliseconds: totalDuration),
      averageCompressionRatio: totalInputSize > 0
          ? totalOutputSize / totalInputSize
          : 1.0,
    );
  }

  /// Save all history entries
  Future<void> _saveAll(List<ConversionHistory> history) async {
    final p = await prefs;
    final jsonList = history.map((h) => h.toJsonString()).toList();
    await p.setStringList(_historyKey, jsonList);
  }
}

/// Statistics about conversion history
class HistoryStats {
  final int totalConversions;
  final int successfulConversions;
  final int totalInputSize;
  final int totalOutputSize;
  final Duration totalConversionTime;
  final double averageCompressionRatio;

  const HistoryStats({
    required this.totalConversions,
    required this.successfulConversions,
    required this.totalInputSize,
    required this.totalOutputSize,
    required this.totalConversionTime,
    required this.averageCompressionRatio,
  });

  factory HistoryStats.empty() {
    return const HistoryStats(
      totalConversions: 0,
      successfulConversions: 0,
      totalInputSize: 0,
      totalOutputSize: 0,
      totalConversionTime: Duration.zero,
      averageCompressionRatio: 1.0,
    );
  }

  int get failedConversions => totalConversions - successfulConversions;

  double get successRate =>
      totalConversions > 0 ? successfulConversions / totalConversions : 0.0;

  String get formattedTotalInput => _formatSize(totalInputSize);
  String get formattedTotalOutput => _formatSize(totalOutputSize);
  String get formattedSavedSpace =>
      _formatSize(totalInputSize - totalOutputSize);

  String get compressionPercent {
    final saved = (1 - averageCompressionRatio) * 100;
    return '${saved.toStringAsFixed(1)}%';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
