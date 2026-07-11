import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bits of session state that should survive a page reload.
/// Plain SharedPreferences (not flutter_secure_storage) since on web there's
/// no OS keychain to back secure storage anyway - it degrades to the same
/// localStorage-backed mechanism. Swap for secure storage on the mobile build.
///
/// The user object is cached here so the app has something to show
/// immediately on cold start, before `/users/me` responds.
class SessionStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _societyIdKey = 'current_society_id';

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> writeToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, dynamic>?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeUser(Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_userKey);
    } else {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  Future<String?> readSocietyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_societyIdKey);
  }

  Future<void> writeSocietyId(String? societyId) async {
    final prefs = await SharedPreferences.getInstance();
    if (societyId == null) {
      await prefs.remove(_societyIdKey);
    } else {
      await prefs.setString(_societyIdKey, societyId);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_societyIdKey);
  }
}
