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
      final fullNameIdx = _findColumnIndex(
          headers, ['fullname', 'full_name', 'name', 'jina']);
      final admissionIdx = _findColumnIndex(headers, [
        'admissionnumber',
        'admission_number',
        'admission',
        'adm',
        'nambari'
      ]);
      final emailIdx = _findColumnIndex(
          headers, ['email', 'barua', 'barua_pepe']);

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

  Future<List<Map<String, String>>> _parseCsv(
      List<int> bytes) async {
    final csvString = String.fromCharCodes(bytes);
    final List<List<dynamic>> rows =
        const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) return [];

    final List<Map<String, String>> voters = [];

    // Headers kutoka row ya kwanza
    final headers = rows[0]
        .map((h) => h.toString().toLowerCase().trim())
        .toList();

    final fullNameIdx = _findColumnIndex(
        headers, ['fullname', 'full_name', 'name', 'jina']);
    final admissionIdx = _findColumnIndex(headers, [
      'admissionnumber',
      'admission_number',
      'admission',
      'adm',
      'nambari'
    ]);
    final emailIdx =
        _findColumnIndex(headers, ['email', 'barua', 'barua_pepe']);

    if (fullNameIdx == -1 || admissionIdx == -1) return [];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final fullName =
          row.length > fullNameIdx ? row[fullNameIdx].toString().trim() : '';
      final admissionNumber = row.length > admissionIdx
          ? row[admissionIdx].toString().trim()
          : '';

      if (fullName.isEmpty || admissionNumber.isEmpty) continue;

      final voter = {
        'fullName': fullName,
        'admissionNumber': admissionNumber,
      };

      if (emailIdx != -1 && emailIdx < row.length) {
        voter['email'] = row[emailIdx].toString().trim();
      }

      voters.add(voter);
      if (voters.length >= 10000) break;
    }

    return voters;
  }

  int _findColumnIndex(List<String> headers, List<String> possible) {
    for (var p in possible) {
      final idx = headers.indexOf(p);
      if (idx != -1) return idx;
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
      // Import kwa batch za 100 kwa kasi
      int totalImported = 0;
      List<String> allErrors = [];
      const batchSize = 100;

      for (var i = 0; i < voters.length; i += batchSize) {
        final batch = voters.sublist(
          i,
          i + batchSize > voters.length ? voters.length : i + batchSize,
        );

        final result = await ApiService.bulkImportVoters(batch);
        totalImported += (result['imported'] ?? 0) as int;

        if (result['errors'] != null) {
          allErrors.addAll(
              List<String>.from(result['errors'] as List));
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Funga loading

      // Onyesha matokeo
      _showImportResultDialog(totalImported, allErrors);
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
                        await ApiService.addVoter({
                          'fullName': fullNameController.text,
                          'admissionNumber':
                              admissionController.text,
                          'email': emailController.text,
                        });
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Mpiga kura ameongezwa!',
                              style: GoogleFonts.poppins()),
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