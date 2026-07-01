import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'voting_screen.dart';
import 'results_screen.dart';
import 'profile_screen.dart';
import '../widgets/election_countdown.dart';

class VoterDashboardScreen extends StatefulWidget {
  const VoterDashboardScreen({super.key});

  @override
  State<VoterDashboardScreen> createState() => _VoterDashboardScreenState();
}

class _VoterDashboardScreenState extends State<VoterDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _fetchDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is Exception
            ? e.toString()
            : 'Imeshindwa kupakia data. Angalia connection yako.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Toka', style: GoogleFonts.poppins()),
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

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) {
      throw Exception('Mwanzilishi hajalogini. Ingia tena.');
    }

    final admissionNumber = currentUser.email!.split('@').first;
    final voterRef = FirebaseFirestore.instance.collection('voters').doc(admissionNumber);
    final voterSnapshot = await voterRef.get();
    if (!voterSnapshot.exists) {
      throw Exception('Mpiga kura hakupatikana katika mfumo wetu.');
    }

    final userData = voterSnapshot.data() ?? {};
    final user = {
      'fullName': userData['fullName'] ?? currentUser.displayName ?? '',
      'admissionNumber': userData['admissionNumber'] ?? admissionNumber,
      'email': userData['email'] ?? currentUser.email,
      'username': userData['username'] ?? admissionNumber,
    };

    final electionSnapshot = await FirebaseFirestore.instance
        .collection('elections')
        .orderBy('votingOpen', descending: true)
        .limit(1)
        .get();

    Map<String, dynamic>? election;
    if (electionSnapshot.docs.isNotEmpty) {
      election = {'id': electionSnapshot.docs.first.id, ...electionSnapshot.docs.first.data()};
    }

    if (election == null) {
      final latestElectionSnapshot = await FirebaseFirestore.instance
          .collection('elections')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();
      if (latestElectionSnapshot.docs.isNotEmpty) {
        election = {'id': latestElectionSnapshot.docs.first.id, ...latestElectionSnapshot.docs.first.data()};
      }
    }

    final electionId = election?['electionId']?.toString() ?? election?['id']?.toString();
    final isVotingOpen = election?['votingOpen'] == true;

    final ticketsSnapshot = await FirebaseFirestore.instance.collection('tickets').get();
    final tickets = ticketsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    bool hasVoted = false;
    if (electionId != null && currentUser.uid.isNotEmpty) {
      final voteDoc = await FirebaseFirestore.instance
          .collection('election_votes')
          .doc('${electionId}_${currentUser.uid}')
          .get();
      hasVoted = voteDoc.exists;
    }

    return {
      'user': user,
      'election': election,
      'mostRecentElection': election,
      'isVotingOpen': isVotingOpen,
      'hasVoted': hasVoted,
      'tickets': tickets,
    };
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.poppins(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: Text('Jaribu Tena', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    }

    final user = _dashboardData?['user'] ?? {};
    final electionActive = _dashboardData?['isVotingOpen'] ?? false;
    final hasVoted = _dashboardData?['hasVoted'] ?? false;
    final tickets = _dashboardData?['tickets'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ya Karibu
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
                  Text(
                    'Karibu! 👋',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    user['fullName'] ?? 'Mpiga Kura',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adm: ${user['admissionNumber'] ?? ''}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElectionCountdown(
              startTime: _dashboardData?['election']?['startTime'] ??
                         _dashboardData?['mostRecentElection']?['startTime'],
              endTime: _dashboardData?['election']?['endTime'] ??
                       _dashboardData?['mostRecentElection']?['endTime'],
              isVotingOpen: electionActive,
            ),
            const SizedBox(height: 16),

            // Hali ya Uchaguzi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: electionActive
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: electionActive
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    electionActive ? Icons.how_to_vote : Icons.pending,
                    color: electionActive ? Colors.green : Colors.orange,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hali ya Uchaguzi',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        electionActive ? 'Unaendelea Sasa!' : 'Haujaanza Bado',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: electionActive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hali ya Kura Yako
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasVoted ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasVoted
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasVoted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: hasVoted ? Colors.blue : Colors.grey,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kura Yako',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        hasVoted ? 'Umeshapiga Kura ✓' : 'Bado Hujapiga Kura',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: hasVoted ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kitufe cha Piga Kura
            if (electionActive && !hasVoted)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VotingScreen(
                          candidates: tickets,
                          onVoted: _loadDashboard,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.how_to_vote),
                  label: Text(
                    'PIGA KURA SASA',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Wagombea
            Text(
              'Wagombea',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Hakuna wagombea bado',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
              )
            else
              ...tickets.map((ticket) {
                final ticketName = ticket['ticketName'] ?? ticket['name'] ?? '';
                final presidentName = ticket['presidentName'] ?? '';
                final presidentParty = ticket['presidentParty'] ?? '';
                final vpName = ticket['vicePresidentName'] ?? '';
                final vpParty = ticket['vicePresidentParty'] ?? '';
                final presidentPhoto = ticket['presidentPhotoUrl'] ?? '';
                final vpPhoto = ticket['vicePresidentPhotoUrl'] ?? '';
            
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header ya Ticket
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.how_to_vote,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ticketName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            
                      // Rais na Makamu
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Rais
                            Expanded(
                              child: _candidateInfoCard(
                                '🏅 Rais',
                                presidentName,
                                presidentParty,
                                presidentPhoto,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Makamu
                            Expanded(
                              child: _candidateInfoCard(
                                '🥈 Makamu',
                                vpName,
                                vpParty,
                                vpPhoto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _candidateInfoCard(
      String role, String name, String party, String photoUrl) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Picha
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          // Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              role,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Jina
          Text(
            name.isNotEmpty ? name : 'Haijawekwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Chama
          if (party.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              party,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      const ResultsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          'E-Voting',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1565C0),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Nyumbani',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Matokeo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}