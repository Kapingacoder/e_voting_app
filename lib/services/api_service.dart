import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Badilisha IP hii na IP ya kompyuta yako
  static const String baseUrl = 'http://192.168.0.182:8080/api';
  static const _storage = FlutterSecureStorage();

  // ═══════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  static Future<void> saveUserInfo(String fullName, String role) async {
    await _storage.write(key: 'full_name', value: fullName);
    await _storage.write(key: 'role', value: role);
  }

  static Future<String?> getFullName() async {
    return await _storage.read(key: 'full_name');
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════
  // AUTH
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════
  // VOTER
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/voter/dashboard'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/voter/profile'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getResults() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/voter/results'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> castVote(int ticketId) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/voter/vote/ticket'),
      headers: headers,
      body: jsonEncode({'ticketId': ticketId}),
    );
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════
  // ADMIN
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getAdminVoters() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/voters'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addVoter(
      Map<String, dynamic> voterData) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/voters/add'),
      headers: headers,
      body: jsonEncode(voterData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteVoter(int id) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/voters/delete/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> bulkImportVoters(
      List<Map<String, String>> voters) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/voters/bulk-import'),
      headers: headers,
      body: jsonEncode(voters),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getAdminCandidates() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/candidates'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminElection() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/election'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> startElection() async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/election/start'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> stopElection() async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/election/stop'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminResults() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/results'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateElection(
      Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/election/update'),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════
  // TICKETS
  // ═══════════════════════════════

  static Future<List<dynamic>> getAdminTickets() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/tickets'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addTicket(
      Map<String, dynamic> ticketData) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/tickets/add'),
      headers: headers,
      body: jsonEncode(ticketData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateTicket(
      int id, Map<String, dynamic> ticketData) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/tickets/$id'),
      headers: headers,
      body: jsonEncode(ticketData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteTicket(int id) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/tickets/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════
  // CHANGE PASSWORD & PROFILE
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> voterChangePassword(
      String currentPassword, String newPassword) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/voter/change-password'),
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/profile'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adminChangePassword(
      String currentPassword, String newPassword) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/change-password'),
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adminChangeUsername(
      String newUsername) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/change-username'),
      headers: headers,
      body: jsonEncode({'newUsername': newUsername}),
    );
    return jsonDecode(response.body);
  }

  // ═══════════════════════════════
  // SUPPORT MESSAGES
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> sendSupportMessage(
      String admissionNumber, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/support-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'admissionNumber': admissionNumber,
        'message': message,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getSupportMessages() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/support-messages'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markMessageRead(int id) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/support-messages/$id/read'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<int> getUnreadCount() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/support-messages/unread-count'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    return (data['count'] ?? 0) as int;
  }

  // ═══════════════════════════════
  // FORGOT PASSWORD
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> forgotPassword(
      String admissionNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admissionNumber': admissionNumber}),
    );
    return jsonDecode(response.body);
  }
}