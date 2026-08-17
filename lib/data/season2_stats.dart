import '../config.dart';
import 'seed.dart';
import 'season1.dart';
import 'season2_matches.dart';

String _nk(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Current squad team for leaderboard labels after recorded trades.
/// Stats totals still come from CricHeroes / scorecards (carry across clubs).
String? season2CurrentTeamName(String playerName) {
  final key = _nk(playerName);
  final byName = <String, String>{
    for (final p in buildSeedPlayers())
      if (p.teamId != kTeamGuest && p.teamId != kTeamFreeAgent)
        _nk(p.name): p.teamName,
  };
  // Trade 1 package (see FplStore._ensureTrade1OxAslamPackage).
  byName[_nk('Aslam Hashim')] = kTeamNames[kTeamOx]!;
  byName[_nk('Faizal')] = kTeamNames[kTeamGb]!;
  byName[_nk('Fazil Farook')] = kTeamNames[kTeamGb]!;
  // Trade 2 package (see FplStore._ensureTrade2AvengersMunafPackage).
  byName[_nk('Munaf Cpm')] = kTeamNames[kTeamAvengers]!;
  byName[_nk('Mashood A C')] = kTeamNames[kTeamGb]!;
  // Releases → free agent (see FplStore._ensureReleaseArifAndFarziii).
  byName[_nk('Arif PVH')] = kTeamNames[kTeamFreeAgent]!;
  // Mini auction buys (see FplStore._ensureMiniAuction).
  byName[_nk('Ejaz')] = kTeamNames[kTeamGb]!;
  byName[_nk('Imran')] = kTeamNames[kTeamGb]!;
  byName[_nk('Anju')] = kTeamNames[kTeamGb]!;
  byName[_nk('Farziii')] = kTeamNames[kTeamGb]!;
  byName[_nk('SADAM')] = kTeamNames[kTeamOx]!;
  byName[_nk('Sadam')] = kTeamNames[kTeamOx]!;
  byName[_nk('Gopi')] = kTeamNames[kTeamAvengers]!;
  byName[_nk('Gopinath')] = kTeamNames[kTeamAvengers]!;
  byName[_nk('Arif KVH')] = kTeamNames[kTeamAvengers]!;
  // CricHeroes spellings vs auction names.
  byName[_nk('Ajaz')] = kTeamNames[kTeamGb]!;
  return byName[key];
}

int _oversToBalls(String overs) {
  final parts = overs.trim().split('.');
  final ov = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final b = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return ov * 6 + b.clamp(0, 5);
}

String _ballsToOvers(int balls) => '${balls ~/ 6}.${balls % 6}';

class _BatAgg {
  _BatAgg(this.name, this.teamName);

  String name;
  String teamName;
  final matchIds = <String>{};
  int innings = 0;
  int runs = 0;
  int highest = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int outs = 0;
}

class _BowlAgg {
  _BowlAgg(this.name, this.teamName);

  String name;
  String teamName;
  final matchIds = <String>{};
  int innings = 0;
  int wickets = 0;
  int balls = 0;
  int maidens = 0;
  int runs = 0;
  int best = 0;
}

/// Season 2 bat/bowl from structured scorecards (cross-check vs CricHeroes CSVs).
({List<Season1BattingRow> batting, List<Season1BowlingRow> bowling})
    season2StatsFromScorecards() {
  final bats = <String, _BatAgg>{};
  final bowls = <String, _BowlAgg>{};

  for (final m in buildSeason2SeedMatches()) {
    for (final inn in m.innings) {
      final bowlingTeamName =
          inn.battingTeamId == m.teamAId ? m.teamBName : m.teamAName;

      for (final b in inn.batting) {
        final key = _nk(b.name);
        final agg = bats.putIfAbsent(
          key,
          () => _BatAgg(b.name, inn.battingTeamName),
        );
        agg.matchIds.add(m.id);
        agg.innings += 1;
        agg.runs += b.runs;
        agg.balls += b.balls;
        agg.fours += b.fours;
        agg.sixes += b.sixes;
        if (b.runs > agg.highest) agg.highest = b.runs;
        final d = b.dismissal.toLowerCase();
        // CricHeroes treats retired out as an out for average (Aslam avg 13.50).
        if (d != 'not out' && d != 'retired hurt') {
          agg.outs += 1;
        }
        agg.teamName = inn.battingTeamName;
      }

      for (final b in inn.bowling) {
        final key = _nk(b.name);
        final agg = bowls.putIfAbsent(
          key,
          () => _BowlAgg(b.name, bowlingTeamName),
        );
        agg.teamName = bowlingTeamName;
        agg.matchIds.add(m.id);
        agg.innings += 1;
        agg.wickets += b.wickets;
        agg.balls += _oversToBalls(b.overs);
        agg.maidens += b.maidens;
        agg.runs += b.runs;
        if (b.wickets > agg.best) agg.best = b.wickets;
      }
    }
  }

  String teamFor(String name, String fallback) =>
      season2CurrentTeamName(name) ?? fallback;

  final batting = <Season1BattingRow>[
    for (final e in bats.entries)
      Season1BattingRow(
        playerId: e.key,
        name: e.value.name,
        teamName: teamFor(e.value.name, e.value.teamName),
        matches: e.value.matchIds.length,
        innings: e.value.innings,
        runs: e.value.runs,
        highest: e.value.highest,
        average: e.value.outs > 0
            ? double.parse((e.value.runs / e.value.outs).toStringAsFixed(2))
            : 0,
        strikeRate: e.value.balls > 0
            ? double.parse(
                (e.value.runs * 100 / e.value.balls).toStringAsFixed(2),
              )
            : 0,
        fours: e.value.fours,
        sixes: e.value.sixes,
      ),
  ]..sort((a, b) => b.runs.compareTo(a.runs));

  final bowling = <Season1BowlingRow>[
    for (final e in bowls.entries)
      Season1BowlingRow(
        playerId: e.key,
        name: e.value.name,
        teamName: teamFor(e.value.name, e.value.teamName),
        matches: e.value.matchIds.length,
        innings: e.value.innings,
        wickets: e.value.wickets,
        overs: _ballsToOvers(e.value.balls),
        maidens: e.value.maidens,
        runs: e.value.runs,
        economy: e.value.balls > 0
            ? double.parse(
                (e.value.runs / (e.value.balls / 6.0)).toStringAsFixed(2),
              )
            : 0,
        best: e.value.best,
      ),
  ]..sort((a, b) {
      final w = b.wickets.compareTo(a.wickets);
      if (w != 0) return w;
      return a.economy.compareTo(b.economy);
    });

  return (batting: batting, bowling: bowling);
}

/// Prefer scorecard bat/bowl + CSV field/MVP; stamp CH player ids & current teams.
Season1Archive season2ArchiveWithScorecardTruth(Season1Archive csv) {
  final fromCards = season2StatsFromScorecards();
  final idByName = <String, String>{
    for (final r in csv.batting)
      if (r.playerId.isNotEmpty) _nk(r.name): r.playerId,
    for (final r in csv.bowling)
      if (r.playerId.isNotEmpty) _nk(r.name): r.playerId,
    for (final r in csv.fielding)
      if (r.playerId.isNotEmpty) _nk(r.name): r.playerId,
  };

  Season1BattingRow stampBat(Season1BattingRow r) => Season1BattingRow(
        playerId: idByName[_nk(r.name)] ?? r.playerId,
        name: r.name,
        teamName: season2CurrentTeamName(r.name) ?? r.teamName,
        matches: r.matches,
        innings: r.innings,
        runs: r.runs,
        highest: r.highest,
        average: r.average,
        strikeRate: r.strikeRate,
        fours: r.fours,
        sixes: r.sixes,
      );

  Season1BowlingRow stampBowl(Season1BowlingRow r) => Season1BowlingRow(
        playerId: idByName[_nk(r.name)] ?? r.playerId,
        name: r.name,
        teamName: season2CurrentTeamName(r.name) ?? r.teamName,
        matches: r.matches,
        innings: r.innings,
        wickets: r.wickets,
        overs: r.overs,
        maidens: r.maidens,
        runs: r.runs,
        economy: r.economy,
        best: r.best,
      );

  final bat = <Season1BattingRow>[
    for (final r in fromCards.batting) stampBat(r),
  ];
  final batKeys = bat.map((r) => _nk(r.name)).toSet();
  for (final r in csv.batting) {
    if (batKeys.contains(_nk(r.name))) continue;
    bat.add(stampBat(r));
  }
  bat.sort((a, b) => b.runs.compareTo(a.runs));

  final bowl = <Season1BowlingRow>[
    for (final r in fromCards.bowling) stampBowl(r),
  ];
  final bowlKeys = bowl.map((r) => _nk(r.name)).toSet();
  for (final r in csv.bowling) {
    if (bowlKeys.contains(_nk(r.name))) continue;
    bowl.add(stampBowl(r));
  }
  bowl.sort((a, b) {
    final w = b.wickets.compareTo(a.wickets);
    if (w != 0) return w;
    return a.economy.compareTo(b.economy);
  });

  final fielding = [
    for (final r in csv.fielding)
      Season1FieldingRow(
        playerId: r.playerId,
        name: r.name,
        teamName: season2CurrentTeamName(r.name) ?? r.teamName,
        matches: r.matches,
        catches: r.catches,
        runOuts: r.runOuts,
        stumpings: r.stumpings,
        totalDismissals: r.totalDismissals,
      ),
  ];

  final mvp = [
    for (final r in csv.mvp)
      Season1MvpRow(
        name: r.name,
        teamName: season2CurrentTeamName(r.name) ?? r.teamName,
        matches: r.matches,
        battingPts: r.battingPts,
        bowlingPts: r.bowlingPts,
        fieldingPts: r.fieldingPts,
        total: r.total,
      ),
  ];

  final heroes = <Season1Hero>[
    if (mvp.isNotEmpty)
      Season1Hero(
        title: 'Player of the tournament',
        name: mvp.first.name,
        teamName: mvp.first.teamName,
        summary:
            'MVP ${mvp.first.total.toStringAsFixed(1)} · ${mvp.first.matches} matches',
      ),
    if (bat.isNotEmpty)
      Season1Hero(
        title: 'Best Batter',
        name: bat.first.name,
        teamName: bat.first.teamName,
        summary:
            '${bat.first.runs} runs · avg ${bat.first.average} · SR ${bat.first.strikeRate}',
      ),
    if (bowl.isNotEmpty)
      Season1Hero(
        title: 'Best Bowler',
        name: bowl.first.name,
        teamName: bowl.first.teamName,
        summary:
            '${bowl.first.wickets} wickets · ${bowl.first.overs} ov · econ ${bowl.first.economy}',
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
    batting: bat,
    bowling: bowl,
    fielding: fielding,
    mvp: mvp,
    heroes: heroes,
  );
}
