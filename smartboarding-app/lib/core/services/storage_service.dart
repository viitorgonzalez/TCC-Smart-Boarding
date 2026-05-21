import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartboarding_app/features/auth/models/auth_token.dart';

class StorageService {
  static const _keyToken = 'auth_token';
  static const _keyFullName = 'auth_full_name';
  static const _keyRole = 'auth_role';
  static const _keyEmail = 'auth_email';

  Future<void> saveAuthToken(AuthToken auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, auth.token);
    await prefs.setString(_keyFullName, auth.fullName);
    await prefs.setString(_keyRole, auth.role);
    await prefs.setString(_keyEmail, auth.email);
  }

  Future<AuthToken?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return null;
    return AuthToken(
      token: token,
      fullName: prefs.getString(_keyFullName) ?? '',
      role: prefs.getString(_keyRole) ?? 'STUDENT',
      email: prefs.getString(_keyEmail) ?? '',
    );
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyEmail);
  }
}
