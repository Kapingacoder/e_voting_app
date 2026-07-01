import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/results_chart.dart';





class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  @override
  void initState() {
    super.initState();
  }

  // No polling needed; StreamBuilder provides real-time updates.

  Stream<QuerySnapshot<Map<String, dynamic>>> _ticketsStream() {
    return FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('voteCount', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _electionsStream() {
    return FirebaseFirestore.instance
        .collection('elections')
        .where('votingOpen', isEqualTo: true)
        .limit(1)
        .snapshots();
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text('Matokeo ya Uchaguzi',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print PDF Report',
            onPressed: null,
          ),

          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // StreamBuilder handles real-time updates, so manual refresh is not needed.
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _electionsStream(),
        builder: (context, electionSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ticketsStream(),
            builder: (context, ticketsSnap) {
              if (electionSnap.connectionState == ConnectionState.waiting ||
                  ticketsSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                );
              }

              if (electionSnap.hasError || ticketsSnap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Imeshindwa kupakia matokeo ya uchaguzi (hakuna ruhusa).',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).maybePop();
                          // StreamBuilder will rebuild when returning.
                        },
                        child: Text(
                          'Rudia tena',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final electionDoc = electionSnap.data?.docs.firstOrNull;
              final isActive = (electionDoc?.data()?['votingOpen'] ?? false) == true;

              final tickets = ticketsSnap.data?.docs
                      .map((d) => {
                            'id': d.id,
                            ...d.data(),
                          })
                      .toList() ??
                  const <Map<String, dynamic>>[];

              if (tickets.isEmpty) {
                return _buildResults(
                  tickets: const <Map<String, dynamic>>[],
                  election: electionDoc?.data(),
                  isActive: isActive,
                );
              }

              return _buildResults(
                tickets: tickets,
                election: electionDoc?.data(),
                isActive: isActive,
              );
            },
          );
        },
      ),

    );
  }

  Widget _buildResults({
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic>? election,
    required bool isActive,
  }) {
    final totalVotes = _getTotalVotes(tickets);


    final sortedTickets = List.from(tickets)
      ..sort((a, b) => ((b['voteCount'] ?? 0))
          .compareTo((a['voteCount'] ?? 0)));

    return RefreshIndicator(
      onRefresh: () async {
        // With Firestore streams, data is updated in real-time.
        // This onRefresh is here for the pull-to-refresh UI pattern,
        // but no explicit data refetching is needed.
        return;
      },
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
                  Text(
                    election?['name'] ?? 'Matokeo ya Uchaguzi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip('Jumla ya Kura', '$totalVotes',
                          Icons.how_to_vote),
                      _statChip('Wagombea', '${sortedTickets.length}',
                          Icons.people),
                      _statChip('Hali',
                          isActive ? 'Inaendelea' : 'Imekwisha',
                          isActive ? Icons.play_circle : Icons.stop_circle),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Inasasisha kila sekunde 10',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
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
                    const SizedBox(height: 8),
                    Text('Matokeo yataonekana baada ya kura kupigwa',
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else
              ...sortedTickets.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                final votes =
                    (ticket['voteCount'] ?? ticket['votes'] ?? 0) as int;
                final percentage =
                    totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
                final isWinner = index == 0 && votes > 0;
                final name =
                    ticket['ticketName'] ?? ticket['name'] ?? '';
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
                      // Header
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
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isWinner ? Colors.amber : color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isWinner
                                    ? const Icon(Icons.emoji_events,
                                        color: Colors.white, size: 22)
                                    : Text('${index + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isWinner
                                            ? Colors.amber.shade800
                                            : color,
                                      )),
                                  if (isWinner)
                                    Text('🏆 Anaongoza',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color:
                                                Colors.amber.shade700)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$votes kura',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: color,
                                    )),
                                Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade100,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),

                      // Wagombea — Rais na Makamu na Picha
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(14, 0, 14, 14),
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

  Widget _statChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style:
                GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _personCard(String role, String name, String party,
      String photoUrl, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Picha
          CircleAvatar(
            radius: 32,
            backgroundColor: color.withOpacity(0.1),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(role,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            name.isNotEmpty ? name : 'Haijawekwa',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (party.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(party,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}