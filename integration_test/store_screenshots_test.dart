import 'package:divinewall/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture real App Store screens', (tester) async {
    app.main();
    // Use bounded pumps: the compass and splash schedule ongoing frames.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.byType(NavigationBar), findsOneWidget);

    for (final screen in [
      ('Home', '01-home'),
      ('Remedies', '02-remedies'),
      ('Discover', '03-discover'),
    ]) {
      final destination = find.byWidgetPredicate(
        (widget) =>
            widget is NavigationDestination && widget.label == screen.$1,
      );
      await tester.tap(destination);
      await tester.pump(const Duration(seconds: 1));
      // Let actual backend content, images and fonts load without mocking them.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: '${screen.$1} is still loading');
      expect(find.byType(Shimmer), findsNothing,
          reason: '${screen.$1} content is still loading');
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(screen.$2);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
