import 'package:divinewall/widgets/remedy_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget gallery(List<String> images) => MaterialApp(
    home: Scaffold(
        body: SizedBox(
            width: 360,
            height: 260,
            child: RemedyImageCarousel(
                images: images,
                imageBuilder: (_, image) => Center(child: Text(image))))));

void main() {
  testWidgets('product photos support arrows, swiping and wraparound',
      (tester) async {
    await tester.pumpWidget(gallery(['Photo A', 'Photo B', 'Photo C']));
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next product image'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Next product image'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous product image'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets(
      'photo list changes reset selection and single images hide arrows',
      (tester) async {
    await tester.pumpWidget(gallery(['Photo A', 'Photo B']));
    await tester.tap(find.byTooltip('Next product image'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(gallery(['Replacement']));
    await tester.pumpAndSettle();
    expect(find.text('Replacement'), findsOneWidget);
    expect(find.byTooltip('Next product image'), findsNothing);
    expect(find.text('2 / 1'), findsNothing);
  });
}
