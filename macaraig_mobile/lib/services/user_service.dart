import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  Map<String, dynamic> data = {};

  // Enhancement 2:
  // Authenticate the user using the DummyJSON login API.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);

      // Enhancement 3:
      // Save the authenticated user's data locally.
      await saveUserData(data);

      return data;
    } else {
      throw Exception(
        'Login failed: ${response.body}',
      );
    }
  }

  // Enhancement 3:
  // Save authenticated user information
  // using SharedPreferences.
  Future<void> saveUserData(
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);

    await prefs.setString(
      'username',
      user.username,
    );

    await prefs.setString(
      'email',
      user.email,
    );

    await prefs.setString(
      'firstName',
      user.firstName,
    );

    await prefs.setString(
      'lastName',
      user.lastName,
    );

    await prefs.setString(
      'gender',
      user.gender,
    );

    await prefs.setString(
      'image',
      user.image,
    );

    await prefs.setString(
      'accessToken',
      user.accessToken,
    );

    await prefs.setString(
      'refreshToken',
      user.refreshToken,
    );

    if (userData.containsKey('token')) {
      await prefs.setString(
        'token',
        userData['token'] ?? '',
      );
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString(
        'token',
        user.accessToken,
      );
    }
  }

  // Enhancement 1 and 3:
  // Retrieve the saved user information.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,

      'username':
          prefs.getString('username') ?? '',

      'email':
          prefs.getString('email') ?? '',

      'firstName':
          prefs.getString('firstName') ?? '',

      'lastName':
          prefs.getString('lastName') ?? '',

      'gender':
          prefs.getString('gender') ?? '',

      'image':
          prefs.getString('image') ?? '',

      'accessToken':
          prefs.getString('accessToken') ?? '',

      'refreshToken':
          prefs.getString('refreshToken') ?? '',

      'token':
          prefs.getString('token') ??
          prefs.getString('accessToken') ??
          '',
    };
  }

  // Enhancement 3:
  // Return the saved information as a User model.
  Future<User> getUser() async {
    final userData = await getUserData();

    return User.fromJson(userData);
  }

  // Enhancement 1:
  // Check if the user is already authenticated.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('accessToken');

    return token != null && token.isNotEmpty;
  }

  // Enhancement 1:
  // Clear saved authentication information when logging out.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('gender');
    await prefs.remove('image');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('token');
  }
}