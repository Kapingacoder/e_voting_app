import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';
import '../services/api_service.dart';

class ResetPasswordWebPage extends StatefulWidget {
  final String? encodedData;

  const ResetPasswordWebPage({super.key, this.encodedData});

  @override
  State<ResetPasswordWebPage> createState() => _ResetPasswordWebPageState();
}

class _ResetPasswordWebPageState extends State<ResetPasswordWebPage> {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLoading = false;
  bool _isNotRobot = false;
  String? _errorMessage;
  String? _successMessage;

  // Decoded voter data
  String? _admissionNumber;
  String? _securityQuestion;
  String? _voterEmail;
  String? _voterName;

  // CAPTCHA
  late int _num1;
  late int _num2;
  late int _correctAnswer;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _decodeData();
  }

  void _generateCaptcha() {
    final random = Random();
    _num1 = random.nextInt(10) + 1;
    _num2 = random.nextInt(10) + 1;
    _correctAnswer = _num1 + _num2;
  }

  void _regenerateCaptcha() {
    setState(() {
      _generateCaptcha();
      _captchaController.clear();
    });
  }

  Future<void> _decodeData() async {
    if (widget.encodedData == null || widget.encodedData!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid reset link. Please request a new password reset.';
      });
      return;
    }

    try {
      // Decode base64
      final decoded = utf8.decode(base64Url.decode(widget.encodedData!));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      // Verify timestamp (link valid for 1 hour)
      final timestamp = data['timestamp'] as int?;
      if (timestamp == null) {
        throw Exception('Invalid link format');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final hourInMs = 60 * 60 * 1000;
      if (now - timestamp > hourInMs) {
        setState(() {
          _errorMessage = 'This reset link has expired. Please request a new one.';
        });
        return;
      }

      setState(() {
        _admissionNumber = data['admission']?.toString();
        _securityQuestion = data['question']?.toString();
        _voterEmail = data['email']?.toString();
        _voterName = data['name']?.toString();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid or corrupted reset link. Please request a new one.';
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate checkbox
    if (!_isNotRobot) {
      setState(() {
        _errorMessage = 'Please confirm that you are not a robot.';
      });
      return;
    }

    // Validate CAPTCHA
    final captchaAnswer = int.tryParse(_captchaController.text.trim());
    if (captchaAnswer == null || captchaAnswer != _correctAnswer) {
      setState(() {
        _errorMessage = 'Incorrect math answer. Please try again.';
      });
      _regenerateCaptcha();
      return;
    }

    if (_admissionNumber == null) {
      setState(() {
        _errorMessage = 'Invalid session. Please request a new reset link.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Use existing API service to reset password
      final result = await ApiService.resetPasswordWithSecurityAnswer(
        _admissionNumber!,
        _answerController.text.trim(),
      );

      if (!mounted) return;

      if (result.containsKey('success') && result['success'] == true) {
        setState(() {
          _isLoading = false;
          _successMessage = result['message']?.toString() ??
              'Password reset successful! Check your email for the new password.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error']?.toString() ??
              'Security answer is incorrect. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _errorMessage != null && _admissionNumber == null
                ? _buildErrorView()
                : _successMessage != null
                    ? _buildSuccessView()
                    : _buildFormView(isSmallScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 80, color: Colors.red),
        const SizedBox(height: 24),
        Text(
          'Invalid Link',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Something went wrong',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Please open the E-Voting app and request a new password reset.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Password Reset Successful!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _successMessage ?? 'Your password has been reset successfully.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.email, color: Colors.blue.shade700, size: 40),
              const SizedBox(height: 12),
              Text(
                'Check Your Email',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ve sent your new password to: $_voterEmail',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'You can now close this page and login to the E-Voting app with your new password.',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormView(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reset Password',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                if (_voterName != null)
                  Text(
                    'Welcome, $_voterName',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Security Question
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Security Question',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _securityQuestion ?? 'Loading...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Answer Field
          TextFormField(
            controller: _answerController,
            decoration: InputDecoration(
              labelText: 'Your Answer',
              labelStyle: GoogleFonts.poppins(fontSize: 14),
              hintText: 'Enter your security answer',
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your answer';
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
                      'Security Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Checkbox
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
                          'I\'m not a robot',
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
                              'Solve this:',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _regenerateCaptcha,
                            tooltip: 'Get new question',
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
                              controller: _captchaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Answer',
                                hintStyle: GoogleFonts.poppins(fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
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
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAnswer,
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
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _captchaController.dispose();
    super.dispose();
  }
}
