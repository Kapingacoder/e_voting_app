import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'admin_election_screen.dart';
import 'admin_voters_screen.dart';
import 'admin_candidates_screen.dart';
import 'admin_results_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
  }

  Future<Map<String, int>> _loadCounts() async {
    final firestore = FirebaseFirestore.instance;
    final usersSnapshot = await firestore.collection('users').get();
    final ticketsSnapshot = await firestore.collection('tickets').get();
    final electionsSnapshot = await firestore.collection('elections').get();
    final unreadSnapshot = await firestore.collection('messages').where('read', isEqualTo: false).get();

    return {
      'users': usersSnapshot.size,
      'tickets': ticketsSnapshot.size,
      'elections': electionsSnapshot.size,
      'unreadMessages': unreadSnapshot.size,
    };
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Toka', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Una uhakika unataka kutoka?', style: GoogleFonts.poppins()),
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

  Widget _buildMenuCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap, {int? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
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
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            ),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _countsFuture,
        builder: (context, snapshot) {
          final counts = snapshot.data ?? {};
          final userCount = counts['users'] ?? 0;
          final ticketsCount = counts['tickets'] ?? 0;
          final electionsCount = counts['elections'] ?? 0;
          final unreadCount = counts['unreadMessages'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Karibu Admin!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Usimamizi wa Mfumo wa E-Voting',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Menyu ya Usimamizi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuCard(
                  Icons.how_to_vote,
                  'Usimamizi wa Uchaguzi',
                  electionsCount > 0 ? 'Uchaguzi umewekwa' : 'Hakuna uchaguzi',
                  const Color(0xFF1565C0),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminElectionScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  Icons.people,
                  'Wapiga Kura',
                  'Wapiga kura: $userCount',
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVotersScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  Icons.person_pin,
                  'Wagombea',
                  'Tickets: $ticketsCount',
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCandidatesScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  Icons.bar_chart,
                  'Matokeo',
                  'Matokeo ya uchaguzi',
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminResultsScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  Icons.notifications_active,
                  'Tuma Arifa',
                  'Tuma taarifa kwa watumiaji',
                  Colors.pink,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen())),
                ),
                const SizedBox(height: 10),
                _buildMenuCard(
                  Icons.message,
                  'Ujumbe wa Voters',
                  'Ujumbe zisizosomewa: $unreadCount',
                  Colors.teal,
                  () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMessagesScreen()));
                    if (mounted) {
                      setState(() {
                        _countsFuture = _loadCounts();
                      });
                    }
                  },
                  badge: unreadCount > 0 ? unreadCount : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      'Toka (Logout)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
