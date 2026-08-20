import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';
import '../models/user.dart';

// services
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 3: Profile screen built on user_service + the User model.
// Loads the persisted user, then renders that user's cart (by userId).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    final data = await _userService.getUserData();
    return User.fromJson(data);
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: CustomText(
                text: 'Unable to load profile.',
                fontSize: 14.sp,
              ),
            );
          }

          final user = snapshot.data!;

          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            children: [
              _buildProfileHeader(user),
              SizedBox(height: 24.h),
              CustomText(
                text: 'My Cart',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 12.h),
              _buildCartSection(user.id),
              SizedBox(height: 24.h),
              SizedBox(
                height: 50.h,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34.r,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  user.image.isNotEmpty ? NetworkImage(user.image) : null,
              child: user.image.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 32.sp,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: user.fullName,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '@${user.username}',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: user.email,
                    fontSize: 12.sp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection(int userId) {
    return FutureBuilder<Cart?>(
      future: CartService().getCartByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return CustomText(
            text: 'Error loading cart: ${snapshot.error}',
            fontSize: 13.sp,
          );
        }

        final cart = snapshot.data;
        if (cart == null || cart.products.isEmpty) {
          return Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Center(
                child: CustomText(
                  text: 'No items in your cart yet.',
                  fontSize: 13.sp,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            ...cart.products.map(_buildCartProductTile),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'Total (${cart.totalQuantity} items):',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                CustomText(
                  text: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartProductTile(CartProduct product) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Image.network(
            product.thumbnail,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, size: 24),
          ),
        ),
        title: CustomText(
          text: product.title,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: CustomText(
          text: 'Qty: ${product.quantity}',
          fontSize: 11.sp,
        ),
        trailing: CustomText(
          text: '\$${product.total.toStringAsFixed(2)}',
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
