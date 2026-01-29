import 'dart:convert';
import 'dart:typed_data';
import 'video_file.dart';
import 'conversion_settings.dart';

/// Model representing a completed conversion in history
/// Stores both source and output information
class ConversionHistory {
  /// Unique identifier
  final String id;

  /// Original source video info
  final VideoFile sourceFile;

  /// Path to the converted output file
  final String outputPath;

  /// Name of the output file
  final String outputName;

  /// Size of output file in bytes
  final int outputSizeBytes;

  /// Settings used for this conversion
  final ConversionSettings settings;

  /// When the conversion started
  final DateTime startedAt;

  /// When the conversion completed
  final DateTime completedAt;

  /// Duration of conversion in milliseconds
  final int conversionDurationMs;

  /// Status of the conversion
  final ConversionStatus status;

  /// Error message if failed
  final String? errorMessage;

  /// Thumbnail of the output video (generated lazily)
  final Uint8List? thumbnail;

  ConversionHistory({
    required this.id,
    required this.sourceFile,
    required this.outputPath,
    required this.outputName,
    required this.outputSizeBytes,
    required this.settings,
    required this.startedAt,
    required this.completedAt,
    required this.conversionDurationMs,
    this.status = ConversionStatus.completed,
    this.errorMessage,
    this.thumbnail,
  });

  /// Create a new history entry when conversion completes
  factory ConversionHistory.create({
    required VideoFile sourceFile,
    required String outputPath,
    required ConversionSettings settings,
    required DateTime startedAt,
    required int outputSizeBytes,
    ConversionStatus status = ConversionStatus.completed,
    String? errorMessage,
    Uint8List? thumbnail,
  }) {
    final now = DateTime.now();
    final outputName = outputPath.split('/').last.split('\\').last;

    return ConversionHistory(
      id: '${now.millisecondsSinceEpoch}_${sourceFile.id}',
      sourceFile: sourceFile,
      outputPath: outputPath,
      outputName: outputName,
      outputSizeBytes: outputSizeBytes,
      settings: settings,
      startedAt: startedAt,
      completedAt: now,
      conversionDurationMs: now.difference(startedAt).inMilliseconds,
      status: status,
      errorMessage: errorMessage,
      thumbnail: thumbnail,
    );
  }

  /// Copy with new values
  ConversionHistory copyWith({
    String? id,
    VideoFile? sourceFile,
    String? outputPath,
    String? outputName,
    int? outputSizeBytes,
    ConversionSettings? settings,
    DateTime? startedAt,
    DateTime? completedAt,
    int? conversionDurationMs,
    ConversionStatus? status,
    String? errorMessage,
    Uint8List? thumbnail,
  }) {
    return ConversionHistory(
      id: id ?? this.id,
      sourceFile: sourceFile ?? this.sourceFile,
      outputPath: outputPath ?? this.outputPath,
      outputName: outputName ?? this.outputName,
      outputSizeBytes: outputSizeBytes ?? this.outputSizeBytes,
      settings: settings ?? this.settings,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      conversionDurationMs: conversionDurationMs ?? this.conversionDurationMs,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  /// Get formatted output file size
  String get formattedOutputSize {
    if (outputSizeBytes < 1024) {
      return '$outputSizeBytes B';
    } else if (outputSizeBytes < 1024 * 1024) {
      return '${(outputSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (outputSizeBytes < 1024 * 1024 * 1024) {
      return '${(outputSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(outputSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Get formatted conversion duration
  String get formattedConversionDuration {
    final duration = Duration(milliseconds: conversionDurationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  /// Get compression ratio
  double get compressionRatio {
    if (sourceFile.sizeInBytes == 0) return 1.0;
    return outputSizeBytes / sourceFile.sizeInBytes;
  }

  /// Get compression percentage (positive = smaller, negative = larger)
  String get compressionDisplay {
    final percent = ((1 - compressionRatio) * 100).toStringAsFixed(1);
    if (compressionRatio < 1) {
      return '-$percent%';
    } else if (compressionRatio > 1) {
      return '+${((compressionRatio - 1) * 100).toStringAsFixed(1)}%';
    }
    return 'Same size';
  }

  /// Get time ago string for display (e.g., "2 hours ago")
  String get timeAgo {
    final diff = DateTime.now().difference(completedAt);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if this is a successful conversion
  bool get isSuccessful => status == ConversionStatus.completed;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceFile': sourceFile.toJson(),
      'outputPath': outputPath,
      'outputName': outputName,
      'outputSizeBytes': outputSizeBytes,
      'settings': settings.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'conversionDurationMs': conversionDurationMs,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    return ConversionHistory(
      id: json['id'] as String,
      sourceFile: VideoFile.fromJson(
        json['sourceFile'] as Map<String, dynamic>,
      ),
      outputPath: json['outputPath'] as String,
      outputName: json['outputName'] as String,
      outputSizeBytes: json['outputSizeBytes'] as int,
      settings: ConversionSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      conversionDurationMs: json['conversionDurationMs'] as int,
      status: ConversionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversionStatus.completed,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON string
  factory ConversionHistory.fromJsonString(String jsonString) {
    return ConversionHistory.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  String toString() {
    return 'ConversionHistory(source: ${sourceFile.name}, output: $outputName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversionHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Status of a conversion
enum ConversionStatus { pending, converting, completed, failed, cancelled }
