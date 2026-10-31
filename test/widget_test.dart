import 'package:divinewall/main.dart';
import 'package:divinewall/models/remedy_data.dart';
import 'package:divinewall/services/account_storage.dart';
import 'package:divinewall/services/compass_service.dart';
import 'package:divinewall/widgets/shared_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('cart adds remedies, updates quantities, and calculates totals',
      () async {
    SharedPreferences.setMockInitialValues({});
    final account = AccountStorage();
    final remedy = RemedyCatalog.all.first;

    await account.addToCart(remedy);
    await account.addToCart(remedy);
    expect(account.cartCount, 2);
    expect(account.cartTotal, remedy.price * 2);

    await account.setCartQuantity(remedy.id, 1);
    expect(account.cartCount, 1);
    expect(account.cartTotal, remedy.price);

    await account.setCartQuantity(remedy.id, 0);
    expect(account.cart, isEmpty);

    await account.addOrder(
      RemedyOrder(
        remedyId: remedy.id,
        remedyName: remedy.title,
        price: remedy.price,
        status: 'paid',
        purchasedAt: DateTime.now(),
        validityStartsAt: DateTime.now(),
        validityEndsAt: DateTime.now().add(const Duration(days: 365)),
      ),
    );
    expect(account.activePurchaseFor(remedy.id), isNotNull);
  });

  test('compass headings normalize across north', () {
    expect(CompassService.normalizeHeading(360), 0);
    expect(CompassService.normalizeHeading(-1), 359);
    expect(CompassService.normalizeHeading(721.5), 1.5);
  });

  test('compass uses the shortest rotation across north', () {
    expect(CompassService.shortestDelta(359, 1), 2);
    expect(CompassService.shortestDelta(1, 359), -2);
    expect(CompassService.shortestDelta(45, 90), 45);
  });

  test('compass chakra artwork is aligned to cardinal headings', () {
    expect(compassChakraRotationDegrees(0), 180);
    expect(compassChakraRotationDegrees(90), 90);
    expect(compassChakraRotationDegrees(180), 0);
    expect(compassChakraRotationDegrees(270), -90);
    expect(compassChakraRotationDegrees(360), 180);
  });

  testWidgets('opens the Kubar Vastu app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const DivineWallApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('Chakra'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Map'), findsWidgets);
  });
}
