import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/product.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 2: details page shown when a product card is tapped.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, size: 48),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: product.brand,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      CustomText(
                        text: '\$${product.price.toStringAsFixed(2)}',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(width: 8.w),
                      CustomText(
                        text: '${product.discountPercentage.toStringAsFixed(0)}% off',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: '${product.rating} • ${product.stock} in stock',
                        fontSize: 13.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Description',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: product.description,
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Category',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: product.category,
                    fontSize: 14.sp,
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Shipping & Warranty',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: product.shippingInformation,
                    fontSize: 14.sp,
                  ),
                  CustomText(
                    text: product.warrantyInformation,
                    fontSize: 14.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
