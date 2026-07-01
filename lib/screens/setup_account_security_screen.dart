import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_security_service.dart';
import 'admin_dashboard_screen.dart';
import 'voter_dashboard_screen.dart';

class SetupAccountSecurityScreen extends StatefulWidget {
  final String? currentPassword;

  const SetupAccountSecurityScreen({super.key, this.currentPassword});

  @override
  State<SetupAccountSecurityScreen> createState() => _SetupAccountSecurityScreenState();
}

class _SetupAccountSecurityScreenState extends State<SetupAccountSecurityScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _answerController = TextEditingController();

  String? _selectedQuestion;

  // CAPTCHA state
  int _a = 0;
  int _b = 0;
  int get _captchaSum => _a + _b;
  final _captchaController = TextEditingController();
  bool _captchaChecked = false;

  bool _isLoading = false;
  final _currentPasswordController = TextEditingController();

  final List<String> _questions = const [
    'What was your first school?',
    'What is the name of your first pet?',
    'What was your favorite book?',
    'What city were you born in?',
  ];

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
  }

  void _refreshCaptcha() {
    setState(() {
      _a = (DateTime.now().millisecondsSinceEpoch % 20) + 1;
      _b = ((DateTime.now().millisecondsSinceEpoch ~/ 3) % 20) + 1;
      _captchaChecked = false;
      _captchaController.clear();
    });
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _submit() async {
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final answer = _answerController.text;
    final captchaText = _captchaController.text.trim();

    if (newPass.isEmpty || confirm.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jaza fields zote.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password mpya hazilingani.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password lazima iwe na herufi 6+.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chagua swali la siri.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_captchaChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tafadhali thibitisha 'Mimi si robot'.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final captchaVal = int.tryParse(captchaText);
    if (captchaVal == null || captchaVal != _captchaSum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CAPTCHA si sahihi.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final answerHash = _sha256(answer.trim());

      // Ensure recent auth before updating the password.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Hujasajiliwa au umekataliwa.',
        );
      }

      try {
        await FirebaseAuthService.updatePassword(newPass);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final password = widget.currentPassword ?? await _requestCurrentPassword();
          if (password == null || password.isEmpty) {
            throw FirebaseAuthException(
              code: 'requires-recent-login',
              message: 'Lazima uingie tena ili kuendelea.',
            );
          }
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);
          await FirebaseAuthService.updatePassword(newPass);
        } else {
          rethrow;
        }
      }

      await UserSecurityService.saveSecurityData(
        securityQuestion: _selectedQuestion!,
        securityAnswerHash: answerHash,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usalama umewekwa kikamilifu!', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      final role = await FirebaseAuthService.getCurrentRole();
      if (!mounted) return;
      if (role == 'admin' || FirebaseAuth.instance.currentUser?.email == 'admin@test.com') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VoterDashboardScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving security data: ${e.toString()}',
            style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _requestCurrentPassword() async {
    _currentPasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Thibitisha Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lazima uweke password yako ya sasa ili kuthibitisha mabadiliko ya usalama.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password ya sasa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Ghairi', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, _currentPasswordController.text.trim());
            },
            child: Text('Thibitisha', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          'Setup Account Security',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tunaomba uweke usalama wa akaunti yako ili kuendelea.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text('Badilisha Password',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text('Security Question',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedQuestion,
                      items: _questions
                          .map((q) => DropdownMenuItem(
                                value: q,
                                child: Text(q),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedQuestion = v),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _answerController,
                      decoration: InputDecoration(
                        labelText: 'Security Answer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text('CAPTCHA',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Checkbox(
                          value: _captchaChecked,
                          onChanged: (v) => setState(() => _captchaChecked = v ?? false),
                        ),
                        Expanded(
                          child: Text(
                            "I’m not a robot",
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesabu: $_a + $_b = ?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _captchaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Jibu',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: _refreshCaptcha,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                'Refresh',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Hifadhi & Endelea',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
