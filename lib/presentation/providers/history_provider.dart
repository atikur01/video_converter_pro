import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/conversion_history.dart';
import '../../data/repositories/history_repository.dart';
import '../../services/file_service.dart';
import '../../services/haptic_service.dart';

/// Provider for managing conversion history
class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _repository = HistoryRepository();
  final FileService _fileService = FileService();
  final HapticService _hapticService = HapticService();

  // ============ State ============
  List<ConversionHistory> _history = [];
  List<ConversionHistory> _recentHistory = [];
  HistoryStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  // ============ Getters ============
  List<ConversionHistory> get history => _history;
  List<ConversionHistory> get recentHistory => _recentHistory;
  HistoryStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasHistory => _history.isNotEmpty;
  bool get hasRecentHistory => _recentHistory.isNotEmpty;
  int get historyCount => _history.length;

  // ============ Initialization ============

  /// Initialize the provider and load history
  Future<void> init() async {
    await _repository.init();
    await loadHistory();
  }

  /// Load all history entries
  Future<void> loadHistory() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final allHistory = await _repository.getAll();

      // Filter out missing files and generate thumbnails
      final existingHistory = <ConversionHistory>[];
      final missingIds = <String>[];

      for (final entry in allHistory) {
        if (await _fileService.fileExists(entry.outputPath)) {
          // Generate thumbnail if not sufficient
          Uint8List? thumbnailData;
          try {
            thumbnailData = await VideoThumbnail.thumbnailData(
              video: entry.outputPath,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 200,
              quality: 50,
            );
          } catch (e) {
            debugPrint(
              'Error generating thumbnail for ${entry.outputPath}: $e',
            );
          }

          existingHistory.add(entry.copyWith(thumbnail: thumbnailData));
        } else {
          missingIds.add(entry.id);
        }
      }

      _history = existingHistory;
      // Re-sort or ensure order if needed, assuming getAll returns sorted
      _recentHistory = _history.take(5).toList();

      // Get stats (initially this might include missing files until delete completes)
      // If we want accurate stats immediately, we might need to calculate locally
      // But for now, let's just get repo stats, and they will update after background delete
      _stats = await _repository.getStats();

      _isLoading = false;
      notifyListeners();

      // Background cleanup of missing files from DB
      if (missingIds.isNotEmpty) {
        _repository.deleteMultiple(missingIds).then((_) async {
          // Update stats after deletion
          _stats = await _repository.getStats();
          notifyListeners();
        });
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh history (alias for loadHistory)
  Future<void> refresh() => loadHistory();

  // ============ CRUD Operations ============

  /// Add a new history entry
  Future<void> addEntry(ConversionHistory entry) async {
    try {
      await _repository.add(entry);
      await loadHistory();
      _hapticService.lightImpact();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete a history entry
  Future<void> deleteEntry(String id) async {
    try {
      // Find the entry to get the output path
      final entry = _history.firstWhere(
        (h) => h.id == id,
        orElse: () => throw Exception('Entry not found'),
      );

      // Optionally delete the output file
      await _fileService.deleteFile(entry.outputPath);

      // Delete from repository
      await _repository.delete(id);
      await loadHistory();

      _hapticService.lightImpact();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete multiple entries
  Future<void> deleteMultiple(List<String> ids) async {
    try {
      // Delete output files
      for (final id in ids) {
        final entry = _history.firstWhere(
          (h) => h.id == id,
          orElse: () => throw Exception('Entry not found'),
        );
        await _fileService.deleteFile(entry.outputPath);
      }

      await _repository.deleteMultiple(ids);
      await loadHistory();

      _hapticService.mediumImpact();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear all history
  Future<void> clearAll({bool deleteFiles = false}) async {
    try {
      if (deleteFiles) {
        // Delete all output files
        for (final entry in _history) {
          await _fileService.deleteFile(entry.outputPath);
        }
      }

      await _repository.clearAll();
      _history = [];
      _recentHistory = [];
      _stats = HistoryStats.empty();

      _hapticService.mediumImpact();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ============ Queries ============

  /// Get history entries for a specific source video
  Future<List<ConversionHistory>> getForVideo(String sourceVideoId) async {
    return _repository.getForVideo(sourceVideoId);
  }

  /// Check if output file still exists
  Future<bool> outputFileExists(ConversionHistory entry) async {
    return _fileService.fileExists(entry.outputPath);
  }

  /// Get entries filtered by date range
  List<ConversionHistory> getByDateRange(DateTime start, DateTime end) {
    return _history.where((h) {
      return h.completedAt.isAfter(start) && h.completedAt.isBefore(end);
    }).toList();
  }

  /// Get entries filtered by format
  List<ConversionHistory> getByFormat(String format) {
    return _history.where((h) {
      return h.settings.outputFormat == format;
    }).toList();
  }

  /// Get successful conversions only
  List<ConversionHistory> get successfulConversions {
    return _history.where((h) => h.isSuccessful).toList();
  }

  /// Get failed conversions only
  List<ConversionHistory> get failedConversions {
    return _history.where((h) => !h.isSuccessful).toList();
  }

  // ============ Stats ============

  /// Refresh statistics
  Future<void> refreshStats() async {
    _stats = await _repository.getStats();
    notifyListeners();
  }

  /// Get total space used by output files
  Future<int> getTotalSpaceUsed() async {
    return _fileService.getOutputDirectorySize();
  }

  /// Get formatted space used
  Future<String> getFormattedSpaceUsed() async {
    final bytes = await getTotalSpaceUsed();
    return _fileService.formatFileSize(bytes);
  }

  // ============ Cleanup ============

  /// Remove entries with missing output files
  Future<void> cleanupMissingFiles() async {
    try {
      final toRemove = <String>[];

      for (final entry in _history) {
        final exists = await _fileService.fileExists(entry.outputPath);
        if (!exists) {
          toRemove.add(entry.id);
        }
      }

      if (toRemove.isNotEmpty) {
        await _repository.deleteMultiple(toRemove);
        await loadHistory();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
