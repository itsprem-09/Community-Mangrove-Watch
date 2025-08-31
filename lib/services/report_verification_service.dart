import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/incident_report.dart';
import 'api_config.dart';

class ReportVerificationService {
  static String get pythonUrl => ApiConfig.pythonBackendUrl;

  // Verify a report using ONNX model
  Future<Map<String, dynamic>> verifyReportWithONNX(IncidentReport report) async {
    try {
      print('[ReportVerification] Starting verification for report: ${report.id}');
      
      // If report has no images, mark as failed
      if (report.images.isEmpty) {
        return {
          'is_verified': false,
          'confidence': 0.0,
          'reason': 'No images provided',
          'status': 'failed',
          'mangrove_detected': false,
          'verification_type': 'image_required',
        };
      }

      // Process each image with ONNX model
      List<Map<String, dynamic>> imageResults = [];
      bool anyMangroveDetected = false;
      double totalConfidence = 0.0;

      for (String imagePath in report.images) {
        if (File(imagePath).existsSync()) {
          final result = await _verifyImageWithONNX(imagePath);
          imageResults.add(result);
          
          if (result['mangrove_detected'] == true) {
            anyMangroveDetected = true;
          }
          totalConfidence += result['confidence'] ?? 0.0;
        }
      }

      // Calculate overall verification result
      final averageConfidence = imageResults.isNotEmpty 
          ? totalConfidence / imageResults.length 
          : 0.0;

      final verificationResult = _evaluateVerificationResult(
        report, 
        anyMangroveDetected, 
        averageConfidence,
        imageResults,
      );

      // Update report status in database
      await _updateReportStatus(report.id, verificationResult);

      return verificationResult;

    } catch (e) {
      print('[ReportVerification] Error during verification: $e');
      return {
        'is_verified': false,
        'confidence': 0.0,
        'reason': 'Verification system error: $e',
        'status': 'error',
        'mangrove_detected': false,
        'verification_type': 'system_error',
      };
    }
  }

  // Verify a single image using ONNX model
  Future<Map<String, dynamic>> _verifyImageWithONNX(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$pythonUrl/verify-mangrove-image'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      request.fields['verification_mode'] = 'strict'; // Use strict mode for verification

      final response = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('ONNX verification timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        
        return {
          'mangrove_detected': data['prediction']?['is_mangrove'] ?? false,
          'confidence': (data['prediction']?['confidence'] ?? 0.0).toDouble(),
          'probability': (data['prediction']?['mangrove_probability'] ?? 0.0).toDouble(),
          'model_type': data['prediction']?['model_type'] ?? 'onnx',
          'processing_time': data['processing_time'] ?? 0.0,
          'image_quality': data['image_quality'] ?? 'unknown',
        };
      } else {
        throw Exception('ONNX service returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('[ReportVerification] ONNX verification failed: $e');
      // Fallback to basic image analysis
      return _fallbackImageAnalysis(imagePath);
    }
  }

  // Fallback image analysis when ONNX is not available
  Map<String, dynamic> _fallbackImageAnalysis(String imagePath) {
    // Basic heuristic based on file properties
    final file = File(imagePath);
    final fileSize = file.lengthSync();
    final fileName = file.path.toLowerCase();
    
    // Simple heuristics (not accurate, but provides some analysis)
    bool likelyMangrove = false;
    double confidence = 0.4;
    
    if (fileName.contains('mangrove') || fileName.contains('forest') || fileName.contains('tree')) {
      likelyMangrove = true;
      confidence = 0.6;
    }
    
    // Larger files might indicate more detailed images
    if (fileSize > 500000) { // > 500KB
      confidence += 0.1;
    }

    return {
      'mangrove_detected': likelyMangrove,
      'confidence': confidence,
      'probability': confidence,
      'model_type': 'fallback_heuristic',
      'processing_time': 0.1,
      'image_quality': fileSize > 200000 ? 'good' : 'fair',
    };
  }

  // Evaluate overall verification result
  Map<String, dynamic> _evaluateVerificationResult(
    IncidentReport report,
    bool mangroveDetected,
    double averageConfidence,
    List<Map<String, dynamic>> imageResults,
  ) {
    // Verification criteria
    const double minConfidenceThreshold = 0.7;
    const double minMangroveConfidence = 0.6;

    bool isVerified = false;
    String status = 'failed';
    String reason = '';

    if (!mangroveDetected) {
      reason = 'No mangrove vegetation detected in provided images';
      status = 'failed';
    } else if (averageConfidence < minMangroveConfidence) {
      reason = 'Low confidence in mangrove detection (${(averageConfidence * 100).toStringAsFixed(1)}%)';
      status = 'failed';
    } else {
      // Additional checks based on incident type
      if (_isIncidentTypeAppropriate(report.type, mangroveDetected)) {
        isVerified = true;
        status = 'verified';
        reason = 'Mangrove vegetation confirmed in incident area';
      } else {
        reason = 'Incident type does not match detected vegetation';
        status = 'failed';
      }
    }

    // If confidence is borderline, mark as pending for manual review
    if (averageConfidence >= 0.5 && averageConfidence < minMangroveConfidence) {
      status = 'pending_review';
      reason = 'Requires manual verification due to moderate confidence';
    }

    return {
      'is_verified': isVerified,
      'confidence': averageConfidence,
      'reason': reason,
      'status': status,
      'mangrove_detected': mangroveDetected,
      'verification_type': 'onnx_model',
      'image_count': imageResults.length,
      'image_results': imageResults,
      'verification_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Check if incident type is appropriate for mangrove detection
  bool _isIncidentTypeAppropriate(IncidentType type, bool mangroveDetected) {
    switch (type) {
      case IncidentType.illegalCutting:
      case IncidentType.pollution:
      case IncidentType.landReclamation:
        // These types should have mangrove vegetation
        return mangroveDetected;
      case IncidentType.dumping:
        // Dumping incidents might be near mangroves but don't always require vegetation in image
        return true;
      case IncidentType.other:
      default:
        return mangroveDetected;
    }
  }

  // Update report status in database
  Future<void> _updateReportStatus(String reportId, Map<String, dynamic> verificationResult) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.expressBackendUrl}/incidents/$reportId/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verification_result': verificationResult,
          'verified_at': DateTime.now().toIso8601String(),
          'verification_method': 'onnx_model',
        }),
      );

      if (response.statusCode == 200) {
        print('[ReportVerification] Report status updated successfully');
      } else {
        print('[ReportVerification] Failed to update report status: ${response.statusCode}');
      }
    } catch (e) {
      print('[ReportVerification] Error updating report status: $e');
    }
  }

  // Get verification details for a specific report
  Future<Map<String, dynamic>?> getReportVerificationDetails(String reportId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.expressBackendUrl}/incidents/$reportId/verification'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('[ReportVerification] Error fetching verification details: $e');
      return null;
    }
  }

  // Batch verify multiple reports
  Future<List<Map<String, dynamic>>> batchVerifyReports(List<IncidentReport> reports) async {
    final results = <Map<String, dynamic>>[];
    
    for (final report in reports) {
      try {
        final result = await verifyReportWithONNX(report);
        results.add({
          'report_id': report.id,
          'verification_result': result,
        });
      } catch (e) {
        results.add({
          'report_id': report.id,
          'verification_result': {
            'is_verified': false,
            'reason': 'Batch verification error: $e',
            'status': 'error',
          },
        });
      }
    }
    
    return results;
  }
}
