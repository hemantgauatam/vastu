import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/vastu_data.dart';
import '../services/compass_service.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  final CompassService compass;
  final String activeChakra;
  final ValueChanged<String> onChakraChange;
  final ValueChanged<CaptureEntry> onCapture;

  const CameraScreen({
    super.key,
    required this.compass,
    required this.activeChakra,
    required this.onChakraChange,
    required this.onCapture,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = false;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    if (_initializing) return;
    setState(() {
      _initializing = true;
      _errorMessage = null;
      _permissionDenied = false;
    });

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _permissionDenied = true;
          _initializing = false;
          _errorMessage =
              'Camera permission denied. Please enable it in Settings.';
        });
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera available on this device.';
          _initializing = false;
        });
        return;
      }

      final rear = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Kubar Vastu: Camera start error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to start camera. Try restarting the app.';
        _initializing = false;
      });
    }
  }

  Future<void> _stopCamera() async {
    await _controller?.dispose();
    if (mounted) setState(() => _controller = null);
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.compass.heading;
    final dirName = VastuData.nameFromDegree(heading);
    final info = VastuData.directions[dirName]!;
    final cameraActive = _controller?.value.isInitialized ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 380 ? 10.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'AUGMENTED COMPASS',
                    style: AppTheme.uiLabel(
                      size: 10,
                      color: AppTheme.gold.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live Vastu Lens',
                    textAlign: TextAlign.center,
                    style: AppTheme.divineTitle(
                      size: constraints.maxWidth < 360 ? 21 : 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCameraSurface(cameraActive, heading, dirName, info),
                  const SizedBox(height: 16),
                  if (!cameraActive)
                    _buildStartButton()
                  else
                    _buildActionRow(heading, dirName),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraSurface(
    bool cameraActive,
    double heading,
    String dirName,
    VastuDirection info,
  ) {
    final shortScreen = MediaQuery.sizeOf(context).height < 700;
    return AspectRatio(
      aspectRatio: shortScreen ? 1 : 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: cameraActive ? Colors.black : AppTheme.bgPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.body.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (cameraActive)
              Positioned.fill(child: CameraPreview(_controller!))
            else
              _buildCameraInactive(),
            if (cameraActive) _buildCrosshair(),
            if (cameraActive) _buildTopHud(heading, dirName),
            if (cameraActive) _buildBottomHud(info),
          ],
        ),
      ),
    );
  }

  Widget _buildCrosshair() {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.goldBright, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withValues(alpha: 0.6),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.goldBright,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud(double heading, String dirName) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: AppTheme.glassStrongDecoration(radius: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('HEADING', style: AppTheme.uiLabel(size: 9)),
                const SizedBox(height: 2),
                Text(
                  '${heading.toStringAsFixed(1)} deg $dirName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.uiText(size: 16, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _stopCamera,
            child: Container(
              width: 36,
              height: 36,
              decoration: AppTheme.glassStrongDecoration(radius: 18),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppTheme.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHud(VastuDirection info) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassStrongDecoration(radius: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [info.color, info.color.withValues(alpha: 0.4)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${info.deity} - ${info.element}',
                    style: AppTheme.uiText(size: 12, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    info.meaning,
                    style: AppTheme.uiText(
                      size: 10,
                      color: AppTheme.cream.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraInactive() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_initializing) ...[
              const CircularProgressIndicator(
                color: AppTheme.gold,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Starting camera...',
                style: AppTheme.uiText(
                  size: 13,
                  color: AppTheme.cream.withValues(alpha: 0.7),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.camera_alt_outlined,
                size: 40,
                color: AppTheme.goldBright,
              ),
              const SizedBox(height: 12),
              Text('Camera Off', style: AppTheme.divineTitle(size: 18)),
              const SizedBox(height: 6),
              Text(
                _errorMessage ??
                    'Start your camera to see the live Vastu overlay.',
                textAlign: TextAlign.center,
                style: AppTheme.uiText(
                  size: 12,
                  color: AppTheme.cream.withValues(alpha: 0.6),
                ),
              ),
              if (_permissionDenied) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => openAppSettings(),
                  child: Text(
                    'Open Settings',
                    style: AppTheme.uiText(
                      size: 12,
                      color: AppTheme.goldBright,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return InkWell(
      onTap: _startCamera,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        alignment: Alignment.center,
        decoration: AppTheme.goldButtonDecoration(radius: 10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: AppTheme.cream,
              ),
              const SizedBox(width: 8),
              Text(
                'Start Live View',
                style: AppTheme.uiText(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppTheme.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(double heading, String dirName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final itemWidth =
            compact ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _actionButton(
                label: 'Capture Reading',
                primary: true,
                onTap: () => _saveReading(heading, dirName),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _actionButton(
                label: 'Stop Camera',
                primary: false,
                onTap: _stopCamera,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton({
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

  void _saveReading(double heading, String dirName) {
    widget.onCapture(
      CaptureEntry(
        time: DateTime.now(),
        heading: heading,
        direction: dirName,
        chakraId: widget.activeChakra,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgPanel,
        content: Text('Reading saved', style: AppTheme.uiText(size: 13)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
