import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/conversion_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/video_thumbnail_card.dart';
import '../widgets/custom_bottom_nav.dart';
import 'conversion_settings_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../../core/constants/app_constants.dart';

/// Main home screen with video picker and recent conversions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize history provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // If we're not on the first tab, go back to first tab
        if (_currentNavIndex != 0) {
          setState(() {
            _currentNavIndex = 0;
          });
          return;
        }

        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit && context.mounted) {
          /// Since this is the root route, we can system exit or let it pop
          /// But typically PopScope with canPop:false checks, so we might need
          /// access to SystemNavigator or just allow pop if we were able to.
          /// However, in a root replacement route, handling exit manually is often needed
          /// or just setting canPop to true appropriately.
          /// Let's use SystemNavigator.pop() for a clean exit feel or just return
          /// and let the system handle "exit" if we had passed this up.
          /// Actually, standard pattern with PopScope(canPop:false) is to not pop.
          /// If we want to exit app, SystemNavigator.pop() is good.

          // We can't change 'canPop' to true easily inside here without state.
          // Easiest is SystemNavigator.pop().
          // But let's verify if user wants to use SystemNavigator.
          // Standard Flutter way is simply SystemNavigator.pop().
          // A safer way for root is:
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _HomeContent(
              onSeeAllPressed: () {
                setState(() {
                  _currentNavIndex = 1;
                });
              },
            ),
            const HistoryScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          items: const [
            CustomBottomNavItem(
              label: 'Home',
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
            ),
            CustomBottomNavItem(
              label: 'History',
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
            ),
            CustomBottomNavItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Exit App?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: const Text(
              'Are you sure you want to exit Video Converter Pro?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Home content with video picker
class _HomeContent extends StatelessWidget {
  final VoidCallback? onSeeAllPressed;

  const _HomeContent({this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child:
                  Row(
                        children: [
                          // Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/inapplogo/logo.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0, duration: 400.ms),
            ),
          ),

          // Main content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big CTA card
                  _VideoPickerCard()
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Recent conversions
                  _RecentConversions(onSeeAllPressed: onSeeAllPressed)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big video picker card
class _VideoPickerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConversionProvider>(
      builder: (context, provider, _) {
        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryCyan.withOpacity(0.2),
                      AppColors.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library,
                  size: 40,
                  color: AppColors.primaryCyan,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Convert Your Videos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'MP4, MKV, AVI, MOV, WEBM, FLV and more',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // Select video button
              SizedBox(
                width: double.infinity,
                child: GradientButton.primary(
                  text: 'Select Video',
                  icon: Icons.folder_open,
                  isLoading: provider.state == ConversionState.selecting,
                  onPressed: () async {
                    await provider.pickVideo();
                    if (context.mounted && provider.hasSelectedVideo) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConversionSettingsScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Recent conversions section
class _RecentConversions extends StatelessWidget {
  final VoidCallback? onSeeAllPressed;

  const _RecentConversions({this.onSeeAllPressed});
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (!provider.hasRecentHistory) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Conversions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: const Text('See All'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Recent items horizontal scroll
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.recentHistory.length,
                itemBuilder: (context, index) {
                  final history = provider.recentHistory[index];
                  return VideoCardCompact(
                    name: history.outputName,
                    format: history.settings.outputFormat,
                    size: history.formattedOutputSize,
                    thumbnail:
                        history.thumbnail ?? history.sourceFile.thumbnail,
                    onTap: () async {
                      final result = await OpenFilex.open(history.outputPath);
                      if (result.type != ResultType.done && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open: ${result.message}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
