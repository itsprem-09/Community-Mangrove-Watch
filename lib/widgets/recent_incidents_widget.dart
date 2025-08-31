import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../blocs/report/report_bloc.dart';
import '../core/theme.dart';
import '../models/incident_report.dart';

class RecentIncidentsWidget extends StatefulWidget {
  const RecentIncidentsWidget({super.key});

  @override
  State<RecentIncidentsWidget> createState() => _RecentIncidentsWidgetState();
}

class _RecentIncidentsWidgetState extends State<RecentIncidentsWidget> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(ReportLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is ReportLoaded) {
          final recentReports = state.reports.take(5).toList();
          
          if (recentReports.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24.w),
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
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 48.w,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No incidents reported yet',
                    style: AppTheme.titleLarge.copyWith(
                      fontSize: 16.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Be the first to report a mangrove incident',
                    style: AppTheme.bodyMedium.copyWith(fontSize: 12.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return Container(
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
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Reports',
                        style: AppTheme.titleLarge.copyWith(fontSize: 16.sp),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all reports
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('View all reports coming soon')),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReports.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1.h,
                    color: AppTheme.textSecondary.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    final report = recentReports[index];
                    return _IncidentListTile(report: report);
                  },
                ),
              ],
            ),
          );
        } else if (state is ReportError) {
          return Container(
            padding: EdgeInsets.all(24.w),
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
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48.w,
                  color: AppTheme.warningRed,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Error loading incidents',
                  style: AppTheme.titleLarge.copyWith(
                    fontSize: 16.sp,
                    color: AppTheme.warningRed,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: AppTheme.bodyMedium.copyWith(fontSize: 12.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return const SizedBox();
      },
    );
  }
}

class _IncidentListTile extends StatelessWidget {
  final IncidentReport report;

  const _IncidentListTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(report.status).withOpacity(0.1),
        child: Icon(
          _getIncidentIcon(report.type),
          color: _getStatusColor(report.status),
          size: 20.w,
        ),
      ),
      title: Text(
        report.type.displayName,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.description.length > 50
                ? '${report.description.substring(0, 50)}...'
                : report.description,
            style: AppTheme.bodyMedium.copyWith(fontSize: 12.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            DateFormat('MMM dd, yyyy').format(report.timestamp),
            style: AppTheme.labelMedium.copyWith(fontSize: 10.sp),
          ),
        ],
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: _getStatusColor(report.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          report.status.name.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(report.status),
          ),
        ),
      ),
      onTap: () {
        context.push('/report-details', extra: report);
      },
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.verified:
        return AppTheme.successGreen;
      case ReportStatus.rejected:
        return AppTheme.warningRed;
      case ReportStatus.resolved:
        return AppTheme.accentBlue;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.illegalCutting:
        return Icons.content_cut;
      case IncidentType.landReclamation:
        return Icons.landscape;
      case IncidentType.pollution:
        return Icons.warning;
      case IncidentType.dumping:
        return Icons.delete_forever;
      case IncidentType.other:
        return Icons.report_problem;
    }
  }
}
