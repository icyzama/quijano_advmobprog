import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/lab4_components.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_loginType == LoginType.dummyJson) {
        await _userService.loginUser(
          username: _identifierController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _userService.signIn(
          email: _identifierController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.splash,
        (route) => false,
      );
    } on UserServiceException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'We could not reach the sign-in service. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchLoginType(LoginType type) {
    if (_isLoading) return;
    setState(() {
      _loginType = type;
      _errorMessage = null;
      _identifierController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFirebase = _loginType == LoginType.firebase;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 22.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 18.h),
                      _BrandHeader(isFirebase: isFirebase),
                      SizedBox(height: 28.h),
                      AppSection(
                        accentColor:
                            isFirebase ? AppColors.teal : AppColors.nuBlue,
                        children: [
                          CustomText(
                            text: 'Sign in',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 14.h),
                          _LoginTypeSelector(
                            selectedType: _loginType,
                            onChanged: _switchLoginType,
                          ),
                          SizedBox(height: 22.h),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _identifierController,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: isFirebase
                                      ? TextInputType.emailAddress
                                      : TextInputType.text,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: isFirebase
                                        ? 'Email Address'
                                        : 'Username',
                                    prefixIcon: Icon(isFirebase
                                        ? Icons.mail_outline
                                        : Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    final input = value?.trim() ?? '';
                                    if (input.isEmpty) {
                                      return isFirebase
                                          ? 'Email address is required'
                                          : 'Username is required';
                                    }
                                    if (isFirebase && !_isValidEmail(input)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16.h),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !_isLoading,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: _isLoading
                                          ? null
                                          : () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            SizedBox(height: 16.h),
                            _ErrorBox(message: _errorMessage!),
                          ],
                          SizedBox(height: 22.h),
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? SizedBox(
                                      width: 22.w,
                                      height: 22.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      isFirebase
                                          ? 'Sign in with Firebase'
                                          : 'Continue with API',
                                    ),
                            ),
                          ),
                          if (isFirebase) ...[
                            SizedBox(height: 12.h),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.signUp,
                                      ),
                              child: const Text('Create Firebase Account'),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

class _LoginTypeSelector extends StatelessWidget {
  const _LoginTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final LoginType selectedType;
  final ValueChanged<LoginType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LoginType>(
      segments: const [
        ButtonSegment(
          value: LoginType.dummyJson,
          icon: Icon(Icons.cloud_queue),
          label: Text('API Account'),
        ),
        ButtonSegment(
          value: LoginType.firebase,
          icon: Icon(Icons.local_fire_department_outlined),
          label: Text('Firebase'),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isFirebase});

  final bool isFirebase;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const NuLogo(size: 108),
        SizedBox(height: 20.h),
        CustomText(
          text: 'NUBD Exchange',
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        CustomText(
          text: isFirebase
              ? 'Use your Firebase email account.'
              : 'Use your DummyJSON API account.',
          fontSize: 13.sp,
          textAlign: TextAlign.center,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: CustomText(
        text: message,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
