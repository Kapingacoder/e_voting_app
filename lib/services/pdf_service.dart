import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateElectionReport({
    required BuildContext context,
    required Map<String, dynamic> resultsData,
  }) async {
    final pdf = pw.Document();

    final tickets = resultsData['tickets'] ?? resultsData['candidates'] ?? [];
    final election = resultsData['election'];
    final electionName = election?['name'] ?? 'General Election';

    int totalVotes = 0;
    for (var t in tickets) {
      totalVotes += (t['voteCount'] ?? t['votes'] ?? 0) as int;
    }

    final sortedTickets = List.from(tickets)
      ..sort((a, b) =>
          ((b['voteCount'] ?? 0)).compareTo((a['voteCount'] ?? 0)));

    final primaryColor = PdfColor.fromHex('#1565C0');
    final accentColor = PdfColor.fromHex('#1976D2');
    final goldColor = PdfColor.fromHex('#FFB300');
    final greenColor = PdfColor.fromHex('#2E7D32');
    final lightBlue = PdfColor.fromHex('#E3F2FD');
    final lightGrey = PdfColor.fromHex('#F5F5F5');
    final darkGrey = PdfColor.fromHex('#424242');
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(
            electionName, dateStr, primaryColor, accentColor),
        footer: (ctx) => _buildFooter(ctx, primaryColor),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(
              totalVotes, sortedTickets.length, election,
              primaryColor, greenColor, lightBlue, lightGrey),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Matokeo ya Kura', primaryColor),
          pw.SizedBox(height: 12),
          _buildBarChart(sortedTickets, totalVotes),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Orodha ya Wagombea', primaryColor),
          pw.SizedBox(height: 12),
          ...sortedTickets.asMap().entries.map((entry) =>
              _buildTicketCard(entry.value, entry.key, totalVotes,
                  primaryColor, goldColor, lightBlue, lightGrey, darkGrey)),
          pw.SizedBox(height: 24),
          if (sortedTickets.isNotEmpty &&
              (sortedTickets[0]['voteCount'] ?? 0) > 0)
            _buildWinnerSection(
                sortedTickets[0], totalVotes, goldColor, primaryColor),
          pw.SizedBox(height: 24),
          _buildFooterNote(primaryColor, lightBlue),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${electionName.replaceAll(' ', '_')}_Results.pdf',
    );
  }

  // ═══════════════════════════════
  // HEADER
  // ═══════════════════════════════
  static pw.Widget _buildHeader(String electionName, String dateStr,
      PdfColor primaryColor, PdfColor accentColor) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [primaryColor, accentColor]),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('E-VOTING SYSTEM',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      letterSpacing: 2)),
              pw.SizedBox(height: 4),
              pw.Text(electionName,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Ripoti Rasmi ya Matokeo',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text('VOTE',
                    style: pw.TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),
              pw.Text(dateStr,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // FOOTER
  // ═══════════════════════════════
  static pw.Widget _buildFooter(pw.Context ctx, PdfColor primaryColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('E-Voting System — Ripoti Rasmi',
              style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
          pw.Text('Ukurasa ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(color: primaryColor, fontSize: 9)),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // SUMMARY
  // ═══════════════════════════════
  static pw.Widget _buildSummarySection(
      int totalVotes,
      int totalTickets,
      Map<String, dynamic>? election,
      PdfColor primaryColor,
      PdfColor greenColor,
      PdfColor lightBlue,
      PdfColor lightGrey) {
    final isActive = election?['votingOpen'] ?? false;

    return pw.Row(
      children: [
        pw.Expanded(
            child: _summaryCard('Jumla ya Kura', '$totalVotes',
                primaryColor, lightBlue)),
        pw.SizedBox(width: 12),
        pw.Expanded(
            child: _summaryCard('Wagombea', '$totalTickets', greenColor,
                PdfColor.fromHex('#E8F5E9'))),
        pw.SizedBox(width: 12),
        pw.Expanded(
            child: _summaryCard(
                'Hali',
                isActive ? 'Inaendelea' : 'Imekwisha',
                isActive
                    ? PdfColor.fromHex('#2E7D32')
                    : PdfColor.fromHex('#C62828'),
                isActive
                    ? PdfColor.fromHex('#E8F5E9')
                    : PdfColor.fromHex('#FFEBEE'))),
      ],
    );
  }

  static pw.Widget _summaryCard(
      String label, String value, PdfColor color, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: pw.TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // BAR CHART
  // ═══════════════════════════════
  static pw.Widget _buildBarChart(
      List<dynamic> tickets, int totalVotes) {
    if (tickets.isEmpty || totalVotes == 0) return pw.SizedBox();

    final colors = [
      PdfColor.fromHex('#1565C0'),
      PdfColor.fromHex('#2E7D32'),
      PdfColor.fromHex('#E65100'),
      PdfColor.fromHex('#6A1B9A'),
      PdfColor.fromHex('#00838F'),
    ];

    final maxVotes = tickets
        .map((t) => (t['voteCount'] ?? 0) as int)
        .fold(0, (a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
      ),
      child: pw.Column(
        children: tickets.asMap().entries.map((entry) {
          final index = entry.key;
          final ticket = entry.value;
          final votes = (ticket['voteCount'] ?? 0) as int;
          final percentage =
              totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
          final barRatio = maxVotes > 0 ? votes / maxVotes : 0.0;
          final color = colors[index % colors.length];
          final name = ticket['ticketName'] ?? ticket['name'] ?? '';

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 90,
                  child: pw.Text(name,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold),
                      maxLines: 2),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      pw.Container(
                        height: 18,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F5F5F5'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.Container(
                        height: 18,
                        width: 350 * barRatio,
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '$votes (${percentage.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════
  // TICKET CARD
  // ═══════════════════════════════
  static pw.Widget _buildTicketCard(
      Map<String, dynamic> ticket,
      int index,
      int totalVotes,
      PdfColor primaryColor,
      PdfColor goldColor,
      PdfColor lightBlue,
      PdfColor lightGrey,
      PdfColor darkGrey) {
    final votes = (ticket['voteCount'] ?? 0) as int;
    final percentage =
        totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
    final isWinner = index == 0 && votes > 0;
    final name = ticket['ticketName'] ?? ticket['name'] ?? '';
    final presidentName = ticket['presidentName'] ?? 'Haijawekwa';
    final presidentParty = ticket['presidentParty'] ?? '';
    final vpName = ticket['vicePresidentName'] ?? 'Haijawekwa';
    final vpParty = ticket['vicePresidentParty'] ?? '';

    final colors = [
      PdfColor.fromHex('#1565C0'),
      PdfColor.fromHex('#2E7D32'),
      PdfColor.fromHex('#E65100'),
      PdfColor.fromHex('#6A1B9A'),
      PdfColor.fromHex('#00838F'),
    ];
    final color = colors[index % colors.length];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
            color: isWinner ? goldColor : PdfColor.fromHex('#E0E0E0'),
            width: isWinner ? 2 : 1),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: isWinner
                  ? PdfColor.fromHex('#FFF8E1')
                  : PdfColor.fromHex('#F5F5F5'),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(12),
                topRight: pw.Radius.circular(12),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 36,
                  height: 36,
                  decoration: pw.BoxDecoration(
                    color: isWinner ? goldColor : color,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${index + 1}',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(name,
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: isWinner ? goldColor : color)),
                      if (isWinner)
                        pw.Text('MSHINDI — Anaongoza kwa kura',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: goldColor,
                                fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$votes kura',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: color)),
                    pw.Text('${percentage.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                            fontSize: 11, color: darkGrey)),
                  ],
                ),
              ],
            ),
          ),

          // Wagombea
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightBlue,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RAIS',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: primaryColor,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text(presidentName,
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                        if (presidentParty.isNotEmpty)
                          pw.Text(presidentParty,
                              style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MAKAMU',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: primaryColor,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text(vpName,
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                        if (vpParty.isNotEmpty)
                          pw.Text(vpParty,
                              style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // WINNER
  // ═══════════════════════════════
  static pw.Widget _buildWinnerSection(Map<String, dynamic> winner,
      int totalVotes, PdfColor goldColor, PdfColor primaryColor) {
    final votes = (winner['voteCount'] ?? 0) as int;
    final percentage =
        totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
    final name = winner['ticketName'] ?? winner['name'] ?? '';
    final presidentName = winner['presidentName'] ?? '';
    final vpName = winner['vicePresidentName'] ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF8E1'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: goldColor, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text('MSHINDI WA UCHAGUZI',
              style: pw.TextStyle(
                  color: goldColor,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 2)),
          pw.SizedBox(height: 12),
          pw.Text(name,
              style: pw.TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Rais: $presidentName  |  Makamu: $vpName',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: pw.BoxDecoration(
              color: goldColor,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              '$votes Kura — ${percentage.toStringAsFixed(1)}% ya Kura Zote',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // FOOTER NOTE
  // ═══════════════════════════════
  static pw.Widget _buildFooterNote(
      PdfColor primaryColor, PdfColor lightBlue) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightBlue,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: primaryColor, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Ripoti hii imetolewa rasmi na mfumo wa E-Voting.',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: primaryColor,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text('Imetolewa: $dateStr',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════
  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold)),
    );
  }
}