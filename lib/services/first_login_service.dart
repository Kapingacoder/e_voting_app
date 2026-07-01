import 'package:shared_preferences/shared_preferences.dart';

class FirstLoginService {
  static const _kIsFirstLogin = 'is_first_login';
  static const _kSecurityQuestion = 'security_question';
  static const _kSecurityAnswerHash = 'security_answer_hash';

  static Future<bool> get isFirstLogin async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsFirstLogin) ?? false;
  }

  static Future<void> setIsFirstLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsFirstLogin, value);
  }

  static Future<void> saveSecurityData({
    required String securityQuestion,
    required String securityAnswerHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSecurityQuestion, securityQuestion);
    await prefs.setString(_kSecurityAnswerHash, securityAnswerHash);
  }

  static Future<Map<String, String?>> getSecurityData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'securityQuestion': prefs.getString(_kSecurityQuestion),
      'securityAnswerHash': prefs.getString(_kSecurityAnswerHash),
    };
  }

  static Future<void> clearSecurityData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSecurityQuestion);
    await prefs.remove(_kSecurityAnswerHash);
  }
}

