
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartBloc(CheckoutApi()),
      child: const _BlocCartView(),
    );
  }
}

class _BlocCartView extends StatefulWidget {
  const _BlocCartView();

  @override
  State<_BlocCartView> createState() => _BlocCartViewState();
}

class _BlocCartViewState extends State<_BlocCartView> {
  final TextEditingController _couponController =
      TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (previous, current) =>
          previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        if (state.status == CheckoutStatus.success) {
          _couponController.clear();

          messenger.hideCurrentMaterialBanner();
          messenger.showSnackBar(
            SnackBar(
              content: Text('Order placed: ${state.orderId}'),
            ),
          );
        } else if (state.status == CheckoutStatus.failure) {
          messenger.hideCurrentMaterialBanner();
          messenger.showMaterialBanner(
            MaterialBanner(
              content: Text(
                state.checkoutError ?? 'Checkout failed',
              ),
              actions: [
                TextButton(
                  onPressed: messenger.hideCurrentMaterialBanner,
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart · Bloc'),
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Undo',
                  onPressed: state.canUndo
                      ? () {
                          context.read<CartBloc>().add(
                                const CartUndone(),
                              );
                        }
                      : null,
                  icon: const Icon(Icons.undo),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            return CartBody(
              state: state,
              couponController: _couponController,
              onAdd: (product) {
                context.read<CartBloc>().add(
                      CartProductAdded(product),
                    );
              },
              onQtyChanged: (productId, delta) {
                context.read<CartBloc>().add(
                      CartQtyChanged(productId, delta),
                    );
              },
              onApplyCoupon: (code) {
                context.read<CartBloc>().add(
                      CartCouponApplied(code),
                    );
              },
              onCheckout: () {
                context.read<CartBloc>().add(
                      const CartCheckoutRequested(),
                    );
              },
              summary: const BlocSummaryCard(),
            );
          },
        ),
      ),
    );
  }
}

class BlocSummaryCard extends StatelessWidget {
  const BlocSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        CartBloc,
        CartState,
        (int, double, double, double)>(
      selector: (state) => (
        state.itemCount,
        state.subtotal,
        state.discount,
        state.total,
      ),
      builder: (context, summary) {
        debugPrint(
          'BlocSummaryCard rebuilt. Total: ${summary.$4}',
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items: ${summary.$1}'),
                Text(
                  'Subtotal: \$${summary.$2.toStringAsFixed(2)}',
                ),
                Text(
                  'Discount: \$${summary.$3.toStringAsFixed(2)}',
                ),
                const Divider(),
                Text(
                  'Total: \$${summary.$4.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
