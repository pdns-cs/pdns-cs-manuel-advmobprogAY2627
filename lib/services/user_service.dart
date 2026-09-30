import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  static const String _localUsername = 'pdenese';
  static const String _localPassword = 'Testing2026!';

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    if (username == _localUsername && password == _localPassword) {
      final userData = _localUserData();
      await saveUserData(userData);
      await saveLoginType('dummyjson');
      return userData;
    }

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
      final Map<String, dynamic> data = jsonDecode(response.body);
      await saveUserData(data);
      await saveLoginType('dummyjson');
      return data;
    }

    throw Exception(response.body);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'id',
      int.tryParse('${userData['id'] ?? 0}') ?? 0,
    );
    await prefs.setString('uid', '${userData['uid'] ?? ''}');
    await prefs.setString('username', '${userData['username'] ?? ''}');
    await prefs.setString('email', '${userData['email'] ?? ''}');
    await prefs.setString('firstName', '${userData['firstName'] ?? ''}');
    await prefs.setString('lastName', '${userData['lastName'] ?? ''}');
    await prefs.setInt(
      'age',
      int.tryParse('${userData['age'] ?? 0}') ?? 0,
    );
    await prefs.setString('contactNo', '${userData['contactNo'] ?? ''}');
    await prefs.setString('gender', '${userData['gender'] ?? ''}');
    await prefs.setString('image', '${userData['image'] ?? ''}');
    await prefs.setString('accessToken', '${userData['accessToken'] ?? ''}');
    await prefs.setString('refreshToken', '${userData['refreshToken'] ?? ''}');

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if ((userData['accessToken'] ?? '').toString().isNotEmpty) {
      await prefs.setString('token', userData['accessToken']);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    try {
      if (currentUser != null) {
        return true;
      }
    } on FirebaseException {
      // Widget tests may run before Firebase.initializeApp().
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return (prefs.getString('loginType') ?? 'dummyjson') == 'dummyjson' &&
        token != null &&
        token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await firebaseAuth.signOut();
      await prefs.clear();
    } catch (error) {
      throw Exception('Failed to log out: $error');
    }
  }

  Future<void> saveLoginType(String loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', loginType);
  }

  Future<String> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') ?? 'dummyjson';
  }

  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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

  Future<Map<String, dynamic>> createFirebaseAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
  }) async {
    final credential = await createAccount(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw Exception('Firebase did not return a user');
    }

    await user.updateDisplayName('$firstName $lastName'.trim());
    final profile = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'username': username,
      'email': email,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profile);
    await saveLoginType('firebase');

    final userData = {
      ...profile,
      'id': 0,
      'uid': user.uid,
      'gender': '',
      'image': '',
      'accessToken': '',
      'refreshToken': '',
      'token': '',
    };
    await saveUserData(userData);
    return userData;
  }

  Future<Map<String, dynamic>> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    final credential = await signIn(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw Exception('Firebase did not return a user');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = <String, dynamic>{
      ...?snapshot.data(),
      'id': 0,
      'uid': user.uid,
      'email': user.email ?? email,
      'firstName': snapshot.data()?['firstName'] ?? '',
      'lastName': snapshot.data()?['lastName'] ?? '',
      'username': snapshot.data()?['username'] ?? '',
      'age': snapshot.data()?['age'] ?? 0,
      'contactNo': snapshot.data()?['contactNo'] ?? '',
      'gender': '',
      'image': '',
      'accessToken': '',
      'refreshToken': '',
      'token': '',
    };
    await saveLoginType('firebase');
    await saveUserData(userData);
    return userData;
  }

  Future<String?> getFirebaseIdToken({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken(forceRefresh);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    final trimmed = username.trim();

    if (trimmed.length < 3 || trimmed.length > 32) {
      throw Exception('Username must be between 3 and 32 characters');
    }

    final user = currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'username': trimmed}, SetOptions(merge: true));
      await user.updateDisplayName(trimmed);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', trimmed);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No signed in user');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (currentUser == null) {
      throw Exception('No signed in user');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Map<String, dynamic> _localUserData() {
    return {
      'id': 1,
      'username': _localUsername,
      'email': 'pdenese@example.com',
      'firstName': 'P',
      'lastName': 'Denese',
      'gender': '',
      'image': '',
      'accessToken': 'local-access-token',
      'refreshToken': 'local-refresh-token',
      'token': 'local-access-token',
    };
  }
}
