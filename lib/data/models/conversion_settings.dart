import '../../core/constants/app_constants.dart';

/// Model for conversion settings selected by the user
/// Contains all configuration options for the FFmpeg conversion
class ConversionSettings {
  /// Type of conversion (video or audio)
  final ConversionType type;

  /// Output format (video or audio depending on type)
  final String outputFormat;

  /// Codec to use for encoding
  final String codec;

  /// Output resolution (0 = keep original)
  final int targetWidth;
  final int targetHeight;

  /// Target frame rate (0 = keep original)
  final int targetFps;

  /// Target bitrate in kbps (0 = auto/CRF-based)
  final int targetBitrate;

  /// Use auto bitrate (CRF-based quality)
  final bool autoBitrate;

  /// Quality mode settings
  final String qualityPreset;
  final int qualityCrf;

  /// Audio bitrate for audio output (in kbps)
  final int audioBitrate;

  const ConversionSettings({
    this.type = ConversionType.video,
    this.outputFormat = 'mp4',
    this.codec = 'libx264',
    this.targetWidth = 0,
    this.targetHeight = 0,
    this.targetFps = 0,
    this.targetBitrate = 0,
    this.autoBitrate = true,
    this.qualityPreset = 'medium',
    this.qualityCrf = 23,
    this.audioBitrate = 192,
  });

  /// Get default settings for video conversion
  factory ConversionSettings.defaultVideo() {
    return const ConversionSettings(
      type: ConversionType.video,
      outputFormat: 'mp4',
      codec: 'libx264',
      targetWidth: 854,
      targetHeight: 480,
      qualityPreset: 'medium',
      qualityCrf: 23,
      autoBitrate: true,
    );
  }

  /// Get default settings for audio extraction
  factory ConversionSettings.defaultAudio() {
    return const ConversionSettings(
      type: ConversionType.audio,
      outputFormat: 'mp3',
      codec: 'libmp3lame',
      audioBitrate: 320,
    );
  }

  /// Create settings from a video format preset
  factory ConversionSettings.fromVideoFormat(VideoFormat format) {
    return ConversionSettings(
      type: ConversionType.video,
      outputFormat: format.extension,
      codec: format.codec,
    );
  }

  /// Create settings from an audio format preset
  factory ConversionSettings.fromAudioFormat(AudioFormat format) {
    return ConversionSettings(
      type: ConversionType.audio,
      outputFormat: format.extension,
      codec: format.codec,
      audioBitrate: format.defaultBitrate,
    );
  }

  /// Create settings from a resolution preset
  ConversionSettings withResolution(ResolutionPreset resolution) {
    return copyWith(
      targetWidth: resolution.width,
      targetHeight: resolution.height,
    );
  }

  /// Create settings from a frame rate preset
  ConversionSettings withFrameRate(FrameRatePreset frameRate) {
    return copyWith(targetFps: frameRate.fps);
  }

  /// Create settings from a quality mode
  ConversionSettings withQualityMode(QualityMode mode) {
    return copyWith(qualityPreset: mode.preset, qualityCrf: mode.crf);
  }

  /// Check if keeping original resolution
  bool get isOriginalResolution => targetWidth == 0 && targetHeight == 0;

  /// Check if keeping original frame rate
  bool get isOriginalFps => targetFps == 0;

  /// Get resolution display string
  String get resolutionDisplay {
    if (isOriginalResolution) return 'Original';
    return '${targetWidth}x$targetHeight';
  }

  /// Get FPS display string
  String get fpsDisplay {
    if (isOriginalFps) return 'Original';
    return '$targetFps fps';
  }

  /// Get bitrate display string
  String get bitrateDisplay {
    if (autoBitrate) return 'Auto';
    if (targetBitrate < 1000) return '$targetBitrate kbps';
    return '${(targetBitrate / 1000).toStringAsFixed(1)} Mbps';
  }

  /// Copy with new values
  ConversionSettings copyWith({
    ConversionType? type,
    String? outputFormat,
    String? codec,
    int? targetWidth,
    int? targetHeight,
    int? targetFps,
    int? targetBitrate,
    bool? autoBitrate,
    String? qualityPreset,
    int? qualityCrf,
    int? audioBitrate,
  }) {
    return ConversionSettings(
      type: type ?? this.type,
      outputFormat: outputFormat ?? this.outputFormat,
      codec: codec ?? this.codec,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      targetFps: targetFps ?? this.targetFps,
      targetBitrate: targetBitrate ?? this.targetBitrate,
      autoBitrate: autoBitrate ?? this.autoBitrate,
      qualityPreset: qualityPreset ?? this.qualityPreset,
      qualityCrf: qualityCrf ?? this.qualityCrf,
      audioBitrate: audioBitrate ?? this.audioBitrate,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'outputFormat': outputFormat,
      'codec': codec,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
      'targetFps': targetFps,
      'targetBitrate': targetBitrate,
      'autoBitrate': autoBitrate,
      'qualityPreset': qualityPreset,
      'qualityCrf': qualityCrf,
      'audioBitrate': audioBitrate,
    };
  }

  /// Create from JSON
  factory ConversionSettings.fromJson(Map<String, dynamic> json) {
    return ConversionSettings(
      type: ConversionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConversionType.video,
      ),
      outputFormat: json['outputFormat'] as String? ?? 'mp4',
      codec: json['codec'] as String? ?? 'libx264',
      targetWidth: json['targetWidth'] as int? ?? 0,
      targetHeight: json['targetHeight'] as int? ?? 0,
      targetFps: json['targetFps'] as int? ?? 0,
      targetBitrate: json['targetBitrate'] as int? ?? 0,
      autoBitrate: json['autoBitrate'] as bool? ?? true,
      qualityPreset: json['qualityPreset'] as String? ?? 'medium',
      qualityCrf: json['qualityCrf'] as int? ?? 23,
      audioBitrate: json['audioBitrate'] as int? ?? 192,
    );
  }

  @override
  String toString() {
    return 'ConversionSettings(type: $type, format: $outputFormat, resolution: $resolutionDisplay, fps: $fpsDisplay)';
  }
}

/// Type of conversion
enum ConversionType { video, audio }
