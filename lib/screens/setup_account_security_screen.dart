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
    'What is your mother’s maiden name?',
    'What was the name of your first teacher?',
    'What was the make of your first car?',
    'What is the name of your favorite childhood friend?',
    'What was your first job?',
    'What is your favorite family vacation spot?',
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
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF4C7DDB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF4C7DDB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Setup Account Security',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Usalama wa akaunti yako ndio nguzo ya usalama wa uchaguzi. Weka password mpya, swali la siri, na thibitisha CAPTCHA.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _securityStep('1', 'Password'),
                            const SizedBox(width: 10),
                            _securityStep('2', 'Swali la siri'),
                            const SizedBox(width: 10),
                            _securityStep('3', 'CAPTCHA'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Badilisha Password',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF203354),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _newPasswordController,
                          label: 'Password Mpya',
                          hint: 'Weka password mpya yenye herufi 6+',
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Thibitisha Password',
                          hint: 'Andika password tena',
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '2. Chagua Swali la Siri',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF203354),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _selectedQuestion,
                          items: _questions
                              .map((q) => DropdownMenuItem(
                                    value: q,
                                    child: Text(
                                      q,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedQuestion = v),
                          decoration: InputDecoration(
                            hintText: 'Chagua swali la siri',
                            filled: true,
                            fillColor: const Color(0xFFF4F7FF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _answerController,
                          label: 'Jibu la Siri',
                          hint: 'Andika jibu lako la siri',
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '3. Thibitisha CAPTCHA',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF203354),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Checkbox(
                              value: _captchaChecked,
                              onChanged: (v) => setState(() => _captchaChecked = v ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              activeColor: const Color(0xFF1565C0),
                            ),
                            Expanded(
                              child: Text(
                                'Mimi si robot',
                                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF4A5368)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hesabu: $_a + $_b = ?',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF203354),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _captchaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Jibu',
                                  hintText: 'Andika jibu hapa',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _refreshCaptcha,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: Text(
                                    'Panga upya CAPTCHA',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1565C0),
                                    side: BorderSide(color: Colors.blue.shade100),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    'Hifadhi Usalama',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityStep(String step, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F7FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
