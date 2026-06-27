import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class AdminForgotPasswordRequestsScreen extends StatefulWidget {
  const AdminForgotPasswordRequestsScreen({super.key});

  @override
  State<AdminForgotPasswordRequestsScreen> createState() =>
      _AdminForgotPasswordRequestsScreenState();
}

class _AdminForgotPasswordRequestsScreenState
    extends State<AdminForgotPasswordRequestsScreen> {
  List<Map<String, dynamic>> _emails = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    setState(() => _isLoading = true);
    try {
      final emails = await ApiService.getForgotPasswordEmails();
      setState(() {
        _emails = emails.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showEmailDetails(Map<String, dynamic> email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          email['type'] == 'security_question'
              ? 'Security Question Request'
              : 'Password Reset Confirmation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Email:', email['email']?.toString() ?? ''),
              _buildInfoRow('Username:', email['username']?.toString() ?? ''),
              if (email['type'] == 'security_question')
                _buildInfoRow('Question:', email['question']?.toString() ?? ''),
              if (email['newPassword'] != null)
                _buildInfoRow('New Password:', email['newPassword']?.toString() ?? ''),
              _buildInfoRow('Sent:', email['sent'] == true ? '✅ Yes' : '❌ No'),
              _buildInfoRow(
                  'Date:', email['sentAt']?.toString().split('T').first ?? ''),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text('Email Body:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email['body']?.toString() ?? '',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
              if (email['error'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Error: ${email['error']}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (email['type'] == 'security_question')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAnswerDialog(email);
              },
              icon: const Icon(Icons.reply),
              label: Text('Answer Question', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Funga', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showAnswerDialog(Map<String, dynamic> email) {
    final answerController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Process Password Reset',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Text(
                      'User: ${email['username']}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Question: ${email['question']}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: InputDecoration(
                  labelText: 'Security Answer',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  hintText: 'Enter the voter\'s security answer',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Verify the answer with the voter, then submit. New password will be auto-generated and sent to their email.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
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
                      if (answerController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Enter the security answer!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final result =
                            await ApiService.resetPasswordWithSecurityAnswer(
                          email['username'],
                          answerController.text.trim(),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            result['message'] ??
                                'Password reset successful.',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: result.containsKey('success')
                              ? Colors.green
                              : Colors.red,
                          duration: const Duration(seconds: 5),
                        ));
                        _loadEmails();
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed: $e',
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
                  : Text('Submit Answer', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12)),
          ),
        ],
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
          'Password Reset Requests',
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
            onPressed: _loadEmails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _emails.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No password reset requests yet',
                          style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _emails.length,
                  itemBuilder: (context, index) {
                    final email = _emails[index];
                    final isQuestion = email['type'] == 'security_question';
                    final sent = email['sent'] == true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isQuestion
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          child: Icon(
                            isQuestion ? Icons.help_outline : Icons.check_circle,
                            color: isQuestion ? Colors.orange : Colors.green,
                          ),
                        ),
                        title: Text(
                          email['username']?.toString() ?? 'Unknown',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email['email']?.toString() ?? '',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  sent ? Icons.check_circle : Icons.error,
                                  size: 14,
                                  color: sent ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sent ? 'Email Sent' : 'Failed to Send',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: sent ? Colors.green : Colors.red),
                                ),
                                const Spacer(),
                                Text(
                                  email['sentAt']
                                          ?.toString()
                                          .split('T')
                                          .first ??
                                      '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showEmailDetails(email),
                      ),
                    );
                  },
                ),
    );
  }
}
