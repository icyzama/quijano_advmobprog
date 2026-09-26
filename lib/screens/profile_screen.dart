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
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    await _userService.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
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
              AppSection(
                children: [
                  CustomText(
                    text: 'Account Information',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  InfoTile(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: user.email,
                  ),
                  InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Username',
                    value: user.username,
                  ),
                  InfoTile(
                    icon: Icons.person_outline,
                    label: 'Gender',
                    value: user.gender,
                  ),
                  InfoTile(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: user.age?.toString() ?? '',
                  ),
                  InfoTile(
                    icon: Icons.confirmation_number_outlined,
                    label: 'User ID',
                    value: user.id.toString(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              AppSection(
                children: [
                  CustomText(
                    text: 'Account',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: _isLoggingOut
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_isLoggingOut ? 'Signing out...' : 'Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
                  color: AppColors.nuGold,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CustomText(
                  text: 'ID ${user.id}',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nuNavy,
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
