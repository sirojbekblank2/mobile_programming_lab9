
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({
    required this.product,
    required this.qty,
  });

  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) {
    return CartLine(
      product: product,
      qty: qty ?? this.qty,
    );
  }
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product product) {
    final index = indexWhere(
      (line) => line.product.id == product.id,
    );

    if (index == -1) {
      return [
        ...this,
        CartLine(product: product, qty: 1),
      ];
    }

    return [
      for (final line in this)
        line.product.id == product.id
            ? line.copyWith(qty: line.qty + 1)
            : line,
    ];
  }

  List<CartLine> without(String productId) {
    return [
      for (final line in this)
        if (line.product.id != productId) line,
    ];
  }

  double get subtotal {
    return fold<double>(
      0,
      (sum, line) => sum + line.subtotal,
    );
  }

  int get itemCount {
    return fold<int>(
      0,
      (sum, line) => sum + line.qty,
    );
  }
}
