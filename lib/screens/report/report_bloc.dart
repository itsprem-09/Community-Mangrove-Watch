import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/incident_report.dart';
import '../../services/api_service.dart';

// Events
abstract class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitReport extends ReportEvent {
  final IncidentReport report;
  SubmitReport(this.report);

  @override
  List<Object?> get props => [report];
}

class LoadReports extends ReportEvent {}

// States
abstract class ReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportSubmitted extends ReportState {}

class ReportsLoaded extends ReportState {
  final List<IncidentReport> reports;
  ReportsLoaded(this.reports);

  @override
  List<Object?> get props => [reports];
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ApiService _apiService;

  ReportBloc(this._apiService) : super(ReportInitial()) {
    on<SubmitReport>(_onSubmitReport);
    on<LoadReports>(_onLoadReports);
  }

  Future<void> _onSubmitReport(SubmitReport event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      await _apiService.submitReport(event.report);
      emit(ReportSubmitted());
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadReports(LoadReports event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final reports = await _apiService.getReports();
      emit(ReportsLoaded(reports));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<String> analyzeImageWithGemini(String imagePath) async {
    return await _apiService.analyzeImageWithGemini(imagePath);
  }
}
