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

  String _fullName() {
    final firstName = (_userData['firstName'] ?? '').toString().trim();
    final lastName = (_userData['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();

    return fullName.isEmpty
        ? (_userData['username'] ?? 'User').toString()
        : fullName;
  }

  String _userEmail() {
    return (_userData['email'] ?? 'No email').toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: _buildAvatarPattern(),
                ),
                SizedBox(height: 18.h),
                CustomText(
                  text: _fullName(),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D2238),
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: '@${(_userData['username'] ?? 'user').toString()}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6F7592),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.mail_outline_rounded,
                  iconColor: const Color(0xFF5B7AE5),
                  label: 'Email',
                  value: _userEmail(),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFFE5A64D),
                  label: 'Gender',
                  value: (_userData['gender'] ?? 'female').toString(),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFF43B3AE),
                  label: 'User ID',
                  value: '#${(_userData['id'] ?? 1).toString()}',
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          SizedBox(
            width: double.infinity,
            height: 58.h,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _userService.logout();
                if (!mounted) return;
                if (!context.mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              },
              icon: Icon(Icons.logout_rounded, size: 24.sp, color: Colors.white),
              label: CustomText(
                text: 'Log Out',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6B56),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPattern() {
    final colors = [
      const Color(0xFF8FE1D4),
      const Color(0xFFE6D26F),
      const Color(0xFFD8E2F2),
      const Color(0xFF6DBDB8),
      const Color(0xFFF4E7A3),
      const Color(0xFF9ED1C1),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4F2),
        borderRadius: BorderRadius.circular(28.r),
      ),
      padding: EdgeInsets.all(18.w),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 6.h,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              borderRadius: BorderRadius.circular(10.r),
            ),
          );
        },
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFE8EAF1),
      indent: 16.w,
      endIndent: 16.w,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomText(
                    text: label,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D2238),
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      text: value,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6F7592),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
