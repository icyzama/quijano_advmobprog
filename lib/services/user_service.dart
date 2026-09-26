import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserServiceException implements Exception {
  final String message;

  const UserServiceException(this.message);

  @override
  String toString() => message;
}

class UserService {
  static const String _userStorageKey = 'authenticated_user';

  // Enhancement 2: Sign-in screen integrated with API authentication.
  Future<User> loginUser({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    final decoded = _decodeObject(response.body);

    if (response.statusCode != 200) {
      throw UserServiceException(
        decoded['message'] as String? ?? 'Unable to sign in. Please try again.',
      );
    }

    final loginUser = User.fromJson(decoded);
    if (!loginUser.hasAuthToken || loginUser.id == 0) {
      throw const UserServiceException(
        'The sign-in response was incomplete. Please try again.',
      );
    }

    final profileUser = await _getAuthenticatedUser(loginUser.accessToken!);
    final userToSave = (profileUser ?? loginUser).copyWith(
      accessToken: loginUser.accessToken,
      refreshToken: loginUser.refreshToken,
    );

    await saveUserData(userToSave);
    return userToSave;
  }

  Future<void> saveUserData(User user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userStorageKey, jsonEncode(user.toJson()));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString(_userStorageKey);

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawUser) as Map<String, dynamic>;
    } catch (_) {
      await preferences.remove(_userStorageKey);
      return null;
    }
  }

  Future<User?> getUser() async {
    final data = await getUserData();
    if (data == null) {
      return null;
    }

    try {
      return User.fromJson(data);
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null && user.id != 0 && user.hasAuthToken;
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userStorageKey);
  }

  Future<User?> _getAuthenticatedUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('$host/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      return User.fromJson(_decodeObject(response.body));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      throw const UserServiceException('Unexpected API response.');
    }

    throw const UserServiceException('Unexpected API response.');
  }
}
