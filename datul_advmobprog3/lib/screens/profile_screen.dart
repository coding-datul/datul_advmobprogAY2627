import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// ==============================================================
// ENHANCEMENT 3: Profile Screen
// - Fetch user data via UserService().getUserData()
// - Show user details depending on the LoginType ()
// - Allow update username, change password, delete account
// - Logout clears session/token and redirects to login
// ==============================================================

class ProfileScreen extends StatefulWidget {
  final User? initialUser;
  final VoidCallback? onUserUpdated;

  const ProfileScreen({super.key, this.initialUser, this.onUserUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  dynamic get _authService => _userService;
  User? _user;
  Map<String, dynamic> _userData = {};
  bool _isFirebaseLogin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUser != oldWidget.initialUser) {
      _loadUserData();
    }
  }

  /// Fetch user data via UserService().getUserData()
  Future<void> _loadUserData() async {
    try {
      final data = Map<String, dynamic>.from(await _userService.getUserData());
      final prefs = await SharedPreferences.getInstance();
      final fbUser = _authService.currentUser;
      final savedLoginType =
          prefs.getString('loginType') ??
          data['loginType']?.toString() ??
          (fbUser != null ? 'firebase' : 'dummyJson');
      final isFirebase = savedLoginType == 'firebase' || fbUser != null;

      if (isFirebase) {
        final emailKey = (fbUser?.email ?? data['email']?.toString() ?? '')
            .toLowerCase();
        if (emailKey.isNotEmpty) {
          final rawProfile = prefs.getString('firebase_profile_$emailKey');
          if (rawProfile != null && rawProfile.isNotEmpty) {
            try {
              final storedMap = Map<String, dynamic>.from(
                jsonDecode(rawProfile),
              );
              storedMap.forEach((k, v) {
                if (data[k] == null ||
                    data[k].toString().isEmpty ||
                    data[k] == 0) {
                  data[k] = v;
                }
              });
            } catch (_) {}
          }
        }
        if (fbUser?.displayName != null && fbUser!.displayName!.isNotEmpty) {
          data['username'] = fbUser.displayName!;
        }
        if (fbUser?.email != null && fbUser!.email!.isNotEmpty) {
          data['email'] = fbUser.email!;
        }
        if (fbUser?.uid != null && fbUser!.uid.isNotEmpty) {
          data['uid'] = fbUser.uid;
        }
      }

      data['age'] = data['age'] ?? prefs.getInt('age') ?? 0;
      data['contactNo'] =
          data['contactNo'] ?? prefs.getString('contactNo') ?? '';
      data['uid'] = data['uid'] ?? prefs.getString('uid') ?? '';

      final parsedUser = User.fromJson(data);

      if (mounted) {
        setState(() {
          _userData = data;
          _user =
              (parsedUser.username.isNotEmpty || parsedUser.email.isNotEmpty)
              ? parsedUser
              : (widget.initialUser ?? parsedUser);
          _isFirebaseLogin = isFirebase;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = widget.initialUser;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showUpdateUsernameDialog(String currentUsername) async {
    final controller = TextEditingController(text: currentUsername);
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Username',
              hintText: 'Enter new username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Username cannot be empty';
              }
              if (val.trim().length < 3) {
                return 'At least 3 characters required';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354593),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newUsername != null && newUsername.isNotEmpty) {
      try {
        if (_authService.currentUser != null) {
          await _authService.updateUsername(username: newUsername);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newUsername);
        await _loadUserData();
        widget.onUserUpdated?.call();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username updated to @$newUsername'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update username: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog(String email) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return 'New password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354593),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.resetPasswordFromCurrentPassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
          email: email,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(String email) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent. Please enter your password to confirm account deletion.',
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteAccount(
          email: email,
          password: passwordController.text,
        );
        await _userService.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/signin', (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
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
      try {
        await _authService.signOut();
      } catch (_) {}
      await _userService.logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: const Color(0xFF354593).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: const Color(0xFF354593), size: 20.sp),
      ),
      title: CustomText(text: label, fontSize: 12.sp, color: Colors.grey),
      subtitle: CustomText(
        text: value,
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
      ),
      trailing: trailing,
    );
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
    final isFirebase = _isFirebaseLogin;

    final displayUsername = (user != null && user.username.isNotEmpty)
        ? user.username
        : (_userData['username']?.toString().isNotEmpty == true
              ? _userData['username'].toString()
              : 'emilys');

    final displayEmail = (user != null && user.email.isNotEmpty)
        ? user.email
        : (_userData['email']?.toString().isNotEmpty == true
              ? _userData['email'].toString()
              : 'emily.johnson@x.dummyjson.com');

    final displayName = (user != null && user.fullName.isNotEmpty)
        ? user.fullName
        : (isFirebase ? displayUsername : 'Emily Johnson');

    final rawAge = int.tryParse(_userData['age']?.toString() ?? '0') ?? 0;
    final displayAge = rawAge > 0 ? '$rawAge years old' : 'Not specified';

    final rawContact =
        (_userData['contactNo'] ?? _userData['phone'])?.toString() ?? '';
    final displayContact = rawContact.isNotEmpty ? rawContact : 'Not specified';

    final displayGender = (user != null && user.gender.isNotEmpty)
        ? user.gender.toUpperCase()
        : 'FEMALE';

    final displayImage = user?.image ?? '';
    final rawUid = _userData['uid']?.toString() ?? '';
    final displayUid = rawUid.isNotEmpty
        ? rawUid
        : (_authService.currentUser?.uid?.toString() ?? 'N/A');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 12.h),
              Center(
                child: CircleAvatar(
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
                        ? Icon(Icons.person, size: 48.sp, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
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
              SizedBox(height: 10.h),

              // LoginType Badge (Enhancement 3: Show user details depending on LoginType)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isFirebase
                      ? const Color(0xFFF5A623).withValues(alpha: 0.15)
                      : const Color(0xFF354593).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isFirebase
                        ? const Color(0xFFF5A623)
                        : const Color(0xFF354593),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFirebase
                          ? Icons.verified_user_outlined
                          : Icons.cloud_done_outlined,
                      size: 15.sp,
                      color: isFirebase
                          ? const Color(0xFFF5A623)
                          : const Color(0xFF354593),
                    ),
                    SizedBox(width: 6.w),
                    CustomText(
                      text: isFirebase
                          ? 'LoginType: Firebase Auth'
                          : 'LoginType: DummyJSON API',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isFirebase
                          ? const Color(0xFFF5A623)
                          : (isDark ? Colors.white : const Color(0xFF354593)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),

              // User Details Card depending on LoginType
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
                      _buildDetailTile(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: displayEmail,
                      ),
                      Divider(height: 1, indent: 64.w),
                      _buildDetailTile(
                        icon: Icons.person_outline,
                        label: 'Username',
                        value: displayUsername,
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18.sp,
                            color: const Color(0xFF354593),
                          ),
                          tooltip: 'Update Username',
                          onPressed: () =>
                              _showUpdateUsernameDialog(displayUsername),
                        ),
                      ),
                      Divider(height: 1, indent: 64.w),
                      if (isFirebase) ...[
                        _buildDetailTile(
                          icon: Icons.cake_outlined,
                          label: 'Age',
                          value: displayAge,
                        ),
                        Divider(height: 1, indent: 64.w),
                        _buildDetailTile(
                          icon: Icons.phone_outlined,
                          label: 'Contact Number',
                          value: displayContact,
                        ),
                        Divider(height: 1, indent: 64.w),
                        _buildDetailTile(
                          icon: Icons.fingerprint,
                          label: 'Firebase UID',
                          value: displayUid,
                        ),
                      ] else ...[
                        _buildDetailTile(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: displayGender,
                        ),
                        if (rawAge > 0) ...[
                          Divider(height: 1, indent: 64.w),
                          _buildDetailTile(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: displayAge,
                          ),
                        ],
                        if (rawContact.isNotEmpty) ...[
                          Divider(height: 1, indent: 64.w),
                          _buildDetailTile(
                            icon: Icons.phone_outlined,
                            label: 'Contact Number',
                            value: displayContact,
                          ),
                        ],
                        Divider(height: 1, indent: 64.w),
                        _buildDetailTile(
                          icon: Icons.tag,
                          label: 'DummyJSON User ID',
                          value: '#${user?.id ?? 1}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Account Management Actions (Enhancement 3: Update username, Change password, Delete account)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.edit_note,
                        color: Color(0xFF354593),
                      ),
                      title: CustomText(
                        text: 'Update Username',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showUpdateUsernameDialog(displayUsername),
                    ),
                    Divider(height: 1, indent: 56.w),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_reset,
                        color: Color(0xFF354593),
                      ),
                      title: CustomText(
                        text: 'Change Password',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showChangePasswordDialog(displayEmail),
                    ),
                    Divider(height: 1, indent: 56.w),
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red.shade700,
                      ),
                      title: CustomText(
                        text: 'Delete Account',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      onTap: () => _showDeleteAccountDialog(displayEmail),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Logout Button
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
