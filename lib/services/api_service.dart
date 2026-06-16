import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _boxName = 'app_data';
  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    if (!_db.containsKey('initialized') || _db.get('initialized') != true) {
      await _seedData();
      await _db.put('initialized', true);
    }
  }

  static Box<dynamic> get _db {
    final box = _box;
    if (box == null) {
      throw Exception('ApiService.initialize() must be called before using ApiService.');
    }
    return box;
  }

  static Future<void> _ensureInitialized() async {
    if (_box == null) {
      await initialize();
    }
  }

  static List<Map<String, dynamic>> _readList(String key) {
    final raw = _db.get(key);
    if (raw is List) {
      return raw.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  static Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    await _db.put(key, value);
  }

  static Map<String, dynamic> _readMap(String key) {
    final raw = _db.get(key);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw.cast<String, dynamic>());
    }
    return <String, dynamic>{};
  }

  static Future<void> _seedData() async {
    await _db.put('admin', {
      'id': 0,
      'username': 'admin',
      'password': 'admin123',
      'fullName': 'System Admin',
      'role': 'ADMIN',
      'email': 'admin@e-voting.app',
    });

    await _writeList('voters', [
      {
        'id': 1001,
        'username': '1001',
        'password': 'password',
        'fullName': 'John Mwangi',
        'admissionNumber': '1001',
        'email': 'john@school.edu',
        'hasVoted': false,
      },
      {
        'id': 1002,
        'username': '1002',
        'password': 'password',
        'fullName': 'Asha Hassan',
        'admissionNumber': '1002',
        'email': 'asha@school.edu',
        'hasVoted': false,
      },
    ]);

    await _writeList('tickets', [
      {
        'id': 1,
        'name': 'Ticket A',
        'description': 'Team A kwa maendeleo',
        'presidentName': 'Musa Juma',
        'presidentParty': 'Umoja',
        'presidentPhotoUrl': '',
        'vicePresidentName': 'Leila Omar',
        'vicePresidentParty': 'Umoja',
        'vicePresidentPhotoUrl': '',
        'isActive': true,
        'voteCount': 0,
      },
      {
        'id': 2,
        'name': 'Ticket B',
        'description': 'Team B kwa uwazi',
        'presidentName': 'Amina Suleiman',
        'presidentParty': 'Amani',
        'presidentPhotoUrl': '',
        'vicePresidentName': 'David Mboya',
        'vicePresidentParty': 'Amani',
        'vicePresidentPhotoUrl': '',
        'isActive': true,
        'voteCount': 0,
      },
    ]);

    await _db.put('election', {
      'name': 'Uchaguzi wa Shule 2026',
      'description': 'Chagua viongozi wa mwaka ujao',
      'startTime': DateTime.now().toIso8601String(),
      'endTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'votingOpen': true,
    });

    await _writeList('support_messages', []);
    await _writeList('votes', []);
    await _db.put('fcmTokens', []);
    await _db.put('credentialsSent', false);
  }

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
    await _storage.delete(key: 'full_name');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'username');
  }

  static Future<void> saveUserInfo(String fullName, String role, String username) async {
    await _storage.write(key: 'full_name', value: fullName);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'username', value: username);
  }

  static Future<String?> getFullName() async {
    return await _storage.read(key: 'full_name');
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════

  static Map<String, dynamic> _getAdmin() {
    return _readMap('admin');
  }

  static List<Map<String, dynamic>> _getVoters() {
    return _readList('voters');
  }

  static Future<void> _setVoters(List<Map<String, dynamic>> voters) async {
    await _writeList('voters', voters);
  }

  static List<Map<String, dynamic>> _getTickets() {
    return _readList('tickets');
  }

  static Future<void> _setTickets(List<Map<String, dynamic>> tickets) async {
    await _writeList('tickets', tickets);
  }

  static List<Map<String, dynamic>> _getVotes() {
    return _readList('votes');
  }

  static Future<void> _setVotes(List<Map<String, dynamic>> votes) async {
    await _writeList('votes', votes);
  }

  static List<Map<String, dynamic>> _getSupportMessages() {
    return _readList('support_messages');
  }

  static Future<void> _setSupportMessages(List<Map<String, dynamic>> messages) async {
    await _writeList('support_messages', messages);
  }

  static Map<String, dynamic> _findVoter(String username) {
    final voters = _getVoters();
    return voters.cast<Map<String, dynamic>>().firstWhere(
      (v) => v['username'] == username || v['admissionNumber'] == username,
      orElse: () => <String, dynamic>{},
    );
  }

  static Map<String, dynamic> _election() {
    return _readMap('election');
  }

  static List<Map<String, dynamic>> _ticketsWithVotes() {
    final tickets = _getTickets();
    final votes = _getVotes();
    final counts = <int, int>{};
    for (final vote in votes) {
      final id = vote['ticketId'] as int?;
      if (id != null) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return tickets.map((ticket) {
      final voteCount = counts[ticket['id'] as int] ?? 0;
      return {
        ...ticket,
        'voteCount': voteCount,
      };
    }).toList();
  }

  // ═══════════════════════════════
  // AUTH
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    await _ensureInitialized();
    final admin = _getAdmin();
    if (admin['username'] == username && admin['password'] == password) {
      return {
        'token': 'local-${DateTime.now().millisecondsSinceEpoch}',
        'fullName': admin['fullName'] ?? 'Admin',
        'role': admin['role'] ?? 'ADMIN',
        'username': admin['username'],
      };
    }
    final voter = _findVoter(username);
    if (voter.isNotEmpty && voter['password'] == password) {
      return {
        'token': 'local-${DateTime.now().millisecondsSinceEpoch}',
        'fullName': voter['fullName'] ?? 'Mpiga Kura',
        'role': 'VOTER',
        'username': voter['username'],
      };
    }
    return {'error': 'Username au password si sahihi.'};
  }

  // ═══════════════════════════════
  // VOTER
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> getDashboard() async {
    await _ensureInitialized();
    final username = await getUsername();
    final user = username != null ? _findVoter(username) : <String, dynamic>{};
    final election = _election();
    final tickets = _ticketsWithVotes().where((ticket) => ticket['isActive'] == true).toList();
    final votes = _getVotes();
    final hasVoted = username != null && votes.any((vote) => vote['voterUsername'] == username);
    return {
      'user': user,
      'election': election,
      'isVotingOpen': election['votingOpen'] == true,
      'hasVoted': hasVoted,
      'tickets': tickets,
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    await _ensureInitialized();
    final username = await getUsername();
    final user = username != null ? _findVoter(username) : <String, dynamic>{};
    return user;
  }

  static Future<dynamic> getResults() async {
    await _ensureInitialized();
    final election = _election();
    return {
      'tickets': _ticketsWithVotes(),
      'election': election,
    };
  }

  static Future<Map<String, dynamic>> castVote(int ticketId) async {
    await _ensureInitialized();
    final username = await getUsername();
    if (username == null) {
      return {'error': 'Tafadhali ingia kwanza.'};
    }
    final election = _election();
    if (election['votingOpen'] != true) {
      return {'error': 'Uchaguzi haujakua wazi.'};
    }
    final voter = _findVoter(username);
    if (voter.isEmpty) {
      return {'error': 'Mpiga kura haipo kwenye data.'};
    }
    final votes = _getVotes();
    if (votes.any((vote) => vote['voterUsername'] == username)) {
      return {'error': 'Umekwisha piga kura.'};
    }
    final ticket = _getTickets().firstWhere(
      (item) => item['id'] == ticketId,
      orElse: () => <String, dynamic>{},
    );
    if (ticket.isEmpty) {
      return {'error': 'Ticket haipo.'};
    }
    votes.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'ticketId': ticketId,
      'voterUsername': username,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _setVotes(votes);
    final allVoters = _getVoters();
    final updatedVoters = allVoters.map((item) {
      if (item['username'] == username) {
        return {...item, 'hasVoted': true};
      }
      return item;
    }).toList();
    await _setVoters(updatedVoters);
    return {'message': 'Kura imewekwa kwa mafanikio.'};
  }

  // ═══════════════════════════════
  // ADMIN
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    await _ensureInitialized();
    final voters = _getVoters();
    final tickets = _getTickets();
    final supportMessages = _getSupportMessages();
    final election = _election();
    final unread = supportMessages.where((msg) => msg['read'] != true).length;
    return {
      'voterCount': voters.length,
      'ticketCount': tickets.length,
      'supportMessageCount': supportMessages.length,
      'unreadCount': unread,
      'election': election,
      'isVotingOpen': election['votingOpen'] == true,
    };
  }

  static Future<List<dynamic>> getAdminVoters() async {
    await _ensureInitialized();
    return _getVoters();
  }

  static Future<Map<String, dynamic>> addVoter(
      Map<String, dynamic> voterData) async {
    await _ensureInitialized();
    final voters = _getVoters();
    final nextId = voters.isEmpty
        ? 1001
        : (voters.map((v) => v['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final voter = {
      'id': nextId,
      'username': voterData['admissionNumber']?.toString() ?? nextId.toString(),
      'password': voterData['password']?.toString() ?? 'password',
      'fullName': voterData['fullName'] ?? 'Mpiga Kura',
      'admissionNumber': voterData['admissionNumber'] ?? nextId.toString(),
      'email': voterData['email'] ?? '',
      'hasVoted': false,
    };
    voters.add(voter);
    await _setVoters(voters);
    return {'message': 'Mpiga kura ameongezwa.'};
  }

  static Future<Map<String, dynamic>> deleteVoter(int id) async {
    await _ensureInitialized();
    final voters = _getVoters();
    final remaining = voters.where((v) => v['id'] != id).toList();
    await _setVoters(remaining);
    return {'message': 'Mpiga kura amefutwa.'};
  }

  static Future<Map<String, dynamic>> bulkImportVoters(
      List<Map<String, String>> voters) async {
    await _ensureInitialized();
    final current = _getVoters();
    var nextId = current.isEmpty
        ? 1001
        : (current.map((v) => v['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    for (final row in voters) {
      current.add({
        'id': nextId,
        'username': row['admissionNumber'] ?? nextId.toString(),
        'password': row['password'] ?? 'password',
        'fullName': row['fullName'] ?? row['name'] ?? 'Mpiga Kura',
        'admissionNumber': row['admissionNumber'] ?? nextId.toString(),
        'email': row['email'] ?? '',
        'hasVoted': false,
      });
      nextId += 1;
    }
    await _setVoters(current);
    return {'message': 'Wapiga kura wameletewa kwa mafanikio.'};
  }

  static Future<Map<String, dynamic>> deleteAllVoters() async {
    await _ensureInitialized();
    await _setVoters([]);
    return {'message': 'Wapiga kura wote walifutwa.'};
  }

  static Future<Map<String, dynamic>> sendCredentialsToAll() async {
    await _ensureInitialized();
    await _db.put('credentialsSent', true);
    return {'message': 'Credentials zimeandikwa na kukabidhiwa kwa wapiga kura.'};
  }

  static Future<List<dynamic>> getAdminCandidates() async {
    return getAdminTickets();
  }

  static Future<Map<String, dynamic>> getAdminElection() async {
    await _ensureInitialized();
    return _election();
  }

  static Future<Map<String, dynamic>> startElection() async {
    await _ensureInitialized();
    final election = _election();
    final updated = {
      ...election,
      'votingOpen': true,
    };
    await _db.put('election', updated);
    return {'message': 'Uchaguzi umeanza.', 'election': updated};
  }

  static Future<Map<String, dynamic>> stopElection() async {
    await _ensureInitialized();
    final election = _election();
    final updated = {
      ...election,
      'votingOpen': false,
    };
    await _db.put('election', updated);
    return {'message': 'Uchaguzi umesimamishwa.', 'election': updated};
  }

  static Future<Map<String, dynamic>> getAdminResults() async {
    await _ensureInitialized();
    return {
      'tickets': _ticketsWithVotes(),
      'election': _election(),
    };
  }

  static Future<Map<String, dynamic>> updateElection(
      Map<String, dynamic> data) async {
    await _ensureInitialized();
    final current = _election();
    final updated = {
      ...current,
      ...data,
      'votingOpen': data['votingOpen'] ?? current['votingOpen'],
    };
    await _db.put('election', updated);
    return {'message': 'Uchaguzi umesasishwa.', 'election': updated};
  }

  // ═══════════════════════════════
  // TICKETS
  // ═══════════════════════════════

  static Future<List<dynamic>> getAdminTickets() async {
    await _ensureInitialized();
    return _getTickets();
  }

  static Future<Map<String, dynamic>> addTicket(
      Map<String, dynamic> ticketData) async {
    await _ensureInitialized();
    final tickets = _getTickets();
    final nextId = tickets.isEmpty
        ? 1
        : (tickets.map((t) => t['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final ticket = {
      'id': nextId,
      'name': ticketData['name'] ?? 'Ticket $nextId',
      'description': ticketData['description'] ?? '',
      'presidentName': ticketData['presidentName'] ?? '',
      'presidentParty': ticketData['presidentParty'] ?? '',
      'presidentPhotoUrl': ticketData['presidentPhotoUrl'] ?? '',
      'vicePresidentName': ticketData['vicePresidentName'] ?? '',
      'vicePresidentParty': ticketData['vicePresidentParty'] ?? '',
      'vicePresidentPhotoUrl': ticketData['vicePresidentPhotoUrl'] ?? '',
      'isActive': ticketData['isActive'] ?? true,
      'voteCount': 0,
    };
    tickets.add(ticket);
    await _setTickets(tickets);
    return {'message': 'Ticket imeongezwa.', 'ticket': ticket};
  }

  static Future<Map<String, dynamic>> updateTicket(
      int id, Map<String, dynamic> ticketData) async {
    await _ensureInitialized();
    final tickets = _getTickets();
    final updated = tickets.map((t) {
      if (t['id'] == id) {
        return {
          ...t,
          ...ticketData,
        };
      }
      return t;
    }).toList();
    await _setTickets(updated);
    return {'message': 'Ticket imesasishwa.'};
  }

  static Future<Map<String, dynamic>> deleteTicket(int id) async {
    await _ensureInitialized();
    final tickets = _getTickets();
    final remaining = tickets.where((t) => t['id'] != id).toList();
    await _setTickets(remaining);
    return {'message': 'Ticket imefutwa.'};
  }

  // ═══════════════════════════════
  // CHANGE PASSWORD & PROFILE
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> voterChangePassword(
      String currentPassword, String newPassword) async {
    await _ensureInitialized();
    final username = await getUsername();
    if (username == null) {
      return {'error': 'Tafadhali ingia kwanza.'};
    }
    final voters = _getVoters();
    var changed = false;
    final updated = voters.map((voter) {
      if (voter['username'] == username && voter['password'] == currentPassword) {
        changed = true;
        return {...voter, 'password': newPassword};
      }
      return voter;
    }).toList();
    if (!changed) {
      return {'error': 'Password ya sasa si sahihi.'};
    }
    await _setVoters(updated);
    return {'message': 'Password imebadilishwa.'};
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    await _ensureInitialized();
    return _getAdmin();
  }

  static Future<Map<String, dynamic>> adminChangePassword(
      String currentPassword, String newPassword) async {
    await _ensureInitialized();
    final admin = _getAdmin();
    if (admin['password'] != currentPassword) {
      return {'error': 'Password ya sasa si sahihi.'};
    }
    final updated = {...admin, 'password': newPassword};
    await _db.put('admin', updated);
    return {'message': 'Password ya admin imebadilishwa.'};
  }

  static Future<Map<String, dynamic>> adminChangeUsername(
      String newUsername) async {
    await _ensureInitialized();
    final voters = _getVoters();
    if (voters.any((v) => v['username'] == newUsername)) {
      return {'error': 'Username tayari inatumika.'};
    }
    final admin = _getAdmin();
    final updated = {...admin, 'username': newUsername};
    await _db.put('admin', updated);
    return {'message': 'Username ya admin imebadilishwa.', 'username': newUsername};
  }

  // ═══════════════════════════════
  // SUPPORT MESSAGES
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> sendSupportMessage(
      String admissionNumber, String message) async {
    await _ensureInitialized();
    final messages = _getSupportMessages();
    final nextId = messages.isEmpty
        ? 1
        : (messages.map((m) => m['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newMessage = {
      'id': nextId,
      'admissionNumber': admissionNumber,
      'message': message,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    messages.add(newMessage);
    await _setSupportMessages(messages);
    return {'message': 'Ujumbe umefikiwa kwa admin.'};
  }

  static Future<List<dynamic>> getSupportMessages() async {
    await _ensureInitialized();
    return _getSupportMessages();
  }

  static Future<Map<String, dynamic>> markMessageRead(int id) async {
    await _ensureInitialized();
    final messages = _getSupportMessages();
    final updated = messages.map((message) {
      if (message['id'] == id) {
        return {...message, 'read': true};
      }
      return message;
    }).toList();
    await _setSupportMessages(updated);
    return {'message': 'Ujumbe umetajwa kama umesomwa.'};
  }

  static Future<int> getUnreadCount() async {
    await _ensureInitialized();
    final messages = _getSupportMessages();
    return messages.where((message) => message['read'] != true).length;
  }

  // ═══════════════════════════════
  // FORGOT PASSWORD
  // ═══════════════════════════════

  static Future<Map<String, dynamic>> forgotPassword(
      String admissionNumber) async {
    await _ensureInitialized();
    final voters = _getVoters();
    var found = false;
    final updated = voters.map((voter) {
      if (voter['admissionNumber'] == admissionNumber || voter['username'] == admissionNumber) {
        found = true;
        return {...voter, 'password': 'password123'};
      }
      return voter;
    }).toList();
    if (!found) {
      return {'error': 'Admission number haipo.'};
    }
    await _setVoters(updated);
    return {
      'message': 'Password imebadilishwa kwa password123. Tumia password mpya kuingia.'
    };
  }

  static Future<void> saveFCMToken(String fcmToken) async {
    await _ensureInitialized();
    final tokens = (_db.get('fcmTokens') as List<dynamic>?) ?? [];
    if (!tokens.contains(fcmToken)) {
      tokens.add(fcmToken);
      await _db.put('fcmTokens', tokens);
    }
  }

  static Future<Map<String, dynamic>> sendBroadcastNotification(
      Map<String, String> data) async {
    await _ensureInitialized();
    final notifications = (_db.get('broadcastNotifications') as List<dynamic>?) ?? [];
    notifications.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'data': data,
      'sentAt': DateTime.now().toIso8601String(),
    });
    await _db.put('broadcastNotifications', notifications);
    return {'message': 'Notification imeandikwa kwa mfumo.'};
  }
}
