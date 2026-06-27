import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'dart:io';
import '../services/api_service.dart';

class AdminVotersScreen extends StatefulWidget {
  const AdminVotersScreen({super.key});

  @override
  State<AdminVotersScreen> createState() => _AdminVotersScreenState();
}

class _AdminVotersScreenState extends State<AdminVotersScreen> {
  List<dynamic> _voters = [];
  List<dynamic> _filteredVoters = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVoters();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVoters = List.from(_voters);
      } else {
        _filteredVoters = _voters.where((voter) {
          final name = (voter['fullName'] ?? '').toLowerCase();
          final username = (voter['username'] ?? '').toLowerCase();
          final admission = (voter['admissionNumber'] ?? '').toLowerCase();
          return name.contains(query) ||
              username.contains(query) ||
              admission.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadVoters() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getAdminVoters();
      setState(() {
        _voters = data;
        _filteredVoters = List.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Imeshindwa kupakia wapiga kura.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVoter(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Futa Mpiga Kura',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kumfuta $name?',
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
      await ApiService.deleteVoter(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name amefutwa!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ));
      _loadVoters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Imeshindwa kumfuta.', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _deleteAllVoters() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text('Futa Wote!',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hatua hii itafuta wapiga kura WOTE ${_voters.length} na haiwezi kurudishwa!',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Una uhakika kabisa?',
                style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hapana, Rudi',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever),
            label: Text('Ndiyo, Futa Wote!',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Inafuta wapiga kura wote...');

    try {
      await ApiService.deleteAllVoters();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Wapiga kura wote wamefutwa!',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ));
      _loadVoters();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imeshindwa kufuta. Jaribu tena.',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _sendCredentialsToAll() async {
    // Angalia kama wana email
    final withEmail = _voters
        .where((v) =>
            v['email'] != null && v['email'].toString().isNotEmpty)
        .length;
    final withoutEmail = _voters.length - withEmail;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.email, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Text('Tuma Credentials',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _statRow(Icons.people,
                      'Wapiga kura wote', '${_voters.length}',
                      const Color(0xFF1565C0)),
                  const Divider(height: 16),
                  _statRow(Icons.email,
                      'Wana email', '$withEmail',
                      Colors.green),
                  const SizedBox(height: 6),
                  _statRow(Icons.email_outlined,
                      'Hawana email', '$withoutEmail',
                      Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email itakuwa na:\n'
                      '• Username (Admission Number)\n'
                      '• Password ya default\n'
                      '• Maelekezo ya kuingia',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ghairi', style: GoogleFonts.poppins()),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: Text('Tuma Emails $withEmail',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog('Inatuma emails... Tafadhali subiri');

    try {
      final result = await ApiService.sendCredentialsToAll();
      if (!mounted) return;
      Navigator.pop(context);

      final sent = (result['sent'] ?? 0) as int;
      final failed = result['failed'] != null
          ? List<String>.from(result['failed'] as List<String>)
          : <String>[];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Matokeo ya Kutuma',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('$sent Emails Zimetumwa!',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green)),
                        Text('Wapiga kura wamearifiwa',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:
                                    Colors.green.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${failed.length} hawakupata email:',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          itemCount: failed.length > 5
                              ? 5
                              : failed.length,
                          itemBuilder: (context, index) =>
                              Text(
                            '• ${failed[index]}',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color:
                                    Colors.orange.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: Text('Sawa!',
                  style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imeshindwa kutuma emails.',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Widget _statRow(IconData icon, String label, String value,
      Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color)),
      ],
    );
  }

  // ═══════════════════════════════
  // BULK IMPORT
  // ═══════════════════════════════
  Future<void> _showBulkImportDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Bulk Voter Import',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text('Maelekezo ya File',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File lazima iwe na columns hizi:\n'
                      '• fullName — Jina kamili\n'
                      '• admissionNumber — Nambari ya usajili\n'
                      '• email — Barua pepe (optional)\n\n'
                      'Inasupport: Excel (.xlsx) na CSV (.csv)\n'
                      'Inaweza kuchukua hadi watu 10,000+',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Format ya Password
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Password ya kila voter itakuwa:\nJina la kwanza + 123 (mfano: john123)',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons za File Type
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickAndImportFile('excel');
                      },
                      icon: const Icon(Icons.table_chart),
                      label: Text('Excel (.xlsx)',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickAndImportFile('csv');
                      },
                      icon: const Icon(Icons.description),
                      label: Text('CSV (.csv)',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
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
        ],
      ),
    );
  }

  Future<void> _pickAndImportFile(String type) async {
    try {
      // Chagua file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'excel' ? ['xlsx', 'xls'] : ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      // Onyesha loading
      _showLoadingDialog('Inasoma file...');

      List<Map<String, String>> voters = [];

      if (type == 'excel') {
        voters = await _parseExcel(file.bytes!);
      } else {
        voters = await _parseCsv(file.bytes!);
      }

      if (!mounted) return;
      Navigator.pop(context); // Funga loading

      if (voters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Hakuna data iliyopatikana kwenye file. Angalia columns zako.',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Onyesha preview kabla ya kuimport
      _showImportPreviewDialog(voters);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hitilafu: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<List<Map<String, String>>> _parseExcel(
      List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Map<String, String>> voters = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;
      if (sheet.rows.isEmpty) continue;

      // Pata headers kutoka row ya kwanza
      final headers = sheet.rows[0]
          .map((cell) =>
              cell?.value?.toString().toLowerCase().trim() ?? '')
          .toList();

      // Angalia columns zilizopo
      final fullNameIdx = _findColumnIndex(headers, [
        'fullname', 'full name', 'full_name', 'name',
        'jina', 'jina kamili', 'jiina',
      ]);

      final admissionIdx = _findColumnIndex(headers, [
        'admissionnumber', 'admission number', 'admission_number',
        'admission', 'adm', 'nambari',
        'namba ya uandikishaji', 'namba', 'uandikishaji',
        'reg', 'regno',
      ]);

      final emailIdx = _findColumnIndex(headers, [
        'email', 'barua', 'barua_pepe', 'barua pepe', 'mail',
      ]);

      if (fullNameIdx == -1 || admissionIdx == -1) continue;

      // Soma rows (skip header row)
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final fullName =
            row[fullNameIdx]?.value?.toString().trim() ?? '';
        final admissionNumber =
            row[admissionIdx]?.value?.toString().trim() ?? '';

        if (fullName.isEmpty || admissionNumber.isEmpty) continue;

        final voter = {
          'fullName': fullName,
          'admissionNumber': admissionNumber,
        };

        if (emailIdx != -1 && emailIdx < row.length) {
          voter['email'] =
              row[emailIdx]?.value?.toString().trim() ?? '';
        }

        voters.add(voter);

        // Limit kwa 10,000
        if (voters.length >= 10000) break;
      }
      break; // Sheet ya kwanza tu
    }

    return voters;
  }

  Future<List<Map<String, String>>> _parseCsv(List<int> bytes) async {
    final List<Map<String, String>> voters = [];

    try {
      // Soma file kama string
      final csvString = String.fromCharCodes(bytes).trim();

      // Split kwa lines
      final lines = csvString.split('\n');
      if (lines.isEmpty) return [];

      // Pata headers kutoka line ya kwanza
      final headerLine = lines[0].trim().replaceAll('\r', '');
      final headers = headerLine
          .split(',')
          .map((h) => h
              .trim()
              .toLowerCase()
              .replaceAll(' ', '')
              .replaceAll('_', '')
              .replaceAll('-', '')
              .replaceAll('"', ''))
          .toList();

      // Debug — angalia headers
      debugPrint('CSV Headers found: $headers');

      // Pata index za columns
      int fullNameIdx = -1;
      int admissionIdx = -1;
      int emailIdx = -1;

      for (var i = 0; i < headers.length; i++) {
        final h = headers[i];
        // Full Name
        if (h.contains('full') ||
            h.contains('name') ||
            h.contains('jina') ||
            h == 'fullname') {
          fullNameIdx = i;
        }
        // Admission Number
        if (h.contains('admission') ||
            h.contains('adm') ||
            h.contains('namba') ||
            h.contains('reg') ||
            (h.contains('number') && h.contains('adm'))) {
          admissionIdx = i;
        }
        // Email
        if (h.contains('email') || h.contains('mail') || h.contains('barua')) {
          emailIdx = i;
        }
      }

      debugPrint(
          'Indexes — name:$fullNameIdx adm:$admissionIdx email:$emailIdx');

      if (fullNameIdx == -1 || admissionIdx == -1) {
        debugPrint('Required columns not found!');
        return [];
      }

      // Soma data rows
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;

        // Split kwa comma — handle quoted values
        final cells = _splitCsvLine(line);
        if (cells.length <= admissionIdx) continue;

        final fullName = fullNameIdx < cells.length
            ? cells[fullNameIdx].trim().replaceAll('"', '')
            : '';
        final admissionNumber = admissionIdx < cells.length
            ? cells[admissionIdx].trim().replaceAll('"', '')
            : '';

        if (fullName.isEmpty || admissionNumber.isEmpty) continue;

        final voter = {
          'fullName': fullName,
          'admissionNumber': admissionNumber,
        };

        if (emailIdx != -1 && emailIdx < cells.length) {
          voter['email'] = cells[emailIdx].trim().replaceAll('"', '');
        }

        voters.add(voter);
        if (voters.length >= 10000) break;
      }

      debugPrint('Total voters parsed: ${voters.length}');
    } catch (e) {
      debugPrint('CSV Parse error: $e');
    }

    return voters;
  }

  // Helper — Split CSV line vizuri
  List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        cells.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    cells.add(current.toString());
    return cells;
  }

  int _findColumnIndex(List<String> headers, List<String> possible) {
    for (var i = 0; i < headers.length; i++) {
      // Safisha header — lowercase, ondoa spaces na underscores
      final header = headers[i]
          .toLowerCase()
          .trim()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('-', '');

      for (var p in possible) {
        final check = p
            .toLowerCase()
            .trim()
            .replaceAll(' ', '')
            .replaceAll('_', '')
            .replaceAll('-', '');

        if (header == check ||
            header.contains(check) ||
            check.contains(header)) {
          return i;
        }
      }
    }
    return -1;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF1565C0)),
            const SizedBox(width: 16),
            Text(message, style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }

  void _showImportPreviewDialog(List<Map<String, String>> voters) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Thibitisha Import',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people,
                        color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Wapiga kura ${voters.length} wamepatikana',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Preview ya watu 5 wa kwanza
              Text(
                'Mfano wa data (watu 5 wa kwanza):',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount:
                      voters.length > 5 ? 5 : voters.length,
                  itemBuilder: (context, index) {
                    final voter = voters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                const Color(0xFF1565C0),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(voter['fullName'] ?? '',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600)),
                                Text(
                                    'Adm: ${voter['admissionNumber'] ?? ''}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (voters.length > 5)
                Text(
                  '... na wengine ${voters.length - 5} zaidi',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ghairi', style: GoogleFonts.poppins()),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _importVoters(voters);
            },
            icon: const Icon(Icons.upload),
            label: Text('Ingiza Wote ${voters.length}',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importVoters(
      List<Map<String, String>> voters) async {
    _showLoadingDialog(
        'Inaingiza wapiga kura ${voters.length}...');
 
    try {
      // Tuma WOTE mara moja — haraka zaidi!
      final result = await ApiService.bulkImportVoters(voters);
      
      if (!mounted) return;
      Navigator.pop(context); // Funga loading
 
      final imported = (result['imported'] ?? 0) as int;
      final errors = result['errors'] != null
          ? List<String>.from(result['errors'] as List)
          : <String>[];
 
      // Onyesha matokeo
      _showImportResultDialog(imported, errors);
      _loadVoters();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hitilafu: ${e.toString()}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showImportResultDialog(
      int imported, List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Matokeo ya Import',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$imported Wameingizwa!',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green),
                      ),
                      Text('Wapiga kura wapya wameongezwa',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ],
              ),
            ),

            // Errors kama zipo
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${errors.length} hawakuingizwa:',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        itemCount: errors.length > 5
                            ? 5
                            : errors.length,
                        itemBuilder: (context, index) => Text(
                          '• ${errors[index]}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade700),
                        ),
                      ),
                    ),
                    if (errors.length > 5)
                      Text('... na ${errors.length - 5} zaidi',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: Text('Sawa!', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // ADD SINGLE VOTER
  // ═══════════════════════════════
  void _showAddVoterDialog() {
    final fullNameController = TextEditingController();
    final admissionController = TextEditingController();
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Ongeza Mpiga Kura',
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(fullNameController, 'Jina Kamili *',
                    Icons.person),
                const SizedBox(height: 10),
                _buildTextField(admissionController,
                    'Admission Number *', Icons.numbers),
                const SizedBox(height: 10),
                _buildTextField(emailController,
                    'Barua Pepe (Optional)', Icons.email),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Username: Admission Number\nPassword: Jina la kwanza + 123',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.blue.shade700),
                        ),
                      ),
                    ],
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
                      if (fullNameController.text.isEmpty ||
                          admissionController.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Jaza fields za lazima (*)',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final result = await ApiService.addVoter({
                          'fullName': fullNameController.text,
                          'admissionNumber':
                              admissionController.text,
                          'email': emailController.text,
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        final password = result['password']?.toString();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                            password != null
                                ? 'Mpiga kura ameongezwa! Password: $password'
                                : 'Mpiga kura ameongezwa!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ));
                        _loadVoters();
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Imeshindwa kuongeza.',
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
                  : Text('Ongeza', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
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
          'Wapiga Kura (${_voters.length})',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Bulk Import Button
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            tooltip: 'Bulk Import',
            onPressed: _showBulkImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            tooltip: 'Tuma Credentials kwa Wote',
            onPressed: _voters.isEmpty ? null : _sendCredentialsToAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Futa Wote',
            onPressed: _voters.isEmpty ? null : _deleteAllVoters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadVoters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVoterDialog,
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Tafuta kwa jina, username, au admission number...',
                hintStyle:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF1565C0)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF1565C0), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Stats Bar
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'Matokeo: ${_filteredVoters.length} kati ya ${_voters.length}'
                        : 'Jumla: ${_voters.length} wapiga kura',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Voters List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1565C0)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadVoters,
                              child: Text('Jaribu Tena',
                                  style: GoogleFonts.poppins()),
                            ),
                          ],
                        ),
                      )
                    : _filteredVoters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchController.text.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.people_outline,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Hakuna matokeo ya "${_searchController.text}"'
                                      : 'Hakuna wapiga kura bado',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadVoters,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  12, 12, 12, 100),
                              itemCount: _filteredVoters.length,
                              itemBuilder: (context, index) {
                                final voter = _filteredVoters[index];
                                final name =
                                    voter['fullName'] ?? 'Hajulikani';
                                final username =
                                    voter['username'] ?? '';
                                final admission =
                                    voter['admissionNumber'] ??
                                        'Haijawekwa';
                                final id = voter['id'] as int?;

                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
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
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            const Color(0xFF1565C0),
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style:
                                                    GoogleFonts.poppins(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14,
                                                )),
                                            Text(
                                              'Adm: $admission',
                                              style:
                                                  GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text('@$username',
                                                style:
                                                    GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                )),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: id != null
                                            ? () =>
                                                _deleteVoter(id, name)
                                            : null,
                                      ),
                                    ],
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
}