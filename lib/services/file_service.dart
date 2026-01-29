import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../data/models/video_file.dart';
import 'ffmpeg_service.dart';

/// Service for file operations
/// Handles video picking, thumbnails, and file system operations
class FileService {
  /// Singleton instance
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final FFmpegService _ffmpegService = FFmpegService();

  /// Supported video extensions
  static const List<String> supportedExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
    'wmv',
    'm4v',
    '3gp',
    'mpeg',
    'mpg',
  ];

  /// Request storage permissions
  Future<bool> requestPermissions() async {
    // For Android 13+ (API 33+), we need specific media permissions
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        // Android 13+
        final videoStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();

        return videoStatus.isGranted || audioStatus.isGranted;
      } else {
        // Android 12 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }

    return true; // iOS doesn't need runtime permissions for file access
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      // Fallback to safe default if something goes wrong
      return 30;
    }
  }

  /// Pick a single video file
  Future<VideoFile?> pickVideo() async {
    try {
      // Request permissions first
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false, // Don't load file into memory
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        return null;
      }

      // Create VideoFile with basic info
      final videoFile = VideoFile.fromPath(file.path!);

      // Get video metadata
      final videoInfo = await _ffmpegService.getVideoInfo(file.path!);

      // Generate thumbnail
      final thumbnail = await generateThumbnail(file.path!);

      return videoFile.copyWith(
        durationMs: videoInfo?.durationMs,
        width: videoInfo?.width,
        height: videoInfo?.height,
        frameRate: videoInfo?.frameRate,
        bitrate: videoInfo?.bitrate,
        thumbnail: thumbnail,
      );
    } catch (e) {
      print('Error picking video: $e');
      rethrow;
    }
  }

  /// Pick multiple video files for batch conversion
  Future<List<VideoFile>> pickMultipleVideos() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final videos = <VideoFile>[];

      for (final file in result.files) {
        if (file.path == null) continue;

        final videoFile = VideoFile.fromPath(file.path!);
        final videoInfo = await _ffmpegService.getVideoInfo(file.path!);
        final thumbnail = await generateThumbnail(file.path!);

        videos.add(
          videoFile.copyWith(
            durationMs: videoInfo?.durationMs,
            width: videoInfo?.width,
            height: videoInfo?.height,
            frameRate: videoInfo?.frameRate,
            bitrate: videoInfo?.bitrate,
            thumbnail: thumbnail,
          ),
        );
      }

      return videos;
    } catch (e) {
      print('Error picking multiple videos: $e');
      rethrow;
    }
  }

  /// Generate thumbnail for a video file
  Future<Uint8List?> generateThumbnail(
    String videoPath, {
    int quality = 50,
    int maxWidth = 256,
    int maxHeight = 256,
  }) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      return thumbnail;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Save thumbnail to file
  Future<String?> saveThumbnail(String videoPath, Uint8List thumbnail) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(thumbnail);
      return file.path;
    } catch (e) {
      print('Error saving thumbnail: $e');
      return null;
    }
  }

  /// Get app's output directory
  Future<Directory> getOutputDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      // Use app-specific external storage directory to avoid Scoped Storage issues
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

    return outputDir;
  }

  /// Get list of converted files in output directory
  Future<List<File>> getConvertedFiles() async {
    try {
      final outputDir = await getOutputDirectory();
      final files = <File>[];

      await for (final entity in outputDir.list()) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (supportedExtensions.contains(extension) ||
              ['mp3', 'aac', 'wav', 'm4a'].contains(extension)) {
            files.add(entity);
          }
        }
      }

      // Sort by modification date, newest first
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      print('Error getting converted files: $e');
      return [];
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get file size
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get total size of output directory
  Future<int> getOutputDirectorySize() async {
    try {
      final outputDir = await getOutputDirectory();
      int totalSize = 0;

      await for (final entity in outputDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Clear output directory
  Future<void> clearOutputDirectory() async {
    try {
      final outputDir = await getOutputDirectory();

      await for (final entity in outputDir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing output directory: $e');
    }
  }

  /// Format file size to human-readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
