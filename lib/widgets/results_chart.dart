import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultsChart extends StatefulWidget {
  final List<dynamic> tickets;
  final int totalVotes;

  const ResultsChart({
    super.key,
    required this.tickets,
    required this.totalVotes,
  });

  @override
  State<ResultsChart> createState() => _ResultsChartState();
}

class _ResultsChartState extends State<ResultsChart> {
  int _touchedIndex = -1;
  bool _showPieChart = true;

  final List<Color> _colors = [
    const Color(0xFF1565C0),
    const Color(0xFF2E7D32),
    const Color(0xFFE65100),
    const Color(0xFF6A1B9A),
    const Color(0xFF00838F),
    const Color(0xFFC62828),
    const Color(0xFF4527A0),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.tickets.isEmpty || widget.totalVotes == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bar_chart, size: 50, color: Colors.grey),
              const SizedBox(height: 8),
              Text('Hakuna kura bado',
                  style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Toggle Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPieChart = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _showPieChart
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart,
                              size: 18,
                              color: _showPieChart
                                  ? Colors.white
                                  : Colors.grey),
                          const SizedBox(width: 6),
                          Text('Pie Chart',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showPieChart
                                    ? Colors.white
                                    : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPieChart = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showPieChart
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart,
                              size: 18,
                              color: !_showPieChart
                                  ? Colors.white
                                  : Colors.grey),
                          const SizedBox(width: 6),
                          Text('Bar Chart',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_showPieChart
                                    ? Colors.white
                                    : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chart
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showPieChart
                ? _buildPieChart()
                : _buildBarChart(),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      key: const ValueKey('pie'),
      height: 220,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse
                    .touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 3,
          centerSpaceRadius: 50,
          sections: widget.tickets.asMap().entries.map((entry) {
            final index = entry.key;
            final ticket = entry.value;
            final votes =
                (ticket['voteCount'] ?? ticket['votes'] ?? 0) as int;
            final percentage = widget.totalVotes > 0
                ? (votes / widget.totalVotes * 100)
                : 0.0;
            final isTouched = index == _touchedIndex;
            final color = _colors[index % _colors.length];
            final name =
                ticket['ticketName'] ?? ticket['name'] ?? '';

            return PieChartSectionData(
              color: color,
              value: votes.toDouble(),
              title: '${percentage.toStringAsFixed(1)}%',
              radius: isTouched ? 65 : 55,
              titleStyle: GoogleFonts.poppins(
                fontSize: isTouched ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: isTouched
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              badgePositionPercentageOffset: 1.3,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxVotes = widget.tickets
        .map((t) => (t['voteCount'] ?? t['votes'] ?? 0) as int)
        .fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      key: const ValueKey('bar'),
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxVotes * 1.3).toDouble(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) =>
                    _colors[group.x % _colors.length].withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final ticket = widget.tickets[group.x];
                  final name =
                      ticket['ticketName'] ?? ticket['name'] ?? '';
                  final votes = rod.toY.toInt();
                  final percentage = widget.totalVotes > 0
                      ? (votes / widget.totalVotes * 100)
                      : 0.0;
                  return BarTooltipItem(
                    '$name\n$votes kura\n${percentage.toStringAsFixed(1)}%',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= widget.tickets.length) {
                      return const SizedBox();
                    }
                    final ticket = widget.tickets[index];
                    final name =
                        ticket['ticketName'] ?? ticket['name'] ?? '';
                    final shortName = name.length > 8
                        ? '${name.substring(0, 8)}...'
                        : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        shortName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox();
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: widget.tickets.asMap().entries.map((entry) {
              final index = entry.key;
              final ticket = entry.value;
              final votes =
                  (ticket['voteCount'] ?? ticket['votes'] ?? 0) as int;
              final color = _colors[index % _colors.length];

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: votes.toDouble(),
                    color: color,
                    width: 28,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (maxVotes * 1.3).toDouble(),
                      color: Colors.grey.shade100,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: widget.tickets.asMap().entries.map((entry) {
        final index = entry.key;
        final ticket = entry.value;
        final votes =
            (ticket['voteCount'] ?? ticket['votes'] ?? 0) as int;
        final percentage = widget.totalVotes > 0
            ? (votes / widget.totalVotes * 100)
            : 0.0;
        final color = _colors[index % _colors.length];
        final name = ticket['ticketName'] ?? ticket['name'] ?? '';

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$name: $votes (${percentage.toStringAsFixed(1)}%)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}