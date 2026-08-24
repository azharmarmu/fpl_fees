import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season2.dart';
import '../screens/tournament_stats_screen.dart';

/// Compact week-wise best team & best player for Home.
class HomeWeekAwards extends StatelessWidget {
  const HomeWeekAwards({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    final awards = season2WeekAwards;
    if (awards.isEmpty) return const SizedBox.shrink();

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
                    'WEEK AWARDS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                      color: const Color(0xFFB8F27A),
                    ),
                  ),
                  const Text(
                    'Best team · best player',
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
                    initialTabIndex: 5,
                  ),
                ),
              ),
              child: const Text(
                'Full table',
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
                    SizedBox(width: 36, child: _Hdr('Wk')),
                    Expanded(flex: 3, child: _Hdr('Best team')),
                    Expanded(flex: 3, child: _Hdr('Best player')),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              for (var i = 0; i < awards.length; i++) ...[
                _AwardRow(award: awards[i]),
                if (i < awards.length - 1)
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
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AwardRow extends StatelessWidget {
  const _AwardRow({required this.award});
  final Season2WeekAward award;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${award.weekIndex}',
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                color: const Color(0xFFB8F27A),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.bestTeamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  award.bestTeamSummary,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  award.bestPlayerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  award.bestPlayerSummary,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
