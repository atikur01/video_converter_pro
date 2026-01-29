import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/video_file.dart';
import '../data/models/conversion_settings.dart';

/// Service for video conversion using FFmpeg
/// Handles all video processing operations with progress callbacks
class FFmpegService {
  /// Singleton instance
  static final FFmpegService _instance = FFmpegService._internal();
  factory FFmpegService() => _instance;
  FFmpegService._internal();

  /// Progress stream controller
  StreamController<ConversionProgress>? _progressController;

  /// Get the output directory for converted files
  Future<String> getOutputDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      // Use app-specific external storage directory to avoid Scoped Storage issues
      // This path is usually /storage/emulated/0/Android/data/com.app.video_converter_pro/files
      directory = await getExternalStorageDirectory();

      // Fallback if external storage is not available
      directory ??= await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final outputDir = Directory('${directory.path}/ConvertedVideos');

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    return outputDir.path;
  }

  /// Generate output file path
  Future<String> generateOutputPath(
    VideoFile source,
    ConversionSettings settings,
  ) async {
    final outputDir = await getOutputDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = source.baseName;
    final extension = settings.outputFormat;

    return '$outputDir/${baseName}_$timestamp.$extension';
  }

  /// Get video information using FFprobe
  Future<VideoInfo?> getVideoInfo(String inputPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(inputPath);
      final info = session.getMediaInformation();

      if (info == null) return null;

      final durationStr = info.getDuration();
      final duration = durationStr != null
          ? double.tryParse(durationStr)
          : null;

      final streams = info.getStreams();

      int? width;
      int? height;
      double? frameRate;
      int? bitrate;

      for (final stream in streams) {
        final type = stream.getType();

        if (type == 'video') {
          width = stream.getWidth();
          height = stream.getHeight();

          // Parse frame rate (e.g., "30/1" or "29.97")
          final fps = stream.getRealFrameRate() ?? stream.getAverageFrameRate();
          if (fps != null) {
            final fpsStr = fps.toString();
            if (fpsStr.contains('/')) {
              final parts = fpsStr.split('/');
              if (parts.length == 2) {
                final num = double.tryParse(parts[0]);
                final den = double.tryParse(parts[1]);
                if (num != null && den != null && den != 0) {
                  frameRate = num / den;
                }
              }
            } else {
              frameRate = double.tryParse(fpsStr);
            }
          }
          break;
        }
      }

      // Get bitrate
      final bitrateStr = info.getBitrate();
      if (bitrateStr != null) {
        bitrate = int.tryParse(bitrateStr);
        if (bitrate != null) {
          bitrate = bitrate ~/ 1000; // Convert to kbps
        }
      }

      return VideoInfo(
        durationMs: duration != null ? (duration * 1000).toInt() : null,
        width: width,
        height: height,
        frameRate: frameRate,
        bitrate: bitrate,
      );
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  /// Convert video with the given settings
  /// Returns a stream of progress updates
  Stream<ConversionProgress> convertVideo({
    required VideoFile source,
    required ConversionSettings settings,
    required String outputPath,
  }) {
    _progressController?.close();
    _progressController = StreamController<ConversionProgress>.broadcast();

    _startConversion(source, settings, outputPath);

    return _progressController!.stream;
  }

  /// Internal conversion logic
  Future<void> _startConversion(
    VideoFile source,
    ConversionSettings settings,
    String outputPath,
  ) async {
    try {
      // Build the FFmpeg command
      final command = _buildCommand(source, settings, outputPath);

      print('FFmpeg command: $command');

      // Emit starting state
      _progressController?.add(
        ConversionProgress(
          progress: 0,
          status: ConversionProgressStatus.starting,
          message: 'Preparing conversion...',
        ),
      );

      // Get video duration for progress calculation
      final videoInfo = await getVideoInfo(source.path);
      final totalDurationMs = videoInfo?.durationMs ?? source.durationMs ?? 0;

      // Execute the FFmpeg command with callbacks
      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            // Success
            final outputFile = File(outputPath);
            final outputSize = await outputFile.exists()
                ? await outputFile.length()
                : 0;

            _progressController?.add(
              ConversionProgress(
                progress: 1.0,
                status: ConversionProgressStatus.completed,
                message: 'Conversion complete!',
                outputPath: outputPath,
                outputSize: outputSize,
              ),
            );
          } else if (ReturnCode.isCancel(returnCode)) {
            // Cancelled
            _progressController?.add(
              ConversionProgress(
                progress: 0,
                status: ConversionProgressStatus.cancelled,
                message: 'Conversion cancelled',
              ),
            );

            // Clean up incomplete file
            final outputFile = File(outputPath);
            if (await outputFile.exists()) {
              await outputFile.delete();
            }
          } else {
            // Failed
            final logs = await session.getAllLogsAsString();
            _progressController?.add(
              ConversionProgress(
                progress: 0,
                status: ConversionProgressStatus.failed,
                message: 'Conversion failed',
                error: 'FFmpeg exited with code $returnCode. Logs: $logs',
              ),
            );
          }

          // Cleanup
          await _progressController?.close();
        },
        (log) {
          // Optional: handle logs
          print(log.getMessage());
        },
        (statistics) {
          final time = statistics.getTime();
          if (time > 0 && totalDurationMs > 0) {
            final progress = (time / totalDurationMs).clamp(0.0, 1.0);
            final eta = _calculateETA(time.toDouble(), totalDurationMs);

            _progressController?.add(
              ConversionProgress(
                progress: progress,
                status: ConversionProgressStatus.converting,
                message: 'Converting...',
                timeProcessedMs: time.toInt(),
                estimatedTimeRemainingMs: eta,
                bitrate: statistics.getBitrate(),
                speed: statistics.getSpeed(),
              ),
            );
          }
        },
      );
    } catch (e) {
      _progressController?.add(
        ConversionProgress(
          progress: 0,
          status: ConversionProgressStatus.failed,
          message: 'Error occurred',
          error: e.toString(),
        ),
      );
      await _progressController?.close();
    }
  }

  /// Build the FFmpeg command string
  String _buildCommand(
    VideoFile source,
    ConversionSettings settings,
    String outputPath,
  ) {
    final List<String> args = [];

    // Overwrite output file if exists
    args.add('-y');

    // Input file
    args.add('-i "${source.path}"');

    if (settings.type == ConversionType.audio) {
      // Audio extraction - no video
      args.add('-vn');
      args.add('-acodec ${settings.codec}');

      // Audio bitrate
      if (settings.codec == 'libmp3lame') {
        // Use quality setting for MP3
        args.add('-q:a 2');
      } else if (settings.codec != 'pcm_s16le') {
        args.add('-b:a ${settings.audioBitrate}k');
      }
    } else {
      // Video conversion

      // Video codec
      args.add('-c:v ${settings.codec}');

      // Resolution scaling
      if (!settings.isOriginalResolution) {
        // Scale to target resolution, maintaining aspect ratio
        args.add(
          '-vf "scale=${settings.targetWidth}:${settings.targetHeight}:force_original_aspect_ratio=decrease,pad=${settings.targetWidth}:${settings.targetHeight}:(ow-iw)/2:(oh-ih)/2"',
        );
      }

      // Frame rate
      if (!settings.isOriginalFps) {
        args.add('-r ${settings.targetFps}');
      }

      // Bitrate / Quality
      if (settings.autoBitrate) {
        // Use CRF for quality-based encoding
        args.add('-crf ${settings.qualityCrf}');
        args.add('-preset ${settings.qualityPreset}');
      } else {
        // Use target bitrate
        args.add('-b:v ${settings.targetBitrate}k');
        args.add('-preset ${settings.qualityPreset}');
      }

      // Audio settings for video output
      args.add('-c:a aac');
      args.add('-b:a 192k');
    }

    // Output file
    args.add('"$outputPath"');

    return args.join(' ');
  }

  /// Calculate estimated time remaining
  int _calculateETA(double currentTimeMs, int totalDurationMs) {
    if (currentTimeMs <= 0) return 0;

    final progress = currentTimeMs / totalDurationMs;
    if (progress <= 0) return 0;

    final remaining = (1 - progress) / progress * currentTimeMs;
    return remaining.toInt();
  }

  /// Cancel the current conversion
  Future<void> cancelConversion() async {
    await FFmpegKit.cancel();
  }

  /// Cancel all running conversions
  Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }

  /// Dispose resources
  void dispose() {
    _progressController?.close();
    _progressController = null;
  }
}

/// Video information from FFprobe
class VideoInfo {
  final int? durationMs;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? bitrate;

  VideoInfo({
    this.durationMs,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
  });
}

/// Progress update during conversion
class ConversionProgress {
  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Current status
  final ConversionProgressStatus status;

  /// Human-readable message
  final String message;

  /// Time processed so far in milliseconds
  final int? timeProcessedMs;

  /// Estimated time remaining in milliseconds
  final int? estimatedTimeRemainingMs;

  /// Current bitrate
  final double? bitrate;

  /// Current speed (e.g., 1.5x)
  final double? speed;

  /// Output file path (only when completed)
  final String? outputPath;

  /// Output file size in bytes (only when completed)
  final int? outputSize;

  /// Error message (only when failed)
  final String? error;

  ConversionProgress({
    required this.progress,
    required this.status,
    required this.message,
    this.timeProcessedMs,
    this.estimatedTimeRemainingMs,
    this.bitrate,
    this.speed,
    this.outputPath,
    this.outputSize,
    this.error,
  });

  /// Get progress as percentage
  int get progressPercent => (progress * 100).round();

  /// Get formatted ETA
  String get formattedETA {
    if (estimatedTimeRemainingMs == null || estimatedTimeRemainingMs! <= 0) {
      return '--:--';
    }

    final duration = Duration(milliseconds: estimatedTimeRemainingMs!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Check if completed successfully
  bool get isCompleted => status == ConversionProgressStatus.completed;

  /// Check if failed
  bool get isFailed => status == ConversionProgressStatus.failed;

  /// Check if cancelled
  bool get isCancelled => status == ConversionProgressStatus.cancelled;

  /// Check if still in progress
  bool get isInProgress =>
      status == ConversionProgressStatus.converting ||
      status == ConversionProgressStatus.starting;
}

/// Status of an ongoing conversion
enum ConversionProgressStatus {
  starting,
  converting,
  completed,
  failed,
  cancelled,
}
