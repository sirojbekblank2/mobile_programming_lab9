
import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
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
        Expanded(
          child: lines.isEmpty
              ? const Center(
                  child: Text('Cart is empty'),
                )
              : ListView(
                  children: [
                    for (final line in lines)
                      ListTile(
                        key: ValueKey(line.product.id),
                        title: Text(line.product.name),
                        subtitle: Text('× ${line.qty}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onRemove(line.product.id),
                        ),
                      ),
                  ],
                ),
        ),
        ListTile(
          title: const Text('Subtotal'),
          trailing: Text(
            lines.subtotal.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }
}
