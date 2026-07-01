import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminElectionScreen extends StatefulWidget {
  const AdminElectionScreen({super.key});

  @override
  State<AdminElectionScreen> createState() => _AdminElectionScreenState();
}

class _AdminElectionScreenState extends State<AdminElectionScreen> {
  bool _isActionLoading = false;

  Future<void> _updateElectionStatus(String id, bool votingOpen) async {
    setState(() => _isActionLoading = true);
    try {
      await FirebaseFirestore.instance.collection('elections').doc(id).update({'votingOpen': votingOpen});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(votingOpen ? 'Uchaguzi umeanza!' : 'Uchaguzi umesimamishwa!', style: GoogleFonts.poppins()), backgroundColor: votingOpen ? Colors.green : Colors.orange));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa kusasisha uchaguzi.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showCreateElectionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ongeza Uchaguzi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jina la Uchaguzi', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Mfano: General Election 2026', hintStyle: GoogleFonts.poppins(fontSize: 12), prefixIcon: const Icon(Icons.title, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 12),
                Text('Maelezo (Optional)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: 'Andika maelezo ya uchaguzi...', hintStyle: GoogleFonts.poppins(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(12)),
                ),
                const SizedBox(height: 12),
                Text('Tarehe ya Kuanza', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showDateTimePicker(ctx, initial: startDate);
                    if (picked != null) setStateDialog(() => startDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(startDate != null ? _formatDateTime(startDate!) : 'Chagua tarehe na saa', style: GoogleFonts.poppins(fontSize: 13, color: startDate != null ? Colors.black87 : Colors.grey)))]),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tarehe ya Kumalizika', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showDateTimePicker(ctx, initial: endDate);
                    if (picked != null) setStateDialog(() => endDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endDate != null ? _formatDateTime(endDate!) : 'Chagua tarehe na saa', style: GoogleFonts.poppins(fontSize: 13, color: endDate != null ? Colors.black87 : Colors.grey)))]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Ghairi', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weka jina la uchaguzi!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      setStateDialog(() => isLoading = true);
                      try {
                        await FirebaseFirestore.instance.collection('elections').add({
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'startTime': startDate?.toIso8601String(),
                          'endTime': endDate?.toIso8601String(),
                          'votingOpen': false,
                          'createdAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uchaguzi mpya umeundwa!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
                      } catch (_) {
                        setStateDialog(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa kuunda uchaguzi.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Unda', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditElectionDialog(Map<String, dynamic> election) {
    final nameController = TextEditingController(text: election['name'] as String? ?? '');
    final descController = TextEditingController(text: election['description'] as String? ?? '');
    DateTime? startDate = _parseDateTime(election['startTime']);
    DateTime? endDate = _parseDateTime(election['endTime']);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sanidi Uchaguzi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jina la Uchaguzi', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Mfano: General Election 2026', hintStyle: GoogleFonts.poppins(fontSize: 12), prefixIcon: const Icon(Icons.title, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 12),
                Text('Maelezo (Optional)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: 'Andika maelezo ya uchaguzi...', hintStyle: GoogleFonts.poppins(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(12)),
                ),
                const SizedBox(height: 12),
                Text('Tarehe ya Kuanza', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showDateTimePicker(ctx, initial: startDate);
                    if (picked != null) setStateDialog(() => startDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(startDate != null ? _formatDateTime(startDate!) : 'Chagua tarehe na saa', style: GoogleFonts.poppins(fontSize: 13, color: startDate != null ? Colors.black87 : Colors.grey)))]),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Tarehe ya Kumalizika', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showDateTimePicker(ctx, initial: endDate);
                    if (picked != null) setStateDialog(() => endDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(endDate != null ? _formatDateTime(endDate!) : 'Chagua tarehe na saa', style: GoogleFonts.poppins(fontSize: 13, color: endDate != null ? Colors.black87 : Colors.grey)))]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Ghairi', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weka jina la uchaguzi!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      setStateDialog(() => isLoading = true);
                      try {
                        await FirebaseFirestore.instance.collection('elections').doc(election['id'] as String).update({
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'startTime': startDate?.toIso8601String(),
                          'endTime': endDate?.toIso8601String(),
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uchaguzi umesasishwa!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
                      } catch (_) {
                        setStateDialog(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa kusasisha uchaguzi.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Hifadhi', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _formatDateTime(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<DateTime?> _showDateTimePicker(BuildContext context, {DateTime? initial}) async {
    final date = await showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(backgroundColor: const Color(0xFF1565C0), title: Text('Usimamizi wa Uchaguzi', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() {}))]),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('elections').limit(1).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Imeshindwa kupakia data ya uchaguzi.', style: GoogleFonts.poppins()));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.how_to_vote_outlined, size: 70, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Hakuna uchaguzi uliopatikana.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Tengeneza uchaguzi mpya ili kuendelea.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showCreateElectionDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                      child: Text('Ongeza Uchaguzi', style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          final doc = docs.first;
          final data = {'id': doc.id, ...doc.data()};
          final votingOpen = data['votingOpen'] as bool? ?? false;
          final name = data['name'] as String? ?? 'Uchaguzi wa Sasa';
          final description = data['description'] as String? ?? '';
          final start = _parseDateTime(data['startTime']);
          final end = _parseDateTime(data['endTime']);
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Uchaguzi', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)), const SizedBox(height: 8), Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(votingOpen ? 'Kura zinaendelea' : 'Kura hazijaanza', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13))]),
                  ),
                  const SizedBox(height: 24),
                  _dataRow('Jina la Uchaguzi', name),
                  if (description.isNotEmpty) ...[const SizedBox(height: 12), _dataRow('Maelezo', description)],
                  const SizedBox(height: 12),
                  _dataRow('Kuanza', start != null ? _formatDateTime(start) : 'Haijapangwa'),
                  const SizedBox(height: 12),
                  _dataRow('Kuisha', end != null ? _formatDateTime(end) : 'Haijapangwa'),
                  const SizedBox(height: 12),
                  _dataRow('Hali ya Kura', votingOpen ? 'Inafunguliwa' : 'Imefungwa'),
                  const SizedBox(height: 24),
                  Row(children: [Expanded(child: ElevatedButton(onPressed: _isActionLoading || votingOpen ? null : () => _updateElectionStatus(doc.id, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)), child: Text('Anza Uchaguzi', style: GoogleFonts.poppins()))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _isActionLoading || !votingOpen ? null : () => _updateElectionStatus(doc.id, false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text('Simamisha Uchaguzi', style: GoogleFonts.poppins()))) ]),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _showEditElectionDialog(data), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1565C0), side: const BorderSide(color: Color(0xFF1565C0))), child: Text('Hariri Uchaguzi', style: GoogleFonts.poppins()))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(height: 6), Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600))]),
    );
  }
}
