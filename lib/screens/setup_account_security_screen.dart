import 'dart:math';
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
  final _captchaAnswerController = TextEditingController();

  List<Map<String, String>> _questions = [];
  String? _selectedQuestionId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNotRobot = false;
  
  // Captcha variables
  late int _num1;
  late int _num2;
  late int _correctAnswer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();
    _num1 = random.nextInt(10) + 1; // 1-10
    _num2 = random.nextInt(10) + 1; // 1-10
    _correctAnswer = _num1 + _num2;
  }

  void _regenerateCaptcha() {
    setState(() {
      _generateCaptcha();
      _captchaAnswerController.clear();
    });
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
    
    // Validate checkbox
    if (!_isNotRobot) {
      setState(() {
        _errorMessage = 'Tafadhali thibitisha kwamba wewe si robot.';
      });
      return;
    }
    
    // Validate CAPTCHA
    final captchaAnswer = int.tryParse(_captchaAnswerController.text.trim());
    if (captchaAnswer == null || captchaAnswer != _correctAnswer) {
      setState(() {
        _errorMessage = 'Jibu la hesabu si sahihi. Jaribu tena.';
      });
      _regenerateCaptcha();
      return;
    }
    
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
                const SizedBox(height: 24),
                
                // CAPTCHA Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Uthibitisho wa Usalama',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // I'm not a robot checkbox
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isNotRobot ? Colors.green : Colors.grey.shade300,
                            width: _isNotRobot ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isNotRobot,
                              onChanged: (value) {
                                setState(() => _isNotRobot = value ?? false);
                              },
                              activeColor: Colors.green,
                            ),
                            Expanded(
                              child: Text(
                                'Mimi si robot',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.grey.shade400,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Math CAPTCHA
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tatua hesabu hii:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _regenerateCaptcha,
                                  tooltip: 'Pata hesabu mpya',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_num1 + $_num2 = ?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _captchaAnswerController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Jibu',
                                      hintStyle: GoogleFonts.poppins(fontSize: 13),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Weka jibu';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
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
