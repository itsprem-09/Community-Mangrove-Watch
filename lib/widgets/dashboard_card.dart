import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(
                  icon,
                  size: 24.w,
                  color: AppTheme.primaryGreen,
                ),
                if (trend != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: (trendUp ?? true) 
                          ? AppTheme.successGreen.withOpacity(0.1)
                          : AppTheme.warningRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (trendUp ?? true) ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12.w,
                          color: (trendUp ?? true) 
                              ? AppTheme.successGreen
                              : AppTheme.warningRed,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          trend!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: (trendUp ?? true) 
                                ? AppTheme.successGreen
                                : AppTheme.warningRed,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
