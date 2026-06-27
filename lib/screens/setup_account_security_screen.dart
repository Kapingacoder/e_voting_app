import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'voter_dashboard_screen.dart';

class SetupAccountSecurityScreen extends StatefulWidget {
  final String username;

  const SetupAccountSecurityScreen({super.key, required this.username});

  @override
  State<SetupAccountSecurityScreen> createState() => _SetupAccountSecurityScreenState();
}

class _SetupAccountSecurityScreenState extends State<SetupAccountSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _answerController = TextEditingController();

  List<Map<String, String>> _questions = [];
  String? _selectedQuestionId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await ApiService.getSecurityQuestions();
    if (mounted) {
      setState(() {
        _questions = questions;
        if (_questions.isNotEmpty) {
          _selectedQuestionId = _questions.first['id'];
        }
      });
    }
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestionId == null) {
      setState(() {
        _errorMessage = 'Chagua swali la usalama.';
      });
      return;
    }

    final selectedQuestion = _questions.firstWhere(
      (item) => item['id'] == _selectedQuestionId,
      orElse: () => <String, String>{},
    );
    final questionText = selectedQuestion['text'] ?? '';
    if (questionText.isEmpty) {
      setState(() {
        _errorMessage = 'Swali lililochaguliwa halipatikani.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.completeFirstTimeSetup(
      widget.username,
      _passwordController.text.trim(),
      questionText,
      _answerController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result.containsKey('error')) {
      setState(() {
        _errorMessage = result['error']?.toString();
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VoterDashboardScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message']?.toString() ?? 'Akaunti imewekwa.',
          style: GoogleFonts.poppins()),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Account Security'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Karibu ${widget.username}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kwa mara ya kwanza kuingia, badili password yako na weka swali/jibu la usalama. Hii itamuwezesha kurejesha password baadaye.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Mpya',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weka password mpya';
                    }
                    if (value.trim().length < 6) {
                      return 'Password inapaswa kuwa angalau herufi 6';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Thibitisha Password Mpya',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Thibitisha password';
                    }
                    if (value.trim() != _passwordController.text.trim()) {
                      return 'Password hazifanani';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedQuestionId,
                  decoration: InputDecoration(
                    labelText: 'Swali la Usalama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _questions.map((question) {
                    return DropdownMenuItem<String>(
                      value: question['id'],
                      child: Text(question['text'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedQuestionId = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Chagua swali la usalama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Jibu la Swali la Usalama',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weka jibu la swali la usalama';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSetup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1565C0),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Hifadhi Usalama',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
