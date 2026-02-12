import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'session_token';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  final FlutterSecureStorage _secureStorage;

  static String? _memoryToken;
  static final Map<String, Object> _memoryPrefs = <String, Object>{};

  Future<String?> readToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } on MissingPluginException {
      return _memoryToken;
    }
  }

  Future<void> writeToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } on MissingPluginException {
      _memoryToken = token;
    }
  }

  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } on MissingPluginException {
      _memoryToken = null;
    }
  }

  Future<bool> readHasSeenOnboarding() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenOnboardingKey) ?? false;
    } on MissingPluginException {
      return (_memoryPrefs[_hasSeenOnboardingKey] as bool?) ?? false;
    }
  }

  Future<void> writeHasSeenOnboarding(bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenOnboardingKey, value);
    } on MissingPluginException {
      _memoryPrefs[_hasSeenOnboardingKey] = value;
    }
  }
}
