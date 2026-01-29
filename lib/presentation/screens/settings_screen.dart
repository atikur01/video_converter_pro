import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

/// Settings screen with theme, cache, and app info
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().refreshCacheSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child:
                    const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1, end: 0),
              ),
            ),

            // Settings list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Consumer<SettingsProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Defaults section
                        _SectionTitle(
                          title: 'Defaults',
                        ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
                        const SizedBox(height: 12),

                        _SettingsTile(
                              icon: Icons.high_quality,
                              iconColor: AppColors.primaryCyan,
                              title: 'Default Quality',
                              subtitle: provider.defaultQualityName,
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textTertiary,
                              ),
                              onTap: () =>
                                  _showQualityPicker(context, provider),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 300.ms)
                            .slideX(begin: 0.05, end: 0),

                        const SizedBox(height: 8),

                        _SettingsTile(
                              icon: Icons.video_file,
                              iconColor: AppColors.success,
                              title: 'Default Format',
                              subtitle: provider.defaultFormat.toUpperCase(),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textTertiary,
                              ),
                              onTap: () => _showFormatPicker(context, provider),
                            )
                            .animate()
                            .fadeIn(delay: 350.ms, duration: 300.ms)
                            .slideX(begin: 0.05, end: 0),

                        const SizedBox(height: 24),

                        // Storage section
                        _SectionTitle(
                          title: 'Storage',
                        ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                        const SizedBox(height: 12),

                        _SettingsTile(
                              icon: Icons.folder,
                              iconColor: AppColors.warning,
                              title: 'Output Files',
                              subtitle: provider.formattedCacheSize,
                              trailing: TextButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _showClearCacheDialog(
                                        context,
                                        provider,
                                      ),
                                child: const Text('Clear'),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 300.ms)
                            .slideX(begin: 0.05, end: 0),

                        const SizedBox(height: 40),

                        // Reset button
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                _showResetDialog(context, provider),
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset All Settings'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

                        const SizedBox(height: 100),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Default Quality',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(3, (index) {
                  final names = ['High Quality', 'Balanced', 'Fast'];
                  final descriptions = [
                    'Best quality, slower conversion',
                    'Good balance of quality and speed',
                    'Quick conversion, smaller file',
                  ];
                  final isSelected = provider.defaultQuality == index;

                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.primaryCyan
                          : AppColors.textTertiary,
                    ),
                    title: Text(names[index]),
                    subtitle: Text(descriptions[index]),
                    onTap: () {
                      provider.setDefaultQuality(index);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFormatPicker(BuildContext context, SettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Default Format',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ...AppConstants.videoFormats.map((format) {
                  final isSelected = provider.defaultFormat == format.extension;

                  return ListTile(
                    leading: Text(
                      format.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(format.name),
                    subtitle: Text(format.description),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryCyan,
                          )
                        : null,
                    onTap: () {
                      provider.setDefaultFormat(format.extension);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Output Files?'),
        content: Text(
          'This will delete all ${provider.formattedCacheSize} of converted files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.clearCache();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset all settings to their default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.resetAll();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
