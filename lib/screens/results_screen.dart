import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/results_chart.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? _resultsData;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadResults();
    // Refresh kila sekunde 10 automatically
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadResults());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadResults() async {
    try {
      final data = await ApiService.getResults();
      if (mounted) {
        setState(() {
          if (data is Map<String, dynamic>) {
            _resultsData = data;
          } else if (data is List) {
            _resultsData = {'tickets': data};
          } else {
            _resultsData = {};
          }
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Imeshindwa kupakia matokeo.';
          _isLoading = false;
        });
      }
    }
  }

  int _getTotalVotes(List<dynamic> results) {
    int total = 0;
    for (var r in results) {
      total += (r['voteCount'] ?? r['votes'] ?? 0) as int;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }

    final tickets = _resultsData?['tickets'] ?? 
                    _resultsData?['candidates'] ?? [];
    final election = _resultsData?['election'];
    final totalVotes = _getTotalVotes(tickets);
    final isActive = election?['votingOpen'] ?? false;

    final sortedTickets = List.from(tickets)
      ..sort((a, b) => ((b['voteCount'] ?? 0)).compareTo((a['voteCount'] ?? 0)));

    return RefreshIndicator(
      onRefresh: _loadResults,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [Colors.green.shade600, Colors.green.shade400]
                      : [const Color(0xFF1565C0), const Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        election?['name'] ?? 'Matokeo ya Uchaguzi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip('Jumla ya Kura', '$totalVotes'),
                      _statChip('Wagombea', '${sortedTickets.length}'),
                      _statChip(
                          'Hali', isActive ? '🟢 Inaendelea' : '🔴 Imekwisha'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Auto-refresh indicator
                  if (isActive)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Inasasisha kila sekunde 10',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (sortedTickets.isNotEmpty) ...[
              ResultsChart(
                tickets: sortedTickets,
                totalVotes: totalVotes,
              ),
              const SizedBox(height: 16),
              Text(
                'Matokeo Kwa Kila Ticket',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (sortedTickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.how_to_vote_outlined,
                        size: 70, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Hakuna matokeo bado',
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
            else
              ...sortedTickets.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                final votes = (ticket['voteCount'] ?? ticket['votes'] ?? 0) as int;
                final percentage =
                    totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
                final isWinner = index == 0 && votes > 0;
                final name = ticket['ticketName'] ?? ticket['name'] ?? '';
                final presidentName = ticket['presidentName'] ?? '';
                final presidentParty = ticket['presidentParty'] ?? '';
                final vpName = ticket['vicePresidentName'] ?? '';
                final vpParty = ticket['vicePresidentParty'] ?? '';
                final presidentPhoto = ticket['presidentPhotoUrl'] ?? '';
                final vpPhoto = ticket['vicePresidentPhotoUrl'] ?? '';

                final colors = [
                  const Color(0xFF1565C0),
                  const Color(0xFF2E7D32),
                  const Color(0xFFE65100),
                  const Color(0xFF6A1B9A),
                  const Color(0xFF00838F),
                ];
                final color = colors[index % colors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isWinner
                        ? Border.all(color: Colors.amber, width: 2)
                        : Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
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
                          color: isWinner
                              ? Colors.amber.shade50
                              : color.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isWinner ? Colors.amber : color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isWinner
                                    ? const Icon(Icons.emoji_events,
                                        color: Colors.white, size: 20)
                                    : Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isWinner
                                          ? Colors.amber.shade800
                                          : color,
                                    ),
                                  ),
                                  if (isWinner)
                                    Text('🏆 Anaongoza',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.amber.shade700)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$votes kura',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),

                      // Rais na Makamu
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: _personCard(
                                '🏅 Rais',
                                presidentName,
                                presidentParty,
                                presidentPhoto,
                                color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _personCard(
                                '🥈 Makamu',
                                vpName,
                                vpParty,
                                vpPhoto,
                                color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _personCard(String role, String name, String party,
      String photoUrl, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(role,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          Text(
            name.isNotEmpty ? name : 'Haijawekwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (party.isNotEmpty)
            Text(party,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}