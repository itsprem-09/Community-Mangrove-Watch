import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Development server configuration
  static const String _localHostUrl = 'http://localhost:5000';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:5000';
  static const String _iosSimulatorUrl = 'http://localhost:5000';
  
  // YOUR MACHINE'S IP ADDRESS - Update this for physical device testing!
  // Note: This IP may change when your network changes. Update as needed.
  static const String _physicalDeviceUrl = 'http://10.167.224.193:5000'; // Your Windows machine IP
  
  // Alternative IPs (in case primary IP doesn't work)
  static const List<String> _alternativeUrls = [
    'http://10.167.224.193:5000',
    'http://10.40.19.96:5000',  // Secondary network interface
    'http://192.168.1.100:5000', // Common home network range
  ];
  
  // Production server (update when deploying)
  static const String _productionUrl = 'http://localhost:5000'; // Change this to your production URL
  
  // Get the appropriate backend URL based on platform
  static String get backendBaseUrl {
    // For web platform
    if (kIsWeb) {
      return _localHostUrl;
    }
    
    try {
      if (Platform.isAndroid) {
        // IMPORTANT: For physical devices, we use the actual IP address
        // The 10.0.2.2 address only works for emulators
        // Check if we're on an emulator or physical device
        return _physicalDeviceUrl; // Using your machine's IP for physical device
      } else if (Platform.isIOS) {
        // iOS physical devices also need the machine's IP address
        return _physicalDeviceUrl;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platforms use localhost
        return _localHostUrl;
      }
    } catch (e) {
      // Platform may not be available (e.g., in tests)
      print('[ApiConfig] Platform detection failed: $e');
    }
    
    // Default fallback
    return _localHostUrl;
  }
  
  // Python backend URL for ML/AI services that are still handled by Python
  static String get pythonBackendUrl {
    // Just append /api to the base URL
    return '$backendBaseUrl/api';
  }
  
  // Helper method to get IP-based URL for physical devices
  // Replace with your actual machine's IP address when testing on physical devices
  static String getPhysicalDeviceUrl(String hostIp) {
    return 'http://$hostIp:5000';
  }
  
  // Debug helper to print current configuration
  static void printConfig() {
    print('[ApiConfig] Backend URL: $backendBaseUrl');
    print('[ApiConfig] Python Backend URL: $pythonBackendUrl');
    print('[ApiConfig] Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
  }
}
