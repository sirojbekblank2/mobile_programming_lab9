
import 'package:flutter/foundation.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) {
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(id, name, price);
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

  @override
  bool operator ==(Object other) {
    return other is CartLine &&
        other.product == product &&
        other.qty == qty;
  }

  @override
  int get hashCode => Object.hash(product, qty);
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

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.canUndo = false,
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final bool canUndo;

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
    bool? canUndo,
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
      canUndo: canUndo ?? this.canUndo,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CartState &&
        listEquals(other.lines, lines) &&
        other.coupon == coupon &&
        other.couponError == couponError &&
        other.status == status &&
        other.orderId == orderId &&
        other.checkoutError == checkoutError &&
        other.canUndo == canUndo;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(lines),
      coupon,
      couponError,
      status,
      orderId,
      checkoutError,
      canUndo,
    );
  }
}
