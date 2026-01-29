import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/conversion_provider.dart';
import '../widgets/animated_progress_ring.dart';
import '../widgets/gradient_button.dart';
import 'success_screen.dart';

/// Converting screen with animated progress
class ConvertingScreen extends StatefulWidget {
  const ConvertingScreen({super.key});

  @override
  State<ConvertingScreen> createState() => _ConvertingScreenState();
}

class _ConvertingScreenState extends State<ConvertingScreen> {
  @override
  void initState() {
    super.initState();
    // Start conversion when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startConversion();
    });
  }

  Future<void> _startConversion() async {
    final provider = context.read<ConversionProvider>();
    await provider.startConversion();

    if (mounted) {
      // Navigate based on result
      if (provider.isCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
        );
      } else if (provider.isFailed) {
        _showErrorDialog(provider.errorMessage ?? 'Unknown error');
      } else if (provider.state == ConversionState.cancelled) {
        Navigator.pop(context);
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 12),
            Text('Conversion Failed'),
          ],
        ),
        content: Text(
          error,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startConversion(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Cancel Conversion?'),
            content: const Text(
              'Are you sure you want to cancel the current conversion?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () {
                  context.read<ConversionProvider>().cancelConversion();
                  Navigator.pop(context, true);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<ConversionProvider>(
          builder: (context, provider, _) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.05),
                    AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // App bar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.cardBackground,
                                  title: const Text('Cancel?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                provider.cancelConversion();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Progress ring
                    AnimatedProgressRing(
                      progress: provider.progressValue,
                      size: 220,
                      strokeWidth: 14,
                    ),

                    const SizedBox(height: 40),

                    // Status text
                    Text(
                      provider.progressMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 12),

                    // ETA
                    if (provider.isConverting &&
                        provider.progress != null &&
                        provider.progress!.estimatedTimeRemainingMs != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ETA: ${provider.estimatedTimeRemaining}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                    const SizedBox(height: 8),

                    // File info
                    if (provider.selectedVideo != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          provider.selectedVideo!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                    const Spacer(),

                    // Batch progress indicator
                    if (provider.isBatchMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.playlist_play,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Video ${provider.currentBatchIndex + 1} of ${provider.totalBatchCount}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value:
                                  (provider.currentBatchIndex + 1) /
                                  provider.totalBatchCount,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.secondaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

                    const SizedBox(height: 40),

                    // Cancel button
                    Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: SizedBox(
                            width: double.infinity,
                            child: GradientOutlineButton(
                              text: 'Cancel',
                              icon: Icons.close,
                              gradient: const LinearGradient(
                                colors: [AppColors.error, AppColors.error],
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.cardBackground,
                                    title: const Text('Cancel Conversion?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  provider.cancelConversion();
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
