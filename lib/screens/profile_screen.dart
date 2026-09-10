import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _userService.getUserData();
      if (!mounted) return;
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fullName = (_userData['firstName'] ?? '').toString().trim().isNotEmpty ||
        (_userData['lastName'] ?? '').toString().trim().isNotEmpty
        ? '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}'.trim()
        : (_userData['username'] ?? '').toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Profile',
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: 20.h),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: fullName.isEmpty ? 'User' : fullName,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: _userData['email'] ?? 'No email',
                      fontSize: 14.sp,
                    ),
                    SizedBox(height: 8.h),
                    CustomText(
                      text: 'Username: ${_userData['username'] ?? 'N/A'}',
                      fontSize: 14.sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
