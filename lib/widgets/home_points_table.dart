import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season1.dart';
import '../data/season2.dart';
import '../screens/tournament_stats_screen.dart';

/// Compact Season 2 points table for Home.
class HomePointsTable extends StatelessWidget {
  const HomePointsTable({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    final standings = season2Standings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POINTS TABLE',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                      color: const Color(0xFFB8F27A),
                    ),
                  ),
                  const Text(
                    'Season 2',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentStatsScreen(
                    cloudEnabled: cloudEnabled,
                    initialSeasonId: 's2',
                  ),
                ),
              ),
              child: const Text(
                'Full stats',
                style: TextStyle(color: Color(0xFFB8F27A), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: _Hdr('#')),
                    Expanded(flex: 3, child: _Hdr('Team')),
                    SizedBox(width: 28, child: _Hdr('P')),
                    SizedBox(width: 28, child: _Hdr('W')),
                    SizedBox(width: 28, child: _Hdr('L')),
                    SizedBox(width: 36, child: _Hdr('Pts')),
                    SizedBox(width: 56, child: _Hdr('NRR')),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              for (var i = 0; i < standings.length; i++) ...[
                _StandingRow(standing: standings[i]),
                if (i < standings.length - 1)
                  const Divider(height: 1, color: Colors.white10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Hdr extends StatelessWidget {
  const _Hdr(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing});
  final Season1Standing standing;

  @override
  Widget build(BuildContext context) {
    final s = standing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${s.rank}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8F27A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${s.played}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${s.won}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${s.lost}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${s.points}',
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 18,
                color: const Color(0xFFB8F27A),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              s.nrr.toStringAsFixed(3),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
