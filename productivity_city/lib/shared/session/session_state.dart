import 'package:productivity_city/shared/models/user_profile.dart';

enum SessionStatus { unknown, unauthenticated, authenticated }

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final UserProfile user;
}

class SessionState {
  const SessionState._({
    required this.status,
    required this.hasSeenOnboarding,
    this.session,
  });

  const SessionState.unknown({this.hasSeenOnboarding = false})
    : status = SessionStatus.unknown,
      session = null;

  const SessionState.unauthenticated({required this.hasSeenOnboarding})
    : status = SessionStatus.unauthenticated,
      session = null;

  const SessionState.authenticated({
    required this.hasSeenOnboarding,
    required this.session,
  }) : status = SessionStatus.authenticated;

  final SessionStatus status;
  final bool hasSeenOnboarding;
  final AuthSession? session;

  bool get isAuthenticated => status == SessionStatus.authenticated;
  bool get isUnknown => status == SessionStatus.unknown;
  UserProfile? get user => session?.user;
  String? get token => session?.token;

  SessionState copyWith({
    SessionStatus? status,
    bool? hasSeenOnboarding,
    AuthSession? session,
    bool clearSession = false,
  }) {
    return SessionState._(
      status: status ?? this.status,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      session: clearSession ? null : (session ?? this.session),
    );
  }
}
