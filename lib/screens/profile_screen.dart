import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Mtumiaji hajasajiliwa.';
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _profileData = snapshot.data();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Badilisha Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(labelText: 'Password ya Sasa', labelStyle: GoogleFonts.poppins(fontSize: 13), prefixIcon: const Icon(Icons.lock_outline, size: 20), suffixIcon: IconButton(icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(labelText: 'Password Mpya', labelStyle: GoogleFonts.poppins(fontSize: 13), prefixIcon: const Icon(Icons.lock, size: 20), suffixIcon: IconButton(icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setDialogState(() => obscureNew = !obscureNew)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(labelText: 'Thibitisha Password Mpya', labelStyle: GoogleFonts.poppins(fontSize: 13), prefixIcon: const Icon(Icons.lock_clock, size: 20), suffixIcon: IconButton(icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Ghairi', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (currentPasswordController.text.isEmpty || newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jaza fields zote!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password mpya hazilingani!', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                        return;
                      }
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password lazima iwe na herufi 6+!', style: GoogleFonts.poppins()), backgroundColor: Colors.orange));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.email == null) {
                          throw Exception('Mtumiaji hajasajiliwa.');
                        }
                        final credential = EmailAuthProvider.credential(email: user.email!, password: currentPasswordController.text);
                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPasswordController.text);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password imebadilishwa!', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
                      } catch (_) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imeshindwa kubadilisha password.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Badilisha', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Toka', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kutoka?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hapana', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Ndiyo, Toka', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF1565C0), size: 20)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)), const SizedBox(height: 4), Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600))]))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16), Text(_error!, style: GoogleFonts.poppins()), const SizedBox(height: 16), ElevatedButton(onPressed: _loadProfile, child: Text('Jaribu Tena', style: GoogleFonts.poppins()))]));
    }

    final fullName = _profileData?['fullName'] as String? ?? '';
    final username = _profileData?['username'] as String? ?? '';
    final admissionNumber = _profileData?['admissionNumber'] as String? ?? '';
    final email = _profileData?['email'] as String? ?? '';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [CircleAvatar(radius: 45, backgroundColor: Colors.white.withOpacity(0.2), child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))), const SizedBox(height: 12), Text(fullName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('🗳️ Mpiga Kura', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13))) ]),
            ),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Text('Taarifa Zangu', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
            const SizedBox(height: 12),
            _infoCard(Icons.person_outline, 'Jina Kamili', fullName),
            const SizedBox(height: 8),
            _infoCard(Icons.badge_outlined, 'Username', username),
            const SizedBox(height: 8),
            _infoCard(Icons.numbers, 'Admission Number', admissionNumber.isNotEmpty ? admissionNumber : 'Haijawekwa'),
            const SizedBox(height: 8),
            _infoCard(Icons.email_outlined, 'Barua Pepe', email.isNotEmpty ? email : 'Haijawekwa'),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Text('Vitendo', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: _showChangePasswordDialog, icon: const Icon(Icons.lock_outline), label: Text('Badilisha Password', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1565C0), side: const BorderSide(color: Color(0xFF1565C0), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: Text('Toka (Logout)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
