import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart> _cartFuture;
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
  }

  Future<Cart> _loadCart() async {
    final user = await _userService.getUser();
    if (user == null) {
      throw const UserServiceException(
          'Please sign in again to view your cart.');
    }

    // Enhancement 3: User model id drives user-specific cart retrieval.
    return _cartService.getCartByUserId(user.id);
  }

  void _retry() {
    setState(() {
      _quantities.clear();
      _cartFuture = _loadCart();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _quantities.clear();
      _cartFuture = _loadCart();
    });
    try {
      await _cartFuture;
    } catch (_) {
      // The FutureBuilder renders the error state after the refresh completes.
    }
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
            return AppStateMessage(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart unavailable',
              message: snapshot.error.toString(),
              actionLabel: 'Retry',
              onAction: _retry,
            );
          }

          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return AppStateMessage(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message:
                  'Products connected to your account will appear here once available.',
              actionLabel: 'Refresh',
              onAction: _retry,
            );
          }

          final subtotal = cart.products.fold<double>(
            0,
            (sum, product) =>
                sum +
                product.price * (_quantities[product.id] ?? product.quantity),
          );
          final totalQuantity = cart.products.fold<int>(
            0,
            (sum, product) =>
                sum + (_quantities[product.id] ?? product.quantity),
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                CustomText(
                  text: 'My Cart',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: 'Cart #${cart.id} for user ${cart.userId}',
                  fontSize: 12.sp,
                ),
                SizedBox(height: 16.h),
                ...cart.products.map(_buildCartProductCard),
                SizedBox(height: 8.h),
                AppSection(
                  children: [
                    CustomText(
                      text: 'Order Summary',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 12.h),
                    _SummaryRow(
                        label: 'Products', value: '${cart.totalProducts}'),
                    _SummaryRow(
                        label: 'Total quantity', value: '$totalQuantity'),
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '\$${subtotal.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'API discounted total',
                      value: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 14.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: FilledButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order confirmed')),
                        ),
                        child: const Text('Confirm Order'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartProductCard(CartProduct product) {
    final quantity = _quantities[product.id] ?? product.quantity;
    final lineTotal = product.price * quantity;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: _asProduct(product)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  product.thumbnail,
                  width: 70.w,
                  height: 70.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70.w,
                    height: 70.w,
                    color: Theme.of(context).colorScheme.surface,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    CustomText(
                      text:
                          '\$${product.price.toStringAsFixed(2)} | ${product.discountPercentage}% off',
                      fontSize: 11.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: 'Subtotal: \$${lineTotal.toStringAsFixed(2)}',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                width: 86.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: () => _changeQuantity(product, -1),
                    ),
                    SizedBox(
                      width: 24.w,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onPressed: () => _changeQuantity(product, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28.w,
      height: 28.w,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 15.sp),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, fontSize: 13.sp),
          CustomText(
            text: value,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
