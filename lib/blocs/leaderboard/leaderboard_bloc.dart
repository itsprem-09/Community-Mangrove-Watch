import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';

// Events
abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LeaderboardLoadRequested extends LeaderboardEvent {}

class LeaderboardRefreshRequested extends LeaderboardEvent {}

// States
abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<Map<String, dynamic>> leaderboard;
  final Map<String, dynamic>? userStats;

  const LeaderboardLoaded({
    required this.leaderboard,
    this.userStats,
  });

  @override
  List<Object?> get props => [leaderboard, userStats];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final ApiService _apiService;

  LeaderboardBloc(this._apiService) : super(LeaderboardInitial()) {
    on<LeaderboardLoadRequested>(_onLeaderboardLoadRequested);
    on<LeaderboardRefreshRequested>(_onLeaderboardRefreshRequested);
  }

  Future<void> _onLeaderboardLoadRequested(
    LeaderboardLoadRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoading());
    
    try {
      final leaderboard = await _apiService.getLeaderboard();
      final userStats = await _apiService.getUserStats();
      
      emit(LeaderboardLoaded(
        leaderboard: leaderboard,
        userStats: userStats,
      ));
    } catch (e) {
      emit(LeaderboardError(message: e.toString()));
    }
  }

  Future<void> _onLeaderboardRefreshRequested(
    LeaderboardRefreshRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    try {
      final leaderboard = await _apiService.getLeaderboard();
      final userStats = await _apiService.getUserStats();
      
      emit(LeaderboardLoaded(
        leaderboard: leaderboard,
        userStats: userStats,
      ));
    } catch (e) {
      emit(LeaderboardError(message: e.toString()));
    }
  }
}
