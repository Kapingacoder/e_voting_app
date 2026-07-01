import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_currentUser == null) {
      setState(() {
        _error = 'Mtumiaji hajasajiliwa.';
        _isLoading = false;
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (!mounted) return;
      setState(() {
        _profileData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia wasifu.';
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Badilisha Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  currentController,
                  'Password ya Sasa',
                  Icons.lock_outline,
                  obscureCurrent,
                  () => setDialogState(
                      () => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  newController,
                  'Password Mpya',
                  Icons.lock,
                  obscureNew,
                  () => setDialogState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  confirmController,
                  'Thibitisha Password Mpya',
                  Icons.lock_clock,
                  obscureConfirm,
                  () => setDialogState(
                      () => obscureConfirm = !obscureConfirm),
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
                      if (currentController.text.isEmpty ||
                          newController.text.isEmpty ||
                          confirmController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Jaza fields zote!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      if (newController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Password mpya hazilingani!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      if (newController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Password lazima iwe na herufi 6+!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        if (_currentUser == null) {
                          throw Exception("Mtumiaji hajasajiliwa.");
                        }

                        // Re-authenticate for security
                        AuthCredential credential = EmailAuthProvider.credential(
                            email: _currentUser!.email!,
                            password: currentController.text);
                        await _currentUser!
                            .reauthenticateWithCredential(credential);

                        // Change password in Firebase Auth
                        await _currentUser!.updatePassword(newController.text);

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Password imebadilishwa!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ));
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              e is FirebaseAuthException
                                  ? 'Password ya sasa si sahihi.'
                                  : 'Imeshindwa kubadilisha password.',
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
                  : Text('Badilisha', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeUsernameDialog() {
    final usernameController = TextEditingController(
        text: _profileData?['username'] ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Badilisha Username',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Username Mpya',
              labelStyle: GoogleFonts.poppins(fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
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
                      if (usernameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Weka username mpya!',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange,
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        if (_currentUser == null) {
                          throw Exception("Mtumiaji hajasajiliwa.");
                        }
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentUser!.uid)
                            .update({'username': usernameController.text});

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Username imebadilishwa!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                        ));
                        _loadProfile(); // Refresh profile data
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Imeshindwa kubadilisha username.',
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
                  : Text('Badilisha', style: GoogleFonts.poppins()),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Toka',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kutoka?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hapana', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Ndiyo, Toka', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String label,
      IconData icon, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              size: 20),
          onPressed: onToggle,
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade500)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color,
      VoidCallback onTap,
      {bool outlined = false}) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label,
              style:
                  GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child:
                CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.poppins()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: Text('Jaribu Tena', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _profileData?['fullName'] ?? 'Admin';
    final username = _profileData?['username'] ?? '';
    final email = _currentUser?.email ?? _profileData?['email'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('Profile ya Admin',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        fullName.isNotEmpty
                            ? fullName[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(fullName,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('⚙️ Administrator',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Taarifa
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Taarifa za Akaunti',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 12),
              _infoCard(
                  Icons.person_outline, 'Jina Kamili', fullName),
              const SizedBox(height: 8),
              _infoCard(
                  Icons.account_circle_outlined, 'Username', username),
              const SizedBox(height: 8),
              _infoCard(
                  Icons.email_outlined,
                  'Barua Pepe',
                  email.isNotEmpty ? email : 'Haijawekwa'),
              const SizedBox(height: 24),

              // Vitendo
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Mabadiliko ya Akaunti',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 12),
              _actionButton(
                'Badilisha Username',
                Icons.person_outline,
                const Color(0xFF1565C0),
                _showChangeUsernameDialog,
                outlined: true,
              ),
              const SizedBox(height: 10),
              _actionButton(
                'Badilisha Password',
                Icons.lock_outline,
                Colors.orange,
                _showChangePasswordDialog,
                outlined: true,
              ),
              const SizedBox(height: 10),
              _actionButton(
                'Toka (Logout)',
                Icons.logout,
                Colors.red,
                _logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}