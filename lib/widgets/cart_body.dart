
import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.state,
    required this.couponController,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.onCheckout,
    this.summary,
  });

  final CartState state;
  final TextEditingController couponController;

  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String code) onApplyCoupon;
  final VoidCallback onCheckout;

  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final product in catalog)
                ActionChip(
                  label: Text(
                    '${product.name} · ${product.price.toStringAsFixed(0)}',
                  ),
                  onPressed: () => onAdd(product),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('coupon-field'),
                  controller: couponController,
                  decoration: const InputDecoration(
                    hintText: 'Coupon code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () =>
                    onApplyCoupon(couponController.text),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
        if (state.couponError != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              state.couponError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: state.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final line in state.lines)
                      ListTile(
                        key: ValueKey(line.product.id),
                        title: Text(line.product.name),
                        subtitle: Text(
                          '${line.product.price.toStringAsFixed(2)} each',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Decrease quantity',
                              icon: const Icon(Icons.remove),
                              onPressed: () => onQtyChanged(
                                line.product.id,
                                -1,
                              ),
                            ),
                            Text('${line.qty}'),
                            IconButton(
                              tooltip: 'Increase quantity',
                              icon: const Icon(Icons.add),
                              onPressed: () => onQtyChanged(
                                line.product.id,
                                1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        summary ??
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _summaryRow('Items', '${state.itemCount}'),
                    _summaryRow(
                      'Subtotal',
                      state.subtotal.toStringAsFixed(2),
                    ),
                    _summaryRow(
                      'Discount',
                      state.discount.toStringAsFixed(2),
                    ),
                    const Divider(),
                    _summaryRow(
                      'Total',
                      state.total.toStringAsFixed(2),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.status == CheckoutStatus.submitting ||
                      state.lines.isEmpty
                  ? null
                  : onCheckout,
              child: state.status == CheckoutStatus.submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Checkout'),
            ),
          ),
        ),
      ],
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
