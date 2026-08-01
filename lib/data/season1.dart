import 'package:flutter/services.dart';

/// Farm Premier League Season 1 archive (23 Jul 2025 – 26 Jul 2026).
/// Stats only — no fees. Source: CricHeroes CSV exports + final points table.
class Season1Meta {
  static const title = 'Farm Premier League';
  static const seasonLabel = 'Season 1';
  static const location = 'Vellore';
  static const dateRange = '23 Jul 2025 – 26 Jul 2026';
  static const totalMatches = 79;
  static const totalTeams = 2;
  static const note = 'Archive · no fees (Season 1)';
}

class Season1Standing {
  const Season1Standing({
    required this.rank,
    required this.teamName,
    required this.played,
    required this.won,
    required this.lost,
    required this.points,
    required this.nrr,
    required this.forScore,
    required this.againstScore,
    required this.last5,
  });

  final int rank;
  final String teamName;
  final int played;
  final int won;
  final int lost;
  final int points;
  final double nrr;
  final String forScore;
  final String againstScore;
  final String last5;
}

/// Final league table from CricHeroes points table export.
const season1Standings = <Season1Standing>[
  Season1Standing(
    rank: 1,
    teamName: 'OX CC',
    played: 77,
    won: 40,
    lost: 37,
    points: 80,
    nrr: 0.088,
    forScore: '3453/653.4',
    againstScore: '3510/675.4',
    last5: 'L-L-W-L-W',
  ),
  Season1Standing(
    rank: 2,
    teamName: 'Gully Blasters',
    played: 77,
    won: 37,
    lost: 40,
    points: 74,
    nrr: -0.088,
    forScore: '3510/675.4',
    againstScore: '3453/653.4',
    last5: 'W-W-L-W-L',
  ),
];

class Season1BattingRow {
  const Season1BattingRow({
    required this.playerId,
    required this.name,
    required this.teamName,
    required this.matches,
    required this.innings,
    required this.runs,
    required this.highest,
    required this.average,
    required this.strikeRate,
    required this.fours,
    required this.sixes,
  });

  final String playerId;
  final String name;
  final String teamName;
  final int matches;
  final int innings;
  final int runs;
  final int highest;
  final double average;
  final double strikeRate;
  final int fours;
  final int sixes;
}

class Season1BowlingRow {
  const Season1BowlingRow({
    required this.playerId,
    required this.name,
    required this.teamName,
    required this.matches,
    required this.innings,
    required this.wickets,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.economy,
    required this.best,
  });

  final String playerId;
  final String name;
  final String teamName;
  final int matches;
  final int innings;
  final int wickets;
  final String overs;
  final int maidens;
  final int runs;
  final double economy;
  final int best;
}

class Season1FieldingRow {
  const Season1FieldingRow({
    required this.playerId,
    required this.name,
    required this.teamName,
    required this.matches,
    required this.catches,
    required this.runOuts,
    this.stumpings = 0,
    required this.totalDismissals,
  });

  final String playerId;
  final String name;
  final String teamName;
  final int matches;
  final int catches;
  final int runOuts;
  final int stumpings;
  final int totalDismissals;
}

class Season1MvpRow {
  const Season1MvpRow({
    required this.name,
    required this.teamName,
    required this.matches,
    required this.battingPts,
    required this.bowlingPts,
    required this.fieldingPts,
    required this.total,
  });

  final String name;
  final String teamName;
  final int matches;
  final double battingPts;
  final double bowlingPts;
  final double fieldingPts;
  final double total;
}

class Season1Hero {
  const Season1Hero({
    required this.title,
    required this.name,
    required this.teamName,
    required this.summary,
  });

  final String title;
  final String name;
  final String teamName;
  final String summary;
}

class Season1Archive {
  const Season1Archive({
    required this.batting,
    required this.bowling,
    required this.fielding,
    required this.mvp,
    required this.heroes,
  });

  final List<Season1BattingRow> batting;
  final List<Season1BowlingRow> bowling;
  final List<Season1FieldingRow> fielding;
  final List<Season1MvpRow> mvp;
  final List<Season1Hero> heroes;
}

class Season1Loader {
  static Season1Archive? _cached;

  static Future<Season1Archive> load() async {
    final hit = _cached;
    if (hit != null) return hit;

    final battingCsv =
        await rootBundle.loadString('assets/season1/batting_leaderboard.csv');
    final bowlingCsv =
        await rootBundle.loadString('assets/season1/bowling_leaderboard.csv');
    final fieldingCsv =
        await rootBundle.loadString('assets/season1/fielding_leaderboard.csv');
    final mvpCsv =
        await rootBundle.loadString('assets/season1/mvp_leaderboard.csv');

    final batting = _parseBatting(battingCsv);
    final bowling = _parseBowling(bowlingCsv);
    final fielding = _parseFielding(fieldingCsv);
    final mvp = _parseMvp(mvpCsv);

    final heroes = <Season1Hero>[
      if (mvp.isNotEmpty)
        Season1Hero(
          title: 'Player of the tournament',
          name: mvp.first.name,
          teamName: mvp.first.teamName,
          summary:
              'MVP ${mvp.first.total.toStringAsFixed(1)} · ${mvp.first.matches} matches',
        ),
      if (batting.isNotEmpty)
        Season1Hero(
          title: 'Best Batter',
          name: batting.first.name,
          teamName: batting.first.teamName,
          summary:
              '${batting.first.runs} runs · avg ${batting.first.average} · SR ${batting.first.strikeRate}',
        ),
      if (bowling.isNotEmpty)
        Season1Hero(
          title: 'Best Bowler',
          name: bowling.first.name,
          teamName: bowling.first.teamName,
          summary:
              '${bowling.first.wickets} wickets · ${bowling.first.overs} ov · econ ${bowling.first.economy}',
        ),
      if (fielding.isNotEmpty)
        Season1Hero(
          title: 'Best Fielder',
          name: fielding.first.name,
          teamName: fielding.first.teamName,
          summary:
              '${fielding.first.totalDismissals} dismissals · ${fielding.first.catches} catches',
        ),
    ];

    return _cached = Season1Archive(
      batting: batting,
      bowling: bowling,
      fielding: fielding,
      mvp: mvp,
      heroes: heroes,
    );
  }

  static List<List<String>> _rows(String csv) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    return [
      for (final line in lines.skip(1)) _splitCsvLine(line),
    ];
  }

  static List<String> _splitCsvLine(String line) {
    // Simple CSV (no escaped quotes in these exports).
    return line.split(',').map((s) => s.trim()).toList();
  }

  static int _i(List<String> r, int i) =>
      int.tryParse(i < r.length ? r[i] : '') ?? 0;

  static double _d(List<String> r, int i) =>
      double.tryParse(i < r.length ? r[i] : '') ?? 0;

  static String _s(List<String> r, int i) => i < r.length ? r[i] : '';

  static List<Season1BattingRow> _parseBatting(String csv) {
    return [
      for (final r in _rows(csv))
        if (r.length >= 15)
          Season1BattingRow(
            playerId: _s(r, 0),
            name: _s(r, 1),
            teamName: _s(r, 3),
            matches: _i(r, 4),
            innings: _i(r, 5),
            runs: _i(r, 6),
            highest: _i(r, 7),
            average: _d(r, 8),
            strikeRate: _d(r, 10),
            fours: _i(r, 13),
            sixes: _i(r, 14),
          ),
    ];
  }

  static List<Season1BowlingRow> _parseBowling(String csv) {
    return [
      for (final r in _rows(csv))
        if (r.length >= 16)
          Season1BowlingRow(
            playerId: _s(r, 0),
            name: _s(r, 1),
            teamName: _s(r, 3),
            matches: _i(r, 4),
            innings: _i(r, 5),
            wickets: _i(r, 6),
            best: _i(r, 8),
            economy: _d(r, 9),
            maidens: _i(r, 11),
            runs: _i(r, 13),
            overs: _s(r, 15),
          ),
    ];
  }

  static List<Season1FieldingRow> _parseFielding(String csv) {
    return [
      for (final r in _rows(csv))
        if (r.length >= 13)
          Season1FieldingRow(
            playerId: _s(r, 0),
            name: _s(r, 1),
            teamName: _s(r, 3),
            matches: _i(r, 4),
            catches: _i(r, 11), // total_catches
            runOuts: _i(r, 7),
            stumpings: _i(r, 9),
            totalDismissals: _i(r, 12),
          ),
    ];
  }

  static List<Season1MvpRow> _parseMvp(String csv) {
    return [
      for (final r in _rows(csv))
        if (r.length >= 10)
          Season1MvpRow(
            name: _s(r, 0),
            teamName: _s(r, 1),
            matches: _i(r, 5),
            battingPts: _d(r, 6),
            bowlingPts: _d(r, 7),
            fieldingPts: _d(r, 8),
            total: _d(r, 9),
          ),
    ];
  }
}
