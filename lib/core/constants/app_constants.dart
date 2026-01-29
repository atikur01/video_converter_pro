/// App-wide constants for Video Converter Pro
/// Contains all the configuration values for video formats, resolutions, etc.

class AppConstants {
  // App Info
  static const String appName = 'Video Converter Pro';
  static const String appVersion = '1.0.0';

  // Animation Durations
  static const Duration splashDuration = Duration(milliseconds: 2500);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // UI Constants
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double cardElevation = 0.0;
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.1;

  // Video Formats
  static const List<VideoFormat> videoFormats = [
    VideoFormat(
      name: 'MP4',
      extension: 'mp4',
      codec: 'libx264',
      description: 'Most compatible',
      icon: '📹',
    ),
    VideoFormat(
      name: 'MKV',
      extension: 'mkv',
      codec: 'libx264',
      description: 'High quality',
      icon: '🎬',
    ),
    VideoFormat(
      name: 'AVI',
      extension: 'avi',
      codec: 'libxvid',
      description: 'Legacy format',
      icon: '📼',
    ),
    VideoFormat(
      name: 'MOV',
      extension: 'mov',
      codec: 'libx264',
      description: 'Apple format',
      icon: '🍎',
    ),
    VideoFormat(
      name: 'WEBM',
      extension: 'webm',
      codec: 'libvpx-vp9',
      description: 'Web optimized',
      icon: '🌐',
    ),
    VideoFormat(
      name: 'FLV',
      extension: 'flv',
      codec: 'flv',
      description: 'Flash video',
      icon: '⚡',
    ),
  ];

  // Audio Formats (for video to audio conversion)
  static const List<AudioFormat> audioFormats = [
    AudioFormat(
      name: 'MP3',
      extension: 'mp3',
      codec: 'libmp3lame',
      description: 'Universal audio',
      icon: '🎵',
      defaultBitrate: 320,
    ),
    AudioFormat(
      name: 'AAC',
      extension: 'aac',
      codec: 'aac',
      description: 'High quality',
      icon: '🎧',
      defaultBitrate: 256,
    ),
    AudioFormat(
      name: 'WAV',
      extension: 'wav',
      codec: 'pcm_s16le',
      description: 'Lossless',
      icon: '🔊',
      defaultBitrate: 1411,
    ),
    AudioFormat(
      name: 'M4A',
      extension: 'm4a',
      codec: 'aac',
      description: 'Apple audio',
      icon: '🍏',
      defaultBitrate: 256,
    ),
  ];

  // Resolution Presets
  static const List<ResolutionPreset> resolutionPresets = [
    ResolutionPreset(
      name: '4K Ultra HD',
      shortName: '4K',
      width: 3840,
      height: 2160,
      icon: '🖥️',
    ),
    ResolutionPreset(
      name: 'Full HD',
      shortName: '1080p',
      width: 1920,
      height: 1080,
      icon: '📺',
    ),
    ResolutionPreset(
      name: 'HD',
      shortName: '720p',
      width: 1280,
      height: 720,
      icon: '📱',
    ),
    ResolutionPreset(
      name: 'SD',
      shortName: '480p',
      width: 854,
      height: 480,
      icon: '📲',
    ),
    ResolutionPreset(
      name: 'Original',
      shortName: 'Auto',
      width: 0,
      height: 0,
      icon: '✨',
    ),
  ];

  // Frame Rate Presets
  static const List<FrameRatePreset> frameRatePresets = [
    FrameRatePreset(
      name: 'Cinematic',
      fps: 24,
      description: 'Film-like motion',
    ),
    FrameRatePreset(name: 'Standard', fps: 30, description: 'Smooth playback'),
    FrameRatePreset(name: 'Smooth', fps: 60, description: 'Ultra smooth'),
    FrameRatePreset(name: 'Original', fps: 0, description: 'Keep original'),
  ];

  // Bitrate Presets (in kbps)
  static const int bitrateMin = 500;
  static const int bitrateMax = 50000;
  static const int bitrateDefault = 8000;

  // Quality Modes
  static const List<QualityMode> qualityModes = [
    QualityMode(
      name: 'High Quality',
      preset: 'slow',
      crf: 18,
      description: 'Best quality, slower',
      icon: '💎',
    ),
    QualityMode(
      name: 'Balanced',
      preset: 'medium',
      crf: 23,
      description: 'Good balance',
      icon: '⚖️',
    ),
    QualityMode(
      name: 'Fast',
      preset: 'veryfast',
      crf: 28,
      description: 'Quick conversion',
      icon: '🚀',
    ),
  ];
  // Default Configuration
  static const String defaultFormat = 'mp4';
  static const int defaultQualityIndex = 1; // Balanced
  static const int defaultResolutionIndex = 3; // 480p (SD)
  static const int defaultFpsIndex = 3; // Original
}

/// Video format configuration
class VideoFormat {
  final String name;
  final String extension;
  final String codec;
  final String description;
  final String icon;

  const VideoFormat({
    required this.name,
    required this.extension,
    required this.codec,
    required this.description,
    required this.icon,
  });
}

/// Audio format configuration
class AudioFormat {
  final String name;
  final String extension;
  final String codec;
  final String description;
  final String icon;
  final int defaultBitrate;

  const AudioFormat({
    required this.name,
    required this.extension,
    required this.codec,
    required this.description,
    required this.icon,
    required this.defaultBitrate,
  });
}

/// Resolution preset configuration
class ResolutionPreset {
  final String name;
  final String shortName;
  final int width;
  final int height;
  final String icon;

  const ResolutionPreset({
    required this.name,
    required this.shortName,
    required this.width,
    required this.height,
    required this.icon,
  });

  bool get isOriginal => width == 0 && height == 0;
}

/// Frame rate preset configuration
class FrameRatePreset {
  final String name;
  final int fps;
  final String description;

  const FrameRatePreset({
    required this.name,
    required this.fps,
    required this.description,
  });

  bool get isOriginal => fps == 0;
}

/// Quality mode configuration
class QualityMode {
  final String name;
  final String preset;
  final int crf;
  final String description;
  final String icon;

  const QualityMode({
    required this.name,
    required this.preset,
    required this.crf,
    required this.description,
    required this.icon,
  });
}
