import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const int _userId = 1;
  late Future<Cart> _cartFuture;
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _cartFuture = CartService().getCartByUserId(_userId);
  }

  void _changeQuantity(CartProduct product, int change) {
    final nextQuantity = (_quantities[product.id] ?? product.quantity) + change;
    if (nextQuantity > 0) {
      setState(() => _quantities[product.id] = nextQuantity);
    }
  }

  Product _asProduct(CartProduct product) {
    return Product(
      id: product.id,
      title: product.title,
      description: '',
      category: '',
      price: product.price,
      discountPercentage: product.discountPercentage,
      rating: 0,
      stock: 0,
      brand: 'Product details',
      thumbnail: product.thumbnail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Cart>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: CustomText(
                    text: 'Error: ${snapshot.error}', fontSize: 14.sp));
          }

          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final subtotal = cart.products.fold<double>(
            0,
            (sum, product) =>
                sum +
                product.price * (_quantities[product.id] ?? product.quantity),
          );

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              CustomText(
                  text: 'Cart', fontSize: 24.sp, fontWeight: FontWeight.bold),
              SizedBox(height: 12.h),
              ...cart.products.map(
                (product) => Card(
                  margin: EdgeInsets.only(bottom: 10.h),
                  child: ListTile(
                    // Enhancement 1: Cart items open the reusable detail screen.
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: _asProduct(product)),
                      ),
                    ),
                    leading: Image.network(product.thumbnail,
                        width: 56.w, fit: BoxFit.cover),
                    title: CustomText(
                        text: product.title,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '\$${product.price.toStringAsFixed(2)}  •  ${product.discountPercentage}% off',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SizedBox(
                      width: 94.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _changeQuantity(product, -1),
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 20.w,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 30.w,
                              minHeight: 30.h,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                              '${_quantities[product.id] ?? product.quantity}'),
                          IconButton(
                            onPressed: () => _changeQuantity(product, 1),
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 20.w,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 30.w,
                              minHeight: 30.h,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                      text: 'Subtotal',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                  CustomText(
                      text: '\$${subtotal.toStringAsFixed(2)}',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ],
              ),
              SizedBox(height: 16.h),
              FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order confirmed')),
                ),
                child: const Text('Confirm Order'),
              ),
            ],
          );
        },
      ),
    );
  }
}
