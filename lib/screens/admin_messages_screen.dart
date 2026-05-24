import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getSupportMessages();
      setState(() {
        _messages = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Imeshindwa kupakia ujumbe.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService.markMessageRead(id);
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == id);
        if (idx != -1) _messages[idx]['read'] = true;
      });
    } catch (e) {
      // ignore
    }
  }

  List<dynamic> get _filteredMessages {
    switch (_filter) {
      case 'unread':
        return _messages
            .where((m) => !(m['read'] ?? m['isRead'] ?? false))
            .toList();
      case 'read':
        return _messages
            .where((m) => m['read'] ?? m['isRead'] ?? false)
            .toList();
      default:
        return _messages;
    }
  }

  int get _unreadCount => _messages
      .where((m) => !(m['read'] ?? m['isRead'] ?? false))
      .length;

  void _showMessageDialog(Map<String, dynamic> message) {
    final id = message['id'] as int?;
    final isRead = message['read'] ?? message['isRead'] ?? false;

    if (!isRead && id != null) {
      _markAsRead(id);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.message, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text('Ujumbe wa Voter',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admission Number
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.numbers,
                      size: 18, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    'Adm: ${message['admissionNumber'] ?? 'Haijulikani'}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tarehe
            Text(
              _formatDate(message['createdAt']),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Ujumbe
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                message['message'] ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 14, height: 1.6),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: Text('Funga', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Sasa hivi';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dakika zilizopita';
      if (diff.inHours < 24) return '${diff.inHours} saa zilizopita';
      if (diff.inDays < 7) return '${diff.inDays} siku zilizopita';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Row(
          children: [
            Text('Ujumbe wa Voters',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_unreadCount',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip('Zote', 'all', _messages.length),
                const SizedBox(width: 8),
                _filterChip('Mpya', 'unread', _unreadCount,
                    color: Colors.red),
                const SizedBox(width: 8),
                _filterChip('Zilizosomwa', 'read',
                    _messages.length - _unreadCount,
                    color: Colors.green),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1565C0)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: Text('Jaribu Tena',
                                  style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                      )
                    : _filteredMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.mark_chat_read_outlined,
                                    size: 70,
                                    color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('Hakuna ujumbe',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 16)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMessages,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount:
                                  _filteredMessages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    _filteredMessages[index];
                                final isRead = message['read'] ??
                                    message['isRead'] ??
                                    false;
                                final id =
                                    message['id'] as int?;

                                return GestureDetector(
                                  onTap: () =>
                                      _showMessageDialog(message),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 10),
                                    padding:
                                        const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : const Color(
                                              0xFFE3F2FD),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                      border: Border.all(
                                        color: isRead
                                            ? Colors.grey.shade200
                                            : const Color(
                                                0xFF1565C0)
                                            .withOpacity(0.3),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.04),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding:
                                              const EdgeInsets.all(
                                                  10),
                                          decoration: BoxDecoration(
                                            color: isRead
                                                ? Colors
                                                    .grey.shade200
                                                : const Color(
                                                    0xFF1565C0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isRead
                                                ? Icons
                                                    .mark_email_read_outlined
                                                : Icons
                                                    .mark_email_unread,
                                            color: isRead
                                                ? Colors.grey
                                                : Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Adm: ${message['admissionNumber'] ?? 'Haijulikani'}',
                                                    style: GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        fontSize:
                                                            13),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal:
                                                              6,
                                                          vertical:
                                                              2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6),
                                                      ),
                                                      child: Text(
                                                          'Mpya',
                                                          style: GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white,
                                                              fontSize:
                                                                  9,
                                                              fontWeight:
                                                                  FontWeight.bold)),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(
                                                  height: 4),
                                              Text(
                                                message['message'] ??
                                                    '',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors
                                                        .grey.shade700),
                                                maxLines: 2,
                                                overflow: TextOverflow
                                                    .ellipsis,
                                              ),
                                              const SizedBox(
                                                  height: 4),
                                              Text(
                                                _formatDate(message[
                                                    'createdAt']),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count,
      {Color color = const Color(0xFF1565C0)}) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : Colors.grey)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}