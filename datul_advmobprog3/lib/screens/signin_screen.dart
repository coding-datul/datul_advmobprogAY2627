import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ==============================================================
// ENHANCEMENT 1 & 2: SigninScreen supporting both
// DummyJSON API (https://dummyjson.com/auth/login) and
// Firebase Auth SDK (UserService().signIn), plus navigation to SignupScreen.
// ==============================================================

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _useFirebaseAuth = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userService = UserService();
    final dynamic authService = userService;
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> userData;

      final bool useFirebase = _useFirebaseAuth || identifier.contains('@');

      if (useFirebase && identifier.contains('@')) {
        final credential = await authService.signIn(
          email: identifier,
          password: password,
        );
        final fbUser = credential.user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginType', 'firebase');
        if (fbUser != null) {
          await prefs.setString('uid', fbUser.uid);
          await prefs.setString('email', fbUser.email ?? identifier);
          await prefs.setString(
            'username',
            (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
                ? fbUser.displayName!
                : identifier.split('@').first,
          );
          final idToken = await fbUser.getIdToken() ?? fbUser.uid;
          await prefs.setString('accessToken', idToken);
          await prefs.setString('token', idToken);
        }
        userData = await userService.getUserData();
      } else {
        userData = await userService.loginUser(identifier, password);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginType', 'dummyJson');
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMsg = e.toString().replaceAll('Exception: ', '');
      try {
        final decoded = jsonDecode(errorMsg);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMsg = decoded['message'].toString();
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $errorMsg\nTip: For DummyJSON use (emilys / emilyspass) or Sign Up for Firebase Auth.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFirebase = _useFirebaseAuth;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header with inline NU logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/nu_logo.png',
                        height: 38.h,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.shopping_bag,
                          size: 38.sp,
                          color: const Color(0xFF354593),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: 'Welcome',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // LoginType Selector (Firebase Auth vs DummyJSON)
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _useFirebaseAuth = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: isFirebase
                                    ? const Color(0xFF354593)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: CustomText(
                                  text: 'Firebase Auth',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isFirebase
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _useFirebaseAuth = false;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: !isFirebase
                                    ? const Color(0xFF354593)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: CustomText(
                                  text: 'DummyJSON API',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: !isFirebase
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Email or Username field
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: isFirebase ? 'Email Address' : 'Username',
                      hintText: isFirebase
                          ? 'e.g. user@example.com'
                          : 'e.g. emilys',
                      prefixIcon: Icon(
                        isFirebase
                            ? Icons.email_outlined
                            : Icons.person_outline,
                        size: 20.sp,
                        color: const Color(0xFF354593),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF354593),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isFirebase
                            ? 'Please enter your email address'
                            : 'Please enter your username';
                      }
                      if (isFirebase && !value.trim().contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: isFirebase
                          ? 'Enter your password'
                          : 'e.g. emilyspass',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 20.sp,
                        color: const Color(0xFF354593),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF354593),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Log In button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF354593),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF354593,
                      ).withValues(alpha: 0.6),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : CustomText(
                            text: 'Log In',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                  ),
                  SizedBox(height: 18.h),

                  // Navigate to Sign Up screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        text: "Don't have an account? ",
                        fontSize: 13.sp,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: CustomText(
                          text: 'Sign Up',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF354593),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
