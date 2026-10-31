import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/vastu_data.dart';
import '../services/compass_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CompassScreen extends StatelessWidget {
  final CompassService compass;
  final String activeChakra;
  final ValueChanged<String> onChakraChange;
  final VoidCallback onOpenCamera;

  const CompassScreen({
    super.key,
    required this.compass,
    required this.activeChakra,
    required this.onChakraChange,
    required this.onOpenCamera,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: compass,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final displayHeading = compass.heading;
    final dirName = VastuData.nameFromDegree(displayHeading);
    final info = VastuData.directions[dirName]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 380 ? 10.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'KUBER VASTU CHAKRA',
                    style: AppTheme.uiLabel(
                      size: 10,
                      color: AppTheme.gold.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildHeadingCard(displayHeading, dirName, info),
                  const SizedBox(height: 14),
                  if (!compass.supported) _buildPermissionCard(),
                  if (compass.calibrationNeeded) _buildCalibrationCard(),
                  _buildImageCompass(displayHeading),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    _buildWebRotationControl(displayHeading),
                  ],
                  const SizedBox(height: 14),
                  DirectionInsightCard(info: info),
                  const SizedBox(height: 14),
                  _buildActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      child: _buildActionButton(
        label: 'Open Live Camera',
        primary: true,
        onTap: onOpenCamera,
      ),
    );
  }

  Widget _buildCalibrationCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2DD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentRed.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.screen_rotation_alt_outlined,
              color: AppTheme.accentRed,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calibrate the compass',
                    style: AppTheme.uiText(
                      size: 13,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Move your phone in a figure-eight away from metal, magnets, and electronics.',
                    style: AppTheme.uiText(size: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCompass(double heading) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math
              .min(constraints.maxWidth, 500.0)
              .clamp(180.0, 500.0)
              .toDouble();
          return SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.16),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: kIsWeb
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) =>
                          compass.setManualHeading(
                        heading + details.delta.dx * 0.8,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: ChakraDisplay(
                          chakraId: 'compass-chakra',
                          rotation: heading,
                          size: size,
                          showNeedle: true,
                          whiteCard: false,
                        ),
                      ),
                    )
                  : ChakraDisplay(
                      chakraId: 'compass-chakra',
                      rotation: heading,
                      size: size,
                      showNeedle: true,
                      whiteCard: false,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebRotationControl(double heading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: AppTheme.insetPanelDecoration(radius: 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.rotate_right, size: 18, color: AppTheme.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag the chakra or use the slider to rotate',
                  style: AppTheme.uiText(size: 12, color: AppTheme.muted),
                ),
              ),
              Text(
                '${heading.toStringAsFixed(1)} deg',
                style: AppTheme.uiText(
                  size: 12,
                  color: AppTheme.goldBright,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: heading.clamp(0.0, 360.0).toDouble(),
            min: 0,
            max: 360,
            divisions: 360,
            activeColor: AppTheme.gold,
            inactiveColor: AppTheme.gold.withValues(alpha: 0.18),
            onChanged: compass.setManualHeading,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingCard(
    double heading,
    String dirName,
    VastuDirection info,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.all(compact ? 14 : 20),
          decoration: AppTheme.cardDecoration(radius: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: heading * math.pi / 180,
                child: Icon(
                  Icons.navigation,
                  size: compact ? 38 : 46,
                  color: AppTheme.accentRed,
                  shadows: [
                    Shadow(
                      color: AppTheme.body.withValues(alpha: 0.35),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${heading.toStringAsFixed(1)} deg',
                      style: AppTheme.divineTitle(
                        size: compact ? 36 : 44,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dirName,
                      style: AppTheme.uiText(
                        size: compact ? 16 : 19,
                        color: AppTheme.goldBright,
                        weight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      '${info.element.toUpperCase()} - ${info.deity.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.uiLabel(size: 9, color: AppTheme.muted),
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

  Widget _buildPermissionCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.insetPanelDecoration(radius: 10),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: AppTheme.goldBright,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compass not available',
                    style: AppTheme.uiText(size: 14, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Browser compass sensors are unavailable. Rotate the chakra manually below.'
                  : 'Your device may not have a magnetometer. You can rotate the chakra manually below.',
              style: AppTheme.uiText(
                size: 12,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        alignment: Alignment.center,
        decoration: primary
            ? AppTheme.goldButtonDecoration(radius: 10)
            : AppTheme.insetPanelDecoration(radius: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: AppTheme.uiText(
              size: 14,
              weight: FontWeight.w600,
              color: AppTheme.cream,
            ),
          ),
        ),
      ),
    );
  }
}
