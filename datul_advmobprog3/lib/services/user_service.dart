import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as user_model;

enum LoginType { dummyJson, firebase }

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  /// DummyJSON Authentication: POST https://dummyjson.com/auth/login
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = Map<String, dynamic>.from(jsonDecode(response.body));
      data['loginType'] = 'dummyJson';

      // Fetch additional user details (age, phone/contactNo) from /users/{id}
      try {
        final userId = data['id'];
        if (userId != null) {
          final profileRes = await http.get(Uri.parse('$host/users/$userId'));
          if (profileRes.statusCode == 200) {
            final profileData = jsonDecode(profileRes.body);
            if (profileData is Map<String, dynamic>) {
              data['age'] = profileData['age'] ?? 0;
              data['contactNo'] = profileData['phone'] ?? '';
              data['phone'] = profileData['phone'] ?? '';
            }
          }
        }
      } catch (_) {}

      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// DummyJSON User Registration: POST https://dummyjson.com/users/add
  Future<Map<String, dynamic>> registerDummyJsonUser({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'phone': contactNo,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to register user on DummyJSON: ${response.body}');
    }
  }

  /// Save User data to SharedPreferences
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = user_model.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('uid', user.uid);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setInt('age', user.age);
    await prefs.setString('contactNo', user.contactNo);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', user.loginType);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token']?.toString() ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }

    // Persist Firebase profile details keyed by email so subsequent Firebase sign-ins retain profile fields
    if (user.loginType == 'firebase' && user.email.isNotEmpty) {
      final profileKey = 'firebase_profile_${user.email.toLowerCase()}';
      await prefs.setString(profileKey, jsonEncode(user.toJson()));
    }
  }

  /// Retrieve active LoginType
  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString('loginType');
    if (savedType == 'firebase' || currentUser != null) {
      return LoginType.firebase;
    }
    return LoginType.dummyJson;
  }

  /// Retrieve user data from SharedPreferences & Firebase Auth
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final fbUser = currentUser;
    final savedLoginType =
        prefs.getString('loginType') ??
        (fbUser != null ? 'firebase' : 'dummyJson');

    Map<String, dynamic> storedProfile = {};
    final emailKey = (fbUser?.email ?? prefs.getString('email') ?? '')
        .toLowerCase();
    if (savedLoginType == 'firebase' && emailKey.isNotEmpty) {
      final rawProfile = prefs.getString('firebase_profile_$emailKey');
      if (rawProfile != null && rawProfile.isNotEmpty) {
        try {
          storedProfile = Map<String, dynamic>.from(jsonDecode(rawProfile));
        } catch (_) {}
      }
    }

    final resolvedUsername =
        (fbUser?.displayName != null && fbUser!.displayName!.isNotEmpty)
        ? fbUser.displayName!
        : (prefs.getString('username')?.isNotEmpty == true
              ? prefs.getString('username')!
              : (storedProfile['username']?.toString().isNotEmpty == true
                    ? storedProfile['username'].toString()
                    : (fbUser?.email != null
                          ? fbUser!.email!.split('@').first
                          : '')));

    final resolvedEmail = fbUser?.email?.isNotEmpty == true
        ? fbUser!.email!
        : (prefs.getString('email') ??
              storedProfile['email']?.toString() ??
              '');

    final resolvedFirstName = prefs.getString('firstName')?.isNotEmpty == true
        ? prefs.getString('firstName')!
        : (storedProfile['firstName']?.toString() ?? '');

    final resolvedLastName = prefs.getString('lastName')?.isNotEmpty == true
        ? prefs.getString('lastName')!
        : (storedProfile['lastName']?.toString() ?? '');

    final resolvedAge = (prefs.getInt('age') ?? 0) > 0
        ? prefs.getInt('age')!
        : (int.tryParse(storedProfile['age']?.toString() ?? '0') ?? 0);

    final resolvedContactNo = prefs.getString('contactNo')?.isNotEmpty == true
        ? prefs.getString('contactNo')!
        : (storedProfile['contactNo']?.toString() ?? '');

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': fbUser?.uid ?? prefs.getString('uid') ?? '',
      'username': resolvedUsername,
      'email': resolvedEmail,
      'firstName': resolvedFirstName,
      'lastName': resolvedLastName,
      'age': resolvedAge,
      'contactNo': resolvedContactNo,
      'phone': resolvedContactNo,
      'gender':
          prefs.getString('gender') ??
          storedProfile['gender']?.toString() ??
          '',
      'image':
          prefs.getString('image') ??
          fbUser?.photoURL ??
          storedProfile['image']?.toString() ??
          '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': savedLoginType,
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<user_model.User> getUser() async {
    final userData = await getUserData();
    return user_model.User.fromJson(userData);
  }

  /// Check if user is Logged In (either via Firebase Auth or DummyJSON token)
  Future<bool> isLoggedIn() async {
    if (currentUser != null) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Logout and Clear User Session Data (clears both SharedPreferences session and Firebase Auth)
  Future<void> logout() async {
    try {
      if (currentUser != null) {
        await firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        'id',
        'uid',
        'username',
        'email',
        'firstName',
        'lastName',
        'age',
        'contactNo',
        'gender',
        'image',
        'accessToken',
        'refreshToken',
        'token',
        'loginType',
      ];
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ==============================================================
  // Firebase Authentication Methods (Enhancement 1)
  // ==============================================================

  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser {
    try {
      return firebaseAuth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser != null) {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> storedProfile = {};
      final rawProfile = prefs.getString(
        'firebase_profile_${email.toLowerCase()}',
      );
      if (rawProfile != null && rawProfile.isNotEmpty) {
        try {
          storedProfile = Map<String, dynamic>.from(jsonDecode(rawProfile));
        } catch (_) {}
      }

      String idToken = '';
      try {
        idToken = await fbUser.getIdToken() ?? '';
      } catch (_) {}

      await saveUserData({
        'id': storedProfile['id'] ?? 1,
        'uid': fbUser.uid,
        'username': (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
            ? fbUser.displayName!
            : (storedProfile['username'] ?? email.split('@').first),
        'email': fbUser.email ?? email,
        'firstName': storedProfile['firstName'] ?? '',
        'lastName': storedProfile['lastName'] ?? '',
        'age': storedProfile['age'] ?? 0,
        'contactNo': storedProfile['contactNo'] ?? '',
        'gender': storedProfile['gender'] ?? '',
        'image': fbUser.photoURL ?? storedProfile['image'] ?? '',
        'accessToken': idToken,
        'token': idToken,
        'loginType': 'firebase',
      });
    }

    return credential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await logout();
  }

  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      await currentUser!.reload();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);

    final email = (currentUser?.email ?? prefs.getString('email') ?? '')
        .toLowerCase();
    if (email.isNotEmpty) {
      final profileKey = 'firebase_profile_$email';
      final rawProfile = prefs.getString(profileKey);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(rawProfile));
          map['username'] = username;
          await prefs.setString(profileKey, jsonEncode(map));
        } catch (_) {}
      }
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    if (currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
      await firebaseAuth.signOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firebase_profile_${email.toLowerCase()}');
    await logout();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (currentUser != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    } else {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Password change requires an active Firebase Auth session.',
      );
    }
  }
}
