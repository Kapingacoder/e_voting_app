import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminCandidatesScreen extends StatefulWidget {
  const AdminCandidatesScreen({super.key});

  @override
  State<AdminCandidatesScreen> createState() => _AdminCandidatesScreenState();
}

class _AdminCandidatesScreenState extends State<AdminCandidatesScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getAdminTickets();
      setState(() {
        _tickets = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Imeshindwa kupakia tickets. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTicket(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Futa Ticket',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kufuta ticket "$name"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hapana', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Futa', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteTicket(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ticket "$name" imefutwa!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ));
      _loadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imeshindwa kufuta ticket.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showAddEditTicketDialog({Map<String, dynamic>? ticket}) {
    final isEdit = ticket != null;
    final nameController = TextEditingController(text: ticket?['name'] ?? '');
    final descController = TextEditingController(text: ticket?['description'] ?? '');
    final presidentNameController = TextEditingController(text: ticket?['presidentName'] ?? '');
    final presidentPartyController = TextEditingController(text: ticket?['presidentParty'] ?? '');
    final presidentPhotoController = TextEditingController(text: ticket?['presidentPhotoUrl'] ?? '');
    final vpNameController = TextEditingController(text: ticket?['vicePresidentName'] ?? '');
    final vpPartyController = TextEditingController(text: ticket?['vicePresidentParty'] ?? '');
    final vpPhotoController = TextEditingController(text: ticket?['vicePresidentPhotoUrl'] ?? '');
    bool isActive = ticket?['isActive'] ?? true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Hariri Ticket' : 'Ongeza Ticket Mpya',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Maelezo ya Ticket
                _sectionTitle('Maelezo ya Ticket'),
                _dialogTextField(nameController, 'Jina la Ticket *', Icons.label),
                const SizedBox(height: 8),
                _dialogTextField(descController, 'Maelezo (Optional)', Icons.description, maxLines: 2),
                const SizedBox(height: 16),

                // Rais
                _sectionTitle('🏅 Rais (President)'),
                _dialogTextField(presidentNameController, 'Jina la Rais *', Icons.person),
                const SizedBox(height: 8),
                _dialogTextField(presidentPartyController, 'Chama cha Rais', Icons.groups),
                const SizedBox(height: 8),
                _dialogTextField(presidentPhotoController, 'URL ya Picha ya Rais', Icons.image),
                const SizedBox(height: 16),

                // Makamu
                _sectionTitle('🥈 Makamu (Vice President)'),
                _dialogTextField(vpNameController, 'Jina la Makamu *', Icons.person_outline),
                const SizedBox(height: 8),
                _dialogTextField(vpPartyController, 'Chama cha Makamu', Icons.groups_outlined),
                const SizedBox(height: 8),
                _dialogTextField(vpPhotoController, 'URL ya Picha ya Makamu', Icons.image_outlined),
                const SizedBox(height: 12),

                // Active Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket Iwe Active?',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                      activeColor: const Color(0xFF1565C0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Ghairi', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          presidentNameController.text.isEmpty ||
                          vpNameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Jaza fields zote za lazima (*)',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final data = {
                        'name': nameController.text,
                        'description': descController.text,
                        'presidentName': presidentNameController.text,
                        'presidentParty': presidentPartyController.text,
                        'presidentPhotoUrl': presidentPhotoController.text,
                        'vicePresidentName': vpNameController.text,
                        'vicePresidentParty': vpPartyController.text,
                        'vicePresidentPhotoUrl': vpPhotoController.text,
                        'isActive': isActive,
                      };

                      try {
                        if (isEdit) {
                          await ApiService.updateTicket(ticket!['id'], data);
                        } else {
                          await ApiService.addTicket(data);
                        }
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            isEdit ? 'Ticket imesasishwa!' : 'Ticket imeongezwa!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ));
                        _loadTickets();
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Imeshindwa. Jaribu tena.',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Sasisha' : 'Ongeza',
                      style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _dialogTextField(
      TextEditingController controller, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          'Wagombea/Tickets (${_tickets.length})',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTickets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTicketDialog(),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ongeza Ticket',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.poppins()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTickets,
                        child: Text('Jaribu Tena', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.how_to_vote_outlined,
                              size: 70, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Hakuna tickets bado',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Bonyeza + kuongeza ticket ya kwanza',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          final id = ticket['id'] as int?;
                          final name = ticket['name'] ?? 'Ticket ${index + 1}';
                          final isActive = ticket['isActive'] ?? true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF1565C0).withOpacity(0.3)
                                    : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header ya Ticket
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF1565C0).withOpacity(0.05)
                                        : Colors.grey.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFF1565C0)
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isActive
                                                    ? const Color(0xFF1565C0)
                                                    : Colors.grey,
                                              ),
                                            ),
                                            if (ticket['description'] != null &&
                                                ticket['description'].isNotEmpty)
                                              Text(
                                                ticket['description'],
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.shade100
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: isActive
                                                ? Colors.green.shade700
                                                : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Rais na Makamu
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Rais
                                      Expanded(
                                        child: _candidateCard(
                                          '🏅 Rais',
                                          ticket['presidentName'] ?? 'Haijawekwa',
                                          ticket['presidentParty'] ?? '',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Makamu
                                      Expanded(
                                        child: _candidateCard(
                                          '🥈 Makamu',
                                          ticket['vicePresidentName'] ?? 'Haijawekwa',
                                          ticket['vicePresidentParty'] ?? '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Kura
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.how_to_vote,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Kura: ${ticket['voteCount'] ?? 0}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),

                                // Buttons
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showAddEditTicketDialog(
                                                  ticket: ticket),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: Text('Hariri',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF1565C0),
                                            side: const BorderSide(
                                                color: Color(0xFF1565C0)),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: id != null
                                              ? () => _deleteTicket(id, name)
                                              : null,
                                          icon: const Icon(Icons.delete_outline,
                                              size: 16),
                                          label: Text('Futa',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
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
                    ),
    );
  }

  Widget _candidateCard(String role, String name, String party) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (party.isNotEmpty)
            Text(party,
                style:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}