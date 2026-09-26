import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _checkAuthentication();
  }

  // Enhancement 1: Persistent authentication through UserService.
  Future<void> _checkAuthentication() async {
    final minimumSplashTime = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );
    final authCheck = _userService.isLoggedIn();

    final results = await Future.wait<Object?>([
      minimumSplashTime.then((_) => null),
      authCheck,
    ]);
    final isLoggedIn = results.last as bool;

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      isLoggedIn ? AppRoutes.home : AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 146.w,
                      height: 146.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140.w,
                            height: 140.w,
                            child: const CircularProgressIndicator(
                              color: AppColors.nuGold,
                              strokeWidth: 2.4,
                            ),
                          ),
                          const NuLogo(size: 112),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CustomText(
                      text: 'NUBD Exchange',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
