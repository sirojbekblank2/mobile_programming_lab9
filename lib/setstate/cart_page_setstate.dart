import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() =>
      _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState _state = const CartState();

  final List<CartState> _history = [];

  final TextEditingController _couponController =
      TextEditingController();

  final CheckoutApi _checkoutApi = CheckoutApi();

  void _saveHistory() {
    _history.add(
      _state.copyWith(
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      ),
    );
  }

  void _add(Product product) {
    _saveHistory();

    setState(() {
      _state = _state.copyWith(
        lines: _state.lines.withProduct(product),
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    });
  }

  void _changeQty(String productId, int delta) {
    _saveHistory();

    setState(() {
      _state = _state.copyWith(
        lines: _state.lines.changeQty(productId, delta),
        status: CheckoutStatus.idle,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    });
  }

  void _applyCoupon(String code) {
    _saveHistory();

    final normalizedCode = code.trim().toUpperCase();

    setState(() {
      if (normalizedCode == 'SAVE10') {
        _state = _state.copyWith(
          coupon: normalizedCode,
          clearCouponError: true,
          status: CheckoutStatus.idle,
          clearOrderId: true,
          clearCheckoutError: true,
        );
      } else {
        _state = _state.copyWith(
          clearCoupon: true,
          couponError: 'Invalid coupon code',
          status: CheckoutStatus.idle,
          clearOrderId: true,
          clearCheckoutError: true,
        );
      }
    });
  }

  Future<void> _checkout() async {
    setState(() {
      _state = _state.copyWith(
        status: CheckoutStatus.submitting,
        clearOrderId: true,
        clearCheckoutError: true,
      );
    });

    try {
      final orderId = await _checkoutApi.submit(_state.total);

      if (!mounted) return;

      _saveHistory();

      setState(() {
        _state = _state.copyWith(
          lines: const [],
          clearCoupon: true,
          clearCouponError: true,
          status: CheckoutStatus.success,
          orderId: orderId,
          clearCheckoutError: true,
        );
      });

      _couponController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order successful: $orderId'),
        ),
      );
    } on CheckoutException catch (error) {
      if (!mounted) return;

      setState(() {
        _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: error.message,
        );
      });
    }
  }

  void _undo() {
    if (_history.isEmpty) return;

    setState(() {
      _state = _history.removeLast();
      _couponController.text = _state.coupon ?? '';
    });
  }

  void _dismissCheckoutError() {
    setState(() {
      _state = _state.copyWith(
        status: CheckoutStatus.idle,
        clearCheckoutError: true,
      );
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: _history.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_state.checkoutError != null)
            MaterialBanner(
              content: Text(_state.checkoutError!),
              leading: const Icon(Icons.error_outline),
              actions: [
                TextButton(
                  onPressed: _dismissCheckoutError,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: CartBody(
              state: _state,
              couponController: _couponController,
              onAdd: _add,
              onQtyChanged: _changeQty,
              onApplyCoupon: _applyCoupon,
              onCheckout: _checkout,
            ),
          ),
        ],
      ),
    );
  }
}