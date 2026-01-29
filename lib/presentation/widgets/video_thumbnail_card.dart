import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/conversion_history.dart';
import '../../services/haptic_service.dart';

/// Video thumbnail card for history list
class VideoThumbnailCard extends StatelessWidget {
  final ConversionHistory history;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onReconvert;

  const VideoThumbnailCard({
    super.key,
    required this.history,
    this.onTap,
    this.onPlay,
    this.onShare,
    this.onDelete,
    this.onReconvert,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return GestureDetector(
      onTap: () {
        hapticService.lightImpact();
        onPlay?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Output name
                  Text(
                    history.outputName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Format and size
                  Row(
                    children: [
                      _buildTag(
                        history.settings.outputFormat.toUpperCase(),
                        AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        history.formattedOutputSize,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Time ago and compression
                  Row(
                    children: [
                      Text(
                        history.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (history.compressionRatio < 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          history.compressionDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            _buildActions(hapticService),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Prefer history thumbnail (generated from output), fallback to source thumbnail
    final thumbnail = history.thumbnail ?? history.sourceFile.thumbnail;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        image: thumbnail != null
            ? DecorationImage(image: MemoryImage(thumbnail), fit: BoxFit.cover)
            : null,
      ),
      child: thumbnail == null
          ? const Center(
              child: Icon(
                Icons.video_file,
                color: AppColors.textTertiary,
                size: 32,
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActions(HapticService haptics) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.info_outline,
          onTap: () {
            haptics.lightImpact();
            onTap?.call();
          },
        ),
        const SizedBox(height: 4),
        _ActionButton(
          icon: Icons.share,
          onTap: () {
            haptics.lightImpact();
            onShare?.call();
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Compact video card for recent conversions
class VideoCardCompact extends StatelessWidget {
  final String name;
  final String format;
  final String size;
  final Uint8List? thumbnail;
  final VoidCallback? onTap;

  const VideoCardCompact({
    super.key,
    required this.name,
    required this.format,
    required this.size,
    this.thumbnail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                image: thumbnail != null
                    ? DecorationImage(
                        image: MemoryImage(thumbnail!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: thumbnail == null
                  ? const Center(
                      child: Icon(
                        Icons.video_file,
                        color: AppColors.textTertiary,
                        size: 28,
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              format.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    size,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
