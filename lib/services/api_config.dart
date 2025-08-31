import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Direct backend URLs - no proxy
  static const String _expressBackendUrl = 'http://localhost:5000'; // Express backend
  static const String _pythonBackendUrl = 'http://localhost:8000'; // Python FastAPI backend
  
  // Android emulator URLs
  static const String _androidExpressUrl = 'http://10.0.2.2:5000';
  static const String _androidPythonUrl = 'http://10.0.2.2:8000';
  
  // iOS simulator URLs
  static const String _iosExpressUrl = 'http://localhost:5000';
  static const String _iosPythonUrl = 'http://localhost:8000';
  
  // Your local machine IP for physical device testing
  static const String _localMachineIp = '10.40.19.96'; // Your current Wi-Fi IP
  
  // Fallback URLs for Android emulator (in order of preference)
  // Prioritize machine IP since 10.0.2.2 has connectivity issues
  static const List<String> _androidFallbackUrls = [
    'http://10.40.19.96:5000',     // Your machine's Wi-Fi IP - prioritize this
    'http://10.167.224.84:5000',   // Your machine's Ethernet IP
    'http://10.0.2.2:5000',        // Standard Android emulator host
    'http://localhost:5000',        // Sometimes works in newer emulators
    'http://127.0.0.1:5000',       // Local loopback
  ];
  
  // Get Express backend URL (auth, incidents, uploads, email)
  static String get expressBackendUrl {
    // For web platform, always use localhost
    if (kIsWeb) {
      return _expressBackendUrl;
    }
    
    // For mobile platforms
    if (Platform.isAndroid) {
      // Check if running on physical device or emulator
      return _isPhysicalDevice() ? 'http://$_localMachineIp:5000' : _androidExpressUrl;
    }
    
    if (Platform.isIOS) {
      // iOS simulator can use localhost, physical device needs IP
      return _isPhysicalDevice() ? 'http://$_localMachineIp:5000' : _iosExpressUrl;
    }
    
    // Default fallback
    return _expressBackendUrl;
  }
  
  // Legacy getter for backward compatibility
  static String get backendBaseUrl => expressBackendUrl;
  
  // Get all possible fallback URLs for the current platform
  static List<String> get fallbackUrls {
    if (kIsWeb) {
      return [_expressBackendUrl];
    }
    
    if (Platform.isAndroid) {
      return _isPhysicalDevice() 
        ? [
            'http://10.40.19.96:5000',    // Wi-Fi IP
            'http://10.167.224.84:5000',  // Ethernet IP
            'http://10.0.2.2:5000',       // Emulator fallback
          ]
        : _androidFallbackUrls;
    }
    
    if (Platform.isIOS) {
      return _isPhysicalDevice() 
        ? [
            'http://10.40.19.96:5000',    // Wi-Fi IP
            'http://10.167.224.84:5000',  // Ethernet IP
          ]
        : [_iosExpressUrl];
    }
    
    return [_expressBackendUrl];
  }
  
  // Python backend URL for ML/AI services
  static String get pythonBackendUrl {
    if (kIsWeb) {
      return _pythonBackendUrl;
    }
    
    if (Platform.isAndroid) {
      return _isPhysicalDevice() ? 'http://$_localMachineIp:8000' : _androidPythonUrl;
    }
    
    if (Platform.isIOS) {
      return _isPhysicalDevice() ? 'http://$_localMachineIp:8000' : _iosPythonUrl;
    }
    
    return _pythonBackendUrl;
  }
  
  // Helper method to detect if running on physical device
  // This is a simple heuristic - you might want to improve this
  static bool _isPhysicalDevice() {
    // For now, assume physical device if running on mobile platform
    // You can improve this detection later with device_info_plus package
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }
  
  // Helper method to get IP-based URL for physical devices
  static String getPhysicalDeviceUrl(String hostIp) {
    return 'http://$hostIp:5000';
  }
  
  // Method to update local machine IP at runtime if needed
  static String getUrlWithCustomIp(String ip) {
    return 'http://$ip:5000';
  }
  
  // Debug helper to print current configuration
  static void printConfig() {
    print('[ApiConfig] ====== API Configuration ======');
    print('[ApiConfig] Express Backend URL: $expressBackendUrl');
    print('[ApiConfig] Python Backend URL: $pythonBackendUrl');
    print('[ApiConfig] Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    print('[ApiConfig] Is Physical Device: ${_isPhysicalDevice()}');
    print('[ApiConfig] Local Machine IP: $_localMachineIp');
    print('[ApiConfig] Debug Mode: $kDebugMode');
    print('[ApiConfig] Fallback URLs: ${fallbackUrls.join(', ')}');
    print('[ApiConfig] ================================');
  }
  
  // Method to manually set the machine IP at runtime
  static String? _runtimeMachineIp;
  static void setMachineIp(String ip) {
    _runtimeMachineIp = ip;
    print('[ApiConfig] Machine IP updated to: $ip');
  }
  
  // Get the effective machine IP (runtime override or default)
  static String get effectiveMachineIp => _runtimeMachineIp ?? _localMachineIp;
}
