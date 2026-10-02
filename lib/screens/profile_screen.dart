import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User?> _userFuture;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  void _setUser(User user) {
    setState(() => _userFuture = Future.value(user));
  }

  Future<void> _logout() async {
    if (_isWorking) return;

    setState(() => _isWorking = true);
    await _userService.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
    );
  }

  Future<void> _updateUsername(User user) async {
    final controller = TextEditingController(text: user.username);
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (username == null) return;

    try {
      final updatedUser = await _userService.updateUsername(username);
      if (!mounted) return;
      _setUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } on UserServiceException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    final currentPassword = currentController.text;
    final newPassword = newController.text;
    final confirmPassword = confirmController.text;
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (confirmed != true) return;
    if (newPassword != confirmPassword) {
      _showError('New password and confirmation must match.');
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } on UserServiceException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This permanently deletes your Firebase account.'),
            SizedBox(height: 14.h),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    final password = passwordController.text;
    passwordController.dispose();

    if (confirmed != true) return;

    try {
      await _userService.deleteAccount(password: password);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.signIn,
        (route) => false,
      );
    } on UserServiceException catch (error) {
      _showError(error.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return AppStateMessage(
              icon: Icons.lock_outline,
              title: 'Session unavailable',
              message: 'Please sign in again to view your profile.',
              actionLabel: 'Sign in',
              onAction: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.signIn,
                (route) => false,
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _ProfileHeader(user: user),
              SizedBox(height: 16.h),
              _AccountInfo(user: user),
              SizedBox(height: 16.h),
              _AccountActions(
                user: user,
                isWorking: _isWorking,
                onLogout: _logout,
                onUpdateUsername: () => _updateUsername(user),
                onChangePassword: _changePassword,
                onDeleteAccount: _deleteAccount,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.isFirebase) {
      return AppSection(
        accentColor: AppColors.teal,
        children: [
          CustomText(
            text: 'Firebase Account',
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8.h),
          InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Authentication Source',
            value: user.loginType.label,
            accentColor: AppColors.teal,
          ),
          InfoTile(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: user.fullName,
            accentColor: AppColors.nuBlue,
          ),
          InfoTile(
            icon: Icons.badge_outlined,
            label: 'Username',
            value: user.username,
            accentColor: AppColors.violet,
          ),
          InfoTile(
            icon: Icons.mail_outline,
            label: 'Email',
            value: user.email,
            accentColor: AppColors.sky,
          ),
          InfoTile(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: user.age == null || user.age == 0 ? '' : user.age.toString(),
            accentColor: AppColors.nuGold,
          ),
          InfoTile(
            icon: Icons.phone_outlined,
            label: 'Contact Number',
            value: user.contactNumber,
            accentColor: AppColors.coral,
          ),
          InfoTile(
            icon: Icons.fingerprint,
            label: 'Firebase UID',
            value: user.firebaseUid ?? '',
            accentColor: AppColors.teal,
          ),
        ],
      );
    }

    return AppSection(
      accentColor: AppColors.nuBlue,
      children: [
        CustomText(
          text: 'API Account Information',
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 8.h),
        InfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Authentication Source',
          value: user.loginType.label,
          accentColor: AppColors.nuBlue,
        ),
        InfoTile(
          icon: Icons.mail_outline,
          label: 'Email',
          value: user.email,
          accentColor: AppColors.sky,
        ),
        InfoTile(
          icon: Icons.badge_outlined,
          label: 'Username',
          value: user.username,
          accentColor: AppColors.violet,
        ),
        InfoTile(
          icon: Icons.person_outline,
          label: 'Gender',
          value: user.gender,
          accentColor: AppColors.teal,
        ),
        InfoTile(
          icon: Icons.cake_outlined,
          label: 'Age',
          value: user.age?.toString() ?? '',
          accentColor: AppColors.nuGold,
        ),
        InfoTile(
          icon: Icons.confirmation_number_outlined,
          label: 'User ID',
          value: user.id.toString(),
          accentColor: AppColors.coral,
        ),
      ],
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.user,
    required this.isWorking,
    required this.onLogout,
    required this.onUpdateUsername,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  final User user;
  final bool isWorking;
  final VoidCallback onLogout;
  final VoidCallback onUpdateUsername;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return AppSection(
      accentColor: user.isFirebase ? AppColors.teal : AppColors.nuGold,
      children: [
        CustomText(
          text: 'Account',
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 14.h),
        if (user.isFirebase) ...[
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Update Username',
            onPressed: onUpdateUsername,
          ),
          _ActionButton(
            icon: Icons.password_outlined,
            label: 'Change Password',
            onPressed: onChangePassword,
          ),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete Firebase Account',
            color: AppColors.error,
            onPressed: onDeleteAccount,
          ),
        ],
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton.icon(
            onPressed: isWorking ? null : onLogout,
            icon: isWorking
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(isWorking ? 'Signing out...' : 'Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppColors.nuBlue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: SizedBox(
        width: double.infinity,
        height: 46.h,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.45)),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.nuNavy,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NuLogo(size: 36),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: user.isFirebase ? AppColors.teal : AppColors.nuGold,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CustomText(
                  text: user.loginType.label,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34.r,
                backgroundColor: AppColors.surface,
                child: ClipOval(
                  child: user.image.isEmpty
                      ? Icon(
                          Icons.person_outline,
                          color: AppColors.nuBlue,
                          size: 34.sp,
                        )
                      : Image.network(
                          user.image,
                          width: 68.w,
                          height: 68.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_outline,
                            color: AppColors.nuBlue,
                            size: 34.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: user.fullName,
                      fontSize: 21.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.surface,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5.h),
                    CustomText(
                      text: '@${user.username}',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.nuGold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
