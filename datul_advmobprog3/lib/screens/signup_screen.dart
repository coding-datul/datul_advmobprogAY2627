import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ==============================================================
// ENHANCEMENT 2: Signup Screen UI requiring:
// - fName, lName, age, contactNo, username, emailAddress, password (with validation)
// - Integrates Firebase Auth createAccount & updateUsername + DummyJSON /users schema
// ==============================================================

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailAddressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userService = UserService();
    final dynamic authService = userService;
    final fName = _fNameController.text.trim();
    final lName = _lNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final contactNo = _contactNoController.text.trim();
    final username = _usernameController.text.trim();
    final emailAddress = _emailAddressController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Create account in Firebase Authentication
      final credential = await authService.createAccount(
        email: emailAddress,
        password: password,
      );

      // 2. Update Firebase Auth displayName with username
      await authService.updateUsername(username: username);

      // 3. Optionally post to DummyJSON /users/add endpoint (see dummyjson.com/users)
      int dummyUserId = 1;
      try {
        final response = await http.post(
          Uri.parse('$host/users/add'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firstName': fName,
            'lastName': lName,
            'age': age,
            'phone': contactNo,
            'username': username,
            'email': emailAddress,
            'password': password,
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final dummyResponse = jsonDecode(response.body);
          if (dummyResponse is Map && dummyResponse['id'] is int) {
            dummyUserId = dummyResponse['id'] as int;
          }
        }
      } catch (_) {}

      final uid = credential.user?.uid ?? '';
      String idToken = '';
      try {
        idToken = await credential.user?.getIdToken() ?? '';
      } catch (_) {}

      // 4. Save complete user profile data into SharedPreferences
      final userData = <String, dynamic>{
        'id': dummyUserId,
        'uid': uid,
        'firstName': fName,
        'lastName': lName,
        'age': age,
        'contactNo': contactNo,
        'phone': contactNo,
        'username': username,
        'email': emailAddress,
        'gender': '',
        'image': '',
        'accessToken': idToken.isNotEmpty
            ? idToken
            : (uid.isNotEmpty ? uid : 'firebase_session'),
        'token': idToken.isNotEmpty
            ? idToken
            : (uid.isNotEmpty ? uid : 'firebase_session'),
        'loginType': 'firebase',
      };

      await userService.saveUserData(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('age', age);
      await prefs.setString('contactNo', contactNo);
      await prefs.setString('uid', uid);
      await prefs.setString('loginType', 'firebase');
      await prefs.setString(
        'firebase_profile_${emailAddress.toLowerCase()}',
        jsonEncode(userData),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: userData,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign up failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF354593)),
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF354593), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Create Account',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nu_logo.png',
                      height: 36.h,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_add_alt_1,
                        size: 36.sp,
                        color: const Color(0xFF354593),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    CustomText(
                      text: 'Sign Up',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Center(
                  child: CustomText(
                    text: 'Register with Firebase Auth & User Profile',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 22.h),

                // First Name (fName) & Last Name (lName) Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          label: 'First Name (fName)',
                          hint: 'e.g. Emily',
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextFormField(
                        controller: _lNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(
                          label: 'Last Name (lName)',
                          hint: 'e.g. Johnson',
                          icon: Icons.badge_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Age & Contact Number (contactNo) Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _buildInputDecoration(
                          label: 'Age',
                          hint: 'e.g. 21',
                          icon: Icons.cake_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter age';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 1 || parsed > 120) {
                            return 'Invalid age';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _contactNoController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          label: 'Contact No.',
                          hint: 'e.g. +63 912 345 6789',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter contact number';
                          }
                          if (value.trim().length < 7) {
                            return 'Contact no. too short';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: _buildInputDecoration(
                    label: 'Username',
                    hint: 'e.g. emilys',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 14.h),

                // Email Address (emailAddress) field
                TextFormField(
                  controller: _emailAddressController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    label: 'Email Address',
                    hint: 'e.g. emily.johnson@x.dummyjson.com',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 14.h),

                // Password field (with validation)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    icon: Icons.lock_outline,
                    isDark: isDark,
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          text: 'Create Account',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 16.h),

                // Redirect to Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: 'Already have an account? ',
                      fontSize: 13.sp,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                    TextButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/signin');
                        }
                      },
                      child: CustomText(
                        text: 'Log In',
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
    );
  }
}
