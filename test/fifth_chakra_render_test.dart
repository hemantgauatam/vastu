import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:divinewall/chakras/fifth_chakra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> bluePixelCount() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  const FifthChakraPainter(rotationDegrees: 0, opacity: 1)
      .paint(canvas, const Size.square(400));
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 400);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(data, isNotNull);
  var bluePixels = 0;
  for (var offset = 0; offset < data!.lengthInBytes; offset += 4) {
    if (data.getUint8(offset + 2) > data.getUint8(offset) + 50 &&
        data.getUint8(offset + 2) > data.getUint8(offset + 1) + 25) {
      bluePixels++;
    }
  }
  image.dispose();
  picture.dispose();
  return bluePixels;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fifth chakra paints its blue radial rings', () async {
    expect(await bluePixelCount(), greaterThan(100));
  });

  test('map rectangle fits within fifth chakra inner circle', () {
    final map = FifthChakraGeometry.mapSize(500, 1.5, 0.96);
    final diagonal = math.sqrt(map.width * map.width + map.height * map.height);
    expect(diagonal,
        closeTo(500 * FifthChakraGeometry.innerDiameterFraction * 0.96, 0.001));
  });
}
