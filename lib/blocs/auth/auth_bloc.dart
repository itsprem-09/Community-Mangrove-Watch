import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final Map<String, dynamic> userData;

  const AuthRegisterRequested({required this.userData});

  @override
  List<Object> get props => [userData];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final User user;

  const AuthUserUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final isValid = await _authService.validateToken();
        if (isValid) {
          final userData = await _authService.getUser();
          final token = await _authService.getToken();
          
          if (userData != null && token != null) {
            final user = User.fromJson(userData);
            emit(AuthAuthenticated(user: user, token: token));
            return;
          }
        }
      }
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await _authService.login(event.email, event.password);
      
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        emit(AuthAuthenticated(user: user, token: result['token']));
      } else {
        emit(AuthError(message: result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Network error: ${e.toString()}'));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await _authService.register(event.userData);
      
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        emit(AuthAuthenticated(user: user, token: result['token']));
      } else {
        emit(AuthError(message: result['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Network error: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(AuthAuthenticated(user: event.user, token: currentState.token));
    }
  }
}
