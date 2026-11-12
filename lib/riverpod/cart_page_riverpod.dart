
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() =>
      _RiverpodCartPageState();
}

class _RiverpodCartPageState
    extends ConsumerState<RiverpodCartPage> {
  final TextEditingController _couponController =
      TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for status changes to perform UI side effects.
    ref.listen<CheckoutStatus>(
      cartProvider.select((state) => state.status),
      (previous, next) {
        if (next == CheckoutStatus.success) {
          final orderId = ref.read(cartProvider).orderId;

          _couponController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order successful: $orderId'),
            ),
          );
        }

        if (next == CheckoutStatus.failure) {
          final error = ref.read(cartProvider).checkoutError ??
              'Checkout failed';

          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              content: Text(error),
              leading: const Icon(Icons.error_outline),
              actions: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .hideCurrentMaterialBanner();
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        }
      },
    );

    // Watch the cart so the page displays the latest state.
    final state = ref.watch(cartProvider);

    // Watch undo availability so the AppBar button updates.
    final canUndo = ref.watch(canUndoProvider);

    // Read the notifier once to obtain its methods.
    // This does not subscribe this widget to notifier changes.
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: CartBody(
        state: state,
        couponController: _couponController,
        onAdd: cart.add,
        onQtyChanged: cart.changeQty,
        onApplyCoupon: cart.applyCoupon,
        onCheckout: cart.checkout,
        summary: const RiverpodSummaryCard(),
      ),
    );
  }
}

class RiverpodSummaryCard extends ConsumerWidget {
  const RiverpodSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each selector listens only to the value it needs.
    final itemCount = ref.watch(
      cartProvider.select((state) => state.itemCount),
    );

    final subtotal = ref.watch(
      cartProvider.select((state) => state.subtotal),
    );

    final discount = ref.watch(
      cartProvider.select((state) => state.discount),
    );

    final total = ref.watch(
      cartProvider.select((state) => state.total),
    );

    debugPrint('RiverpodSummaryCard rebuilt. Total: $total');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _summaryRow('Items', '$itemCount'),
            _summaryRow(
              'Subtotal',
              subtotal.toStringAsFixed(2),
            ),
            _summaryRow(
              'Discount',
              discount.toStringAsFixed(2),
            ),
            const Divider(),
            _summaryRow(
              'Total',
              total.toStringAsFixed(2),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
