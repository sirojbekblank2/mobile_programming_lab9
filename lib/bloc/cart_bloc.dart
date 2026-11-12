
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(_onProductAdded);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCheckoutRequested>(
      _onCheckoutRequested,
      transformer: droppable(),
    );
    on<CartUndone>(_onUndone);
  }

  final CheckoutApi _api;

  CartSnapshot _snapshot(CartState current) {
    return CartSnapshot(
      lines: current.lines,
      coupon: current.coupon,
      couponError: current.couponError,
    );
  }

  void _emitCartMutation(
    Emitter<CartState> emit, {
    required List<CartLine> lines,
    String? coupon,
    String? couponError,
    bool clearCoupon = false,
    bool clearCouponError = false,
  }) {
    final nextSnapshot = CartSnapshot(
      lines: lines,
      coupon: clearCoupon ? null : coupon ?? state.coupon,
      couponError:
          clearCouponError ? null : couponError ?? state.couponError,
    );

    if (nextSnapshot == _snapshot(state)) return;

    emit(
      state.copyWith(
        lines: lines,
        coupon: coupon,
        couponError: couponError,
        clearCoupon: clearCoupon,
        clearCouponError: clearCouponError,
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
        history: [...state.history, _snapshot(state)],
        canUndo: true,
      ),
    );
  }

  void _onProductAdded(
    CartProductAdded event,
    Emitter<CartState> emit,
  ) {
    _emitCartMutation(
      emit,
      lines: state.lines.withProduct(event.product),
      clearCouponError: true,
    );
  }

  void _onQtyChanged(
    CartQtyChanged event,
    Emitter<CartState> emit,
  ) {
    _emitCartMutation(
      emit,
      lines: state.lines.changeQty(event.productId, event.delta),
      clearCouponError: true,
    );
  }

  void _onCouponApplied(
    CartCouponApplied event,
    Emitter<CartState> emit,
  ) {
    final normalizedCode = event.code.trim().toUpperCase();

    if (normalizedCode == 'SAVE10') {
      _emitCartMutation(
        emit,
        lines: state.lines,
        coupon: normalizedCode,
        clearCouponError: true,
      );
    } else {
      _emitCartMutation(
        emit,
        lines: state.lines,
        clearCoupon: true,
        couponError: 'Invalid coupon code',
      );
    }
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.lines.isEmpty ||
        state.status == CheckoutStatus.submitting) {
      return;
    }

    final previousSnapshot = _snapshot(state);
    final checkoutTotal = state.total;

    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        clearOrderId: true,
        clearCheckoutError: true,
      ),
    );

    try {
      final orderId = await _api.submit(checkoutTotal);

      if (emit.isDone) return;

      emit(
        state.copyWith(
          lines: const [],
          clearCoupon: true,
          clearCouponError: true,
          status: CheckoutStatus.success,
          orderId: orderId,
          clearCheckoutError: true,
          history: [...state.history, previousSnapshot],
          canUndo: true,
        ),
      );
    } on CheckoutException catch (error) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: error.message,
        ),
      );
    }
  }

  void _onUndone(
    CartUndone event,
    Emitter<CartState> emit,
  ) {
    if (state.history.isEmpty) return;

    final previousSnapshot = state.history.last;
    final remainingHistory = state.history.sublist(
      0,
      state.history.length - 1,
    );

    emit(
      state.copyWith(
        lines: previousSnapshot.lines,
        coupon: previousSnapshot.coupon,
        couponError: previousSnapshot.couponError,
        clearCoupon: previousSnapshot.coupon == null,
        clearCouponError: previousSnapshot.couponError == null,
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
        history: remainingHistory,
        canUndo: remainingHistory.isNotEmpty,
      ),
    );
  }
}
