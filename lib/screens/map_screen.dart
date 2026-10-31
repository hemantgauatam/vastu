import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../chakras/chakra_variants.dart';
import '../chakras/chakra_map_geometry.dart';
import '../chakras/fifth_chakra.dart';
import '../models/vastu_data.dart';
import '../theme/app_theme.dart';

// The supplied chakra artwork's visual convergence point sits fractionally
// away from its bitmap bounds' mathematical centre. Keep the correction
// proportional so preview and high-resolution reports share the same centre.
Offset _chakraCenterCalibration(Size size) => Offset(
      size.width * -0.0017,
      size.height * 0.0034,
    );

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const int _reportRasterPixels = 1400;
  static const double _reportRasterSize = 1400.0;

  static const Map<String, String> _reportChakras = {
    '16-directions': '16 Zone Map',
    '32-gates': '32 Gates Map',
    '45-devata': '45 Devta Map',
    'vastu-purush': 'Vastu Purush Map',
    'kv-chakra': 'KV Chakra Special Map',
  };
  Uint8List? _originalImageBytes;
  ui.Image? _decodedImage;
  ui.Image? _vastuPurushOverlay;
  ui.Image? _devata45Overlay;
  ui.Image? _devata45TextlessOverlay;
  ui.Image? _gate32Overlay;
  Uint8List? _croppedImageBytes;

  Rect _cropRect = const Rect.fromLTWH(0, 0, 100, 100);
  final ValueNotifier<Rect> _cropRectNotifier = ValueNotifier<Rect>(
    const Rect.fromLTWH(0, 0, 100, 100),
  );

  // Start with stronger contrast so chakra geometry and labels remain legible
  // over detailed architectural drawings.
  double _chakraOpacity = 0.94;
  double _mapScale = 0.96;
  double _chakraRotationDegrees = 0;
  double _mapRotationDegrees = 0;
  double _cropRotationDegrees = 0;
  String _selectedChakra = 'vastu-purush';
  Offset _chakraOffset = Offset.zero;

  bool _isLoading = false;
  bool _isGeneratingReport = false;
  double _reportProgress = 0;
  String _reportStatus = '';
  int _currentStep = 0;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _degreeController = TextEditingController();
  final GlobalKey _mapReportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_loadChakraAssets());
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 1200,
      targetHeight: 1200,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  Future<void> _loadChakraAssets() async {
    final images = await Future.wait([
      _loadAssetImage('assets/images/vastu_p1.png'),
      // Render the supplied labelled 45 Devata artwork as one continuous
      // geometry. Joining a separately generated outer band introduces tiny
      // angular seams because its divider construction is not identical.
      _loadAssetImage('assets/images/45devtaaaa_uppp.png'),
      _loadAssetImage('assets/images/45_d_no_text.png'),
    ]);
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    setState(() {
      _vastuPurushOverlay = images[0];
      _devata45Overlay = images[1];
      _devata45TextlessOverlay = images[2];
    });
  }

  // Vastu Purush must use the supplied reference artwork everywhere it is
  // rendered (editor, preview and report).
  bool _isAssetChakra(String id) => id == 'vastu-purush';

  ui.Image? _assetChakraImage(String id) => switch (id) {
        '45-devata' => _devata45Overlay,
        '32-gates' => _gate32Overlay,
        _ => _vastuPurushOverlay,
      };

  Rect _assetArtworkBounds(String id) => switch (id) {
        // Remove the uneven white canvas around the visible circular artwork.
        // Values are normalized, so they work at every display/report size.
        // The 1254×1254 PNG contains substantial white padding. These measured
        // bounds isolate a centred 1158×1158 square around the visible outer
        // circle, allowing it to meet the generated direction band exactly.
        '45-devata' => const Rect.fromLTRB(
            60 / 1254,
            24 / 1254,
            1218 / 1254,
            1182 / 1254,
          ),
        'vastu-purush' => const Rect.fromLTRB(
            35.5 / 1376,
            36 / 1393,
            1343.5 / 1376,
            1344 / 1393,
          ),
        _ => const Rect.fromLTWH(0, 0, 1, 1),
      };

  // Scale the complete chakra against the map's shortest side. This keeps the
  // inner circle on the map while allowing the outer circle to surround it,
  // matching the requested reference sketch.
  // Usable diameter inside the labelled outer band of circular chakras.
  double _mapContainmentFactor(String chakraId) => switch (chakraId) {
        // These painters use a 0.49 outer radius and their labelled band
        // starts at 91% of that radius. Compensate for the editor's 0.96 map
        // scale so the map diagonal ends exactly on that inner band circle:
        // 0.98 * 0.91 / 0.96.
        '16-directions' || '32-gates' => (0.98 * 0.91) / 0.96,
        _ => 1.0,
      };

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }
      final bytes = await pickedFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      _installSourceImage(bytes, decoded);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      setState(() => _isLoading = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (result == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.length < 8) {
        throw const FormatException('The selected PDF could not be read.');
      }
      if (bytes.length > 50 * 1024 * 1024) {
        throw const FormatException('PDF must be smaller than 50 MB.');
      }
      final signature = String.fromCharCodes(bytes.take(5));
      if (signature != '%PDF-') {
        throw const FormatException('The selected file is not a valid PDF.');
      }

      Uint8List? previewBytes;
      await for (final page in Printing.raster(
        bytes,
        pages: const [0],
        dpi: 180,
      )) {
        previewBytes = await page.toPng();
        break;
      }
      if (previewBytes == null || previewBytes.isEmpty) {
        throw const FormatException(
          'The PDF is corrupted, encrypted, or has no visible first page.',
        );
      }
      final decoded = await decodeImageFromList(previewBytes);
      _installSourceImage(previewBytes, decoded);
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('PDF upload failed: $error');
      }
    }
  }

  void _installSourceImage(Uint8List bytes, ui.Image decoded) {
    final imgW = decoded.width.toDouble();
    final imgH = decoded.height.toDouble();
    final cropSize = math.min(imgW, imgH) * 0.85;
    final cropRect = Rect.fromLTWH(
      (imgW - cropSize) / 2,
      (imgH - cropSize) / 2,
      cropSize,
      cropSize,
    );
    _decodedImage?.dispose();
    setState(() {
      _originalImageBytes = bytes;
      _decodedImage = decoded;
      _cropRect = cropRect;
      _cropRectNotifier.value = cropRect;
      _croppedImageBytes = null;
      _currentStep = 1;
      _cropRotationDegrees = 0;
      _mapRotationDegrees = 0;
      _chakraRotationDegrees = 0;
      _chakraOffset = Offset.zero;
      _degreeController.text = '0';
      _isLoading = false;
    });
  }

  Future<void> _applyCrop() async {
    if (_decodedImage == null) return;
    setState(() => _isLoading = true);
    try {
      final source = _decodedImage!;
      final sourceWidth = source.width;
      final sourceHeight = source.height;
      final fullRecorder = ui.PictureRecorder();
      final fullCanvas = Canvas(fullRecorder);
      fullCanvas.translate(sourceWidth / 2, sourceHeight / 2);
      fullCanvas.rotate(_cropRotationDegrees * math.pi / 180);
      fullCanvas.drawImage(
        source,
        Offset(-sourceWidth / 2, -sourceHeight / 2),
        Paint()..filterQuality = FilterQuality.high,
      );
      final fullPicture = fullRecorder.endRecording();
      final rotatedFullImage =
          await fullPicture.toImage(sourceWidth, sourceHeight);
      fullPicture.dispose();
      final fullByteData = await rotatedFullImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (fullByteData == null) {
        rotatedFullImage.dispose();
        throw 'Full image rotation failed';
      }

      final width = _cropRect.width.toInt();
      final height = _cropRect.height.toInt();
      if (width <= 0 || height <= 0) throw 'Invalid size';
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        rotatedFullImage,
        _cropRect,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(width, height);
      final byteData = await croppedImg.toByteData(
        format: ui.ImageByteFormat.png,
      );
      picture.dispose();
      croppedImg.dispose();
      if (byteData == null) throw 'Encode failed';
      final previousImage = _decodedImage;
      setState(() {
        _decodedImage = rotatedFullImage;
        _originalImageBytes = fullByteData.buffer.asUint8List();
        _croppedImageBytes = byteData.buffer.asUint8List();
        _chakraOpacity = 0.94;
        _mapScale = 0.96;
        _currentStep = 2;
        _chakraOffset = Offset.zero;
        _chakraRotationDegrees = 0;
        _mapRotationDegrees = 0;
        _cropRotationDegrees = 0;
        _degreeController.text = '0';
        _isLoading = false;
      });
      if (previousImage != rotatedFullImage) previousImage?.dispose();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Crop failed: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _resetAll() {
    _decodedImage?.dispose();
    setState(() {
      _originalImageBytes = null;
      _decodedImage = null;
      _croppedImageBytes = null;
      _currentStep = 0;
      _chakraOffset = Offset.zero;
      _chakraRotationDegrees = 0;
      _mapRotationDegrees = 0;
      _cropRotationDegrees = 0;
    });
  }

  void _goBackToCrop() {
    setState(() {
      _croppedImageBytes = null;
      _currentStep = 1;
    });
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    _vastuPurushOverlay?.dispose();
    _devata45Overlay?.dispose();
    _devata45TextlessOverlay?.dispose();
    _gate32Overlay?.dispose();
    _cropRectNotifier.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep overlay pixels transparent, but give the Android workspace a
      // neutral base so platform black does not show through.
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          backgroundColor: AppTheme.bgPanel,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 44,
          leading: _currentStep == 2
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  color: AppTheme.gold,
                  onPressed: _goBackToCrop,
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentStep == 2) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  _currentStep == 0
                      ? 'Upload Floor Plan'
                      : _currentStep == 1
                          ? 'Crop Floor Plan'
                          : 'Kuber Vastu',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.cream,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (_currentStep > 0)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                color: AppTheme.gold,
                onPressed: _resetAll,
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_currentStep < 2) _buildStepIndicator(),
              Expanded(
                child: _currentStep == 0
                    ? _buildUploadScreen()
                    : _currentStep == 1
                        ? _buildCropScreen()
                        : _buildChakraOverlayScreen(),
              ),
              if (_currentStep == 1) _buildCropControls(),
              if (_currentStep == 2) _buildChakraControls(),
            ],
          ),
          if (_isGeneratingReport) _buildReportProgressOverlay(),
        ],
      ),
    );
  }

  Size _rotatedBoundingSize(double width, double height) {
    final radians = _cropRotationDegrees * math.pi / 180;
    final cosine = math.cos(radians).abs();
    final sine = math.sin(radians).abs();
    return Size(
      width * cosine + height * sine,
      width * sine + height * cosine,
    );
  }

  Size _effectiveCropSize() {
    final rotated = _rotatedBoundingSize(
      _cropRect.width,
      _cropRect.height,
    );
    return Size(
      math.max(1.0, rotated.width),
      math.max(1.0, rotated.height),
    );
  }

  double _chakraSideForCrop(String chakraId) {
    final cropSize = _effectiveCropSize();
    if (chakraId == '16-directions' || chakraId == '32-gates') {
      // Match _inscribedMapSize: the crop's four corners must remain inside
      // the chakra circle in both preview and uncropped report.
      final cropDiagonal = math.sqrt(
        cropSize.width * cropSize.width + cropSize.height * cropSize.height,
      );
      return cropDiagonal / (_mapScale * _mapContainmentFactor(chakraId));
    }
    if (chakraId == '45-devata' || chakraId == 'vastu-purush') {
      return chakraSideForMapEdges(chakraId, cropSize);
    }
    return math.max(cropSize.width, cropSize.height);
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(
          bottom: BorderSide(color: AppTheme.gold.withValues(alpha: 0.16)),
        ),
      ),
      child: Row(
        children: [
          _stepDot(1, 'Upload', _currentStep >= 0),
          _stepLine(_currentStep >= 1),
          _stepDot(2, 'Crop', _currentStep >= 1),
          _stepLine(_currentStep >= 2),
          _stepDot(3, 'Analyze', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _stepDot(int number, String label, bool active) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppTheme.gold : AppTheme.goldSoft,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.cream : AppTheme.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: active ? AppTheme.gold : AppTheme.muted,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      width: 14,
      height: 2,
      color: active ? AppTheme.gold : AppTheme.goldSoft,
    );
  }

  Widget _buildUploadScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.gold.withValues(alpha: 0.3),
                    AppTheme.gold.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.upload_file,
                size: 36,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Your Floor Plan',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.cream,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload → Crop → Mark Zones',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.cream.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined, size: 16),
                  label: Text(
                    _isLoading ? 'Loading...' : 'Upload Image',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(
                    'Upload PDF',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropScreen() {
    if (_decodedImage == null || _originalImageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final imgW = _decodedImage!.width.toDouble();
        final imgH = _decodedImage!.height.toDouble();
        final scale = math.min(
              constraints.maxWidth / imgW,
              constraints.maxHeight / imgH,
            ) *
            0.92;
        final displayW = imgW * scale;
        final displayH = imgH * scale;
        return ValueListenableBuilder<Rect>(
          valueListenable: _cropRectNotifier,
          builder: (context, cropRect, _) {
            final dispLeft = cropRect.left * scale;
            final dispTop = cropRect.top * scale;
            final dispWidth = cropRect.width * scale;
            final dispHeight = cropRect.height * scale;
            return Container(
              color: AppTheme.bgDarker,
              child: Center(
                child: SizedBox(
                  width: displayW,
                  height: displayH,
                  child: RepaintBoundary(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRect(
                            child: Transform.rotate(
                              angle: _cropRotationDegrees * math.pi / 180,
                              child: RawImage(
                                image: _decodedImage,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CropMaskPainter(
                                cropRect: Rect.fromLTWH(
                                  dispLeft,
                                  dispTop,
                                  dispWidth,
                                  dispHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: dispLeft,
                          top: dispTop,
                          width: dispWidth,
                          height: dispHeight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              double newLeft =
                                  cropRect.left + details.delta.dx / scale;
                              double newTop =
                                  cropRect.top + details.delta.dy / scale;
                              newLeft = newLeft
                                  .clamp(0.0, imgW - cropRect.width)
                                  .toDouble();
                              newTop = newTop
                                  .clamp(0.0, imgH - cropRect.height)
                                  .toDouble();
                              _updateCropRect(
                                Rect.fromLTWH(
                                  newLeft,
                                  newTop,
                                  cropRect.width,
                                  cropRect.height,
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppTheme.gold, width: 1.5),
                              ),
                              child: CustomPaint(
                                size: Size(dispWidth, dispHeight),
                                painter: _GridPainter(),
                              ),
                            ),
                          ),
                        ),
                        _resizeHandle(
                          Offset(dispLeft - 9, dispTop - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              topLeft: true),
                        ),
                        _resizeHandle(
                          Offset(dispLeft + dispWidth - 9, dispTop - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              topRight: true),
                        ),
                        _resizeHandle(
                          Offset(dispLeft - 9, dispTop + dispHeight - 9),
                          (dx, dy) => _resizeFrom(
                            dx,
                            dy,
                            scale,
                            imgW,
                            imgH,
                            bottomLeft: true,
                          ),
                        ),
                        _resizeHandle(
                          Offset(dispLeft + dispWidth - 9,
                              dispTop + dispHeight - 9),
                          (dx, dy) => _resizeFrom(
                            dx,
                            dy,
                            scale,
                            imgW,
                            imgH,
                            bottomRight: true,
                          ),
                        ),
                        _resizeHandle(
                          Offset(dispLeft - 9, dispTop + dispHeight / 2 - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              leftEdge: true),
                        ),
                        _resizeHandle(
                          Offset(dispLeft + dispWidth - 9,
                              dispTop + dispHeight / 2 - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              rightEdge: true),
                        ),
                        _resizeHandle(
                          Offset(dispLeft + dispWidth / 2 - 9, dispTop - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              topEdge: true),
                        ),
                        _resizeHandle(
                          Offset(dispLeft + dispWidth / 2 - 9,
                              dispTop + dispHeight - 9),
                          (dx, dy) => _resizeFrom(dx, dy, scale, imgW, imgH,
                              bottomEdge: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateCropRect(Rect value) {
    _cropRect = value;
    _cropRectNotifier.value = value;
  }

  Widget _resizeHandle(Offset position, void Function(double, double) onDrag) {
    return Positioned(
      left: position.dx - 7,
      top: position.dy - 7,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold,
                border: Border.all(color: AppTheme.bgPanel, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resizeFrom(
    double dx,
    double dy,
    double scale,
    double imgW,
    double imgH, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    bool leftEdge = false,
    bool rightEdge = false,
    bool topEdge = false,
    bool bottomEdge = false,
  }) {
    final ddx = dx / scale, ddy = dy / scale;
    double left = _cropRect.left, top = _cropRect.top;
    double right = _cropRect.right, bottom = _cropRect.bottom;
    if (topLeft) {
      left += ddx;
      top += ddy;
    }
    if (topRight) {
      right += ddx;
      top += ddy;
    }
    if (bottomLeft) {
      left += ddx;
      bottom += ddy;
    }
    if (bottomRight) {
      right += ddx;
      bottom += ddy;
    }
    if (leftEdge) left += ddx;
    if (rightEdge) right += ddx;
    if (topEdge) top += ddy;
    if (bottomEdge) bottom += ddy;
    const minSize = 50.0;
    if (right - left < minSize) {
      if (topLeft || bottomLeft || leftEdge) {
        left = right - minSize;
      } else {
        right = left + minSize;
      }
    }
    if (bottom - top < minSize) {
      if (topLeft || topRight || topEdge) {
        top = bottom - minSize;
      } else {
        bottom = top + minSize;
      }
    }
    left = left.clamp(0.0, imgW).toDouble();
    top = top.clamp(0.0, imgH).toDouble();
    right = right.clamp(0.0, imgW).toDouble();
    bottom = bottom.clamp(0.0, imgH).toDouble();
    _updateCropRect(Rect.fromLTRB(left, top, right, bottom));
  }

  Future<void> _rotateCrop(int direction) async {
    final source = _decodedImage;
    if (source == null || _isLoading || direction == 0) return;
    setState(() => _isLoading = true);

    try {
      final clockwise = direction > 0;
      final oldWidth = source.width.toDouble();
      final oldHeight = source.height.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      if (clockwise) {
        canvas.translate(oldHeight, 0);
        canvas.rotate(math.pi / 2);
      } else {
        canvas.translate(0, oldWidth);
        canvas.rotate(-math.pi / 2);
      }
      canvas.drawImage(
        source,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final rotatedImage = await picture.toImage(source.height, source.width);
      picture.dispose();
      final byteData = await rotatedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        rotatedImage.dispose();
        throw 'Image rotation failed';
      }

      final oldCrop = _cropRect;
      final rotatedCrop = clockwise
          ? Rect.fromLTRB(
              oldHeight - oldCrop.bottom,
              oldCrop.left,
              oldHeight - oldCrop.top,
              oldCrop.right,
            )
          : Rect.fromLTRB(
              oldCrop.top,
              oldWidth - oldCrop.right,
              oldCrop.bottom,
              oldWidth - oldCrop.left,
            );

      if (!mounted) {
        rotatedImage.dispose();
        return;
      }
      final previousImage = _decodedImage;
      setState(() {
        _decodedImage = rotatedImage;
        _originalImageBytes = byteData.buffer.asUint8List();
        _cropRect = rotatedCrop;
        _cropRectNotifier.value = rotatedCrop;
        _isLoading = false;
      });
      if (previousImage != rotatedImage) previousImage?.dispose();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Rotation failed: $error');
    }
  }

  void _adjustCropRotation(double amount) {
    setState(() {
      _cropRotationDegrees = (_cropRotationDegrees + amount) % 360;
      if (_cropRotationDegrees < 0) _cropRotationDegrees += 360;
    });
  }

  Widget _buildCropControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(
          top: BorderSide(color: AppTheme.gold.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.body.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease rotation',
                onPressed: () => _adjustCropRotation(-1),
                icon: const Icon(Icons.remove_circle_outline, size: 19),
                color: AppTheme.cream,
              ),
              Expanded(
                child: Slider(
                  value: _cropRotationDegrees,
                  min: 0,
                  max: 360,
                  divisions: 360,
                  activeColor: AppTheme.gold,
                  inactiveColor: AppTheme.gold.withValues(alpha: 0.25),
                  label: '${_cropRotationDegrees.round()}°',
                  onChanged: (value) {
                    setState(() => _cropRotationDegrees = value);
                  },
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '${_cropRotationDegrees.round()}°',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.cream,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase rotation',
                onPressed: () => _adjustCropRotation(1),
                icon: const Icon(Icons.add_circle_outline, size: 19),
                color: AppTheme.cream,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_decodedImage == null) return;
                    final imgW = _decodedImage!.width.toDouble();
                    final imgH = _decodedImage!.height.toDouble();
                    final cropSize = math.min(imgW, imgH) * 0.85;
                    setState(() {
                      _cropRect = Rect.fromLTWH(
                        (imgW - cropSize) / 2,
                        (imgH - cropSize) / 2,
                        cropSize,
                        cropSize,
                      );
                      _cropRectNotifier.value = _cropRect;
                      _cropRotationDegrees = 0;
                    });
                  },
                  icon: const Icon(Icons.restart_alt, size: 14),
                  label: Text('Reset', style: GoogleFonts.inter(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cream,
                    side: BorderSide(
                        color: AppTheme.gold.withValues(alpha: 0.36)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rotateCrop(-1),
                  icon: const Icon(Icons.rotate_left, size: 14),
                  label: Text('Left', style: GoogleFonts.inter(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cream,
                    side: BorderSide(
                        color: AppTheme.gold.withValues(alpha: 0.36)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rotateCrop(1),
                  icon: const Icon(Icons.rotate_right, size: 14),
                  label: Text('Right', style: GoogleFonts.inter(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cream,
                    side: BorderSide(
                        color: AppTheme.gold.withValues(alpha: 0.36)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _applyCrop,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.cream,
                          ),
                        )
                      : const Icon(Icons.crop, size: 14),
                  label: Text(
                    _isLoading ? 'Cropping...' : 'Crop & Continue',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.cream,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// STEP 3: Chakra wraps the image (chakra fits viewport, image inside chakra)
  Widget _buildChakraOverlayScreen() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const padding = 4.0;
          final maxChakraInViewport = math.max(
            0.0,
            math.min(
              constraints.maxWidth - padding * 2,
              constraints.maxHeight - padding * 2,
            ),
          );
          final chakraDisplaySize = maxChakraInViewport;
          final chakraWrapsMap = _selectedChakra == '16-directions' ||
              _selectedChakra == '32-gates';
          final chakraUnderMap = _selectedChakra == '45-devata' ||
              _selectedChakra == 'vastu-purush';
          final kvMapInside = _selectedChakra == 'kv-chakra';
          final circularFrame = chakraWrapsMap || kvMapInside;

          final viewportCenterX = constraints.maxWidth / 2;
          final viewportCenterY = constraints.maxHeight / 2;

          final rotatedCropSize = _effectiveCropSize();
          final cropAspect = rotatedCropSize.width / rotatedCropSize.height;
          var mapArea = chakraUnderMap
              ? _fitMapSize(
                  chakraDisplaySize * 0.96,
                  chakraDisplaySize * 0.96,
                  cropAspect,
                )
              : kvMapInside
                  ? FifthChakraGeometry.mapSize(
                      chakraDisplaySize,
                      cropAspect,
                      _mapScale,
                    )
                  : _inscribedMapSize(
                      chakraDisplaySize *
                          _mapContainmentFactor(_selectedChakra),
                      cropAspect,
                    );
          var assetChakraSize = math.min(mapArea.width, mapArea.height);
          if (chakraUnderMap) {
            assetChakraSize = chakraSideForMapEdges(
              _selectedChakra,
              mapArea,
            );
            final maxAssetSize = chakraDisplaySize * 0.96;
            if (assetChakraSize > maxAssetSize) {
              final correction = maxAssetSize / assetChakraSize;
              mapArea = Size(
                mapArea.width * correction,
                mapArea.height * correction,
              );
              assetChakraSize = maxAssetSize;
            }
          }
          final mapAreaWidth = mapArea.width;
          final mapAreaHeight = mapArea.height;
          final chakraLeft =
              viewportCenterX - chakraDisplaySize / 2 + _chakraOffset.dx;
          final chakraTop =
              viewportCenterY - chakraDisplaySize / 2 + _chakraOffset.dy;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: chakraLeft,
                top: chakraTop,
                child: GestureDetector(
                  // Keep the map/chakra fixed under finger gestures in the
                  // Android/iOS app. Rotation remains available through the
                  // degree controls; desktop web keeps mouse-drag rotation.
                  onPanUpdate: kIsWeb
                      ? (details) {
                          setState(() {
                            _chakraRotationDegrees = (_chakraRotationDegrees -
                                    details.delta.dx * 0.45) %
                                360;
                            if (_chakraRotationDegrees < 0) {
                              _chakraRotationDegrees += 360;
                            }
                            _degreeController.text =
                                _formatDegree(_chakraRotationDegrees);
                          });
                        }
                      : null,
                  child: RepaintBoundary(
                    key: _mapReportKey,
                    child: SizedBox(
                      width: chakraDisplaySize,
                      height: chakraDisplaySize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: circularFrame
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          color: Colors.transparent,
                          // Chakra painters already draw their circumference.
                          // A widget border would darken the same edge again.
                          border: null,
                          boxShadow: null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildMapLayer(
                              mapAreaWidth,
                              mapAreaHeight,
                              opacity: 1,
                            ),
                            if (kvMapInside)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: FifthChakraPainter(
                                      rotationDegrees: FifthChakraGeometry
                                          .rotationForBearing(
                                        _chakraRotationDegrees,
                                      ),
                                      opacity: _chakraOpacity,
                                    ),
                                  ),
                                ),
                              ),
                            if (chakraUnderMap)
                              IgnorePointer(
                                child: SizedBox(
                                  width: assetChakraSize,
                                  height: assetChakraSize,
                                  child: CustomPaint(
                                    painter: ((_selectedChakra == '45-devata' &&
                                                _devata45Overlay != null) ||
                                            (_selectedChakra ==
                                                    'vastu-purush' &&
                                                _vastuPurushOverlay != null))
                                        ? _VastuPurushImagePainter(
                                            image:
                                                _selectedChakra == '45-devata'
                                                    ? _devata45Overlay
                                                    : _vastuPurushOverlay,
                                            normalizedSourceRect:
                                                _assetArtworkBounds(
                                              _selectedChakra,
                                            ),
                                            rotationDegrees:
                                                _assetChakraRotation(
                                              _selectedChakra,
                                            ),
                                            opacity: _chakraOpacity,
                                            grayscale: true,
                                            transparentWhite: true,
                                          )
                                        : _CodeChakraOverlayPainter(
                                            chakraId: _selectedChakra ==
                                                    'vastu-purush'
                                                ? 'vastu-purush-inner'
                                                : _selectedChakra,
                                            rotationDegrees:
                                                _renderedChakraRotation(
                                              _selectedChakra,
                                            ),
                                            opacity: _chakraOpacity,
                                          ),
                                  ),
                                ),
                              ),
                            if (chakraWrapsMap)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ClipOval(
                                    child: CustomPaint(
                                      painter: _CodeChakraOverlayPainter(
                                        chakraId: _selectedChakra,
                                        rotationDegrees:
                                            _renderedChakraRotation(
                                          _selectedChakra,
                                        ),
                                        opacity: _chakraOpacity,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!kvMapInside)
                              IgnorePointer(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.9),
                                    border: Border.all(
                                        color: Colors.white, width: 0.8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Alignment badge stays visible without taking space below.
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPanel.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation,
                        size: 10,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${VastuData.nameFromDegree(_normalizeDegree(_chakraRotationDegrees))}  |  ${_formatDegree(_chakraRotationDegrees)} deg',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapLayer(
    double width,
    double height, {
    double opacity = 1,
  }) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: ClipRect(
            child: Transform.rotate(
              angle: _mapRotationDegrees * math.pi / 180,
              child: Image.memory(
                _croppedImageBytes!,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Size _inscribedMapSize(double chakraDiameter, double aspectRatio) {
    final safeAspect =
        aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1.0;
    // Largest rectangle of this aspect ratio whose corners stay inside
    // the Chakra circle. _mapScale leaves a small visual margin.
    final usableDiameter = chakraDiameter * _mapScale;
    final height = usableDiameter / math.sqrt(safeAspect * safeAspect + 1);
    return Size(height * safeAspect, height);
  }

  Size _fitMapSize(
    double maxWidth,
    double maxHeight,
    double aspectRatio,
  ) {
    final safeAspect =
        aspectRatio.isFinite && aspectRatio > 0 ? aspectRatio : 1.0;
    if (maxWidth / maxHeight > safeAspect) {
      return Size(maxHeight * safeAspect, maxHeight);
    }
    return Size(maxWidth, maxWidth / safeAspect);
  }

  Widget _buildChakraControls() {
    final degree = _normalizeDegree(_chakraRotationDegrees);
    if (_degreeController.text.isEmpty) {
      _degreeController.text = _formatDegree(degree);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(
          top: BorderSide(color: AppTheme.gold.withValues(alpha: 0.16)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.body.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final full = constraints.maxWidth;
              final half = full < 320 ? full : (full - 8) / 2;
              final actionWidth = (full - 8) / 2;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(width: half, child: _chakraDropdown()),
                      SizedBox(width: half, child: _degreeField()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: actionWidth,
                        height: 42,
                        child: _applyButton(),
                      ),
                      SizedBox(
                        width: actionWidth,
                        height: 42,
                        child: _reportButton(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chakraDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: AppTheme.insetPanelDecoration(radius: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChakra,
          isExpanded: true,
          dropdownColor: AppTheme.bgPanel,
          iconEnabledColor: AppTheme.gold,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.cream,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(
              value: '16-directions',
              child: Text('16 Zone'),
            ),
            DropdownMenuItem(value: '32-gates', child: Text('32 Gate')),
            DropdownMenuItem(
              value: '45-devata',
              child: Text('45 Devata'),
            ),
            DropdownMenuItem(
                value: 'vastu-purush', child: Text('Vastu Purush')),
            DropdownMenuItem(
                value: 'kv-chakra', child: Text('KV Chakra Special')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedChakra = value);
          },
        ),
      ),
    );
  }

  Widget _degreeField() {
    return TextField(
      controller: _degreeController,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppTheme.cream,
        fontWeight: FontWeight.w600,
      ),
      decoration:
          AppTheme.inputDecoration(label: 'Put degree', suffixText: 'deg'),
      onSubmitted: (_) => _applyDegreeFromInput(),
    );
  }

  Widget _applyButton() {
    return ElevatedButton.icon(
      onPressed: _applyDegreeFromInput,
      icon: const Icon(Icons.explore, size: 15),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Apply',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.cream,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _reportButton() {
    return OutlinedButton.icon(
      onPressed: _isGeneratingReport ? null : _showReportOptions,
      icon: _isGeneratingReport
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined, size: 15),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _isGeneratingReport ? 'Generating...' : 'Download Report',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.gold,
        side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildReportProgressOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 290,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.bgPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Generating your report',
                  textAlign: TextAlign.center,
                  style: AppTheme.uiText(size: 15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  _reportStatus,
                  textAlign: TextAlign.center,
                  style: AppTheme.uiText(size: 11, color: AppTheme.muted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _reportProgress,
                    minHeight: 7,
                    backgroundColor: AppTheme.gold.withValues(alpha: 0.16),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '${(_reportProgress * 100).round()}% • Please wait',
                  style: AppTheme.uiText(size: 10, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportOptions() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppTheme.bgPanel,
        title: Text(
          'Download report',
          style: AppTheme.divineTitle(size: 20),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _downloadReport(currentOnly: true);
            },
            child: ListTile(
              leading:
                  const Icon(Icons.description_outlined, color: AppTheme.gold),
              title: Text(
                'Download current map',
                style: AppTheme.uiText(size: 13, weight: FontWeight.w700),
              ),
              subtitle: Text(
                'One PDF page with the selected Chakra',
                style: AppTheme.uiText(size: 11, color: AppTheme.muted),
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _downloadReport();
            },
            child: ListTile(
              leading: const Icon(Icons.library_books_outlined,
                  color: AppTheme.gold),
              title: Text(
                'Download all maps',
                style: AppTheme.uiText(size: 13, weight: FontWeight.w700),
              ),
              subtitle: Text(
                'One full page for every Chakra',
                style: AppTheme.uiText(size: 11, color: AppTheme.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _normalizeDegree(double degree) {
    final normalized = degree % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  String _formatDegree(double degree) {
    final normalized = _normalizeDegree(degree);
    return normalized == normalized.roundToDouble()
        ? normalized.toStringAsFixed(0)
        : normalized.toStringAsFixed(1);
  }

  double _renderedChakraRotation(String chakraId) {
    // Every map chakra is now generated by the same code coordinate system:
    // 0 degrees is North and angles increase clockwise. Keep one shared map
    // alignment for preview and report rendering so changing the chakra never
    // changes the direction selected by the user.
    // A positive entered bearing means the plan's North lies clockwise from
    // the page top, so the chakra must counter-rotate by that bearing. The
    // code painters apply the negative canvas rotation internally.
    // Do not add an artwork correction here: the entered bearing is also the
    // alignment reference visible on an imported plan. Even a small fixed
    // offset makes the overlay spokes diverge from a chakra already present
    // in that image.
    // A half-degree clockwise fine tune matches the reference spokes visible
    // in imported, pre-aligned Vastu plans without the previous full-degree
    // over-correction.
    return -_chakraRotationDegrees + 0.5;
  }

  double _assetChakraRotation(String chakraId) {
    // The reference assets are already authored on the North axis. Keeping
    // their native orientation preserves the Vastu Purusha head in NE and
    // keeps the embedded radial lines aligned with its direction labels.
    // Bitmap painters rotate directly while generated painters counter-rotate
    // internally, so composite bitmap/code chakras need an inverse angle.
    // _CodeChakraOverlayPainter compensates for the code painters' internal
    // counter-rotation. The bitmap therefore receives this same displayed
    // angle so the 45 Devata inner artwork and outer direction ring rotate as
    // one locked chakra and their radial boundaries remain joined.
    return -_chakraRotationDegrees + 0.5;
  }

  String _outerRingId(String chakraId) =>
      chakraId == '32-gates' || chakraId == 'kv-chakra'
          ? '32-outer-ring'
          : chakraId == '45-devata'
              ? '45-outer-ring'
              : '16-outer-ring';

  void _applyDegreeFromInput() {
    FocusScope.of(context).unfocus();
    final raw = _degreeController.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      _showError('Enter a valid degree');
      return;
    }
    setState(() {
      _chakraRotationDegrees = _normalizeDegree(parsed);
      _degreeController.text = _formatDegree(_chakraRotationDegrees);
    });
  }

  // ignore: unused_element
  Future<Uint8List?> _captureMapReportImageTodayBackup(
    String chakraId, {
    bool showChakra = true,
    bool showChakraText = true,
  }) async {
    final source = _decodedImage;
    if (source == null) return null;

    const outputPixels = 2048;
    const outputSize = 2048.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..color = const Color(0xFFF7F3E9),
    );

    final totalMapRotation = _cropRotationDegrees + _mapRotationDegrees;
    final angle = totalMapRotation * math.pi / 180;
    final rotatedWidth = source.width.abs() * math.cos(angle).abs() +
        source.height.abs() * math.sin(angle).abs();
    final rotatedHeight = source.width.abs() * math.sin(angle).abs() +
        source.height.abs() * math.cos(angle).abs();
    final safeDiameter = showChakra ? outputSize * 0.79 : outputSize * 0.96;
    final mapSize = _fitMapSize(
      safeDiameter * 0.96,
      safeDiameter * 0.96,
      rotatedWidth / rotatedHeight,
    );
    final mapRect = Rect.fromCenter(
      center: const Offset(outputSize / 2, outputSize / 2),
      width: mapSize.width,
      height: mapSize.height,
    );

    final imageScale = math.min(
      mapRect.width / rotatedWidth,
      mapRect.height / rotatedHeight,
    );
    canvas.save();
    canvas.translate(mapRect.center.dx, mapRect.center.dy);
    canvas.rotate(angle);
    canvas.scale(imageScale);
    canvas.drawImage(
      source,
      Offset(-source.width / 2, -source.height / 2),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    if (showChakra) {
      final innerSide = math.min(mapRect.width, mapRect.height);
      final innerRect = Rect.fromCenter(
        center: mapRect.center,
        width: innerSide,
        height: innerSide,
      );
      canvas.save();
      canvas.translate(innerRect.left, innerRect.top);
      if (chakraId == '45-devata' && showChakraText) {
        _DevataLabelsPainter(
          rotationDegrees: _assetChakraRotation(chakraId),
          opacity: 1,
        ).paint(canvas, innerRect.size);
      } else if (chakraId == 'vastu-purush') {
        _CodeChakraOverlayPainter(
          chakraId: 'vastu-purush-inner',
          rotationDegrees: _assetChakraRotation(chakraId),
          opacity: 0.95,
        ).paint(canvas, innerRect.size);
      } else if (chakraId == 'kv-chakra') {
        _CodeChakraOverlayPainter(
          chakraId: 'kv-inner',
          rotationDegrees: _assetChakraRotation(chakraId),
          opacity: 0.95,
        ).paint(canvas, innerRect.size);
      }
      canvas.restore();

      _CodeChakraOverlayPainter(
        chakraId: _outerRingId(chakraId),
        rotationDegrees: _renderedChakraRotation(chakraId),
        opacity: 0.95,
      ).paint(canvas, const Size.square(outputSize));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputPixels, outputPixels);
    picture.dispose();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  // ignore: unused_element
  Future<Uint8List?> _captureMapReportImage(
    String chakraId, {
    bool showChakra = true,
    bool showChakraText = true,
  }) async {
    final croppedBytes = _croppedImageBytes;
    if (croppedBytes == null) return null;
    final source = await decodeImageFromList(croppedBytes);
    final fitsMapInsideChakra =
        chakraId == '16-directions' || chakraId == '32-gates';
    final sourceSize = Size(
      source.width.toDouble(),
      source.height.toDouble(),
    );
    if (showChakra && fitsMapInsideChakra) {
      const outputPixels = _reportRasterPixels;
      const outputSize = _reportRasterSize;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final fittedMapSize = _inscribedMapSize(
        outputSize * _mapContainmentFactor(chakraId),
        sourceSize.width / sourceSize.height,
      );
      final fittedMapRect = Rect.fromCenter(
        center: const Offset(outputSize / 2, outputSize / 2),
        width: fittedMapSize.width,
        height: fittedMapSize.height,
      );
      canvas.save();
      canvas.clipPath(
        Path()
          ..addOval(
            const Rect.fromLTWH(0, 0, outputSize, outputSize),
          ),
      );
      canvas.translate(outputSize / 2, outputSize / 2);
      canvas.rotate(_mapRotationDegrees * math.pi / 180);
      canvas.translate(-outputSize / 2, -outputSize / 2);
      canvas.drawImageRect(
        source,
        Offset.zero & sourceSize,
        fittedMapRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      if (_isAssetChakra(chakraId)) {
        _VastuPurushImagePainter(
          image: _assetChakraImage(chakraId),
          reduceCenterDot: chakraId == '32-gates',
          normalizedSourceRect: _assetArtworkBounds(chakraId),
          rotationDegrees: _assetChakraRotation(chakraId),
          opacity: 1,
          grayscale: true,
          transparentWhite: true,
        ).paint(canvas, const Size.square(outputSize));
      } else {
        _CodeChakraOverlayPainter(
          chakraId: chakraId,
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 0.95,
        ).paint(canvas, const Size.square(outputSize));
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(outputPixels, outputPixels);
      picture.dispose();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      source.dispose();
      return bytes?.buffer.asUint8List();
    }
    final logicalWidth = sourceSize.width;
    final logicalHeight = sourceSize.height;
    final outputScale =
        (_reportRasterSize / math.max(logicalWidth, logicalHeight))
            .clamp(0.5, 4.0)
            .toDouble();
    final outputWidth = math.max(1, (logicalWidth * outputScale).round());
    final outputHeight = math.max(1, (logicalHeight * outputScale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(outputScale);

    canvas.save();
    canvas.translate(logicalWidth / 2, logicalHeight / 2);
    canvas.rotate(_mapRotationDegrees * math.pi / 180);
    canvas.translate(-logicalWidth / 2, -logicalHeight / 2);
    canvas.drawImageRect(
      source,
      Offset.zero & sourceSize,
      Offset.zero & sourceSize,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    if (showChakra) {
      final placement = Offset.zero & sourceSize;
      final containedInCrop =
          chakraId == '45-devata' || chakraId == 'vastu-purush';
      final side = math.min(placement.width, placement.height) *
          (containedInCrop ? 0.96 : 1.0);
      canvas.save();
      canvas.translate(
        placement.center.dx - side / 2,
        placement.center.dy - side / 2,
      );
      if (chakraId == '45-devata' && !showChakraText) {
        final textlessOverlay = _devata45TextlessOverlay;
        if (textlessOverlay != null) {
          _VastuPurushImagePainter(
            image: textlessOverlay,
            rotationDegrees: _assetChakraRotation(chakraId),
            opacity: 1,
            grayscale: true,
            transparentWhite: true,
          ).paint(canvas, Size.square(side));
        } else {
          _Textless45DevataPainter(
            rotationDegrees: _renderedChakraRotation(chakraId),
            opacity: 0.95,
          ).paint(canvas, Size.square(side));
        }
      } else if (_isAssetChakra(chakraId)) {
        _VastuPurushImagePainter(
          image: _assetChakraImage(chakraId),
          normalizedSourceRect: _assetArtworkBounds(chakraId),
          rotationDegrees: _assetChakraRotation(chakraId),
          opacity: 1,
          grayscale: true,
          transparentWhite: true,
        ).paint(canvas, Size.square(side));
      } else {
        _CodeChakraOverlayPainter(
          chakraId: chakraId,
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 0.95,
        ).paint(canvas, Size.square(side));
      }
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    source.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<Uint8List?> _captureFifthChakraReportImage({
    ui.Image? croppedSource,
  }) async {
    final source = _decodedImage;
    if (source == null) return null;
    final sourceSize = Size(source.width.toDouble(), source.height.toDouble());
    final cropSize = _effectiveCropSize();
    final cropRect = Rect.fromCenter(
      center: _cropRect.center,
      width: cropSize.width,
      height: cropSize.height,
    );
    final side = FifthChakraGeometry.chakraSideForMap(cropSize, _mapScale);
    final chakraRect = Rect.fromCenter(
      center: cropRect.center,
      width: side,
      height: side,
    );
    final bounds = (Offset.zero & sourceSize)
        .expandToInclude(chakraRect.inflate(side * 0.08));
    final scale = (_reportRasterSize / math.max(bounds.width, bounds.height))
        .clamp(0.25, 4.0)
        .toDouble();
    final outputWidth = math.max(1, (bounds.width * scale).round());
    final outputHeight = math.max(1, (bounds.height * scale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    canvas.translate(-bounds.left, -bounds.top);
    canvas.drawImageRect(
      source,
      Offset.zero & sourceSize,
      Offset.zero & sourceSize,
      Paint()..filterQuality = FilterQuality.high,
    );

    if (croppedSource != null) {
      canvas.save();
      canvas.clipRect(cropRect);
      canvas.translate(cropRect.center.dx, cropRect.center.dy);
      canvas.rotate(_mapRotationDegrees * math.pi / 180);
      canvas.translate(-cropRect.center.dx, -cropRect.center.dy);
      canvas.drawImageRect(
        croppedSource,
        Rect.fromLTWH(
          0,
          0,
          croppedSource.width.toDouble(),
          croppedSource.height.toDouble(),
        ),
        cropRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(chakraRect.left, chakraRect.top);
    FifthChakraPainter(
      rotationDegrees: FifthChakraGeometry.rotationForBearing(
        _chakraRotationDegrees,
      ),
      opacity: 1,
    ).paint(canvas, Size.square(side));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<Uint8List?> _captureUncroppedMapReportImage(
    String chakraId, {
    bool showChakraText = true,
    ui.Image? croppedSource,
  }) async {
    final source = _decodedImage;
    if (source == null) return null;
    final sourceSize = Size(
      source.width.toDouble(),
      source.height.toDouble(),
    );
    // For 45 Devata and Vastu Purusha, the inner circle stays on the selected
    // crop while the outer ring extends slightly beyond it.
    // Build a canvas from the union of the map and chakra bounds so no part of
    // a ring is clipped before the image is placed in the PDF.
    final chakraSide = _chakraSideForCrop(chakraId);
    final chakraRect = Rect.fromCenter(
      center: _cropRect.center,
      width: chakraSide,
      height: chakraSide,
    );
    final effectiveCropSize = _effectiveCropSize();
    final processedCropRect = Rect.fromCenter(
      center: _cropRect.center,
      width: effectiveCropSize.width,
      height: effectiveCropSize.height,
    );
    // Keep a generous raster margin around the nominal chakra square. Some
    // supplied artwork and thick rotated strokes reach the square's edge;
    // exact bounds can therefore still look cut off after PDF scaling.
    final chakraExportBounds = chakraRect.inflate(chakraSide * 0.08);
    final contentBounds = (Offset.zero & sourceSize)
        .expandToInclude(processedCropRect)
        .expandToInclude(chakraExportBounds);
    final outputScale = (_reportRasterSize /
            math.max(contentBounds.width, contentBounds.height))
        .clamp(0.25, 4.0)
        .toDouble();
    final outputWidth =
        math.max(1, (contentBounds.width * outputScale).round());
    final outputHeight =
        math.max(1, (contentBounds.height * outputScale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(outputScale);
    canvas.translate(-contentBounds.left, -contentBounds.top);
    canvas.drawImageRect(
      source,
      Offset.zero & sourceSize,
      Offset.zero & sourceSize,
      Paint()..filterQuality = FilterQuality.high,
    );

    // Put the exact processed crop (including crop rotation) back at its
    // original center. The complete source remains visible outside this
    // rectangle, while the chakra aligns to the same map shown in preview.
    if (croppedSource != null) {
      canvas.save();
      canvas.clipRect(processedCropRect);
      canvas.translate(
        processedCropRect.center.dx,
        processedCropRect.center.dy,
      );
      canvas.rotate(_mapRotationDegrees * math.pi / 180);
      canvas.translate(
        -processedCropRect.center.dx,
        -processedCropRect.center.dy,
      );
      canvas.drawImageRect(
        croppedSource,
        Rect.fromLTWH(
          0,
          0,
          croppedSource.width.toDouble(),
          croppedSource.height.toDouble(),
        ),
        processedCropRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(
      _cropRect.center.dx - chakraSide / 2,
      _cropRect.center.dy - chakraSide / 2,
    );
    final chakraSize = Size.square(chakraSide);
    if (chakraId == '45-devata' && !showChakraText) {
      final textlessOverlay = _devata45TextlessOverlay;
      if (textlessOverlay != null) {
        _VastuPurushImagePainter(
          image: textlessOverlay,
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 1,
          grayscale: true,
          transparentWhite: true,
        ).paint(canvas, chakraSize);
      } else {
        _Textless45DevataPainter(
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 0.95,
        ).paint(canvas, chakraSize);
      }
    } else if (chakraId == '45-devata' && _devata45Overlay != null) {
      _VastuPurushImagePainter(
        image: _devata45Overlay,
        normalizedSourceRect: _assetArtworkBounds(chakraId),
        rotationDegrees: _assetChakraRotation(chakraId),
        opacity: 1,
        grayscale: true,
        transparentWhite: true,
      ).paint(canvas, chakraSize);
    } else if (_isAssetChakra(chakraId)) {
      _VastuPurushImagePainter(
        image: _assetChakraImage(chakraId),
        reduceCenterDot: chakraId == '32-gates',
        normalizedSourceRect: _assetArtworkBounds(chakraId),
        rotationDegrees: _assetChakraRotation(chakraId),
        opacity: 1,
        grayscale: true,
        transparentWhite: true,
      ).paint(canvas, chakraSize);
    } else {
      _CodeChakraOverlayPainter(
        chakraId: chakraId == 'vastu-purush' ? 'vastu-purush-inner' : chakraId,
        rotationDegrees: _assetChakraRotation(chakraId),
        opacity: 0.95,
      ).paint(canvas, chakraSize);
    }
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  // ignore: unused_element
  Future<Uint8List?> _captureChakraDetailImage(
    String chakraId, {
    bool showChakraText = true,
  }) async {
    const outputPixels = 1400;
    const outputSize = 1400.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..color = Colors.white,
    );

    if (chakraId == '45-devata' && !showChakraText) {
      final textlessOverlay = _devata45TextlessOverlay;
      if (textlessOverlay != null) {
        _VastuPurushImagePainter(
          image: textlessOverlay,
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 1,
          grayscale: true,
          transparentWhite: true,
        ).paint(canvas, const Size.square(outputSize));
      } else {
        _Textless45DevataPainter(
          rotationDegrees: _renderedChakraRotation(chakraId),
          opacity: 1,
        ).paint(canvas, const Size.square(outputSize));
      }
    } else if (_isAssetChakra(chakraId)) {
      _VastuPurushImagePainter(
        image: _assetChakraImage(chakraId),
        reduceCenterDot: chakraId == '32-gates',
        normalizedSourceRect: _assetArtworkBounds(chakraId),
        rotationDegrees: _assetChakraRotation(chakraId),
        opacity: 1,
        grayscale: true,
        transparentWhite: true,
      ).paint(canvas, const Size.square(outputSize));
    } else {
      _CodeChakraOverlayPainter(
        chakraId: chakraId,
        rotationDegrees: _renderedChakraRotation(chakraId),
        opacity: 1,
      ).paint(canvas, const Size.square(outputSize));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputPixels, outputPixels);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _downloadReport({bool currentOnly = false}) async {
    if (_isGeneratingReport) return;
    ui.Image? reportCropImage;
    setState(() {
      _isGeneratingReport = true;
      _reportProgress = 0.05;
      _reportStatus = 'Preparing map images…';
    });
    try {
      final croppedBytes = _croppedImageBytes;
      if (croppedBytes != null) {
        reportCropImage = await decodeImageFromList(croppedBytes);
      }
      final reports = <_MapChakraReport>[];
      final selectedReports = currentOnly
          ? [_selectedChakra]
          : _reportChakras.keys.toList(growable: false);
      final renderedImages = <String, Uint8List?>{};
      const renderBatchSize = 2;
      for (var batchStart = 0;
          batchStart < selectedReports.length;
          batchStart += renderBatchSize) {
        final batchEnd = math.min(
          batchStart + renderBatchSize,
          selectedReports.length,
        );
        final batchIds = selectedReports.sublist(batchStart, batchEnd);
        if (mounted) {
          setState(() {
            _reportStatus = batchIds.length == 1
                ? 'Rendering ${_reportChakras[batchIds.first] ?? 'Vastu Chakra'}'
                : 'Rendering two Chakra pages';
            _reportProgress =
                0.1 + (batchStart / selectedReports.length) * 0.65;
          });
        }
        final batchImages = await Future.wait(
          batchIds.map((chakraId) {
            if (chakraId == 'kv-chakra') {
              return _captureFifthChakraReportImage(
                croppedSource: reportCropImage,
              );
            }
            // Export the complete source plan for every chakra. For 16 Zone
            // and 32 Gate, _chakraSideForCrop keeps the four selected-crop
            // corners touching the chakra while the rest of the map remains
            // visible around it.
            return _captureUncroppedMapReportImage(
              chakraId,
              croppedSource: reportCropImage,
            );
          }),
        );
        for (var batchIndex = 0; batchIndex < batchIds.length; batchIndex++) {
          renderedImages[batchIds[batchIndex]] = batchImages[batchIndex];
        }
      }
      for (var index = 0; index < selectedReports.length; index++) {
        final chakraId = selectedReports[index];
        if (mounted) {
          setState(() {
            _reportStatus =
                'Rendering ${_reportChakras[chakraId] ?? 'Vastu Chakra'}…';
            _reportProgress = 0.1 + (index / selectedReports.length) * 0.65;
          });
        }
        final reportName = _reportChakras[chakraId] ?? 'Vastu Chakra';
        reports.add(
          _MapChakraReport(
            name: reportName,
            uncroppedMapImageBytes: renderedImages[chakraId],
          ),
        );
        if (mounted) {
          setState(() {
            _reportProgress =
                0.1 + ((index + 1) / selectedReports.length) * 0.65;
          });
        }
      }
      if (mounted) {
        setState(() {
          _reportProgress = 0.82;
          _reportStatus = 'Building PDF document…';
        });
      }
      final pdfBytes = await _buildPdfReport(
        reports: reports,
      );
      final now = DateTime.now();
      final filename =
          'kuber-vastu-${currentOnly ? 'current' : 'all'}-report-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
      if (mounted) {
        setState(() {
          _reportProgress = 0.96;
          _reportStatus = 'Opening save and share options…';
        });
      }
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      if (mounted) {
        setState(() => _reportProgress = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vastu report is ready to save or share.')),
        );
      }
    } catch (e) {
      _showError('Report failed: $e');
    } finally {
      reportCropImage?.dispose();
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
          _reportProgress = 0;
          _reportStatus = '';
        });
      }
    }
  }

  Future<Uint8List> _buildPdfReport({
    required List<_MapChakraReport> reports,
  }) async {
    final logoData = await rootBundle.load('assets/images/app_logo.png');
    final appLogo = pw.MemoryImage(logoData.buffer.asUint8List());
    final googlePlayIcon = await rootBundle.loadString(
      'assets/images/google_play_icon.svg',
    );
    final appleIosIcon = await rootBundle.loadString(
      'assets/images/apple_ios_icon.svg',
    );
    final document = pw.Document(
      title: 'Kuber Vastu Map Report',
      author: 'Kuber Vastu - The Miracle King',
    );
    final gold = PdfColor.fromHex('#C9A84C');
    final dark = PdfColor.fromHex('#17130D');
    for (var index = 0; index < reports.length; index++) {
      final report = reports[index];
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 26),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfHeader(appLogo, gold, dark, report.name),
              pw.SizedBox(height: 12),
              pw.Expanded(
                child: _pdfMapPanel(report.uncroppedMapImageBytes),
              ),
              pw.SizedBox(height: 8),
              _pdfFooter(
                'Page ${index + 1} of ${reports.length}',
                googlePlayIcon,
                appleIosIcon,
              ),
            ],
          ),
        ),
      );
    }
    return document.save();
  }

  pw.Widget _pdfMapPanel(Uint8List? imageBytes) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: imageBytes == null
            ? pw.Center(child: pw.Text('Preview was not available.'))
            : pw.Center(
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
      );

  pw.Widget _pdfHeader(
    pw.MemoryImage logo,
    PdfColor gold,
    PdfColor dark,
    String heading,
  ) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: gold, width: 1)),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              color: PdfColor.fromHex('#F5EEDC'),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Image(
                logo,
                width: 34,
                height: 34,
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Text(
                heading,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ),
            pw.Text(
              'www.kubervastu.com',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: gold,
              ),
            ),
          ],
        ),
      );

  // ignore: unused_element
  pw.Widget _pdfSummaryTable(
    String chakra,
    String direction,
    double degree,
  ) {
    final rows = <(String, String)>[
      ('Chakra', chakra),
      ('Direction', direction),
      ('Alignment degree', '${_formatDegree(degree)} degrees'),
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.75),
        1: pw.FlexColumnWidth(1.25),
      },
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Container(
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  row.$1,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(row.$2, style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfFooter(
    String page,
    String googlePlayIcon,
    String appleIosIcon,
  ) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'www.kubervastu.com  |  9828630111  |  9314508455',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Row(
            children: [
              pw.SvgImage(svg: googlePlayIcon, width: 12, height: 12),
              pw.SizedBox(width: 3),
              pw.Text(
                'Play Store',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SvgImage(svg: appleIosIcon, width: 12, height: 12),
              pw.SizedBox(width: 3),
              pw.Text(
                'iOS',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            page,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      );
}

class _MapChakraReport {
  final String name;
  final Uint8List? uncroppedMapImageBytes;

  const _MapChakraReport({
    required this.name,
    required this.uncroppedMapImageBytes,
  });
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  _CropMaskPainter({required this.cropRect});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()..addRect(cropRect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CropMaskPainter old) => old.cropRect != cropRect;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final w = size.width / 3, h = size.height / 3;
    canvas.drawLine(Offset(w, 0), Offset(w, size.height), paint);
    canvas.drawLine(Offset(w * 2, 0), Offset(w * 2, size.height), paint);
    canvas.drawLine(Offset(0, h), Offset(size.width, h), paint);
    canvas.drawLine(Offset(0, h * 2), Offset(size.width, h * 2), paint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _VastuPurushImagePainter extends CustomPainter {
  final ui.Image? image;
  final Rect normalizedSourceRect;
  final double rotationDegrees;
  final double opacity;
  final bool grayscale;
  final bool transparentWhite;
  final bool reduceCenterDot;

  const _VastuPurushImagePainter({
    required this.image,
    this.normalizedSourceRect = const Rect.fromLTWH(0, 0, 1, 1),
    required this.rotationDegrees,
    required this.opacity,
    this.grayscale = true,
    this.transparentWhite = false,
    this.reduceCenterDot = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final source = image;
    if (source == null) return;
    final side = size.shortestSide;
    final destination = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    canvas.save();
    canvas.translate(
      _chakraCenterCalibration(size).dx,
      _chakraCenterCalibration(size).dy,
    );
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationDegrees * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);
    // Keep supplied bitmap chakras readable over detailed floor plans while
    // retaining enough transparency to see the map underneath.
    // Bitmap chakras need extra contrast to match the generated chakra lines
    // and labels. White pixels are removed below, so this darkens only the
    // meaningful artwork while preserving the floor plan underneath.
    final effectiveOpacity = (opacity * 0.92).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(alpha: effectiveOpacity);
    if (transparentWhite) {
      // Convert the white-backed chakra bitmap to black line art with alpha
      // derived from luminance. This is reliable in PictureRecorder exports
      // on Android, iOS and web, where BlendMode.multiply can rasterize the
      // complete report image as a blank white rectangle.
      paint
        ..blendMode = BlendMode.srcOver
        ..colorFilter = const ColorFilter.matrix([
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          // Preserve the transparent white background while making the
          // Vastu Purush drawing and labels readable over detailed maps.
          // Alpha is 60% of (255 - luminance).
          -0.12756,
          -0.42912,
          -0.04332,
          0,
          153,
        ]);
    } else {
      paint.blendMode = BlendMode.multiply;
    }
    if (grayscale && !transparentWhite) {
      paint.colorFilter = const ColorFilter.matrix([
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
      ]);
    }
    if (reduceCenterDot) {
      final fullArea = Path()..addRect(destination);
      final centerCutout = Path()
        ..addOval(
          Rect.fromCircle(
            center: destination.center,
            radius: side * 0.018,
          ),
        );
      canvas.clipPath(
        Path.combine(PathOperation.difference, fullArea, centerCutout),
      );
    }
    canvas.drawImageRect(
      source,
      Rect.fromLTRB(
        normalizedSourceRect.left * source.width,
        normalizedSourceRect.top * source.height,
        normalizedSourceRect.right * source.width,
        normalizedSourceRect.bottom * source.height,
      ),
      destination,
      paint,
    );
    canvas.restore();
    if (reduceCenterDot) {
      final calibratedCenter = Offset(size.width / 2, size.height / 2) +
          _chakraCenterCalibration(size);
      canvas.drawCircle(
        calibratedCenter,
        side * 0.0045,
        Paint()..color = Colors.black.withValues(alpha: effectiveOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_VastuPurushImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.normalizedSourceRect != normalizedSourceRect ||
        oldDelegate.rotationDegrees != rotationDegrees ||
        oldDelegate.opacity != opacity ||
        oldDelegate.grayscale != grayscale ||
        oldDelegate.transparentWhite != transparentWhite ||
        oldDelegate.reduceCenterDot != reduceCenterDot;
  }
}

/// A clean 45 Devata chakra construction for report pages where the user
/// needs the zone geometry without the raster artwork's labels.
class _Textless45DevataPainter extends CustomPainter {
  final double rotationDegrees;
  final double opacity;

  const _Textless45DevataPainter({
    required this.rotationDegrees,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.48;
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.shortestSide * 0.0024);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationDegrees * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    for (final factor in [1.0, 0.70, 0.43, 0.27]) {
      canvas.drawCircle(center, radius * factor, linePaint);
    }

    // The outer Devata band contains 32 equal directional divisions.
    for (var index = 0; index < 32; index++) {
      final angle = (-90 + index * 11.25) * math.pi / 180;
      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * radius * 0.70,
              math.sin(angle) * radius * 0.70,
            ),
        center +
            Offset(
              math.cos(angle) * radius,
              math.sin(angle) * radius,
            ),
        linePaint,
      );
    }

    // Four primary inner sectors preserve the 45 Devata layout while
    // deliberately omitting all names and other text.
    for (var index = 0; index < 4; index++) {
      final angle = (-45 + index * 90) * math.pi / 180;
      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * radius * 0.27,
              math.sin(angle) * radius * 0.27,
            ),
        center +
            Offset(
              math.cos(angle) * radius * 0.70,
              math.sin(angle) * radius * 0.70,
            ),
        linePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Textless45DevataPainter oldDelegate) =>
      oldDelegate.rotationDegrees != rotationDegrees ||
      oldDelegate.opacity != opacity;
}

class _DevataLabelsPainter extends CustomPainter {
  final double rotationDegrees;
  final double opacity;

  const _DevataLabelsPainter({
    required this.rotationDegrees,
    required this.opacity,
  });

  static const _outerNames = <String>[
    'ROGA',
    'AHI',
    'MUKHYA',
    'BHALLAT',
    'SOMA',
    'BHUJANG',
    'ADITI',
    'DITI',
    'SHIKHI',
    'PARJANYA',
    'JAYANT',
    'MAHENDRI',
    'SURYA',
    'SATYA',
    'ANTRIKSH',
    'ANIL',
    'PUSHA',
    'VITATHA',
    'GRIHASPATYA',
    'YAMA',
    'GANDHARVA',
    'BHRINGRAJ',
    'MRIGAH',
    'PITRA',
    'DAUVARIK',
    'SUGREEV',
    'PUSHPDANT',
    'VARUN',
    'ASUR',
    'SHOSHA',
    'PAPYAKSHMA',
    'RUDRA',
  ];

  static const _innerNames = <String>[
    'RAJYA KSHMA',
    'BHUDHAR',
    'AAPA HAA',
    'AAPAHA VATSA',
    'ARYAMA',
    'SAVITUR',
    'SAVITRA',
    'VIVASWAN',
    'INDRA',
    'JAYA',
    'MITRA',
    'PRITHVIDHAR',
  ];

  Offset _rotate(Offset point, Offset center) {
    final angle = rotationDegrees * math.pi / 180;
    final delta = point - center;
    return center +
        Offset(
          delta.dx * math.cos(angle) - delta.dy * math.sin(angle),
          delta.dx * math.sin(angle) + delta.dy * math.cos(angle),
        );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final edge = math.min(size.width, size.height);
    final outerRadius = edge * 0.43;
    final innerRadius = edge * 0.255;

    final positions = <Offset>[];
    for (var i = 0; i < 8; i++) {
      final t = (i + 0.5) / 8;
      positions.add(Offset(center.dx - outerRadius + t * outerRadius * 2,
          center.dy - outerRadius));
    }
    for (var i = 0; i < 8; i++) {
      final t = (i + 0.5) / 8;
      positions.add(Offset(center.dx + outerRadius,
          center.dy - outerRadius + t * outerRadius * 2));
    }
    for (var i = 7; i >= 0; i--) {
      final t = (i + 0.5) / 8;
      positions.add(Offset(center.dx - outerRadius + t * outerRadius * 2,
          center.dy + outerRadius));
    }
    for (var i = 7; i >= 0; i--) {
      final t = (i + 0.5) / 8;
      positions.add(Offset(center.dx - outerRadius,
          center.dy - outerRadius + t * outerRadius * 2));
    }

    for (var i = 0; i < _outerNames.length; i++) {
      _paintSticker(canvas, _outerNames[i], _rotate(positions[i], center), edge,
          compact: true);
    }
    for (var i = 0; i < _innerNames.length; i++) {
      final angle = (-90 + i * 30) * math.pi / 180;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * innerRadius;
      _paintSticker(canvas, _innerNames[i], _rotate(point, center), edge);
    }
    _paintSticker(canvas, 'BRAHMA', center, edge, emphasized: true);
  }

  void _paintSticker(
    Canvas canvas,
    String label,
    Offset center,
    double scale, {
    bool compact = false,
    bool emphasized = false,
  }) {
    final fontSize = scale *
        (compact
            ? 0.014
            : emphasized
                ? 0.022
                : 0.016);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black.withValues(alpha: opacity),
          fontSize: fontSize.clamp(5.5, 30),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: scale * (compact ? 0.13 : 0.19));
    final padX = scale * 0.007;
    final padY = scale * 0.0035;
    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + padX * 2,
      height: painter.height + padY * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(scale * 0.008)),
      Paint()..color = Colors.white.withValues(alpha: 0.88 * opacity),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(scale * 0.008)),
      Paint()
        ..color = const Color(0xFFB88923).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, scale * 0.0012),
    );
    painter.paint(
        canvas,
        Offset(rect.center.dx - painter.width / 2,
            rect.center.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_DevataLabelsPainter oldDelegate) =>
      oldDelegate.rotationDegrees != rotationDegrees ||
      oldDelegate.opacity != opacity;
}

class _CodeChakraOverlayPainter extends CustomPainter {
  final String chakraId;
  final double rotationDegrees;
  final double opacity;

  const _CodeChakraOverlayPainter({
    required this.chakraId,
    required this.rotationDegrees,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centerCalibration = _chakraCenterCalibration(size);
    // Preserve label contrast; native painters independently soften only
    // structural lines and fills.
    final effectiveOpacity = opacity.clamp(0.0, 1.0).toDouble();
    final layerPaint = Paint()
      ..color = Colors.white.withValues(alpha: effectiveOpacity);
    if (chakraId != 'compass-chakra') {
      layerPaint.colorFilter = const ColorFilter.matrix([
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
      ]);
    }
    canvas.saveLayer(
      rect,
      layerPaint,
    );
    canvas.translate(centerCalibration.dx, centerCalibration.dy);
    chakraPainterFor(
      chakraId,
      -rotationDegrees,
      transparentBackground: true,
    ).paint(canvas, size);
    if (chakraId == '16-directions' || chakraId == '32-gates') {
      // Remove the final antialiased circumference left by the filled sector
      // edges. The overlay is isolated in this saveLayer, so clearing here
      // affects only the chakra and never the underlying floor plan.
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.shortestSide * 0.49,
        Paint()
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2.4, size.shortestSide * 0.006),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CodeChakraOverlayPainter oldDelegate) {
    return oldDelegate.chakraId != chakraId ||
        oldDelegate.rotationDegrees != rotationDegrees ||
        oldDelegate.opacity != opacity;
  }
}
