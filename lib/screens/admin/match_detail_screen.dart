import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';

class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.match});

  final MatchScorecard match;

  @override
  Widget build(BuildContext context) {
    final m = match;
    final df = DateFormat('d MMM yyyy');
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Scorecard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${m.teamAName} vs ${m.teamBName}',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(
            df.format(m.date),
            style: const TextStyle(color: Colors.white54),
          ),
          if (m.ground.isNotEmpty)
            Text(m.ground, style: const TextStyle(color: Colors.white38)),
          const SizedBox(height: 12),
          Text(
            '${m.teamAName}: ${m.teamAScore.isEmpty ? "—" : m.teamAScore}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '${m.teamBName}: ${m.teamBScore.isEmpty ? "—" : m.teamBScore}',
            style: const TextStyle(color: Colors.white),
          ),
          if (m.resultText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              m.resultText,
              style: const TextStyle(
                color: Color(0xFFB8F27A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (m.tossText.isNotEmpty)
            Text(
              'Toss: ${m.tossText}',
              style: const TextStyle(color: Colors.white54),
            ),
          if (!m.hasStructuredCard) ...[
            const SizedBox(height: 24),
            const Text(
              'Full batting/bowling not entered yet.',
              style: TextStyle(color: Colors.white38),
            ),
          ] else
            for (var i = 0; i < m.innings.length; i++)
              _InningsBlock(index: i, innings: m.innings[i]),
        ],
      ),
    );
  }
}

class _InningsBlock extends StatelessWidget {
  const _InningsBlock({required this.index, required this.innings});
  final int index;
  final MatchInnings innings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INNINGS ${index + 1} · ${innings.battingTeamName}',
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(
            innings.scoreLabel,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          const Text(
            'Batting',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(child: Text('Batter', style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 36, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 36, child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 28, child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 28, child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
            ],
          ),
          const Divider(height: 12, color: Colors.white12),
          if (innings.batting.isEmpty)
            const Text('—', style: TextStyle(color: Colors.white38))
          else
            for (final b in innings.batting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: const TextStyle(color: Colors.white)),
                          if (b.dismissal.isNotEmpty)
                            Text(
                              b.dismissal,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${b.runs}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFFB8F27A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${b.balls}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${b.fours}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${b.sixes}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 14),
          const Text(
            'Bowling',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(child: Text('Bowler', style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 40, child: Text('O', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 28, child: Text('M', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 36, child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
              SizedBox(width: 28, child: Text('W', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
            ],
          ),
          const Divider(height: 12, color: Colors.white12),
          if (innings.bowling.isEmpty)
            const Text('—', style: TextStyle(color: Colors.white38))
          else
            for (final b in innings.bowling)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        b.overs,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${b.maidens}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${b.runs}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${b.wickets}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFFB8F27A),
                          fontWeight: FontWeight.w700,
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
}
