
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(CheckoutApi()),
      child: const _CubitCartView(),
    );
  }
}

class _CubitCartView extends StatefulWidget {
  const _CubitCartView();

  @override
  State<_CubitCartView> createState() => _CubitCartViewState();
}

class _CubitCartViewState extends State<_CubitCartView> {
  final TextEditingController _couponController =
      TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
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
          title: const Text('Cart · Cubit'),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Undo',
                  onPressed: state.canUndo
                      ? () => context.read<CartCubit>().undo()
                      : null,
                  icon: const Icon(Icons.undo),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            final cubit = context.read<CartCubit>();

            return CartBody(
              state: state,
              couponController: _couponController,
              onAdd: cubit.add,
              onQtyChanged: cubit.changeQty,
              onApplyCoupon: cubit.applyCoupon,
              onCheckout: cubit.checkout,
              summary: const CubitSummaryCard(),
            );
          },
        ),
      ),
    );
  }
}

class CubitSummaryCard extends StatelessWidget {
  const CubitSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        CartCubit,
        CartState,
        (int, double, double, double)>(
      selector: (state) => (
        state.itemCount,
        state.subtotal,
        state.discount,
        state.total,
      ),
      builder: (context, summary) {
        debugPrint('CubitSummaryCard rebuilt. Total: ${summary.$4}');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items: ${summary.$1}'),
                Text('Subtotal: \$${summary.$2.toStringAsFixed(2)}'),
                Text('Discount: \$${summary.$3.toStringAsFixed(2)}'),
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
