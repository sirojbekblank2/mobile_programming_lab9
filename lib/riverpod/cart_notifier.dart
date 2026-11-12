
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) {
  return CheckoutApi();
});

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = [];

  @override
  CartState build() {
    return const CartState();
  }

  bool get canUndo => _history.isNotEmpty;

  void _saveHistory() {
    _history.add(
      state.copyWith(
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      ),
    );
  }

  void add(Product product) {
    _saveHistory();

    state = state.copyWith(
      lines: state.lines.withProduct(product),
      status: CheckoutStatus.idle,
      clearOrderId: true,
      clearCheckoutError: true,
    );
  }

  void changeQty(String productId, int delta) {
    _saveHistory();

    state = state.copyWith(
      lines: state.lines.changeQty(productId, delta),
      status: CheckoutStatus.idle,
      clearOrderId: true,
      clearCheckoutError: true,
    );
  }

  void applyCoupon(String code) {
    _saveHistory();

    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode == 'SAVE10') {
      state = state.copyWith(
        coupon: normalizedCode,
        clearCouponError: true,
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    } else {
      state = state.copyWith(
        clearCoupon: true,
        couponError: 'Invalid coupon code',
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    }
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.status == CheckoutStatus.submitting) {
      return;
    }

    final api = ref.read(checkoutApiProvider);
    final total = state.total;

    state = state.copyWith(
      status: CheckoutStatus.submitting,
      clearOrderId: true,
      clearCheckoutError: true,
    );

    try {
      final orderId = await api.submit(total);

      if (!ref.mounted) return;

      _saveHistory();

      state = state.copyWith(
        lines: const [],
        clearCoupon: true,
        clearCouponError: true,
        status: CheckoutStatus.success,
        orderId: orderId,
        clearCheckoutError: true,
      );
    } on CheckoutException catch (error) {
      if (!ref.mounted) return;

      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: error.message,
      );
    }
  }

  void undo() {
    if (_history.isEmpty) return;

    state = _history.removeLast();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
  isAutoDispose: true,
);

final canUndoProvider = Provider<bool>((ref) {
  // Watch cart changes so this provider recalculates when history changes.
  ref.watch(cartProvider);

  return ref.read(cartProvider.notifier).canUndo;
});
