import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static String get baseUrl => ApiConfig.backendBaseUrl;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

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
      print('[AuthService] Attempting login for: $email');
      print('[AuthService] Using backend URL: $baseUrl');
      
      final response = await _makeRequestWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ).timeout(_timeout),
        'login',
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
      return _handleNetworkError(e, 'login');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      print('[AuthService] Registering user with URL: $baseUrl/auth/register');
      print('[AuthService] User data: ${userData.keys.join(', ')}'); // Don't log sensitive data
      
      final response = await _makeRequestWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        ).timeout(_timeout),
        'register',
      );
      
      print('[AuthService] Register response status: ${response.statusCode}');
      print('[AuthService] Register response body: ${response.body}');

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
      return _handleNetworkError(e, 'register');
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

  // Helper method to make HTTP requests with retry logic
  Future<http.Response> _makeRequestWithRetry(
    Future<http.Response> Function() requestFunction,
    String operation,
  ) async {
    int retryCount = 0;
    Duration delay = const Duration(seconds: 1);

    while (retryCount < _maxRetries) {
      try {
        print('[AuthService] Attempt ${retryCount + 1} for $operation');
        final response = await requestFunction();
        print('[AuthService] Request successful for $operation');
        return response;
      } on TimeoutException catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('[AuthService] Max retries reached for $operation');
          throw TimeoutException(
            'Connection timeout after $_maxRetries attempts',
            _timeout,
          );
        }
        print('[AuthService] Timeout on attempt $retryCount for $operation, retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      } on SocketException catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('[AuthService] Max retries reached for $operation due to socket error');
          throw SocketException(
            'Network unreachable after $_maxRetries attempts: ${e.message}',
            osError: e.osError,
            address: e.address,
            port: e.port,
          );
        }
        print('[AuthService] Socket error on attempt $retryCount for $operation: ${e.message}');
        await Future.delayed(delay);
        delay *= 2;
      } on http.ClientException catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          print('[AuthService] Max retries reached for $operation due to client error');
          rethrow;
        }
        print('[AuthService] Client error on attempt $retryCount for $operation: $e');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
    
    throw Exception('Failed to complete $operation after $_maxRetries attempts');
  }

  // Helper method to handle network errors
  Map<String, dynamic> _handleNetworkError(dynamic error, String operation) {
    print('[AuthService] Network error during $operation: $error');
    
    String message = 'Network error';
    
    if (error is TimeoutException) {
      message = 'Connection timeout. Please check your internet connection and try again.';
    } else if (error is SocketException) {
      if (error.message.contains('Failed host lookup')) {
        message = 'Cannot connect to server. Please check your internet connection.';
      } else if (error.message.contains('Connection refused')) {
        message = 'Server is not responding. Please try again later.';
      } else {
        message = 'Network error: ${error.message}';
      }
    } else if (error is http.ClientException) {
      message = 'Connection failed. Please check your internet connection.';
    } else {
      message = 'An unexpected error occurred: ${error.toString()}';
    }
    
    return {
      'success': false,
      'message': message,
    };
  }
}
