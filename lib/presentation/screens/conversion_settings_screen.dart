import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/video_file.dart';
import '../../data/models/conversion_settings.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/format_card.dart';
import '../widgets/bitrate_slider.dart';
import 'converting_screen.dart';

/// Conversion settings screen
/// Allows user to configure format, resolution, FPS, and bitrate
class ConversionSettingsScreen extends StatefulWidget {
  const ConversionSettingsScreen({super.key});

  @override
  State<ConversionSettingsScreen> createState() =>
      _ConversionSettingsScreenState();
}

class _ConversionSettingsScreenState extends State<ConversionSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _selectedFormatIndex = 0;
  int _selectedResolutionIndex =
      AppConstants.defaultResolutionIndex; // 720p by default
  int _selectedFpsIndex = 3; // Original
  int _selectedQualityIndex = 1; // Balanced

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load defaults from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();

      // Set default format
      final formatIndex = AppConstants.videoFormats.indexWhere(
        (f) => f.extension == settings.defaultFormat,
      );
      if (formatIndex != -1) {
        setState(() {
          _selectedFormatIndex = formatIndex;

          // Also update provider
          final format = AppConstants.videoFormats[formatIndex];
          context.read<ConversionProvider>().setOutputFormat(
            format.extension,
            format.codec,
          );
        });
      }

      // Set default quality
      setState(() {
        _selectedQualityIndex = settings.defaultQuality;

        // Also update provider
        final quality = AppConstants.qualityModes[settings.defaultQuality];
        context.read<ConversionProvider>().setQualityMode(
          quality.preset,
          quality.crf,
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Conversion Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<ConversionProvider>().clearVideo();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<ConversionProvider>(
        builder: (context, provider, _) {
          final video = provider.selectedVideo;
          if (video == null) {
            return const Center(child: Text('No video selected'));
          }

          return CustomScrollView(
            slivers: [
              // Video info header
              SliverToBoxAdapter(
                child:
                    (provider.isBatchMode
                            ? _BatchInfoHeader(
                                count: provider.totalBatchCount,
                                videos: provider.batchVideos,
                              )
                            : _VideoInfoHeader(video: video))
                        .animate()
                        .fadeIn(duration: 300.ms),
              ),

              // Tabs
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: AppColors.background,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Video'),
                      Tab(text: 'Audio'),
                    ],
                    onTap: (index) {
                      provider.setConversionType(
                        index == 0
                            ? ConversionType.video
                            : ConversionType.audio,
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 16)),

              // Settings content
              SliverFillRemaining(
                hasScrollBody: true,
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _VideoSettings(
                            selectedFormatIndex: _selectedFormatIndex,
                            selectedResolutionIndex: _selectedResolutionIndex,
                            selectedFpsIndex: _selectedFpsIndex,
                            selectedQualityIndex: _selectedQualityIndex,
                            onFormatChanged: (index) {
                              setState(() => _selectedFormatIndex = index);
                              final format = AppConstants.videoFormats[index];
                              provider.setOutputFormat(
                                format.extension,
                                format.codec,
                              );
                            },
                            onResolutionChanged: (index) {
                              setState(() => _selectedResolutionIndex = index);
                              final res = AppConstants.resolutionPresets[index];
                              provider.setResolution(res.width, res.height);
                            },
                            onFpsChanged: (index) {
                              setState(() => _selectedFpsIndex = index);
                              final fps = AppConstants.frameRatePresets[index];
                              provider.setFrameRate(fps.fps);
                            },
                            onQualityChanged: (index) {
                              setState(() => _selectedQualityIndex = index);
                              final quality = AppConstants.qualityModes[index];
                              provider.setQualityMode(
                                quality.preset,
                                quality.crf,
                              );
                            },
                          ),
                          _AudioSettings(
                            onFormatChanged: (index) {
                              final format = AppConstants.audioFormats[index];
                              provider.setOutputFormat(
                                format.extension,
                                format.codec,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Bottom action
                    _BottomActions(
                          onStart: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ConvertingScreen(),
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Video info header
class _VideoInfoHeader extends StatelessWidget {
  final dynamic video;

  const _VideoInfoHeader({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                image: video.thumbnail != null
                    ? DecorationImage(
                        image: MemoryImage(video.thumbnail!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: video.thumbnail == null
                  ? const Icon(Icons.video_file, color: AppColors.textTertiary)
                  : null,
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(text: video.formattedSize, icon: Icons.storage),
                      const SizedBox(width: 8),
                      _InfoChip(
                        text: video.formattedDuration,
                        icon: Icons.timer,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        text: video.resolution,
                        icon: Icons.aspect_ratio,
                      ),
                    ],
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

class _BatchInfoHeader extends StatelessWidget {
  final int count;
  final List<dynamic> videos;

  const _BatchInfoHeader({required this.count, required this.videos});

  @override
  Widget build(BuildContext context) {
    // Calculate total size
    int totalBytes = 0;
    for (var v in videos) {
      if (v is VideoFile) {
        totalBytes += v.sizeInBytes;
      }
    }

    // Simple formatter (could move to FileService)
    String sizeStr = '';
    if (totalBytes > 1024 * 1024 * 1024) {
      sizeStr = '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else {
      sizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail Stack
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.playlist_play,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Videos Selected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(text: sizeStr, icon: Icons.storage),
                      const SizedBox(width: 8),
                      const _InfoChip(text: 'Batch Mode', icon: Icons.layers),
                    ],
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

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Video conversion settings
class _VideoSettings extends StatelessWidget {
  final int selectedFormatIndex;
  final int selectedResolutionIndex;
  final int selectedFpsIndex;
  final int selectedQualityIndex;
  final ValueChanged<int> onFormatChanged;
  final ValueChanged<int> onResolutionChanged;
  final ValueChanged<int> onFpsChanged;
  final ValueChanged<int> onQualityChanged;

  const _VideoSettings({
    required this.selectedFormatIndex,
    required this.selectedResolutionIndex,
    required this.selectedFpsIndex,
    required this.selectedQualityIndex,
    required this.onFormatChanged,
    required this.onResolutionChanged,
    required this.onFpsChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection
          _SectionTitle(title: 'Output Format'),
          const SizedBox(height: 12),
          FormatCardGrid(
            items: AppConstants.videoFormats
                .map(
                  (f) => FormatCardData(
                    title: f.name,
                    subtitle: f.description,
                    icon: f.icon,
                  ),
                )
                .toList(),
            selectedIndex: selectedFormatIndex,
            onSelected: onFormatChanged,
            crossAxisCount: 3,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Resolution selection
          _SectionTitle(title: 'Resolution'),
          const SizedBox(height: 12),
          FormatCardGrid(
            items: AppConstants.resolutionPresets
                .map(
                  (r) => FormatCardData(
                    title: r.shortName,
                    subtitle: r.name,
                    icon: r.icon,
                  ),
                )
                .toList(),
            selectedIndex: selectedResolutionIndex,
            onSelected: onResolutionChanged,
            crossAxisCount: 3,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // FPS selection
          _SectionTitle(title: 'Frame Rate'),
          const SizedBox(height: 12),
          FormatCardGrid(
            items: AppConstants.frameRatePresets
                .map(
                  (f) => FormatCardData(
                    title: f.isOriginal ? 'Auto' : '${f.fps}fps',
                    subtitle: f.description,
                  ),
                )
                .toList(),
            selectedIndex: selectedFpsIndex,
            onSelected: onFpsChanged,
            crossAxisCount: 3,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Quality selection
          _SectionTitle(title: 'Quality Mode'),
          const SizedBox(height: 12),
          QualitySelector(
            selectedIndex: selectedQualityIndex,
            options: AppConstants.qualityModes.map((q) => q.name).toList(),
            onChanged: onQualityChanged,
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

          const SizedBox(height: 24),

          // Bitrate slider
          Consumer<ConversionProvider>(
            builder: (context, provider, _) {
              return BitrateSlider(
                value: provider.settings.targetBitrate,
                isAuto: provider.settings.autoBitrate,
                onChanged: (value) {
                  provider.setBitrate(value);
                },
                onAutoChanged: (auto) {
                  provider.setBitrate(
                    provider.settings.targetBitrate,
                    auto: auto,
                  );
                },
              );
            },
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// Audio extraction settings
class _AudioSettings extends StatefulWidget {
  final ValueChanged<int> onFormatChanged;

  const _AudioSettings({required this.onFormatChanged});

  @override
  State<_AudioSettings> createState() => _AudioSettingsState();
}

class _AudioSettingsState extends State<_AudioSettings> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Audio Format'),
          const SizedBox(height: 12),
          FormatCardGrid(
            items: AppConstants.audioFormats
                .map(
                  (f) => FormatCardData(
                    title: f.name,
                    subtitle: f.description,
                    icon: f.icon,
                  ),
                )
                .toList(),
            selectedIndex: _selectedIndex,
            onSelected: (index) {
              setState(() => _selectedIndex = index);
              widget.onFormatChanged(index);
            },
            crossAxisCount: 2,
          ),

          const SizedBox(height: 24),

          // Info card
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: AppColors.info),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Audio will be extracted from your video with the selected format.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Bottom actions
class _BottomActions extends StatelessWidget {
  final VoidCallback onStart;

  const _BottomActions({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Consumer<ConversionProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Settings summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryChip(
                      label: 'Format',
                      value: provider.settings.outputFormat.toUpperCase(),
                    ),
                    _SummaryChip(
                      label: 'Resolution',
                      value: provider.settings.resolutionDisplay,
                    ),
                    _SummaryChip(
                      label: 'Quality',
                      value: provider.settings.qualityPreset,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton.primary(
                    text: 'Start Conversion',
                    icon: Icons.play_arrow,
                    onPressed: onStart,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryCyan,
          ),
        ),
      ],
    );
  }
}
