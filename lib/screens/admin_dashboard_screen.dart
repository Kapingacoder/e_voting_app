import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
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
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadMessages = count);
      }
    } catch (e) {
      // ignore
    }
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
              await ApiService.deleteToken();
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
                            fontWeight: FontWeight.bold),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 40),
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
              'Anza, simamisha, panga uchaguzi',
              const Color(0xFF1565C0),
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminElectionScreen())),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              Icons.people,
              'Wapiga Kura',
              'Ongeza, hariri, futa wapiga kura',
              Colors.green,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminVotersScreen())),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              Icons.person_pin,
              'Wagombea',
              'Simamia wagombea wa uchaguzi',
              Colors.orange,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminCandidatesScreen())),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              Icons.bar_chart,
              'Matokeo',
              'Angalia matokeo ya uchaguzi',
              Colors.purple,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminResultsScreen())),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              Icons.notifications_active,
              'Tuma Arifa (Push)',
              'Tuma taarifa za papo hapo kwa simu',
              Colors.pink,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminNotificationsScreen())),
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
              Icons.message,
              'Ujumbe wa Voters',
              'Soma ujumbe kutoka kwa wapiga kura',
              Colors.teal,
              () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminMessagesScreen()));
                _loadUnreadCount();
              },
              badge: _unreadMessages > 0 ? _unreadMessages : null,
            ),
            const SizedBox(height: 30),

            // Kitufe cha Toka
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}