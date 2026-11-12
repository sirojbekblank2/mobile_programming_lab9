
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  late MockCheckoutApi mockApi;

  setUp(() {
    mockApi = MockCheckoutApi();
  });

  group('CartBloc', () {
    blocTest<CartBloc, CartState>(
      'adds the same product twice and applies SAVE10',
      build: () => CartBloc(mockApi),
      act: (bloc) {
        bloc.add(CartProductAdded(catalog[0]));
        bloc.add(CartProductAdded(catalog[0]));
        bloc.add(const CartCouponApplied('SAVE10'));
      },
      expect: () => [
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 1),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 2),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[0], qty: 1),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[0], qty: 2),
          ],
          coupon: 'SAVE10',
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[0], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[0], qty: 2),
              ],
            ),
          ],
        ),
      ],
    );

    blocTest<CartBloc, CartState>(
      'emits submitting then failure when checkout is declined',
      build: () {
        when(() => mockApi.submit(any())).thenThrow(
          const CheckoutException('Card declined'),
        );

        return CartBloc(mockApi);
      },
      act: (bloc) {
        bloc.add(CartProductAdded(catalog[2]));
        bloc.add(CartProductAdded(catalog[2]));
        bloc.add(CartProductAdded(catalog[2]));
        bloc.add(const CartCheckoutRequested());
      },
      expect: () => [
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 1),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 2),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 3),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 3),
          ],
          canUndo: true,
          status: CheckoutStatus.submitting,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 3),
          ],
          canUndo: true,
          status: CheckoutStatus.failure,
          checkoutError: 'Card declined',
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockApi.submit(597.0)).called(1);
      },
    );

    blocTest<CartBloc, CartState>(
      'ignores duplicate checkout events while one is running',
      build: () {
        when(() => mockApi.submit(any())).thenAnswer(
          (_) {
            submitted.complete();
            return checkoutCompleter.future;
          },
        );

        return CartBloc(mockApi);
      },
      setUp: () {
        submitted = Completer<void>();
        checkoutCompleter = Completer<String>();
      },
      act: (bloc) async {
        final productsAdded = bloc.stream.firstWhere(
          (state) => state.itemCount == 3,
        );

        bloc.add(CartProductAdded(catalog[2]));
        bloc.add(CartProductAdded(catalog[2]));
        bloc.add(CartProductAdded(catalog[2]));

        await productsAdded;

        bloc.add(const CartCheckoutRequested());
        bloc.add(const CartCheckoutRequested());

        await submitted.future;

        checkoutCompleter.complete('ORD-1234');
      },
      expect: () => [
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 1),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 2),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 3),
          ],
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
          ],
        ),
        CartState(
          lines: [
            CartLine(product: catalog[2], qty: 3),
          ],
          canUndo: true,
          status: CheckoutStatus.submitting,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
          ],
        ),
        CartState(
          status: CheckoutStatus.success,
          orderId: 'ORD-1234',
          canUndo: true,
          history: [
            const CartSnapshot(lines: []),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 1),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 2),
              ],
            ),
            CartSnapshot(
              lines: [
                CartLine(product: catalog[2], qty: 3),
              ],
            ),
          ],
        ),
      ],
      verify: (_) {
        verify(() => mockApi.submit(597.0)).called(1);
      },
    );
  });
}

late Completer<void> submitted;
late Completer<String> checkoutCompleter;
