import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/conversion_provider.dart';
import '../widgets/video_thumbnail_card.dart';
import '../widgets/skeleton_loader.dart';
import 'conversion_settings_screen.dart';

/// History screen showing all past conversions
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Consumer<HistoryProvider>(
                    builder: (context, provider, _) {
                      if (!provider.hasHistory) return const SizedBox.shrink();

                      return IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.textSecondary,
                        onPressed: () => _showClearDialog(context, provider),
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
            ),

            // Stats card
            Consumer<HistoryProvider>(
              builder: (context, provider, _) {
                if (!provider.hasHistory || provider.stats == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryCyan.withOpacity(0.1),
                              AppColors.primaryBlue.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryCyan.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              value: '${provider.stats!.totalConversions}',
                              label: 'Total',
                              icon: Icons.video_library,
                            ),
                            _StatItem(
                              value: provider.stats!.formattedTotalOutput,
                              label: 'Output',
                              icon: Icons.storage,
                            ),
                            _StatItem(
                              value: provider.stats!.compressionPercent,
                              label: 'Saved',
                              icon: Icons.compress,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),

            const SizedBox(height: 20),

            // History list
            Expanded(
              child: Consumer<HistoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: SkeletonList(itemCount: 5),
                      ),
                    );
                  }

                  if (!provider.hasHistory) {
                    return _EmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: AppColors.primaryCyan,
                    backgroundColor: AppColors.cardBackground,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.history.length,
                      itemBuilder: (context, index) {
                        final history = provider.history[index];

                        return VideoThumbnailCard(
                              history: history,
                              onTap: () {
                                // Show details bottom sheet
                                _showDetailsSheet(context, history);
                              },
                              onPlay: () async {
                                final result = await OpenFilex.open(
                                  history.outputPath,
                                );
                                if (result.type != ResultType.done &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open: ${result.message}',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              onShare: () async {
                                await Share.shareXFiles([
                                  XFile(history.outputPath),
                                ]);
                              },
                              onDelete: () {
                                provider.deleteEntry(history.id);
                              },
                              onReconvert: () {
                                // Re-convert the source file
                                final conversionProvider = context
                                    .read<ConversionProvider>();
                                conversionProvider.setVideo(history.sourceFile);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ConversionSettingsScreen(),
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: index * 50),
                              duration: 300.ms,
                            )
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History'),
        content: const Text('Do you want to also delete the converted files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll(deleteFiles: false);
              Navigator.pop(context);
            },
            child: const Text('Keep Files'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.clearAll(deleteFiles: true);
              Navigator.pop(context);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, dynamic history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  history.outputName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Details
                _DetailRow(
                  label: 'Format',
                  value: history.settings.outputFormat.toUpperCase(),
                ),
                _DetailRow(
                  label: 'Resolution',
                  value: history.settings.resolutionDisplay,
                ),
                _DetailRow(label: 'Size', value: history.formattedOutputSize),
                _DetailRow(label: 'Converted', value: history.timeAgo),
                _DetailRow(
                  label: 'Duration',
                  value: history.formattedConversionDuration,
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<HistoryProvider>().deleteEntry(
                            history.id,
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final conversionProvider = context
                              .read<ConversionProvider>();
                          conversionProvider.setVideo(history.sourceFile);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConversionSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Re-convert',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Prevents wrapping
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryCyan, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 50,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversion history will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
