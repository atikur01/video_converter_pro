import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptic_service.dart';

/// Format selection card for video/audio formats, resolutions, etc.
class FormatCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? icon; // Emoji icon
  final IconData? iconData; // Material icon
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const FormatCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconData,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          hapticService.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cardBackgroundElevated
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (icon != null)
              Text(icon!, style: const TextStyle(fontSize: 28))
            else if (iconData != null)
              Icon(
                iconData,
                size: 28,
                color: isSelected
                    ? AppColors.primaryCyan
                    : AppColors.textSecondary,
              ),

            const SizedBox(height: 8),

            // Title
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryCyan
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Selection indicator
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryCyan,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryCyan,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal format card for list views
class FormatCardHorizontal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? icon;
  final IconData? iconData;
  final bool isSelected;
  final VoidCallback? onTap;

  const FormatCardHorizontal({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconData,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          hapticService.selectionClick();
          onTap!();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cardBackgroundElevated
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            if (icon != null)
              Text(icon!, style: const TextStyle(fontSize: 24))
            else if (iconData != null)
              Icon(
                iconData,
                size: 24,
                color: isSelected
                    ? AppColors.primaryCyan
                    : AppColors.textSecondary,
              ),

            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryCyan
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.primaryCyan,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grid of format cards
class FormatCardGrid extends StatelessWidget {
  final List<FormatCardData> items;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const FormatCardGrid({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onSelected,
    this.crossAxisCount = 3,
    this.spacing = 12,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return SizedBox(
              width: itemWidth,
              child: FormatCard(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                iconData: item.iconData,
                isSelected: selectedIndex == index,
                onTap: () => onSelected?.call(index),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Data class for format card
class FormatCardData {
  final String title;
  final String? subtitle;
  final String? icon;
  final IconData? iconData;

  const FormatCardData({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconData,
  });
}
