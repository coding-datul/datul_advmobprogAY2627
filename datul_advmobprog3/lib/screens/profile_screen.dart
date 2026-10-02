import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  final User? initialUser;

  const ProfileScreen({super.key, this.initialUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _user = widget.initialUser;
      _isLoading = false;
    } else {
      _loadUserData();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUser != null && widget.initialUser != _user) {
      setState(() {
        _user = widget.initialUser;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserService().getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserService().logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF354593)),
        ),
      );
    }

    final user = _user;
    final displayName = (user != null && user.fullName.isNotEmpty)
        ? user.fullName
        : ((user != null && user.firstName.isNotEmpty)
              ? user.firstName
              : 'Emily Johnson');

    final displayUsername = (user != null && user.username.isNotEmpty)
        ? user.username
        : 'emilys';

    final displayEmail = (user != null && user.email.isNotEmpty)
        ? user.email
        : 'emily.johnson@x.dummyjson.com';

    final displayGender = (user != null && user.gender.isNotEmpty)
        ? user.gender
        : 'female';

    final displayImage = user?.image ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16.h),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52.r,
                      backgroundColor: const Color(
                        0xFF354593,
                      ).withValues(alpha: 0.15),
                      child: CircleAvatar(
                        radius: 48.r,
                        backgroundColor: const Color(0xFF354593),
                        backgroundImage: displayImage.isNotEmpty
                            ? NetworkImage(displayImage)
                            : null,
                        child: displayImage.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 48.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: displayName,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              SizedBox(height: 4.h),
              CustomText(
                text: '@$displayUsername',
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 28.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF354593,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: const Color(0xFF354593),
                            size: 20.sp,
                          ),
                        ),
                        title: CustomText(
                          text: 'Email',
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                        subtitle: CustomText(
                          text: displayEmail,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Divider(height: 1, indent: 64.w),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF354593,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: const Color(0xFF354593),
                            size: 20.sp,
                          ),
                        ),
                        title: CustomText(
                          text: 'Username',
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                        subtitle: CustomText(
                          text: displayUsername,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Divider(height: 1, indent: 64.w),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF354593,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.wc_outlined,
                            color: const Color(0xFF354593),
                            size: 20.sp,
                          ),
                        ),
                        title: CustomText(
                          text: 'Gender',
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                        subtitle: CustomText(
                          text: displayGender.toUpperCase(),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
