import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminElectionScreen extends StatefulWidget {
  const AdminElectionScreen({super.key});

  @override
  State<AdminElectionScreen> createState() => _AdminElectionScreenState();
}

class _AdminElectionScreenState extends State<AdminElectionScreen> {
  Map<String, dynamic>? _electionData;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadElection();
  }

  Future<void> _loadElection() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getAdminElection();
      setState(() {
        _electionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Imeshindwa kupakia data. Jaribu tena.';
        _isLoading = false;
      });
    }
  }

  Future<void> _startElection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Anza Uchaguzi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kuanza uchaguzi sasa?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hapana', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Ndiyo, Anza!', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isActionLoading = true);
    try {
      final result = await ApiService.startElection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Uchaguzi umeanza!',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ));
      _loadElection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imeshindwa kuanza uchaguzi.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _stopElection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Simamisha Uchaguzi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kusimamisha uchaguzi?',
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
            child: Text('Ndiyo, Simamisha!', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isActionLoading = true);
    try {
      final result = await ApiService.stopElection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Uchaguzi umesimamishwa!',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ));
      _loadElection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imeshindwa kusimamisha.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  void _showEditElectionDialog() {
    final nameController = TextEditingController(
        text: _electionData?['name'] ?? '');
    final descController = TextEditingController(
        text: _electionData?['description'] ?? '');
    DateTime? startDate;
    DateTime? endDate;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Sanidi Uchaguzi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jina
                Text('Jina la Uchaguzi',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Mfano: General Election 2026',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon: const Icon(Icons.title, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Maelezo
                Text('Maelezo (Optional)',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Andika maelezo ya uchaguzi...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Tarehe ya Kuanza
                Text('Tarehe ya Kuanza',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDateTimePicker(ctx);
                    if (picked != null) {
                      setDialogState(() => startDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          startDate != null
                              ? '${startDate!.day}/${startDate!.month}/${startDate!.year} ${startDate!.hour}:${startDate!.minute.toString().padLeft(2, '0')}'
                              : 'Chagua tarehe na saa',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: startDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tarehe ya Kumalizika
                Text('Tarehe ya Kumalizika',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDateTimePicker(ctx);
                    if (picked != null) {
                      setDialogState(() => endDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          endDate != null
                              ? '${endDate!.day}/${endDate!.month}/${endDate!.year} ${endDate!.hour}:${endDate!.minute.toString().padLeft(2, '0')}'
                              : 'Chagua tarehe na saa',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: endDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Weka jina la uchaguzi!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await ApiService.updateElection({
                          'name': nameController.text,
                          'description': descController.text,
                          'startTime': startDate?.toIso8601String() ??
                              _electionData?['startTime'],
                          'endTime': endDate?.toIso8601String() ??
                              _electionData?['endTime'],
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Uchaguzi umesasishwa!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.green,
                        ));
                        _loadElection();
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Imeshindwa kusasisha.',
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
                  : Text('Hifadhi', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    if (!mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade600, fontSize: 14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Haijawekwa';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _electionData?['votingOpen'] == true;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('Usimamizi wa Uchaguzi',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditElectionDialog,
            tooltip: 'Hariri Uchaguzi',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadElection,
          ),
        ],
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
                        onPressed: _loadElection,
                        child: Text('Jaribu Tena',
                            style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadElection,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hali ya Uchaguzi Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [Colors.green.shade600, Colors.green.shade400]
                                  : [const Color(0xFF1565C0), const Color(0xFF1976D2)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    isActive ? Icons.how_to_vote : Icons.pending,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? '🟢 Inaendelea' : '🔴 Imesimama',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _electionData?['name'] ?? 'Uchaguzi',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_electionData?['description'] != null)
                                Text(
                                  _electionData!['description'],
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Maelezo Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Maelezo ya Uchaguzi',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const Divider(),
                              _infoRow('Jina',
                                  _electionData?['name'] ?? 'Haijawekwa'),
                              _infoRow('Hali',
                                  isActive ? 'Inaendelea' : 'Imesimama'),
                              _infoRow('Inaanza',
                                  _formatDate(_electionData?['startTime'])),
                              _infoRow('Inaisha',
                                  _formatDate(_electionData?['endTime'])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vitendo
                        Text('Vitendo',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700)),
                        const SizedBox(height: 12),

                        // Kitufe cha Edit
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _showEditElectionDialog,
                            icon: const Icon(Icons.edit),
                            label: Text('HARIRI MAELEZO YA UCHAGUZI',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(
                                  color: Color(0xFF1565C0), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Anza au Simamisha
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isActionLoading ? null : (isActive ? _stopElection : _startElection),
                            icon: _isActionLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Icon(isActive ? Icons.stop : Icons.play_arrow),
                            label: Text(
                              isActive ? 'SIMAMISHA UCHAGUZI' : 'ANZA UCHAGUZI',
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isActive ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}