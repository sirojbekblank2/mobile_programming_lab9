
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late MockCheckoutApi mockApi;

  setUp(() {
    mockApi = MockCheckoutApi();
  });

  group('CartCubit', () {
    blocTest<CartCubit, CartState>(
      'adds the same product twice and applies SAVE10',
      build: () {
        return CartCubit(mockApi);
      },
      act: (cubit) {
        cubit.add(catalog[0]);
        cubit.add(catalog[0]);
        cubit.applyCoupon('SAVE10');
      },
      expect: () => [
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 1),
          ],
          canUndo: true,
        ),
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 2),
          ],
          canUndo: true,
        ),
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 2),
          ],
          coupon: 'SAVE10',
          canUndo: true,
        ),
      ],
    );

    
blocTest<CartCubit, CartState>(
  'emits submitting then failure when checkout is declined',
  build: () {
    when(() => mockApi.submit(any())).thenThrow(
      const CheckoutException('Card declined'),
    );

    return CartCubit(mockApi);
  },
  act: (cubit) async {
    cubit.add(catalog[2]);
    cubit.add(catalog[2]);
    cubit.add(catalog[2]);

    await cubit.checkout();
  },
  expect: () => [
    CartState(
      lines: [
        CartLine(product: catalog[2], qty: 1),
      ],
      canUndo: true,
    ),
    CartState(
      lines: [
        CartLine(product: catalog[2], qty: 2),
      ],
      canUndo: true,
    ),
    CartState(
      lines: [
        CartLine(product: catalog[2], qty: 3),
      ],
      canUndo: true,
    ),
    CartState(
      lines: [
        CartLine(product: catalog[2], qty: 3),
      ],
      canUndo: true,
      status: CheckoutStatus.submitting,
    ),
    CartState(
      lines: [
        CartLine(product: catalog[2], qty: 3),
      ],
      canUndo: true,
      status: CheckoutStatus.failure,
      checkoutError: 'Card declined',
    ),
  ],
  verify: (_) {
    verify(() => mockApi.submit(597.0)).called(1);
  },
);

  });
}
