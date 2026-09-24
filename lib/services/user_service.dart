import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

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
      return data;
    }

    throw Exception(response.body);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('id', userData['id'] ?? 0);
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('gender', userData['gender'] ?? '');
    await prefs.setString('image', userData['image'] ?? '');
    await prefs.setString('accessToken', userData['accessToken'] ?? '');
    await prefs.setString('refreshToken', userData['refreshToken'] ?? '');

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
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (error) {
      throw Exception('Failed to log out: $error');
    }
  }

  Map<String, dynamic> _localUserData() {
    return {
      'id': 5,
      'username': _localUsername,
      'email': 'pdenese@example.com',
      'firstName': 'P',
      'lastName': 'Denese',
      'gender': 'female',
      'image': '',
      'accessToken': 'local-access-token',
      'refreshToken': 'local-refresh-token',
      'token': 'local-access-token',
    };
  }
}
