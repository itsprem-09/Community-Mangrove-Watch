import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/incident_report.dart';
import '../models/user.dart';
import 'api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.backendBaseUrl;

  Future<String> analyzeImageWithGemini(String imagePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze-image'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return data['prediction'];
    }
    throw Exception('Failed to analyze image');
  }

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
      
      print('[ApiService] Submitting report: ${jsonEncode(reportData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/incidents'),
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

  Future<List<IncidentReport>> getReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/incidents'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => IncidentReport.fromJson(json)).toList();
    }
    throw Exception('Failed to load reports');
  }

  Future<Map<String, dynamic>> getPredictionFromGEE(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict-mangrove'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get mangrove prediction');
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load leaderboard');
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/dashboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load analytics');
  }
}
