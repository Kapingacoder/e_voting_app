import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ElectionCountdown extends StatefulWidget {
  final String? startTime;
  final String? endTime;
  final bool isVotingOpen;

  const ElectionCountdown({
    super.key,
    this.startTime,
    this.endTime,
    required this.isVotingOpen,
  });

  @override
  State<ElectionCountdown> createState() => _ElectionCountdownState();
}

class _ElectionCountdownState extends State<ElectionCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  String _label = '';
  bool _isExpired = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05)
        .animate(_pulseController);
    _calculateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _calculateCountdown() {
    final now = DateTime.now();

    try {
      if (widget.isVotingOpen) {
        // Uchaguzi unaendelea — hesabu muda wa kumalizika
        if (widget.endTime != null) {
          final end = DateTime.parse(widget.endTime!);
          final diff = end.difference(now);
          if (diff.isNegative) {
            setState(() {
              _isExpired = true;
              _label = 'Uchaguzi Umekwisha';
              _remaining = Duration.zero;
            });
          } else {
            setState(() {
              _isExpired = false;
              _label = 'Uchaguzi Unaisha';
              _remaining = diff;
            });
          }
        }
      } else {
        // Uchaguzi haujanza — hesabu muda wa kuanza
        if (widget.startTime != null) {
          final start = DateTime.parse(widget.startTime!);
          final diff = start.difference(now);
          if (diff.isNegative) {
            setState(() {
              _isExpired = true;
              _label = 'Inasubiri Kuanzishwa';
              _remaining = Duration.zero;
            });
          } else {
            setState(() {
              _isExpired = false;
              _label = 'Uchaguzi Unaanza';
              _remaining = diff;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _label = 'Wakati Haujawekwa';
        _remaining = Duration.zero;
      });
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final isActive = widget.isVotingOpen && !_isExpired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.green.shade700, Colors.green.shade500]
              : _isExpired
                  ? [Colors.grey.shade700, Colors.grey.shade500]
                  : [const Color(0xFF1565C0), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : const Color(0xFF1565C0))
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label na Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (isActive) const SizedBox(width: 8),
              Text(
                _label.isEmpty ? 'Countdown' : _label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Countdown Numbers
          if (!_isExpired && _remaining != Duration.zero)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (days > 0) ...[
                  _timeUnit(_twoDigits(days), 'Siku'),
                  _divider(),
                ],
                _timeUnit(_twoDigits(hours), 'Saa'),
                _divider(),
                _timeUnit(_twoDigits(minutes), 'Dak'),
                _divider(),
                _timeUnit(_twoDigits(seconds), 'Sek'),
              ],
            )
          else
            Text(
              _isExpired ? '⏰ 00 : 00 : 00' : 'Wakati Haujawekwa',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 12),

          // Progress Bar
          if (!_isExpired && _remaining != Duration.zero)
            _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _timeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Text(
      ':',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProgressBar() {
    double progress = 0.0;

    try {
      if (widget.isVotingOpen && widget.endTime != null) {
        final end = DateTime.parse(widget.endTime!);
        final start = widget.startTime != null
            ? DateTime.parse(widget.startTime!)
            : end.subtract(const Duration(hours: 24));
        final total = end.difference(start).inSeconds;
        final elapsed =
            DateTime.now().difference(start).inSeconds;
        progress = total > 0
            ? (elapsed / total).clamp(0.0, 1.0)
            : 0.0;
      } else if (!widget.isVotingOpen &&
          widget.startTime != null) {
        final start = DateTime.parse(widget.startTime!);
        final created =
            start.subtract(const Duration(days: 7));
        final total =
            start.difference(created).inSeconds;
        final elapsed =
            DateTime.now().difference(created).inSeconds;
        progress = total > 0
            ? (elapsed / total).clamp(0.0, 1.0)
            : 0.0;
      }
    } catch (e) {
      progress = 0.0;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isVotingOpen
              ? '${(progress * 100).toStringAsFixed(0)}% ya muda umepita'
              : '${(progress * 100).toStringAsFixed(0)}% ya muda wa kusubiri',
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}