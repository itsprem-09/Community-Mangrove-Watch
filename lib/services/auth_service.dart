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
  // Auth service connects directly to Express backend
  static String get baseUrl => ApiConfig.expressBackendUrl;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  // Cache for working URL to avoid repeated tests
  static String? _workingUrl;
  static DateTime? _lastUrlTest;

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
      
      // Print detailed configuration for debugging
      ApiConfig.printConfig();
      
      // Test server connectivity with fallback URLs
      final workingUrl = await _findWorkingUrl();
      if (workingUrl == null) {
        return {
          'success': false,
          'message': 'Cannot connect to server. Please ensure the backend server is running.\n\nTried URLs: ${ApiConfig.fallbackUrls.join(', ')}',
          'debug_info': {
            'primary_url': baseUrl,
            'fallback_urls': ApiConfig.fallbackUrls,
            'platform': Platform.isAndroid ? 'Android' : Platform.operatingSystem,
          }
        };
      }
      
      print('[AuthService] Using working URL: $workingUrl');
      _workingUrl = workingUrl; // Cache the working URL
      
      final response = await _makeRequestWithRetry(
        () => http.post(
          Uri.parse('$workingUrl/auth/login'),
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
      // Find working URL first
      final workingUrl = await _findWorkingUrl();
      if (workingUrl == null) {
        return {
          'success': false,
          'message': 'Cannot connect to server. Please ensure the backend server is running.\n\nTried URLs: ${ApiConfig.fallbackUrls.join(', ')}',
        };
      }
      
      print('[AuthService] Registering user with URL: $workingUrl/auth/register');
      print('[AuthService] User data: ${userData.keys.join(', ')}'); // Don't log sensitive data
      
      final response = await _makeRequestWithRetry(
        () => http.post(
          Uri.parse('$workingUrl/auth/register'),
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
      final currentUrl = _currentBaseUrl;
      final response = await http.get(
        Uri.parse('$currentUrl/user/profile'),
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

  // Method to find a working URL from the fallback list
  Future<String?> _findWorkingUrl() async {
    // Return cached URL if it's recent (less than 5 minutes old)
    if (_workingUrl != null && _lastUrlTest != null) {
      final timeSinceLastTest = DateTime.now().difference(_lastUrlTest!);
      if (timeSinceLastTest.inMinutes < 5) {
        print('[AuthService] Using cached working URL: $_workingUrl');
        return _workingUrl;
      }
    }
    
    print('[AuthService] Testing fallback URLs for connectivity...');
    final fallbackUrls = ApiConfig.fallbackUrls;
    
    for (int i = 0; i < fallbackUrls.length; i++) {
      final url = fallbackUrls[i];
      print('[AuthService] Testing URL ${i + 1}/${fallbackUrls.length}: $url');
      
      try {
        final response = await http.get(
          Uri.parse('$url/health'),
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          print('[AuthService] ✅ URL working: $url');
          _workingUrl = url;
          _lastUrlTest = DateTime.now();
          return url;
        } else {
          print('[AuthService] ❌ URL returned ${response.statusCode}: $url');
        }
      } catch (e) {
        print('[AuthService] ❌ URL failed ($e): $url');
      }
    }
    
    print('[AuthService] ❌ No working URLs found');
    return null;
  }
  
  // Helper method to get the current working base URL
  String get _currentBaseUrl => _workingUrl ?? baseUrl;
  
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
