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

  // GEE Predictions - Direct to Python backend
  Future<Map<String, dynamic>> getPredictionFromGEE(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$pythonUrl/predict-mangrove-enhanced'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get mangrove prediction');
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
}
