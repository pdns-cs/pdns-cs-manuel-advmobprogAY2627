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
  String _loginType = 'dummyjson';
  bool _isLoading = true;

  bool get _usesFirebase => _loginType == 'firebase';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _userService.getUserData();
      final loginType = await _userService.getLoginType();
      if (!mounted) return;
      setState(() {
        _userData = data;
        _loginType = loginType;
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

  Future<void> _updateUsername() async {
    final controller = TextEditingController(
      text: (_userData['username'] ?? '').toString(),
    );

    final username = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'New username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (username == null || username.trim().isEmpty) {
      return;
    }

    try {
      await _userService.updateUsername(username: username);
      await _loadUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: $error')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_usesFirebase) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final email = (_userData['email'] ?? '').toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        email: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (!_usesFirebase) return;

    final email = (_userData['email'] ?? '').toString();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter password to confirm',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _userService.deleteAccount(
        email: email,
        password: passwordController.text,
      );
      await _userService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete account failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
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
                  color: colorScheme.onSurface,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: '@${(_userData['username'] ?? 'user').toString()}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
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
                  iconColor: colorScheme.primary,
                  label: 'Email',
                  value: _userEmail(),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: colorScheme.secondary,
                  label: 'Login Type',
                  value: _usesFirebase ? 'Firebase' : 'DummyJSON',
                ),
                if (_usesFirebase) ...[
                  _divider(),
                  _infoRow(
                    icon: Icons.cake_outlined,
                    iconColor: colorScheme.tertiary,
                    label: 'Age',
                    value: (_userData['age'] ?? 'Not provided').toString(),
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.phone_outlined,
                    iconColor: colorScheme.secondary,
                    label: 'Contact Number',
                    value: (_userData['contactNo'] ?? 'Not provided')
                        .toString(),
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.badge_outlined,
                    iconColor: colorScheme.primary,
                    label: 'Firebase UID',
                    value: (_userData['uid'] ?? '').toString(),
                  ),
                ] else ...[
                  _divider(),
                  _infoRow(
                    icon: Icons.person_outline_rounded,
                    iconColor: colorScheme.tertiary,
                    label: 'Gender',
                    value: (_userData['gender'] ?? 'Not provided').toString(),
                  ),
                  _divider(),
                  _infoRow(
                    icon: Icons.badge_outlined,
                    iconColor: colorScheme.secondary,
                    label: 'User ID',
                    value: '#${(_userData['id'] ?? 0).toString()}',
                  ),
                  if ((_userData['age'] ?? 0) != 0) ...[
                    _divider(),
                    _infoRow(
                      icon: Icons.cake_outlined,
                      iconColor: colorScheme.tertiary,
                      label: 'Age',
                      value: _userData['age'].toString(),
                    ),
                  ],
                  if ((_userData['contactNo'] ?? '').toString().isNotEmpty) ...[
                    _divider(),
                    _infoRow(
                      icon: Icons.phone_outlined,
                      iconColor: colorScheme.secondary,
                      label: 'Contact Number',
                      value: _userData['contactNo'].toString(),
                    ),
                  ],
                ],
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Column(
            children: [
              _actionButton(
                label: 'Update Username',
                icon: Icons.edit_note_rounded,
                color: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                onPressed: _updateUsername,
              ),
              if (_usesFirebase) ...[
                SizedBox(height: 12.h),
                _actionButton(
                  label: 'Change Password',
                  icon: Icons.lock_reset_rounded,
                  color: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  onPressed: _changePassword,
                ),
                SizedBox(height: 12.h),
                _actionButton(
                  label: 'Delete Account',
                  icon: Icons.delete_forever_rounded,
                  color: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                  onPressed: _deleteAccount,
                ),
              ],
              SizedBox(height: 12.h),
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
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 24.sp,
                    color: colorScheme.onError,
                  ),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onError,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPattern() {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.surfaceContainerHigh,
      colorScheme.onSurfaceVariant,
      colorScheme.outline,
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color foregroundColor,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20.sp, color: foregroundColor),
        label: CustomText(
          text: label,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
