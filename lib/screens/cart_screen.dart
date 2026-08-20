import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';

// screens
import 'product_detail_screen.dart';

// services
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  // Enhancement 1: Added cart_screen.dart to render cart products.
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = _loadCart();
  }

  // Enhancement 3: Reads the signed-in user's id from UserService's saved
  // data so the cart shown here always matches whoever is logged in.
  Future<Cart?> _loadCart() async {
    final userData = await UserService().getUserData();
    final userId = userData['id'] as int? ?? 0;
    // Show only products added in this app session, scoped to that userId.
    return CartService().getCartByUserId(userId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: CustomText(
                  text: 'Error: ${snapshot.error}',
                  fontSize: 14.sp,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final cart = snapshot.data;
          if (cart == null || cart.products.isEmpty) {
            return Center(
              child: CustomText(text: 'Cart is empty.', fontSize: 14.sp),
            );
          }

          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            children: [
              // Enhancement 1: Render cart data as clickable cart item cards.
              ...cart.products.map(_buildCartItem),
              SizedBox(height: 16.h),
              _buildSummaryRow(
                label: 'Subtotal:',
                value: '\$${cart.total.toStringAsFixed(2)}',
              ),
              SizedBox(height: 10.h),
              _buildSummaryRow(
                label: 'Discounted Total:',
                value: '\$${cart.discountedTotal.toStringAsFixed(2)}',
              ),
              SizedBox(height: 10.h),
              _buildSummaryRow(
                label: 'Total Quantity:',
                value: '${cart.totalQuantity}',
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: CustomText(
                    text: 'Confirm Order',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartProduct product) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 14.h),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        // Enhancement 1: Cart products are clickable and open the same
        // ProductDetailScreen used by the product grid.
        onTap: () => _openProductDetail(product.id),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              SizedBox(
                width: 78.w,
                height: 78.w,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 28),
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
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text:
                          '${product.discountPercentage.toStringAsFixed(0)}% off • \$${product.total.toStringAsFixed(2)} total',
                      fontSize: 11.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  CustomText(
                    text: '${product.quantity}',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 13.sp, fontWeight: FontWeight.w500),
        CustomText(text: value, fontSize: 13.sp, fontWeight: FontWeight.w700),
      ],
    );
  }

  Future<void> _openProductDetail(int productId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final product = await ProductService().getProductById(productId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }
}
