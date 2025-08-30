import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String baseUrl = 'http://localhost:5000/api'; // Express server

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        await saveToken(token);
        
        // Get user profile
        final userProfile = await getUserProfile();
        if (userProfile != null) {
          await saveUser(userProfile);
        }
        
        return {
          'success': true,
          'token': token,
          'user': userProfile,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveUser(data);
        
        // Auto-login after registration
        return await login(userData['email'], userData['password']);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Token expired, logout user
        await logout();
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  Future<bool> validateToken() async {
    final profile = await getUserProfile();
    return profile != null;
  }
}
