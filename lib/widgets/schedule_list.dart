import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../screens/schedule_screen.dart';
import '../services/fpl_store.dart';

/// Compact selected-week fixtures for Home, with arrow to full schedule.
class HomeWeekSchedule extends StatelessWidget {
  const HomeWeekSchedule({super.key, required this.store});

  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final weekId = store.selectedWeekId;
        final list = store.fixturesForWeek(weekId);
        final week = store.selectedWeek;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF163020),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleScreen(store: store),
                  ),
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'THIS WEEK',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 20,
                                color: const Color(0xFFB8F27A),
                              ),
                            ),
                            Text(
                              week == null
                                  ? 'No week selected'
                                  : '${week.label} · ${DateFormat('d MMM').format(week.date)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Show all',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleScreen(store: store),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFB8F27A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: list.isEmpty
                    ? const Text(
                        'No fixtures for this week (schedule covers Aug–Sep).',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      )
                    : Column(
                        children: [
                          for (final f in list)
                            _FixtureRow(
                              fixture: f,
                              result: store.matchForFixture(f),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FixtureRow extends StatelessWidget {
  const _FixtureRow({required this.fixture, this.result});
  final ScheduledFixture fixture;
  final MatchScorecard? result;

  @override
  Widget build(BuildContext context) {
    final done = result != null &&
        (result!.resultText.isNotEmpty ||
            result!.teamAScore.isNotEmpty ||
            result!.teamBScore.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${fixture.slot}.',
              style: TextStyle(
                color: fixture.isOpening
                    ? const Color(0xFFB8F27A)
                    : Colors.white38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fixture.matchup,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        fixture.isOpening ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (done) ...[
                  const SizedBox(height: 2),
                  Text(
                    _scoreLine(result!),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (result!.resultText.isNotEmpty)
                    Text(
                      result!.resultText,
                      style: const TextStyle(
                        color: Color(0xFFB8F27A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (done)
            Container(
              margin: const EdgeInsets.only(left: 6, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E5A3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Color(0xFFB8F27A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (fixture.isOpening)
            Container(
              margin: const EdgeInsets.only(left: 6, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E5A3C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '1st',
                style: TextStyle(
                  color: Color(0xFFB8F27A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _scoreLine(MatchScorecard m) {
    final a = m.teamAScore.isEmpty ? '—' : m.teamAScore;
    final b = m.teamBScore.isEmpty ? '—' : m.teamBScore;
    return '${m.teamAName} $a  ·  ${m.teamBName} $b';
  }
}

/// Full fixture list grouped by week.
class ScheduleList extends StatelessWidget {
  const ScheduleList({
    super.key,
    required this.store,
    this.compact = false,
  });

  final FplStore store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fixtures = [...store.fixtures]
      ..sort((a, b) {
        final dc = a.date.compareTo(b.date);
        if (dc != 0) return dc;
        return a.slot.compareTo(b.slot);
      });
    if (fixtures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Schedule not loaded yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final byWeek = <String, List<ScheduledFixture>>{};
    for (final f in fixtures) {
      byWeek.putIfAbsent(f.weekId, () => []).add(f);
    }
    final weekIds = byWeek.keys.toList()..sort();
    final df = DateFormat('EEE, d MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final weekId in weekIds) ...[
          Builder(
            builder: (context) {
              final list = byWeek[weekId]!;
              final date = list.first.date;
              String label = weekId;
              try {
                final w = store.weeks.firstWhere((x) => x.id == weekId);
                label = w.label;
              } catch (_) {}
              return Padding(
                padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.bebasNeue(
                        fontSize: compact ? 18 : 22,
                        color: const Color(0xFFB8F27A),
                      ),
                    ),
                    Text(
                      df.format(date),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    for (final f in list)
                      _FixtureRow(
                        fixture: f,
                        result: store.matchForFixture(f),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
