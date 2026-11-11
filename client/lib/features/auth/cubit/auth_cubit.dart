import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yakkity/core/network/api_error.dart';
import 'package:yakkity/core/network/session_events.dart';
import 'package:yakkity/features/auth/data/auth_repository.dart';
import 'package:yakkity/features/auth/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo, SessionEvents session) : super(const AuthState()) {
    // Если interceptor поймал 401, нас выкидывает на экран входа
    _sub = session.onExpired.listen((_) => _onSessionExpired());
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _sub;

  /// Вызывается при старте приложения
  Future<void> start() async {
    try {
      final user = await _repo.restoreSession();
      if (state.status != AuthStatus.checking) return; // уже решили иначе
      emit(
        user == null ? state.copyWith(status: AuthStatus.unauthenticated) : state.copyWith(status: AuthStatus.authenticated, user: user),
      );
    } catch (e) {
      if (state.status != AuthStatus.checking) return;
      emit(state.copyWith(status: AuthStatus.unauthenticated, error: apiErrorMessage(e)));
    }
  }

  Future<void> requestCode(String phone) async {
    emit(state.copyWith(loading: true, phone: phone));
    try {
      final devCode = await _repo.sendCode(phone);
      emit(state.copyWith(step: AuthStep.code, phone: phone, devCode: devCode));
    } catch (e) {
      emit(state.copyWith(error: apiErrorMessage(e)));
    }
  }

  Future<void> verifyCode(String code) async {
    emit(state.copyWith(loading: true));
    try {
      final user = await _repo.verify(state.phone!, code);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(error: apiErrorMessage(e)));
    }
  }

  void backToPhone() => emit(state.copyWith(step: AuthStep.phone));

  Future<void> saveName(String name) async {
    emit(state.copyWith(loading: true));
    try {
      final user = await _repo.updateName(name);
      emit(state.copyWith(user: user));
    } catch (e) {
      emit(state.copyWith(error: apiErrorMessage(e)));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onSessionExpired() => emit(const AuthState(status: AuthStatus.unauthenticated, error: 'Сессия истекла, войди снова'));

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
