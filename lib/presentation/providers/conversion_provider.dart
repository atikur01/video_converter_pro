import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/video_file.dart';
import '../../data/models/conversion_settings.dart';
import '../../data/models/conversion_history.dart';
import '../../data/repositories/history_repository.dart';
import '../../services/ffmpeg_service.dart';
import '../../services/file_service.dart';
import '../../services/haptic_service.dart';

/// State of the conversion process
enum ConversionState {
  idle, // No conversion in progress
  selecting, // User is selecting a video
  configuring, // User is configuring settings
  converting, // Conversion in progress
  completed, // Conversion completed successfully
  failed, // Conversion failed
  cancelled, // User cancelled conversion
}

/// Provider for managing video conversion state
class ConversionProvider extends ChangeNotifier {
  final FFmpegService _ffmpegService = FFmpegService();
  final FileService _fileService = FileService();
  final HapticService _hapticService = HapticService();
  final HistoryRepository _historyRepository = HistoryRepository();

  // ============ State ============
  ConversionState _state = ConversionState.idle;
  VideoFile? _selectedVideo;
  ConversionSettings _settings = ConversionSettings.defaultVideo();
  ConversionProgress? _progress;
  String? _errorMessage;
  String? _outputPath;
  DateTime? _startTime;

  // Batch conversion
  List<VideoFile> _batchVideos = [];
  int _currentBatchIndex = 0;
  bool _isBatchMode = false;

  // ============ Getters ============
  ConversionState get state => _state;
  VideoFile? get selectedVideo => _selectedVideo;
  ConversionSettings get settings => _settings;
  ConversionProgress? get progress => _progress;
  String? get errorMessage => _errorMessage;
  String? get outputPath => _outputPath;
  DateTime? get startTime => _startTime;

  // Batch getters
  List<VideoFile> get batchVideos => _batchVideos;
  int get currentBatchIndex => _currentBatchIndex;
  bool get isBatchMode => _isBatchMode;
  int get totalBatchCount => _batchVideos.length;
  bool get hasBatchVideos => _batchVideos.isNotEmpty;

  // Computed getters
  bool get hasSelectedVideo => _selectedVideo != null;
  bool get isConverting => _state == ConversionState.converting;
  bool get isCompleted => _state == ConversionState.completed;
  bool get isFailed => _state == ConversionState.failed;
  bool get canStartConversion => hasSelectedVideo && !isConverting;

  double get progressValue => _progress?.progress ?? 0.0;
  int get progressPercent => _progress?.progressPercent ?? 0;
  String get progressMessage => _progress?.message ?? '';
  String get estimatedTimeRemaining => _progress?.formattedETA ?? '--:--';

  // ============ Video Selection ============

  /// Pick a video file from device
  Future<void> pickVideo() async {
    try {
      _setState(ConversionState.selecting);

      final video = await _fileService.pickVideo();

      if (video != null) {
        _selectedVideo = video;
        _hapticService.lightImpact();
        _setState(ConversionState.configuring);
      } else {
        _setState(ConversionState.idle);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hapticService.error();
      _setState(ConversionState.idle);
    }
  }

  /// Pick multiple videos for batch conversion
  Future<void> pickMultipleVideos() async {
    try {
      _setState(ConversionState.selecting);

      final videos = await _fileService.pickMultipleVideos();

      if (videos.isNotEmpty) {
        _batchVideos = videos;
        _selectedVideo = videos.first;
        _isBatchMode = true;
        _currentBatchIndex = 0;
        _hapticService.lightImpact();
        _setState(ConversionState.configuring);
      } else {
        _setState(ConversionState.idle);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hapticService.error();
      _setState(ConversionState.idle);
    }
  }

  /// Set video directly (for re-conversion from history)
  void setVideo(VideoFile video) {
    _selectedVideo = video;
    _isBatchMode = false;
    _batchVideos = [];
    _hapticService.lightImpact();
    _setState(ConversionState.configuring);
  }

  /// Clear selected video
  void clearVideo() {
    _selectedVideo = null;
    _isBatchMode = false;
    _batchVideos = [];
    _currentBatchIndex = 0;
    _progress = null;
    _errorMessage = null;
    _outputPath = null;
    _setState(ConversionState.idle);
  }

  // ============ Settings ============

  /// Update conversion settings
  void updateSettings(ConversionSettings newSettings) {
    _settings = newSettings;
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set output format
  void setOutputFormat(String format, String codec) {
    _settings = _settings.copyWith(outputFormat: format, codec: codec);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set conversion type (video or audio)
  void setConversionType(ConversionType type) {
    if (type == ConversionType.audio) {
      _settings = ConversionSettings.defaultAudio();
    } else {
      _settings = ConversionSettings.defaultVideo();
    }
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set resolution
  void setResolution(int width, int height) {
    _settings = _settings.copyWith(targetWidth: width, targetHeight: height);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set frame rate
  void setFrameRate(int fps) {
    _settings = _settings.copyWith(targetFps: fps);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set bitrate
  void setBitrate(int bitrate, {bool auto = false}) {
    _settings = _settings.copyWith(targetBitrate: bitrate, autoBitrate: auto);
    _hapticService.selectionClick();
    notifyListeners();
  }

  /// Set quality mode
  void setQualityMode(String preset, int crf) {
    _settings = _settings.copyWith(qualityPreset: preset, qualityCrf: crf);
    _hapticService.selectionClick();
    notifyListeners();
  }

  // ============ Conversion ============

  /// Start the conversion process
  Future<void> startConversion() async {
    if (_selectedVideo == null) return;

    try {
      _setState(ConversionState.converting);
      _startTime = DateTime.now();
      _errorMessage = null;
      _hapticService.mediumImpact();

      // Generate output path
      _outputPath = await _ffmpegService.generateOutputPath(
        _selectedVideo!,
        _settings,
      );

      // Start conversion and listen to progress
      final progressStream = _ffmpegService.convertVideo(
        source: _selectedVideo!,
        settings: _settings,
        outputPath: _outputPath!,
      );

      await for (final progress in progressStream) {
        _progress = progress;
        notifyListeners();

        if (progress.isCompleted) {
          await _handleConversionComplete(progress);
          break;
        } else if (progress.isFailed) {
          _errorMessage = progress.error;
          _hapticService.error();
          _setState(ConversionState.failed);
          break;
        } else if (progress.isCancelled) {
          _hapticService.warning();
          _setState(ConversionState.cancelled);
          break;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _hapticService.error();
      _setState(ConversionState.failed);
    }
  }

  /// Handle successful conversion
  Future<void> _handleConversionComplete(ConversionProgress progress) async {
    // Save to history
    final historyEntry = ConversionHistory.create(
      sourceFile: _selectedVideo!,
      outputPath: progress.outputPath!,
      settings: _settings,
      startedAt: _startTime!,
      outputSizeBytes: progress.outputSize ?? 0,
    );

    await _historyRepository.add(historyEntry);

    _hapticService.success();
    _setState(ConversionState.completed);

    // Handle batch mode
    if (_isBatchMode && _currentBatchIndex < _batchVideos.length - 1) {
      // Automatically start next conversion after a short delay
      await Future.delayed(const Duration(seconds: 1));
      _currentBatchIndex++;
      _selectedVideo = _batchVideos[_currentBatchIndex];
      await startConversion();
    }
  }

  /// Cancel the current conversion
  Future<void> cancelConversion() async {
    await _ffmpegService.cancelConversion();
    _hapticService.warning();
  }

  // ============ Reset ============

  /// Reset to idle state
  void reset() {
    _selectedVideo = null;
    _progress = null;
    _errorMessage = null;
    _outputPath = null;
    _startTime = null;
    _isBatchMode = false;
    _batchVideos = [];
    _currentBatchIndex = 0;
    _settings = ConversionSettings.defaultVideo();
    _setState(ConversionState.idle);
  }

  /// Reset for next conversion (keeps video cleared)
  void resetForNext() {
    _selectedVideo = null;
    _progress = null;
    _errorMessage = null;
    _outputPath = null;
    _startTime = null;
    _setState(ConversionState.idle);
  }

  // ============ Helpers ============

  void _setState(ConversionState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _ffmpegService.dispose();
    super.dispose();
  }
}
