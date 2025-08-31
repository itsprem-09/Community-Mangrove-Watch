import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class GeeService {
  static String get baseUrl => ApiConfig.pythonBackendUrl;
  
  // Cache for working URL to avoid repeated tests
  static String? _workingUrl;
  static DateTime? _lastUrlTest;
  
  /// Find a working Python backend URL specifically for GEE services
  Future<String?> _findWorkingBackendUrl() async {
    // Return cached URL if it's recent (less than 5 minutes old)
    if (_workingUrl != null && _lastUrlTest != null) {
      final timeSinceLastTest = DateTime.now().difference(_lastUrlTest!);
      if (timeSinceLastTest.inMinutes < 5) {
        print('[GeeService] Using cached working URL: $_workingUrl');
        return _workingUrl;
      }
    }
    
    print('[GeeService] Testing backend URLs for GEE services...');
    // Only try Python backend URLs for GEE services
    // Prioritize machine IP for Android emulator since 10.0.2.2 has connection issues
    final urlsToTest = [
      'http://10.40.19.96:8000', // Your current machine IP - prioritize this
      ApiConfig.pythonBackendUrl,
      'http://localhost:8000',
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000', // Android emulator fallback
    ];
    
    for (int i = 0; i < urlsToTest.length; i++) {
      final url = urlsToTest[i];
      print('[GeeService] Testing Python backend ${i + 1}/${urlsToTest.length}: $url');
      
      try {
        // Test specifically for GEE endpoint availability
        final response = await http.get(
          Uri.parse('$url/health'),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          // Additional check: verify this backend actually has GEE endpoints
          try {
            final geeTestResponse = await http.get(
              Uri.parse('$url/gee/mangrove-visualization?center_lat=0&center_lng=0&zoom=1'),
            ).timeout(const Duration(seconds: 15));
            
            // Accept any response (even errors) as long as the endpoint exists
            if (geeTestResponse.statusCode != 404) {
              print('[GeeService] ✅ Python backend with GEE services found: $url');
              _workingUrl = url;
              _lastUrlTest = DateTime.now();
              return url;
            } else {
              print('[GeeService] ❌ Backend lacks GEE endpoints: $url');
            }
          } catch (e) {
            print('[GeeService] ❌ GEE endpoint test failed: $url ($e)');
          }
        } else {
          print('[GeeService] ❌ Backend health check failed ${response.statusCode}: $url');
        }
      } catch (e) {
        print('[GeeService] ❌ Backend connection failed: $url ($e)');
      }
    }
    
    print('[GeeService] ❌ No Python backend with GEE services found, using mock data');
    return null;
  }

  /// Get mangrove visualization data from the backend
  Future<Map<String, dynamic>> getMangroveVisualizationData({
    double centerLat = -2.0164,
    double centerLng = -44.5626,
    int zoom = 9,
  }) async {
    try {
      print('[GeeService] Fetching mangrove visualization data...');
      
      // Try to find a working backend URL first
      final workingUrl = await _findWorkingBackendUrl();
      
      if (workingUrl == null) {
        print('[GeeService] No working backend found, using mock data');
        return _getMockVisualizationData(centerLat, centerLng, zoom);
      }
      
      final response = await http.get(
        Uri.parse('$workingUrl/gee/mangrove-visualization')
            .replace(queryParameters: {
          'center_lat': centerLat.toString(),
          'center_lng': centerLng.toString(),
          'zoom': zoom.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 90));  // Increased to 90 seconds for GEE processing

      print('[GeeService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[GeeService] Successfully received visualization data');
        return data;
      } else {
        print('[GeeService] Error response: ${response.body}');
        throw Exception('Failed to get visualization data: ${response.statusCode}');
      }
    } catch (e) {
      print('[GeeService] Error in getMangroveVisualizationData: $e');
      // Return mock data on error for development
      return _getMockVisualizationData(centerLat, centerLng, zoom);
    }
  }

  /// Get the HTML URL for the mangrove visualization
  String getMangroveHtmlUrl({
    double centerLat = -2.0164,
    double centerLng = -44.5626,
    int zoom = 9,
  }) {
    // Use cached working URL if available, otherwise fallback to base URL
    final urlToUse = _workingUrl ?? baseUrl;
    return Uri.parse('$urlToUse/gee/mangrove-html')
        .replace(queryParameters: {
      'center_lat': centerLat.toString(),
      'center_lng': centerLng.toString(),
      'zoom': zoom.toString(),
    }).toString();
  }

  /// Get satellite analysis for a specific location
  Future<Map<String, dynamic>> getSatelliteAnalysis(
    double lat, 
    double lng,
  ) async {
    try {
      print('[GeeService] Getting satellite analysis for $lat, $lng');
      
      final response = await http.get(
        Uri.parse('$baseUrl/satellite-analysis/$lat/$lng'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get satellite analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('[GeeService] Error in getSatelliteAnalysis: $e');
      // Return mock data on error
      return _getMockSatelliteData(lat, lng);
    }
  }

  /// Get mangrove extent data for a location
  Future<Map<String, dynamic>> getMangroveExtent(
    double latitude,
    double longitude, {
    double radiusKm = 10.0,
  }) async {
    try {
      print('[GeeService] Getting mangrove extent for $latitude, $longitude');
      
      final response = await http.get(
        Uri.parse('$baseUrl/mangrove-extent').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius_km': radiusKm.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get mangrove extent: ${response.statusCode}');
      }
    } catch (e) {
      print('[GeeService] Error in getMangroveExtent: $e');
      // Return mock data on error
      return _getMockExtentData(latitude, longitude);
    }
  }

  /// Get mangrove trends for a location
  Future<Map<String, dynamic>> getMangoveTrends(
    double latitude,
    double longitude, {
    double radiusKm = 10.0,
  }) async {
    try {
      print('[GeeService] Getting mangrove trends for $latitude, $longitude');
      
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/mangrove-trends').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius_km': radiusKm.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get mangrove trends: ${response.statusCode}');
      }
    } catch (e) {
      print('[GeeService] Error in getMangoveTrends: $e');
      // Return mock data on error
      return _getMockTrendsData(latitude, longitude);
    }
  }

  /// Check if the backend is available
  Future<bool> checkBackendHealth() async {
    final workingUrl = await _findWorkingBackendUrl();
    return workingUrl != null;
  }

  // Mock data methods for development
  Map<String, dynamic> _getMockVisualizationData(
    double centerLat, 
    double centerLng, 
    int zoom,
  ) {
    return {
      'map_id': 'mock_map_id',
      'token': 'mock_token',
      'tile_url_template': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'visualization_params': {
        'min': 0,
        'max': 1.0,
        'palette': ['d40115']
      },
      'center': {
        'latitude': centerLat,
        'longitude': centerLng
      },
      'zoom': zoom,
      'statistics': {
        'mangrove_pixel_count': 5000.0,
        'ndvi_mean': 0.65,
        'area_analyzed_km2': 31415.93
      },
      'layer_info': {
        'name': 'Mock Mangrove Data',
        'description': 'Simulated mangrove data for development',
        'year': 2020,
        'resolution': '30m'
      }
    };
  }

  Map<String, dynamic> _getMockSatelliteData(double lat, double lng) {
    final baseNdvi = 0.3 + (lat.abs() / 90 * 0.4);
    return {
      'latitude': lat,
      'longitude': lng,
      'ndvi': baseNdvi,
      'ndwi': 0.2,
      'savi': baseNdvi * 0.8,
      'area_stats': {
        'ndvi_mean': baseNdvi,
        'ndvi_std': 0.15,
        'water_percentage': 25.0
      },
      'data_date': DateTime.now().toIso8601String(),
      'cloud_cover': 'low',
      'data_source': 'Mock'
    };
  }

  Map<String, dynamic> _getMockExtentData(double lat, double lng) {
    final baseArea = lat.abs() * 10;
    return {
      'current_extent_hectares': baseArea,
      'historical_extent_hectares': baseArea * 1.2,
      'change_hectares': baseArea * -0.2,
      'change_percentage': -16.7
    };
  }

  Map<String, dynamic> _getMockTrendsData(double lat, double lng) {
    final years = [1996, 2000, 2005, 2010, 2015, 2020];
    const baseHealth = 75.0;
    
    final trends = years.asMap().entries.map((entry) {
      final index = entry.key;
      final year = entry.value;
      final healthScore = baseHealth - (index * 2) + (index % 2 * 5);
      
      return {
        'year': year,
        'ndvi_mean': healthScore / 100,
        'health_score': healthScore.clamp(0, 100)
      };
    }).toList();
    
    return {
      'trends': trends,
      'location': {'latitude': lat, 'longitude': lng},
      'radius_km': 10
    };
  }
}
