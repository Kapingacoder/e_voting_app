import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'voter_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(
          () => _errorMessage = 'Jaza admission number na password');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      if (result.containsKey('token')) {
        await ApiService.saveToken(result['token']);
        await ApiService.saveUserInfo(
          result['fullName'] ?? '',
          result['role'] ?? '',
        );
        if (!mounted) return;
        final role = result['role'] ?? '';
        if (role == 'ADMIN') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(
                  builder: (_) => const VoterDashboardScreen()));
        }
      } else {
        setState(() {
          _errorMessage =
              result['error'] ?? 'Login imeshindwa. Jaribu tena.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Hakuna connection na server. Angalia internet yako.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final admissionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Umesahau Password?',
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.blue.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Weka admission number yako — password itumwe kwa email yako.',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: admissionController,
                decoration: InputDecoration(
                  labelText: 'Admission Number',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.numbers, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
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
                      if (admissionController.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              'Weka admission number!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final result =
                            await ApiService.forgotPassword(
                                admissionController.text.trim());
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                            result['message'] ??
                                'Password imetumwa kwa email yako!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 4),
                        ));
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              'Imeshindwa. Jaribu tena.',
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
                  : Text('Tuma Password',
                      style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportMessageDialog() {
    final admissionController = TextEditingController();
    final messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.support_agent,
                  color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text('Wasiliana na Admin',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange.shade200)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ujumbe wako utaonekana kwa admin. Taja tatizo lako wazi.',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: admissionController,
                  decoration: InputDecoration(
                    labelText: 'Admission Number Yako',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.numbers, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Ujumbe Wako *',
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    hintText:
                        'Eleza tatizo lako hapa...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.message_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
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
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (admissionController.text.isEmpty ||
                          messageController.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text('Jaza fields zote!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final result =
                            await ApiService.sendSupportMessage(
                          admissionController.text.trim(),
                          messageController.text.trim(),
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                            result['message'] ??
                                'Ujumbe wako umetumwa kwa admin!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ));
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              'Imeshindwa kutuma. Jaribu tena.',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
              icon: const Icon(Icons.send),
              label: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Tuma Ujumbe',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.how_to_vote,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('E-Voting',
                  style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Ingia kwenye akaunti yako',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 40),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: GoogleFonts.poppins(
                                      color: Colors.red.shade700,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    // Admission Number
                    Text('Admission Number',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Weka admission number yako',
                        prefixIcon:
                            const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text('Password',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Weka password yako',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero),
                        child: Text('Umesahau Password?',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF1565C0),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('Ingia',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Support Message Button
              GestureDetector(
                onTap: _showSupportMessageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.support_agent,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Wasiliana na Admin',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}