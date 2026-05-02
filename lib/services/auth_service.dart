import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/faculty.dart';

/// Manages authentication state using JWT tokens.
/// Token is stored securely and sent as Authorization: Bearer <token> header.
class AuthService extends ChangeNotifier {
  static const _storage  = FlutterSecureStorage();
  static const _keyToken   = 'jwt_token';
  static const _keyFaculty = 'faculty_json';

  Faculty? _faculty;
  String?  _token;

  Faculty? get faculty    => _faculty;
  String?  get token      => _token;
  bool     get isLoggedIn => _faculty != null && _token != null;
  bool     get isAdmin    => _faculty?.isAdmin ?? false;

  // Keep sessionCookie as alias so ApiService doesn't need changes
  String?  get sessionCookie => _token;

  /// Called on app start — restores session from secure storage.
  Future<void> loadFromStorage() async {
    try {
      final token   = await _storage.read(key: _keyToken);
      final facJson = await _storage.read(key: _keyFaculty);
      if (token != null && facJson != null) {
        _token   = token;
        _faculty = Faculty.fromJson(jsonDecode(facJson) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {
      await clearSession();
    }
  }

  /// Persists session after successful login.
  Future<void> saveSession(Faculty faculty, String token) async {
    _faculty = faculty;
    _token   = token;
    await _storage.write(key: _keyToken,   value: token);
    await _storage.write(key: _keyFaculty, value: jsonEncode(faculty.toJson()));
    notifyListeners();
  }

  /// Updates the in-memory faculty profile.
  Future<void> updateFaculty(Faculty faculty) async {
    _faculty = faculty;
    await _storage.write(key: _keyFaculty, value: jsonEncode(faculty.toJson()));
    notifyListeners();
  }

  /// Clears all stored credentials.
  Future<void> clearSession() async {
    _faculty = null;
    _token   = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
