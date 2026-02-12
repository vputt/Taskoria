import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:productivity_city/shared/providers/repositories.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required AuthRepository authRepository,
    required SessionStorage storage,
    required VoidCallback invalidateAppData,
  }) : _authRepository = authRepository,
       _storage = storage,
       _invalidateAppData = invalidateAppData;

  final AuthRepository _authRepository;
  final SessionStorage _storage;
  final VoidCallback _invalidateAppData;

  SessionState _state = const SessionState.unknown();
  bool _restored = false;
  Future<void>? _restoreFuture;

  SessionState get state => _state;

  Future<void> restoreSession() {
    if (_restoreFuture != null) {
      return _restoreFuture!;
    }
    _restoreFuture = _restoreSession();
    return _restoreFuture!;
  }

  Future<void> _restoreSession() async {
    if (_restored) {
      return;
    }
    final bool hasSeenOnboarding = await _storage.readHasSeenOnboarding();
    try {
      final AuthSession? session = await _authRepository.restoreSession();
      _state = session == null
          ? SessionState.unauthenticated(hasSeenOnboarding: hasSeenOnboarding)
          : SessionState.authenticated(
              hasSeenOnboarding: hasSeenOnboarding,
              session: session,
            );
    } catch (_) {
      _state = SessionState.unauthenticated(
        hasSeenOnboarding: hasSeenOnboarding,
      );
    }
    _restored = true;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    await _storage.writeHasSeenOnboarding(true);
    if (_state.hasSeenOnboarding) {
      return;
    }
    _state = _state.copyWith(hasSeenOnboarding: true);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final AuthSession session = await _authRepository.login(
      email: email,
      password: password,
    );
    await _storage.writeHasSeenOnboarding(true);
    _state = SessionState.authenticated(
      hasSeenOnboarding: true,
      session: session,
    );
    _invalidateAppData();
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    await _authRepository.register(
      email: email,
      username: username,
      password: password,
    );
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _storage.writeHasSeenOnboarding(true);
    _state = const SessionState.unauthenticated(hasSeenOnboarding: true);
    notifyListeners();
    _invalidateAppData();
  }

  Future<void> handleUnauthorized() async {
    if (_state.status == SessionStatus.unauthenticated) {
      await _storage.clearToken();
      return;
    }
    await logout();
  }
}
