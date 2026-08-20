import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 1: Custom splash screen UI that checks persistent
// authentication (via UserService) before deciding where to route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Enhancement 1: Persistent auth check — reads the token saved by
  // UserService in SharedPreferences instead of forcing a fresh login.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F5),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96.w,
                height: 96.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Image.asset(
                    'assets/icons/BE_logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              CustomText(
                text: 'Bulldogs Exchange',
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                textAlign: TextAlign.center,
                color: const Color(0xFF1F2D6D),
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Curated essentials',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
                color: const Color(0xFF7A7F9A),
              ),
              SizedBox(height: 28.h),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F2D6D)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
