import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../models/incident_report.dart';
import '../../services/report_verification_service.dart';
import '../../core/theme.dart';
import '../../widgets/responsive_text.dart';

class ReportDetailsScreen extends StatefulWidget {
  final IncidentReport report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final ReportVerificationService _verificationService = ReportVerificationService();
  Map<String, dynamic>? _verificationResult;
  bool _isVerifying = false;
  bool _hasAttemptedVerification = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationDetails();
  }

  Future<void> _loadVerificationDetails() async {
    try {
      final details = await _verificationService.getReportVerificationDetails(widget.report.id);
      if (details != null) {
        setState(() {
          _verificationResult = details;
          _hasAttemptedVerification = true;
        });
      }
    } catch (e) {
      print('Error loading verification details: $e');
    }
  }

  Future<void> _verifyReport() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await _verificationService.verifyReportWithONNX(widget.report);
      setState(() {
        _verificationResult = result;
        _hasAttemptedVerification = true;
        _isVerifying = false;
      });

      // Show result snackbar
      if (mounted) {
        final isVerified = result['is_verified'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified 
                  ? '✅ Report verified successfully!' 
                  : '❌ Verification failed: ${result['reason']}',
            ),
            backgroundColor: isVerified ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: _getStatusColor(widget.report.status),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            SizedBox(height: 16.h),
            
            // Images Section
            if (widget.report.images.isNotEmpty) ...[
              _buildImagesSection(),
              SizedBox(height: 16.h),
            ],
            
            // Details Section
            _buildDetailsSection(),
            SizedBox(height: 16.h),
            
            // Location Section
            _buildLocationSection(),
            SizedBox(height: 16.h),
            
            // Verification Section
            _buildVerificationSection(),
            SizedBox(height: 24.h),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(widget.report.status),
            _getStatusColor(widget.report.status).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(widget.report.status).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(widget.report.type),
                color: Colors.white,
                size: 28.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ResponsiveText(
                  widget.report.title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          Row(
            children: [
              _buildStatusChip(),
              SizedBox(width: 12.w),
              _buildSeverityChip(),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          ResponsiveText(
            DateFormat('MMM dd, yyyy • HH:mm').format(widget.report.timestamp),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: AppTheme.primaryGreen),
              SizedBox(width: 8.w),
              Text(
                'Evidence Photos (${widget.report.images.length})',
                style: AppTheme.titleMedium.copyWith(fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.report.images.length == 1 ? 1 : 2,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 1.2,
            ),
            itemCount: widget.report.images.length,
            itemBuilder: (context, index) {
              final imagePath = widget.report.images[index];
              return GestureDetector(
                onTap: () {
                  _showImageDialog(imagePath);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: File(imagePath).existsSync()
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryGreen),
              SizedBox(width: 8.w),
              Text(
                'Incident Details',
                style: AppTheme.titleMedium.copyWith(fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          _buildDetailRow('Type', widget.report.type.name.toUpperCase()),
          _buildDetailRow('Severity', widget.report.severity.name.toUpperCase()),
          _buildDetailRow('Reporter', 'Anonymous User'), // TODO: Get real reporter name
          _buildDetailRow('Report ID', widget.report.id),
          
          SizedBox(height: 12.h),
          
          Text(
            'Description:',
            style: AppTheme.labelLarge.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          ResponsiveText(
            widget.report.description,
            style: AppTheme.bodyMedium.copyWith(fontSize: 14.sp),
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryGreen),
              SizedBox(width: 8.w),
              Text(
                'Location Information',
                style: AppTheme.titleMedium.copyWith(fontSize: 16.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          _buildDetailRow('Latitude', widget.report.latitude.toStringAsFixed(6)),
          _buildDetailRow('Longitude', widget.report.longitude.toStringAsFixed(6)),
          
          SizedBox(height: 12.h),
          
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open in maps app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Map integration coming soon')),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('View on Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryGreen),
              SizedBox(width: 8.w),
              Text(
                'AI Verification',
                style: AppTheme.titleMedium.copyWith(fontSize: 16.sp),
              ),
              const Spacer(),
              if (!_hasAttemptedVerification && !_isVerifying && widget.report.images.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _verifyReport,
                  icon: const Icon(Icons.smart_toy, size: 16),
                  label: const Text('Verify with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          
          if (_isVerifying)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    '🤖 AI is analyzing report images...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Using best.onnx model for verification',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (_verificationResult != null)
            _buildVerificationResult()
          else if (widget.report.images.isEmpty)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'No images provided - Manual verification required',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending, color: Colors.blue[700]),
                  SizedBox(width: 8.w),
                  const Expanded(
                    child: Text(
                      'Tap "Verify with AI" to check if images contain mangrove vegetation',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    final confidence = (_verificationResult!['confidence'] ?? 0.0) * 100;
    final mangroveDetected = _verificationResult!['mangrove_detected'] ?? false;
    final reason = _verificationResult!['reason'] ?? 'No reason provided';
    final status = _verificationResult!['status'] ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main result
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _getVerificationResultColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getVerificationResultColor(status).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                _getVerificationResultIcon(status),
                size: 48.w,
                color: _getVerificationResultColor(status),
              ),
              SizedBox(height: 8.h),
              Text(
                _getVerificationResultTitle(status),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: _getVerificationResultColor(status),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ResponsiveText(
                reason,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _getVerificationResultColor(status),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Detailed metrics
        _buildDetailRow('Mangrove Detected', mangroveDetected ? 'YES' : 'NO'),
        _buildDetailRow('AI Confidence', '${confidence.toStringAsFixed(1)}%'),
        _buildDetailRow('Model Type', _verificationResult!['model_type'] ?? 'Unknown'),
        _buildDetailRow('Verification Time', 
          _verificationResult!['verification_timestamp'] != null 
            ? DateFormat('MMM dd, HH:mm').format(DateTime.parse(_verificationResult!['verification_timestamp']))
            : 'Unknown'),
        
        if (_verificationResult!['image_results'] != null)
          ..._buildImageVerificationResults(),
      ],
    );
  }

  List<Widget> _buildImageVerificationResults() {
    final imageResults = _verificationResult!['image_results'] as List<dynamic>;
    
    return [
      SizedBox(height: 12.h),
      Text(
        'Individual Image Analysis:',
        style: AppTheme.labelLarge.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 8.h),
      
      ...imageResults.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value as Map<String, dynamic>;
        final detected = result['mangrove_detected'] ?? false;
        final confidence = (result['confidence'] ?? 0.0) * 100;
        
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: detected ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: detected ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                detected ? Icons.check_circle : Icons.cancel,
                color: detected ? Colors.green : Colors.red,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Image ${index + 1}: ${detected ? "Mangrove detected" : "No mangrove"} (${confidence.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: detected ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ];
  }


  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.report.images.isNotEmpty && !_hasAttemptedVerification && !_isVerifying)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _verifyReport,
              icon: const Icon(Icons.smart_toy),
              label: const Text('Verify with ONNX Model'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ),
        
        SizedBox(height: 12.h),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add to favorites or follow report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Follow feature coming soon')),
                  );
                },
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Follow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.report.status.name.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSeverityChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8.w,
            color: _getSeverityColor(widget.report.severity),
          ),
          SizedBox(width: 4.w),
          Text(
            widget.report.severity.name.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Evidence Photo'),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: File(imagePath).existsSync()
                    ? Image.file(File(imagePath), fit: BoxFit.contain)
                    : const Center(child: Text('Image not found')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.verified:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.resolved:
        return AppTheme.accentBlue;
    }
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return Colors.yellow;
      case SeverityLevel.medium:
        return Colors.orange;
      case SeverityLevel.high:
        return Colors.red;
      case SeverityLevel.critical:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(IncidentType type) {
    switch (type) {
      case IncidentType.pollution:
        return Icons.water_drop;
      case IncidentType.illegalCutting:
        return Icons.content_cut;
      case IncidentType.landReclamation:
        return Icons.landscape;
      case IncidentType.dumping:
        return Icons.delete_forever;
      case IncidentType.other:
        return Icons.report_problem;
    }
  }

  Color _getVerificationResultColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending_review':
        return Colors.orange;
      case 'error':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getVerificationResultIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'pending_review':
        return Icons.schedule;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getVerificationResultTitle(String status) {
    switch (status) {
      case 'verified':
        return 'Report Verified ✅';
      case 'failed':
        return 'Verification Failed ❌';
      case 'pending_review':
        return 'Pending Manual Review ⏳';
      case 'error':
        return 'Verification Error ⚠️';
      default:
        return 'Unknown Status';
    }
  }
}
