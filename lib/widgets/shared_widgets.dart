import 'package:flutter/material.dart';
import '../chakras/chakra_variants.dart';
import '../models/vastu_data.dart';
import '../theme/app_theme.dart';

/// North is centred at the bottom of the supplied bitmap, so a half turn
/// places it under the fixed pointer.
const double compassChakraArtworkCalibrationDegrees = 180.0;

double compassChakraRotationDegrees(double heading) {
  final normalizedHeading = (heading % 360.0 + 360.0) % 360.0;
  return compassChakraArtworkCalibrationDegrees - normalizedHeading;
}

class ChakraDisplay extends StatelessWidget {
  final String chakraId;
  final double rotation;
  final double size;
  final bool showNeedle;
  final bool whiteCard;

  const ChakraDisplay({
    super.key,
    required this.chakraId,
    required this.rotation,
    this.size = 300,
    this.showNeedle = false,
    this.whiteCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            // The main Chakra artwork reaches almost to the bitmap edge.
            // Give it extra room so its outer ring remains fully visible at
            // every rotation angle while the circular clip hides the corners.
            padding: EdgeInsets.all(chakraId == 'compass-chakra' ? 12 : 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: chakraId == 'compass-chakra'
                  ? Colors.white
                  : whiteCard
                      ? AppTheme.bgPanel.withValues(alpha: 0.98)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: whiteCard
                  ? Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.18),
                      width: 1,
                    )
                  : null,
              boxShadow: whiteCard
                  ? [
                      BoxShadow(
                        color: AppTheme.body.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : null,
            ),
            child: chakraId == 'compass-chakra'
                ? Transform.rotate(
                    // Counter-rotate the calibrated artwork by the live phone
                    // heading so the fixed pointer reads the same bearing.
                    angle: compassChakraRotationDegrees(rotation) *
                        3.141592653589793 /
                        180,
                    child: Image.asset(
                      'assets/images/main_chakraa.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      // Decode at the artwork's full resolution. The Chakra
                      // contains small bilingual labels that become soft when
                      // Flutter downsizes the image cache before rotating it.
                      isAntiAlias: true,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => CustomPaint(
                        painter: chakraPainterFor(chakraId, rotation),
                      ),
                    ),
                  )
                : chakraId == '32-gates'
                    ? Transform.rotate(
                        // Calibrate the supplied wheel so true North lies on
                        // the N4/N5 dividing line.
                        angle: (16.875 - rotation) * 3.141592653589793 / 180,
                        child: Image.asset(
                          'assets/images/32_zone.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) =>
                              CustomPaint(
                            painter: chakraPainterFor(chakraId, rotation),
                          ),
                        ),
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: chakraId == 'vastu-purush'
                            ? Transform.rotate(
                                angle: -rotation * 3.141592653589793 / 180,
                                child: Image.asset(
                                  'assets/images/vastu_purusu.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              )
                            : CustomPaint(
                                painter: chakraPainterFor(chakraId, rotation),
                              ),
                      ),
          ),
          if (showNeedle)
            Positioned(
              top: 0,
              child: Icon(
                Icons.navigation,
                size: (size * 0.09).clamp(20.0, 30.0).toDouble(),
                color: AppTheme.accentRed,
                shadows: [
                  Shadow(
                    color: AppTheme.body.withValues(alpha: 0.32),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ChakraChipSelector extends StatelessWidget {
  final String activeId;
  final ValueChanged<String> onChanged;

  const ChakraChipSelector({
    super.key,
    required this.activeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChakraRegistry.all.map((chakra) {
          final active = chakra.id == activeId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onChanged(chakra.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.gold
                      : AppTheme.bgPanel.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppTheme.gold
                        : AppTheme.gold.withValues(alpha: 0.22),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  chakra.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(
                    size: 11,
                    color: active ? AppTheme.bgPanel : AppTheme.cream,
                    weight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DirectionInsightCard extends StatelessWidget {
  final VastuDirection info;

  const DirectionInsightCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: info.color.withValues(alpha: 0.7)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    info.name,
                    style: AppTheme.uiText(
                      size: 12,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 70)
                        .clamp(140.0, constraints.maxWidth)
                        .toDouble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.deity} - ${info.element}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.uiText(
                        size: 14,
                        color: AppTheme.gold,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.meaning,
                      style: AppTheme.uiText(
                        size: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: AppTheme.cardDecoration(radius: 10),
        child: Icon(icon, size: 19, color: AppTheme.gold),
      ),
    );
  }
}
