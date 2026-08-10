import 'dart:collection';

import 'package:flutter/foundation.dart';
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
    return _cached = await loadFromAssetPaths(
      battingAsset: 'assets/season1/batting_leaderboard.csv',
      bowlingAsset: 'assets/season1/bowling_leaderboard.csv',
      fieldingAsset: 'assets/season1/fielding_leaderboard.csv',
      mvpAsset: 'assets/season1/mvp_leaderboard.csv',
    );
  }

  /// Shared CricHeroes CSV parser (Season 1 / Season 2 exports share columns).
  /// Collapses mid-season team switches into one row per player so awards
  /// (best batter / bowler / fielder / MVP) use full season totals.
  static Future<Season1Archive> loadFromAssetPaths({
    required String battingAsset,
    required String bowlingAsset,
    required String fieldingAsset,
    required String mvpAsset,
  }) async {
    final battingCsv = await rootBundle.loadString(battingAsset);
    final bowlingCsv = await rootBundle.loadString(bowlingAsset);
    final fieldingCsv = await rootBundle.loadString(fieldingAsset);
    final mvpCsv = await rootBundle.loadString(mvpAsset);

    final batting = _mergeBatting(_parseBatting(battingCsv));
    final bowling = _mergeBowling(_parseBowling(bowlingCsv));
    final fielding = _mergeFielding(_parseFielding(fieldingCsv));
    final mvp = _mergeMvp(_parseMvp(mvpCsv));

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

    return Season1Archive(
      batting: batting,
      bowling: bowling,
      fielding: fielding,
      mvp: mvp,
      heroes: heroes,
    );
  }

  static String _nameKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _teamLabel(Set<String> teams, String fallback) {
    if (teams.isEmpty) return fallback;
    // Last team seen ≈ current club after a trade.
    return teams.last;
  }

  /// Sum bat rows that share [playerId] (CricHeroes id survives team change).
  @visibleForTesting
  static List<Season1BattingRow> mergeBattingForTest(
    List<Season1BattingRow> rows,
  ) =>
      _mergeBatting(rows);

  @visibleForTesting
  static List<Season1BowlingRow> mergeBowlingForTest(
    List<Season1BowlingRow> rows,
  ) =>
      _mergeBowling(rows);

  @visibleForTesting
  static List<Season1MvpRow> mergeMvpForTest(List<Season1MvpRow> rows) =>
      _mergeMvp(rows);

  static List<Season1BattingRow> _mergeBatting(List<Season1BattingRow> rows) {
    final order = <String>[];
    final map = <String, Season1BattingRow>{};
    final teams = <String, Set<String>>{};
    final balls = <String, int>{};
    final outs = <String, int>{};

    for (final r in rows) {
      final id = r.playerId.isNotEmpty ? r.playerId : 'n:${_nameKey(r.name)}';
      if (!map.containsKey(id)) order.add(id);
      teams.putIfAbsent(id, () => <String>{});
      if (r.teamName.isNotEmpty) teams[id]!.add(r.teamName);

      final prev = map[id];
      if (prev == null) {
        map[id] = r;
        // Recover balls from SR when possible for later merge accuracy.
        if (r.strikeRate > 0 && r.runs > 0) {
          balls[id] = (r.runs * 100 / r.strikeRate).round();
        }
        if (r.average > 0 && r.runs > 0) {
          final o = (r.runs / r.average).round();
          outs[id] = o > 0 ? o : 0;
        }
        continue;
      }

      final runs = prev.runs + r.runs;
      final innings = prev.innings + r.innings;
      final matches = prev.matches + r.matches;
      final fours = prev.fours + r.fours;
      final sixes = prev.sixes + r.sixes;
      final highest = prev.highest >= r.highest ? prev.highest : r.highest;

      var b = balls[id] ?? 0;
      if (r.strikeRate > 0 && r.runs > 0) {
        b += (r.runs * 100 / r.strikeRate).round();
      }
      balls[id] = b;

      var o = outs[id] ?? 0;
      if (r.average > 0 && r.runs > 0) {
        o += (r.runs / r.average).round();
      }
      outs[id] = o;

      final avg = o > 0 ? runs / o : (innings > 0 ? runs / innings : 0.0);
      final sr = b > 0 ? runs * 100 / b : 0.0;

      map[id] = Season1BattingRow(
        playerId: prev.playerId.isNotEmpty ? prev.playerId : r.playerId,
        name: r.name.isNotEmpty ? r.name : prev.name,
        teamName: _teamLabel(teams[id]!, r.teamName),
        matches: matches,
        innings: innings,
        runs: runs,
        highest: highest,
        average: double.parse(avg.toStringAsFixed(2)),
        strikeRate: double.parse(sr.toStringAsFixed(2)),
        fours: fours,
        sixes: sixes,
      );
    }

    final merged = [for (final id in order) map[id]!];
    merged.sort((a, b) => b.runs.compareTo(a.runs));
    return merged;
  }

  static int _oversToBalls(String overs) {
    final parts = overs.trim().split('.');
    final ov = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final b = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return ov * 6 + b.clamp(0, 5);
  }

  static String _ballsToOvers(int balls) => '${balls ~/ 6}.${balls % 6}';

  static List<Season1BowlingRow> _mergeBowling(List<Season1BowlingRow> rows) {
    final order = <String>[];
    final map = <String, Season1BowlingRow>{};
    final teams = <String, Set<String>>{};

    for (final r in rows) {
      final id = r.playerId.isNotEmpty ? r.playerId : 'n:${_nameKey(r.name)}';
      if (!map.containsKey(id)) order.add(id);
      teams.putIfAbsent(id, () => <String>{});
      if (r.teamName.isNotEmpty) teams[id]!.add(r.teamName);

      final prev = map[id];
      if (prev == null) {
        map[id] = r;
        continue;
      }

      final wickets = prev.wickets + r.wickets;
      final runs = prev.runs + r.runs;
      final balls = _oversToBalls(prev.overs) + _oversToBalls(r.overs);
      final overs = _ballsToOvers(balls);
      final economy = balls > 0 ? runs / (balls / 6.0) : 0.0;

      map[id] = Season1BowlingRow(
        playerId: prev.playerId.isNotEmpty ? prev.playerId : r.playerId,
        name: r.name.isNotEmpty ? r.name : prev.name,
        teamName: _teamLabel(teams[id]!, r.teamName),
        matches: prev.matches + r.matches,
        innings: prev.innings + r.innings,
        wickets: wickets,
        overs: overs,
        maidens: prev.maidens + r.maidens,
        runs: runs,
        economy: double.parse(economy.toStringAsFixed(2)),
        best: prev.best >= r.best ? prev.best : r.best,
      );
    }

    final merged = [for (final id in order) map[id]!];
    merged.sort((a, b) {
      final w = b.wickets.compareTo(a.wickets);
      if (w != 0) return w;
      return a.economy.compareTo(b.economy);
    });
    return merged;
  }

  static List<Season1FieldingRow> _mergeFielding(List<Season1FieldingRow> rows) {
    final order = <String>[];
    final map = <String, Season1FieldingRow>{};
    final teams = <String, Set<String>>{};

    for (final r in rows) {
      final id = r.playerId.isNotEmpty ? r.playerId : 'n:${_nameKey(r.name)}';
      if (!map.containsKey(id)) order.add(id);
      teams.putIfAbsent(id, () => <String>{});
      if (r.teamName.isNotEmpty) teams[id]!.add(r.teamName);

      final prev = map[id];
      if (prev == null) {
        map[id] = r;
        continue;
      }

      map[id] = Season1FieldingRow(
        playerId: prev.playerId.isNotEmpty ? prev.playerId : r.playerId,
        name: r.name.isNotEmpty ? r.name : prev.name,
        teamName: _teamLabel(teams[id]!, r.teamName),
        matches: prev.matches + r.matches,
        catches: prev.catches + r.catches,
        runOuts: prev.runOuts + r.runOuts,
        stumpings: prev.stumpings + r.stumpings,
        totalDismissals: prev.totalDismissals + r.totalDismissals,
      );
    }

    final merged = [for (final id in order) map[id]!];
    merged.sort((a, b) => b.totalDismissals.compareTo(a.totalDismissals));
    return merged;
  }

  static List<Season1MvpRow> _mergeMvp(List<Season1MvpRow> rows) {
    final order = <String>[];
    final map = <String, Season1MvpRow>{};
    final teams = <String, LinkedHashSet<String>>{};

    for (final r in rows) {
      final id = _nameKey(r.name);
      if (id.isEmpty) continue;
      if (!map.containsKey(id)) order.add(id);
      teams.putIfAbsent(id, LinkedHashSet<String>.new);
      if (r.teamName.isNotEmpty) teams[id]!.add(r.teamName);

      final prev = map[id];
      if (prev == null) {
        map[id] = r;
        continue;
      }

      map[id] = Season1MvpRow(
        name: r.name.isNotEmpty ? r.name : prev.name,
        teamName: _teamLabel(teams[id]!, r.teamName),
        matches: prev.matches >= r.matches ? prev.matches : r.matches,
        battingPts: prev.battingPts + r.battingPts,
        bowlingPts: prev.bowlingPts + r.bowlingPts,
        fieldingPts: prev.fieldingPts + r.fieldingPts,
        total: prev.total + r.total,
      );
    }

    final merged = [for (final id in order) map[id]!];
    merged.sort((a, b) => b.total.compareTo(a.total));
    return merged;
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
