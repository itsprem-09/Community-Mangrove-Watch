import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme.dart';
import '../services/api_service.dart';

class MangroveHealthWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MangroveHealthWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MangroveHealthWidget> createState() => _MangroveHealthWidgetState();
}

class _MangroveHealthWidgetState extends State<MangroveHealthWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _healthData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMangroveHealth();
  }

  Future<void> _loadMangroveHealth() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final prediction = await apiService.getPredictionFromGEE(
        widget.latitude,
        widget.longitude,
      );

      setState(() {
        _healthData = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Mangrove Health',
                style: AppTheme.titleLarge.copyWith(fontSize: 16.sp),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMangroveHealth,
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48.w,
                  color: AppTheme.warningRed,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Failed to load health data',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.warningRed,
                  ),
                ),
              ],
            )
          else if (_healthData != null)
            Column(
              children: [
                // Health Score Circle
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 120.w,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40.w,
                            sections: [
                              PieChartSectionData(
                                value: (_healthData!['predicted_coverage'] ?? 0.0) * 100,
                                color: AppTheme.primaryGreen,
                                title: '',
                                radius: 20.w,
                              ),
                              PieChartSectionData(
                                value: (100 - ((_healthData!['predicted_coverage'] ?? 0.0) * 100)).toDouble(),
                                color: AppTheme.textSecondary.withOpacity(0.2),
                                title: '',
                                radius: 20.w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HealthMetric(
                            label: 'Coverage',
                            value: '${((_healthData!['predicted_coverage'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                            icon: Icons.forest,
                          ),
                          SizedBox(height: 8.h),
                          _HealthMetric(
                            label: 'NDVI',
                            value: (_healthData!['ndvi_value'] ?? 0.0).toStringAsFixed(2),
                            icon: Icons.eco,
                          ),
                          SizedBox(height: 8.h),
                          _HealthMetric(
                            label: 'Confidence',
                            value: '${((_healthData!['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                            icon: Icons.verified,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Health Status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _getHealthColor(_healthData!['predicted_coverage'] ?? 0.0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getHealthIcon(_healthData!['predicted_coverage'] ?? 0.0),
                        color: _getHealthColor(_healthData!['predicted_coverage'] ?? 0.0),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _getHealthStatus(_healthData!['predicted_coverage'] ?? 0.0),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _getHealthColor(_healthData!['predicted_coverage'] ?? 0.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getHealthColor(double coverage) {
    if (coverage >= 0.7) return AppTheme.successGreen;
    if (coverage >= 0.4) return Colors.orange;
    return AppTheme.warningRed;
  }

  IconData _getHealthIcon(double coverage) {
    if (coverage >= 0.7) return Icons.eco;
    if (coverage >= 0.4) return Icons.warning;
    return Icons.dangerous;
  }

  String _getHealthStatus(double coverage) {
    if (coverage >= 0.7) return 'Healthy Mangroves';
    if (coverage >= 0.4) return 'Moderate Coverage';
    return 'Low Coverage - Action Needed';
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.w,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(fontSize: 10.sp),
            ),
            Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
