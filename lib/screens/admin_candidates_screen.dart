import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminCandidatesScreen extends StatefulWidget {
  const AdminCandidatesScreen({super.key});

  @override
  State<AdminCandidatesScreen> createState() => _AdminCandidatesScreenState();
}

class _AdminCandidatesScreenState extends State<AdminCandidatesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteTicket(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Futa Ticket', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kufuta ticket "$name"?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hapana', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Futa', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('tickets').doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket "$name" imefutwa!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa kufuta ticket.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
    }
  }

  void _showAddEditTicketDialog({QueryDocumentSnapshot<Map<String, dynamic>>? ticket}) {
    final isEdit = ticket != null;
    final nameController = TextEditingController(text: ticket?.data()['name'] as String? ?? '');
    final descController = TextEditingController(text: ticket?.data()['description'] as String? ?? '');
    final candidateNameController = TextEditingController(text: ticket?.data()['candidateName'] as String? ?? '');
    final candidatePartyController = TextEditingController(text: ticket?.data()['candidateParty'] as String? ?? '');
    final candidatePhotoController = TextEditingController(text: ticket?.data()['candidatePhotoUrl'] as String? ?? '');
    final presidentNameController = TextEditingController(text: ticket?.data()['presidentName'] as String? ?? '');
    final presidentPartyController = TextEditingController(text: ticket?.data()['presidentParty'] as String? ?? '');
    final presidentPhotoController = TextEditingController(text: ticket?.data()['presidentPhotoUrl'] as String? ?? '');
    final vpNameController = TextEditingController(text: ticket?.data()['vicePresidentName'] as String? ?? '');
    final vpPartyController = TextEditingController(text: ticket?.data()['vicePresidentParty'] as String? ?? '');
    final vpPhotoController = TextEditingController(text: ticket?.data()['vicePresidentPhotoUrl'] as String? ?? '');
    bool isActive = ticket?.data()['isActive'] as bool? ?? true;
    String positionType = ticket?.data()['positionType'] as String? ?? 'ticket';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Hariri Ticket' : 'Ongeza Ticket Mpya', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Aina ya Nafasi'),
                Row(
                  children: [
                    Expanded(child: _typeOption(label: 'Single', value: 'single', selected: positionType == 'single', onTap: () => setDialogState(() => positionType = 'single'))),
                    const SizedBox(width: 8),
                    Expanded(child: _typeOption(label: 'Ticket', value: 'ticket', selected: positionType == 'ticket', onTap: () => setDialogState(() => positionType = 'ticket'))),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Maelezo ya Ticket'),
                _dialogTextField(nameController, 'Jina la Ticket *', Icons.label),
                const SizedBox(height: 8),
                _dialogTextField(descController, 'Maelezo (Optional)', Icons.description, maxLines: 2),
                const SizedBox(height: 16),
                if (positionType == 'single') ...[
                  _sectionTitle('Mgombea'),
                  _dialogTextField(candidateNameController, 'Jina la Mgombea *', Icons.person),
                  const SizedBox(height: 8),
                  _dialogTextField(candidatePartyController, 'Chama / Group', Icons.groups),
                  const SizedBox(height: 8),
                  _dialogTextField(candidatePhotoController, 'URL ya Picha', Icons.image),
                ] else ...[
                  _sectionTitle('🏅 Rais'),
                  _dialogTextField(presidentNameController, 'Jina la Rais *', Icons.person),
                  const SizedBox(height: 8),
                  _dialogTextField(presidentPartyController, 'Chama cha Rais', Icons.groups),
                  const SizedBox(height: 8),
                  _dialogTextField(presidentPhotoController, 'URL ya Picha ya Rais', Icons.image),
                  const SizedBox(height: 16),
                  _sectionTitle('🥈 Makamu'),
                  _dialogTextField(vpNameController, 'Jina la Makamu *', Icons.person_outline),
                  const SizedBox(height: 8),
                  _dialogTextField(vpPartyController, 'Chama cha Makamu', Icons.groups_outlined),
                  const SizedBox(height: 8),
                  _dialogTextField(vpPhotoController, 'URL ya Picha ya Makamu', Icons.image_outlined),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket Iwe Active?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(value: isActive, onChanged: (val) => setDialogState(() => isActive = val), activeColor: const Color(0xFF1565C0)),
                  ],
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
                      final title = nameController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weka jina la ticket!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      if (positionType == 'single' && candidateNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weka jina la mgombea!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      if (positionType == 'ticket' && (presidentNameController.text.trim().isEmpty || vpNameController.text.trim().isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Weka majina ya Rais na Makamu!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      setDialogState(() => isLoading = true);

                      final entryData = <String, dynamic>{
                        'name': title,
                        'description': descController.text.trim(),
                        'positionType': positionType,
                        'isActive': isActive,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (positionType == 'single') {
                        entryData.addAll({
                          'candidateName': candidateNameController.text.trim(),
                          'candidateParty': candidatePartyController.text.trim(),
                          'candidatePhotoUrl': candidatePhotoController.text.trim(),
                        });
                        if (isEdit) {
                          entryData.addAll({
                            'presidentName': FieldValue.delete(),
                            'presidentParty': FieldValue.delete(),
                            'presidentPhotoUrl': FieldValue.delete(),
                            'vicePresidentName': FieldValue.delete(),
                            'vicePresidentParty': FieldValue.delete(),
                            'vicePresidentPhotoUrl': FieldValue.delete(),
                          });
                        }
                      } else {
                        entryData.addAll({
                          'presidentName': presidentNameController.text.trim(),
                          'presidentParty': presidentPartyController.text.trim(),
                          'presidentPhotoUrl': presidentPhotoController.text.trim(),
                          'vicePresidentName': vpNameController.text.trim(),
                          'vicePresidentParty': vpPartyController.text.trim(),
                          'vicePresidentPhotoUrl': vpPhotoController.text.trim(),
                        });
                        if (isEdit) {
                          entryData.addAll({
                            'candidateName': FieldValue.delete(),
                            'candidateParty': FieldValue.delete(),
                            'candidatePhotoUrl': FieldValue.delete(),
                          });
                        }
                      }

                      try {
                        if (isEdit) {
                          await _firestore.collection('tickets').doc(ticket!.id).update(entryData);
                        } else {
                          await _firestore.collection('tickets').add({
                            ...entryData,
                            'voteCount': 0,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Ticket imesasishwa!' : 'Ticket imeongezwa!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
                      } catch (_) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa. Jaribu tena.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? 'Sasisha' : 'Ongeza', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeOption({required String label, required String value, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300),
        ),
        child: Center(child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87))),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
    );
  }

  Widget _dialogTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _sectionDetailCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('Wagombea/Tickets', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTicketDialog(),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ongeza', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('tickets').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Imeshindwa kupakia wagombea.', style: GoogleFonts.poppins()));
          }
          final tickets = snapshot.data?.docs ?? [];
          if (tickets.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.how_to_vote_outlined, size: 70, color: Colors.grey), const SizedBox(height: 16), Text('Hakuna wagombea au tickets bado', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)), const SizedBox(height: 8), Text('Bonyeza + kuongeza ticket ya kwanza', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13))]));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final data = ticket.data();
                final positionType = data['positionType'] as String? ?? 'ticket';
                final name = data['name'] as String? ?? 'Ticket ${index + 1}';
                final isActive = data['isActive'] as bool? ?? true;
                final voteCount = data['voteCount'] as int? ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? const Color(0xFF1565C0).withOpacity(0.3) : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: isActive ? const Color(0xFF1565C0).withOpacity(0.05) : Colors.grey.shade50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: isActive ? const Color(0xFF1565C0) : Colors.grey, borderRadius: BorderRadius.circular(8)),
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? const Color(0xFF1565C0) : Colors.grey)), if ((data['description'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 4), Text(data['description'] as String, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey))]])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: isActive ? Colors.green.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Text(isActive ? 'Active' : 'Inactive', style: GoogleFonts.poppins(fontSize: 11, color: isActive ? Colors.green.shade700 : Colors.grey, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: positionType == 'single'
                            ? _sectionDetailCard('Mgombea', data['candidateName'] as String? ?? 'Haijawekwa', data['candidateParty'] as String? ?? '')
                            : Row(
                                children: [
                                  Expanded(child: _sectionDetailCard('Rais', data['presidentName'] as String? ?? 'Haijawekwa', data['presidentParty'] as String? ?? '')),
                                  const SizedBox(width: 10),
                                  Expanded(child: _sectionDetailCard('Makamu', data['vicePresidentName'] as String? ?? 'Haijawekwa', data['vicePresidentParty'] as String? ?? '')),
                                ],
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          children: [
                            const Icon(Icons.how_to_vote, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Kura: $voteCount', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAddEditTicketDialog(ticket: ticket),
                                icon: const Icon(Icons.edit, size: 16),
                                label: Text('Hariri', style: GoogleFonts.poppins(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1565C0),
                                  side: const BorderSide(color: Color(0xFF1565C0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteTicket(ticket.id, name),
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: Text('Futa', style: GoogleFonts.poppins(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
