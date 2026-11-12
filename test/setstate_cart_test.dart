import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cart_four_ways/setstate/cart_page_setstate.dart';

void main() {
  testWidgets(
    'Adding two keyboards and applying SAVE10 gives 88.20',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SetStateCartPage(),
        ),
      );

      // Add two keyboards.
      await tester.tap(find.text('Keyboard · 49'));
      await tester.pump();

      await tester.tap(find.text('Keyboard · 49'));
      await tester.pump();

      // Enter the coupon.
      await tester.enterText(
        find.byKey(const Key('coupon-field')),
        'SAVE10',
      );

      // Apply the coupon.
      await tester.tap(find.text('Apply'));
      await tester.pump();

      // 49 × 2 = 98
      // 10% discount = 9.80
      // Total = 88.20
      expect(find.text('88.20'), findsOneWidget);
    },
  );
}