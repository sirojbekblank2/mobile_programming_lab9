
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;
  final List<CartState> _history = [];

  void _saveHistory() {
    _history.add(state);
  }

  void add(Product product) {
    final nextState = state.copyWith(
      lines: state.lines.withProduct(product),
      status: CheckoutStatus.idle,
      clearOrderId: true,
      clearCheckoutError: true,
    );

    _emitMutation(nextState);
  }

  void changeQty(String productId, int delta) {
    final nextState = state.copyWith(
      lines: state.lines.changeQty(productId, delta),
      status: CheckoutStatus.idle,
      clearOrderId: true,
      clearCheckoutError: true,
    );

    _emitMutation(nextState);
  }

  void applyCoupon(String code) {
    final normalizedCode = code.trim().toUpperCase();

    final CartState nextState;

    if (normalizedCode == 'SAVE10') {
      nextState = state.copyWith(
        coupon: normalizedCode,
        clearCouponError: true,
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    } else {
      nextState = state.copyWith(
        clearCoupon: true,
        couponError: 'Invalid coupon code',
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    }

    _emitMutation(nextState);
  }

  void _emitMutation(CartState nextState) {
    if (nextState == state) {
      emit(nextState);
      return;
    }

    _saveHistory();
    emit(nextState.copyWith(canUndo: true));
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty ||
        state.status == CheckoutStatus.submitting) {
      return;
    }

    final previousState = state;
    final total = state.total;

    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        clearOrderId: true,
        clearCheckoutError: true,
      ),
    );

    try {
      final orderId = await _api.submit(total);

      if (isClosed) return;

      _history.add(previousState);

      emit(
        state.copyWith(
          lines: const [],
          clearCoupon: true,
          clearCouponError: true,
          status: CheckoutStatus.success,
          orderId: orderId,
          clearCheckoutError: true,
          canUndo: true,
        ),
      );
    } on CheckoutException catch (error) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: error.message,
        ),
      );
    }
  }

  void undo() {
    if (_history.isEmpty) return;

    final previousState = _history.removeLast();

    emit(
      previousState.copyWith(
        canUndo: _history.isNotEmpty,
      ),
    );
  }
}
