import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'token';
  static const _fullNameKey = 'fullName';
  static const _roleKey = 'role';
  static const _emailKey = 'email';

  // Cacheia a instância de SharedPreferences: evita reabrir o storage a cada
  // getter (o interceptor JWT chama getToken() em toda requisição HTTP).
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveAuth({
    required String token,
    required String fullName,
    required String role,
    required String email,
  }) async {
    final prefs = await _instance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_emailKey, email);
  }

  Future<String?> getToken() async => (await _instance()).getString(_tokenKey);

  Future<String?> getFullName() async =>
      (await _instance()).getString(_fullNameKey);

  Future<String?> getRole() async => (await _instance()).getString(_roleKey);

  Future<String?> getEmail() async => (await _instance()).getString(_emailKey);

  Future<void> clearAuth() async {
    final prefs = await _instance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
  }
}
