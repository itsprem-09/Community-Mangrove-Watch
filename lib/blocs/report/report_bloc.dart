import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/incident_report.dart';
import '../../services/api_service.dart';

// Events
abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {}

class ReportSubmitted extends ReportEvent {
  final IncidentReport report;

  const ReportSubmitted({required this.report});

  @override
  List<Object> get props => [report];
}

class ReportRefreshRequested extends ReportEvent {}

class ReportFilterChanged extends ReportEvent {
  final String? statusFilter;

  const ReportFilterChanged({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
}

// States
abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportSubmitting extends ReportState {}

class ReportLoaded extends ReportState {
  final List<IncidentReport> reports;
  final String? currentFilter;

  const ReportLoaded({required this.reports, this.currentFilter});

  @override
  List<Object?> get props => [reports, currentFilter];
}

class ReportSubmitSuccess extends ReportState {
  final IncidentReport report;

  const ReportSubmitSuccess({required this.report});

  @override
  List<Object> get props => [report];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ApiService _apiService;

  ReportBloc(this._apiService) : super(ReportInitial()) {
    on<ReportLoadRequested>(_onReportLoadRequested);
    on<ReportSubmitted>(_onReportSubmitted);
    on<ReportRefreshRequested>(_onReportRefreshRequested);
    on<ReportFilterChanged>(_onReportFilterChanged);
  }

  Future<void> _onReportLoadRequested(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    
    try {
      final reports = await _apiService.getReports();
      emit(ReportLoaded(reports: reports));
    } catch (e) {
      emit(ReportError(message: e.toString()));
    }
  }

  Future<void> _onReportSubmitted(
    ReportSubmitted event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportSubmitting());
    
    try {
      await _apiService.submitReport(event.report);
      emit(ReportSubmitSuccess(report: event.report));
      
      // Refresh the reports list
      add(ReportLoadRequested());
    } catch (e) {
      emit(ReportError(message: 'Failed to submit report: ${e.toString()}'));
    }
  }

  Future<void> _onReportRefreshRequested(
    ReportRefreshRequested event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final reports = await _apiService.getReports();
      if (state is ReportLoaded) {
        final currentState = state as ReportLoaded;
        emit(ReportLoaded(reports: reports, currentFilter: currentState.currentFilter));
      } else {
        emit(ReportLoaded(reports: reports));
      }
    } catch (e) {
      emit(ReportError(message: e.toString()));
    }
  }

  Future<void> _onReportFilterChanged(
    ReportFilterChanged event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final reports = await _apiService.getReports();
      
      List<IncidentReport> filteredReports = reports;
      if (event.statusFilter != null) {
        filteredReports = reports.where((report) => 
          report.status.name == event.statusFilter).toList();
      }
      
      emit(ReportLoaded(reports: filteredReports, currentFilter: event.statusFilter));
    } catch (e) {
      emit(ReportError(message: e.toString()));
    }
  }
}
