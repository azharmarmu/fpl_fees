import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import 'add_match_screen.dart';

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
        actions: [
          if (m.hasPdf)
            IconButton(
              tooltip: 'Open PDF',
              onPressed: () => openMatchPdf(context, m),
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFB8F27A)),
            ),
        ],
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
              'No structured batting/bowling yet. Open the PDF if attached.',
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
          const SizedBox(height: 8),
          const Text(
            'Batting',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          if (innings.batting.isEmpty)
            const Text('—', style: TextStyle(color: Colors.white38))
          else
            for (final b in innings.batting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                    Text(
                      '${b.runs} (${b.balls})',
                      style: const TextStyle(color: Color(0xFFB8F27A)),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          const Text(
            'Bowling',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
          ),
          if (innings.bowling.isEmpty)
            const Text('—', style: TextStyle(color: Colors.white38))
          else
            for (final b in innings.bowling)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      '${b.overs}-${b.maidens}-${b.runs}-${b.wickets}',
                      style: const TextStyle(color: Color(0xFFB8F27A)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
