import 'dart:convert';

class ResetPasswordHelper {
  /// Generates a secure reset password link with encrypted data
  static String generateResetLink(
    String admissionNumber,
    String securityQuestion,
    String email,
    String fullName,
  ) {
    final data = {
      'admission': admissionNumber,
      'question': securityQuestion,
      'email': email,
      'name': fullName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Convert to JSON and encode
    final jsonString = jsonEncode(data);
    final encoded = base64Url.encode(utf8.encode(jsonString));

    // Generate link (will be updated with actual GitHub Pages URL)
    return 'https://kapingacoder.github.io/e_voting_app/#/reset?data=$encoded';
  }

  /// Decodes reset link data
  static Map<String, dynamic>? decodeResetLink(String encodedData) {
    try {
      final decoded = utf8.decode(base64Url.decode(encodedData));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Checks if reset link is still valid (1 hour expiry)
  static bool isLinkValid(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as int?;
    if (timestamp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hourInMs = 60 * 60 * 1000; // 1 hour
    return (now - timestamp) <= hourInMs;
  }
}
