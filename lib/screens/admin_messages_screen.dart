import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  String _filter = 'all';

  int _unreadCount(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) => !(doc.data()['read'] as bool? ?? false)).length;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (_filter == 'unread') {
      return docs.where((doc) => !(doc.data()['read'] as bool? ?? false)).toList();
    }
    if (_filter == 'read') {
      return docs.where((doc) => doc.data()['read'] as bool? ?? false).toList();
    }
    return docs;
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('messages').doc(docId).update({'read': true});
  }

  void _showMessageDialog(Map<String, dynamic> message, String docId) {
    final isRead = message['read'] as bool? ?? false;
    if (!isRead) {
      _markAsRead(docId);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.message, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text('Ujumbe wa Voter', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.numbers, size: 18, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adm: ${message['admissionNumber'] ?? 'Haijulikani'}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_formatDate(message['createdAt']), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(message['message'] ?? '', style: GoogleFonts.poppins(fontSize: 14, height: 1.6)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: Text('Funga', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic createdAt) {
    DateTime date;
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is DateTime) {
      date = createdAt;
    } else if (createdAt is String) {
      date = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika zilizopita';
    if (diff.inHours < 24) return '${diff.inHours} saa zilizopita';
    if (diff.inDays < 7) return '${diff.inDays} siku zilizopita';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _filterChip(String label, String value, int count, {Color color = const Color(0xFF1565C0)}) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black87)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? Colors.white24 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.white : Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('Ujumbe wa Voters', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() {})),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Imeshindwa kupakia ujumbe.', style: GoogleFonts.poppins()));
          }

          final docs = snapshot.data?.docs ?? [];
          final unreadCount = _unreadCount(docs);
          final filteredDocs = _filteredDocs(docs);

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _filterChip('Zote', 'all', docs.length),
                    const SizedBox(width: 8),
                    _filterChip('Mpya', 'unread', unreadCount, color: Colors.red),
                    const SizedBox(width: 8),
                    _filterChip('Zilizosomwa', 'read', docs.length - unreadCount, color: Colors.green),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.mark_chat_read_outlined, size: 70, color: Colors.grey), const SizedBox(height: 16), Text('Hakuna ujumbe', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final message = doc.data();
                          final isRead = message['read'] as bool? ?? false;
                          return GestureDetector(
                            onTap: () => _showMessageDialog(message, doc.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRead ? Colors.grey.shade200 : const Color(0xFF1565C0).withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: isRead ? Colors.grey.shade200 : const Color(0xFF1565C0), shape: BoxShape.circle),
                                    child: Icon(isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread, color: isRead ? Colors.grey : Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Adm: ${message['admissionNumber'] ?? 'Haijulikani'}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                            if (!isRead)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                                child: Text('Mpya', style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(message['message'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(_formatDate(message['createdAt']), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
