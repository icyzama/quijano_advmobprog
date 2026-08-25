import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/product.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Enhancement 2: Detailed product view screen
    return Scaffold(
      appBar: AppBar(
        title: CustomText(text: product.brand, fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(product.thumbnail, height: 250.h, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20.h),
            CustomText(text: product.title, fontSize: 22.sp, fontWeight: FontWeight.bold),
            SizedBox(height: 10.h),
            CustomText(text: '\$${product.price}', fontSize: 20.sp, fontWeight: FontWeight.bold),
            SizedBox(height: 15.h),
            CustomText(text: product.description, fontSize: 14.sp),
          ],
        ),
      ),
    );
  }
}
