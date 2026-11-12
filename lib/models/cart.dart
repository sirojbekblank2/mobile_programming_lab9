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

/// Pure cart operations shared by all four state-management styles.
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

  List<CartLine> changeQty(String productId, int delta) {
    return [
      for (final line in this)
        if (line.product.id != productId)
          line
        else if (line.qty + delta > 0)
          line.copyWith(qty: line.qty + delta),
    ];
  }

  double get subtotal {
    return fold(0.0, (sum, line) => sum + line.subtotal);
  }

  int get itemCount {
    return fold(0, (sum, line) => sum + line.qty);
  }
}

enum CheckoutStatus {
  idle,
  submitting,
  success,
  failure,
}

/// Complete immutable state of the cart.
class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;

  // Derived values: never store these separately.
  int get itemCount => lines.itemCount;

  double get subtotal => lines.subtotal;

  double get discount {
    return coupon == 'SAVE10' ? subtotal * 0.10 : 0;
  }

  double get total => subtotal - discount;

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    String? couponError,
    CheckoutStatus? status,
    String? orderId,
    String? checkoutError,
    bool clearCoupon = false,
    bool clearCouponError = false,
    bool clearOrderId = false,
    bool clearCheckoutError = false,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: clearCoupon ? null : coupon ?? this.coupon,
      couponError:
          clearCouponError ? null : couponError ?? this.couponError,
      status: status ?? this.status,
      orderId: clearOrderId ? null : orderId ?? this.orderId,
      checkoutError: clearCheckoutError
          ? null
          : checkoutError ?? this.checkoutError,
    );
  }
}