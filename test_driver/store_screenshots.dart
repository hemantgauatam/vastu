import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Platform.environment['SCREENSHOT_OUTPUT']!;
  await Directory(output).create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      // iOS captures each screen when takeScreenshot is called in the test.
      // The driver receives these saved PNGs after the test completes.
      await File('$output/$name.png').writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
