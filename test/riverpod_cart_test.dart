
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  test(
    'Adding two keyboards and applying SAVE10 gives 88.20',
    () {
      final container = ProviderContainer();

      addTearDown(container.dispose);

      // Keep the auto-disposed provider alive during the test.
      final subscription = container.listen(
        cartProvider,
        (previous, next) {},
      );

      addTearDown(subscription.close);

      final cart = container.read(cartProvider.notifier);

      cart.add(catalog[0]);
      cart.add(catalog[0]);
      cart.applyCoupon('SAVE10');

      final state = container.read(cartProvider);

      expect(state.itemCount, 2);
      expect(state.subtotal, 98);
      expect(state.discount, 9.8);
      expect(state.total, 88.2);
    },
  );

  test(
    'Checkout failure preserves cart lines',
    () async {
      final mockApi = MockCheckoutApi();

      when(() => mockApi.submit(any())).thenThrow(
        const CheckoutException('Card declined'),
      );

      final container = ProviderContainer(
        overrides: [
          checkoutApiProvider.overrideWithValue(mockApi),
        ],
      );

      addTearDown(container.dispose);

      // Keep the auto-disposed provider alive during the test.
      final subscription = container.listen(
        cartProvider,
        (previous, next) {},
      );

      addTearDown(subscription.close);

      final cart = container.read(cartProvider.notifier);

      // Three monitors cost 597, which is above the API's 500 limit.
      cart.add(catalog[2]);
      cart.add(catalog[2]);
      cart.add(catalog[2]);

      await cart.checkout();

      final state = container.read(cartProvider);

      expect(state.status, CheckoutStatus.failure);
      expect(state.checkoutError, 'Card declined');
      expect(state.itemCount, 3);
      expect(state.lines.length, 1);

      verify(() => mockApi.submit(597)).called(1);
    },
  );
}
