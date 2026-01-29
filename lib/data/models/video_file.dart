import 'dart:io';
import 'dart:typed_data';

/// Model representing a video file selected for conversion
/// Contains metadata about the source video
class VideoFile {
  /// Unique identifier for this video
  final String id;

  /// Full path to the video file
  final String path;

  /// File name including extension
  final String name;

  /// File name without extension
  final String baseName;

  /// File extension (e.g., 'mp4', 'mkv')
  final String extension;

  /// File size in bytes
  final int sizeInBytes;

  /// Video duration in milliseconds
  final int? durationMs;

  /// Video width in pixels
  final int? width;

  /// Video height in pixels
  final int? height;

  /// Video frame rate
  final double? frameRate;

  /// Video bitrate in kbps
  final int? bitrate;

  /// Thumbnail as bytes (generated lazily)
  final Uint8List? thumbnail;

  /// When the file was picked/added
  final DateTime addedAt;

  VideoFile({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeInBytes,
    this.durationMs,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
    this.thumbnail,
    DateTime? addedAt,
  }) : baseName = name.contains('.')
           ? name.substring(0, name.lastIndexOf('.'))
           : name,
       extension = name.contains('.')
           ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
           : '',
       addedAt = addedAt ?? DateTime.now();

  /// Create from file path
  factory VideoFile.fromPath(String path, {String? id}) {
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;

    return VideoFile(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      name: name,
      sizeInBytes: file.existsSync() ? file.lengthSync() : 0,
    );
  }

  /// Get formatted file size (e.g., "12.5 MB")
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Get formatted duration (e.g., "12:34")
  String get formattedDuration {
    if (durationMs == null) return '--:--';

    final duration = Duration(milliseconds: durationMs!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get resolution string (e.g., "1920x1080")
  String get resolution {
    if (width == null || height == null) return 'Unknown';
    return '${width}x$height';
  }

  /// Copy with new values
  VideoFile copyWith({
    String? id,
    String? path,
    String? name,
    int? sizeInBytes,
    int? durationMs,
    int? width,
    int? height,
    double? frameRate,
    int? bitrate,
    Uint8List? thumbnail,
    DateTime? addedAt,
  }) {
    return VideoFile(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      bitrate: bitrate ?? this.bitrate,
      thumbnail: thumbnail ?? this.thumbnail,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'sizeInBytes': sizeInBytes,
      'durationMs': durationMs,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'bitrate': bitrate,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory VideoFile.fromJson(Map<String, dynamic> json) {
    return VideoFile(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      sizeInBytes: json['sizeInBytes'] as int,
      durationMs: json['durationMs'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      frameRate: json['frameRate'] as double?,
      bitrate: json['bitrate'] as int?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'VideoFile(name: $name, size: $formattedSize, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
