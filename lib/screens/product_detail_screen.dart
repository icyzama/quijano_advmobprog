import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2: Details page shown when a product/article card is clicked.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    try {
      // Enhancement 3: Add the displayed product to the selected user's cart.
      final Cart cart = await CartService().addToCart(
        userId: cartUserId,
        productId: widget.product.id,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Added to cart ${cart.id}')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add to cart: $error')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 2: Full product details (image, title, price, description).
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
            text: widget.product.brand,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(widget.product.thumbnail,
                    height: 250.h, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20.h),
            CustomText(
                text: widget.product.title,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold),
            SizedBox(height: 10.h),
            CustomText(
                text: '\$${widget.product.price}',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold),
            SizedBox(height: 15.h),
            CustomText(text: widget.product.description, fontSize: 14.sp),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAdding ? null : _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(_isAdding ? 'Adding...' : 'Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
