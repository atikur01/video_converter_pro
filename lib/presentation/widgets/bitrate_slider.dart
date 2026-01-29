import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/haptic_service.dart';

/// Custom styled slider for bitrate selection
class BitrateSlider extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final bool isAuto;
  final ValueChanged<int>? onChanged;
  final ValueChanged<bool>? onAutoChanged;

  const BitrateSlider({
    super.key,
    required this.value,
    this.min = 500,
    this.max = 50000,
    this.isAuto = true,
    this.onChanged,
    this.onAutoChanged,
  });

  @override
  State<BitrateSlider> createState() => _BitrateSliderState();
}

class _BitrateSliderState extends State<BitrateSlider> {
  final HapticService _hapticService = HapticService();
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.toDouble().clamp(
      widget.min.toDouble(),
      widget.max.toDouble(),
    );
  }

  @override
  void didUpdateWidget(BitrateSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value.toDouble().clamp(
        widget.min.toDouble(),
        widget.max.toDouble(),
      );
    }
  }

  String _formatBitrate(double value) {
    if (value < 1000) {
      return '${value.toInt()} kbps';
    } else {
      return '${(value / 1000).toStringAsFixed(1)} Mbps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with auto toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bitrate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: widget.isAuto,
                  onChanged: (value) {
                    _hapticService.selectionClick();
                    widget.onAutoChanged?.call(value);
                  },
                  activeColor: AppColors.primaryCyan,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Slider or Auto indicator
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: widget.isAuto
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quality-based encoding (CRF)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          secondChild: Column(
            children: [
              // Value display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      _formatBitrate(_currentValue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryCyan,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.primaryCyan,
                  overlayColor: AppColors.primaryCyan.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: _GradientThumbShape(),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: _currentValue,
                  min: widget.min.toDouble(),
                  max: widget.max.toDouble(),
                  divisions: 99,
                  onChanged: (value) {
                    setState(() {
                      _currentValue = value;
                    });
                    widget.onChanged?.call(value.toInt());
                  },
                  onChangeEnd: (value) {
                    _hapticService.selectionClick();
                  },
                ),
              ),

              // Min/Max labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatBitrate(widget.min.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      _formatBitrate(widget.max.toDouble()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom thumb shape with gradient
class _GradientThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 14, glowPaint);

    // White circle background
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawCircle(center, 10, bgPaint);

    // Gradient inner circle
    final rect = Rect.fromCircle(center: center, radius: 8);
    final gradientPaint = Paint()
      ..shader = AppColors.primaryGradient.createShader(rect);
    canvas.drawCircle(center, 8, gradientPaint);
  }
}

/// Quality selector chip list
class QualitySelector extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final ValueChanged<int>? onChanged;

  const QualitySelector({
    super.key,
    required this.selectedIndex,
    required this.options,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = HapticService();

    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              hapticService.selectionClick();
              onChanged?.call(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: index < options.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              child: Center(
                child: Text(
                  options[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primaryCyan
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
