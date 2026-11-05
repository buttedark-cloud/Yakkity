import 'package:equatable/equatable.dart';

import '../data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

enum AuthStep { phone, code }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.checking,
    this.step = AuthStep.phone,
    this.loading = false,
    this.phone,
    this.user,
    this.error,
    this.devCode,
  });

  final AuthStatus status;
  final AuthStep step;
  final bool loading;
  final String? phone;
  final AuthUser? user;
  final String? error;
  final String? devCode;

  /// status, step, phone и user сохраняются при копировании.
  /// loading, error и devCode сбрасываются, если их не передали заново:
  /// ошибка и «крутилка» живут только одно состояние.
  AuthState copyWith({AuthStatus? status, AuthStep? step, bool? loading, String? phone, AuthUser? user, String? error, String? devCode}) =>
      AuthState(
        status: status ?? this.status,
        step: step ?? this.step,
        loading: loading ?? false,
        phone: phone ?? this.phone,
        user: user ?? this.user,
        error: error,
        devCode: devCode ?? this.devCode,
      );

  @override
  List<Object?> get props => [status, step, loading, phone, user, error, devCode];
}
