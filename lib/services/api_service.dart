import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/incident_report.dart';
import '../models/user.dart';
import 'api_config.dart';

class ApiService {
  // Express backend URL for auth, incidents, uploads, email
  static String get expressUrl => ApiConfig.expressBackendUrl;
  // Python backend URL for AI/ML, GEE, predictions
  static String get pythonUrl => ApiConfig.pythonBackendUrl;
  
  // Legacy getter for backward compatibility
  static String get baseUrl => expressUrl;

  // AI/ML Image Analysis - Direct to Python backend
  Future<String> analyzeImageWithGemini(String imagePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$pythonUrl/public/analyze-image'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return data['prediction']['description'] ?? 'Analysis completed';
    }
    throw Exception('Failed to analyze image');
  }

  // Incidents - Direct to Express backend
  Future<void> submitReport(IncidentReport report) async {
    try {
      // Convert the report to the format expected by the backend
      final reportData = {
        'type': report.type.name,
        'description': report.description,
        'title': report.title,
        'location': {
          'latitude': report.latitude,
          'longitude': report.longitude,
        },
        'severity': report.severity.name,
        'userId': report.userId,
        'reporterName': 'User', // Default name if not available
        'images': report.images,
        'timestamp': report.timestamp.toIso8601String(),
        'status': report.status.name,
      };
      
      print('[ApiService] Submitting report to Express: ${jsonEncode(reportData)}');
      
      final response = await http.post(
        Uri.parse('$expressUrl/incidents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
        );
      
      print('[ApiService] Response status: ${response.statusCode}');
      print('[ApiService] Response body: ${response.body}');
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['message'] ?? errorBody['error'] ?? 'Failed to submit report');
      }
    } catch (e) {
      print('[ApiService] Error submitting report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  // Incidents - Direct to Express backend
  Future<List<IncidentReport>> getReports() async {
    final response = await http.get(
      Uri.parse('$expressUrl/incidents'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => IncidentReport.fromJson(json)).toList();
    }
    throw Exception('Failed to load reports');
  }

  // GEE Predictions - Direct to Python backend with fallback
  Future<Map<String, dynamic>> getPredictionFromGEE(double lat, double lng) async {
    try {
      print('[ApiService] Requesting mangrove prediction for lat: $lat, lng: $lng');
      
      final response = await http.post(
        Uri.parse('$pythonUrl/predict-mangrove-enhanced'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('[ApiService] Backend request timed out, using mock data');
          throw Exception('Backend timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ApiService] Received prediction data: $data');
        
        // Validate the data and ensure it has reasonable values
        final validatedData = _validatePredictionData(data, lat, lng);
        return validatedData;
      } else {
        print('[ApiService] Backend returned status: ${response.statusCode}');
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      print('[ApiService] Backend request failed: $e, using realistic mock data');
      return _generateRealisticMockData(lat, lng);
    }
  }

  // Leaderboard - Direct to Python backend
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$pythonUrl/leaderboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load leaderboard');
  }

  // User Stats - Direct to Python backend (where user stats are calculated)
  Future<Map<String, dynamic>?> getUserStats() async {
    final response = await http.get(
      Uri.parse('$pythonUrl/user/profile'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Analytics - Direct to Python backend
  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await http.get(
      Uri.parse('$pythonUrl/analytics/dashboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load analytics');
  }

  // GEE Visualization - Direct to Python backend
  Future<Map<String, dynamic>> getMangroveVisualization({double? lat, double? lng, int? zoom}) async {
    String url = '$pythonUrl/gee/mangrove-visualization';
    if (lat != null && lng != null) {
      url += '?center_lat=$lat&center_lng=$lng';
      if (zoom != null) {
        url += '&zoom=$zoom';
      }
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load mangrove visualization');
  }
  
  // Mangrove Trends - Direct to Python backend
  Future<Map<String, dynamic>> getMangrove_Trends(double lat, double lng, {double radiusKm = 10}) async {
    final response = await http.get(
      Uri.parse('$pythonUrl/analytics/mangrove-trends?latitude=$lat&longitude=$lng&radius_km=$radiusKm'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load mangrove trends');
  }
  
  // Satellite Analysis - Direct to Python backend
  Future<Map<String, dynamic>> getSatelliteAnalysis(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$pythonUrl/satellite-analysis/$lat/$lng'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load satellite analysis');
  }

  // ONNX-based Mangrove Prediction - Direct to Python backend
  Future<Map<String, dynamic>> predictMangroveFromImage(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$pythonUrl/predict-mangrove-image'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Add timeout for backend requests
      final response = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Backend request timed out. Using local processing instead.');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        
        // Ensure the prediction data has the expected format
        final prediction = data['prediction'] ?? {};
        return {
          'is_mangrove': prediction['is_mangrove'] ?? false,
          'confidence': prediction['confidence'] ?? 0.0,
          'mangrove_probability': prediction['mangrove_probability'] ?? 0.0,
          'prediction_class': prediction['prediction_class'] ?? 'unknown',
          'model_type': prediction['model_type'] ?? 'backend_onnx',
          'message': prediction['message'] ?? 'Analysis completed via backend',
          'processing_type': 'remote',
        };
      } else {
        throw Exception('Backend returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('Backend prediction failed: $e');
      throw Exception('Backend unavailable: ${e.toString()}');
    }
  }

  // Helper method to validate prediction data and ensure realistic values
  Map<String, dynamic> _validatePredictionData(Map<String, dynamic> data, double lat, double lng) {
    // Ensure required fields exist and have reasonable values
    double coverage = (data['predicted_coverage'] ?? 0.0).toDouble();
    double ndvi = (data['ndvi_value'] ?? 0.0).toDouble();
    double confidence = (data['confidence'] ?? 0.0).toDouble();
    
    // If values seem unrealistic (all zeros), generate better mock data
    if (coverage == 0.0 && ndvi == 0.0) {
      print('[ApiService] Backend returned zero values, generating realistic data');
      return _generateRealisticMockData(lat, lng);
    }
    
    // Validate and clamp values to realistic ranges
    coverage = coverage.clamp(0.0, 1.0);
    ndvi = ndvi.clamp(-1.0, 1.0);
    confidence = confidence.clamp(0.0, 1.0);
    
    return {
      'predicted_coverage': coverage,
      'ndvi_value': ndvi,
      'confidence': confidence,
      'model_type': data['model_type'] ?? 'gee_enhanced',
      'message': data['message'] ?? 'Real-time analysis from Google Earth Engine',
      'location': {
        'latitude': lat,
        'longitude': lng,
      },
    };
  }

  // Generate realistic mock mangrove health data based on location
  Map<String, dynamic> _generateRealisticMockData(double lat, double lng) {
    // Create pseudo-random but consistent data based on coordinates
    final seed = (lat * 1000 + lng * 1000).abs().toInt();
    final random = _PseudoRandom(seed);
    
    // Determine if location is likely to have mangroves (coastal tropical/subtropical)
    bool isCoastalTropical = _isCoastalTropicalLocation(lat, lng);
    
    double baseCoverage, baseNdvi, baseConfidence;
    
    if (isCoastalTropical) {
      // Higher likelihood of mangroves in coastal tropical areas
      baseCoverage = 0.3 + random.nextDouble() * 0.5; // 30-80%
      baseNdvi = 0.2 + random.nextDouble() * 0.4; // 0.2-0.6
      baseConfidence = 0.7 + random.nextDouble() * 0.25; // 70-95%
    } else {
      // Lower likelihood in non-coastal or non-tropical areas
      baseCoverage = random.nextDouble() * 0.3; // 0-30%
      baseNdvi = -0.1 + random.nextDouble() * 0.4; // -0.1-0.3
      baseConfidence = 0.6 + random.nextDouble() * 0.3; // 60-90%
    }
    
    // Add some temporal variation (simulate different seasons/conditions)
    final dayOfYear = DateTime.now().dayOfYear;
    final seasonalFactor = 0.9 + 0.2 * (dayOfYear / 365.0); // Slight seasonal variation
    
    final coverage = (baseCoverage * seasonalFactor).clamp(0.0, 1.0);
    final ndvi = (baseNdvi * seasonalFactor).clamp(-1.0, 1.0);
    final confidence = baseConfidence.clamp(0.0, 1.0);
    
    print('[ApiService] Generated realistic mock data: Coverage: ${(coverage * 100).toStringAsFixed(1)}%, NDVI: ${ndvi.toStringAsFixed(2)}, Confidence: ${(confidence * 100).toStringAsFixed(0)}%');
    
    return {
      'predicted_coverage': coverage,
      'ndvi_value': ndvi,
      'confidence': confidence,
      'model_type': 'mock_realistic',
      'message': 'Simulated data - Enable backend for real-time analysis',
      'location': {
        'latitude': lat,
        'longitude': lng,
      },
      'is_mock': true,
    };
  }
  
  // Helper to determine if location is coastal tropical (more likely to have mangroves)
  bool _isCoastalTropicalLocation(double lat, double lng) {
    // Rough heuristic: tropical/subtropical latitudes (between 30°N and 30°S)
    // and near known mangrove regions
    final absLat = lat.abs();
    
    if (absLat > 35) return false; // Too far from tropics
    
    // Known mangrove regions (simplified)
    // Southeast Asia, Caribbean, Florida, Australia, etc.
    final knownRegions = [
      // Southeast Asia
      {'latMin': -10, 'latMax': 25, 'lngMin': 90, 'lngMax': 140},
      // Caribbean/Central America
      {'latMin': 10, 'latMax': 25, 'lngMin': -90, 'lngMax': -60},
      // Florida/Gulf of Mexico
      {'latMin': 20, 'latMax': 30, 'lngMin': -100, 'lngMax': -80},
      // Northern Australia
      {'latMin': -25, 'latMax': -10, 'lngMin': 110, 'lngMax': 155},
      // West Africa
      {'latMin': -5, 'latMax': 15, 'lngMin': -20, 'lngMax': 10},
      // Indian Ocean (Sri Lanka, India)
      {'latMin': 5, 'latMax': 15, 'lngMin': 70, 'lngMax': 85},
    ];
    
    for (final region in knownRegions) {
      if (lat >= region['latMin']! && lat <= region['latMax']! &&
          lng >= region['lngMin']! && lng <= region['lngMax']!) {
        return true;
      }
    }
    
    // Default to moderate likelihood for tropical coastal areas
    return absLat < 25;
  }
}

// Simple pseudo-random number generator for consistent results
class _PseudoRandom {
  int _seed;
  
  _PseudoRandom(this._seed);
  
  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}

// Extension to get day of year
extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final startOfYear = DateTime(year, 1, 1);
    return difference(startOfYear).inDays + 1;
  }
}
