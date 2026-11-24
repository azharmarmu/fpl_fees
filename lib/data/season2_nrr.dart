import '../config.dart';
import '../models/models.dart';
import 'season1.dart';
import 'season2_matches.dart';
import 'season2_points.dart';

/// Cricket overs → balls (legal delivery count).
int season2OversToBalls(String overs) {
  final parts = overs.trim().split('.');
  final ov = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final b = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return ov * 6 + b.clamp(0, 5);
}

/// CricHeroes-style `runs/overs.balls` (e.g. `1348/228.2`).
String season2BallsToForAgainstDisplay(int runs, int balls) =>
    '$runs/${balls ~/ 6}.${balls % 6}';

/// Scheduled balls per side for this match (8-over day vs 10-over league).
int season2MatchScheduledBalls(MatchScorecard match) {
  if (match.innings.isEmpty) return 60;
  final longest = match.innings
      .map((i) => season2OversToBalls(i.overs))
      .reduce((a, b) => a > b ? a : b);
  return longest <= 48 ? 48 : 60;
}

String? _winnerTeamId(MatchScorecard match) {
  final t = match.resultText.trim();
  if (t.isEmpty || t.toLowerCase().contains('no result')) return null;
  final idx = t.toLowerCase().indexOf(' won by');
  if (idx <= 0) return null;
  final name = t.substring(0, idx).trim();
  for (final e in kTeamNames.entries) {
    if (e.value == name) return e.key;
  }
  return null;
}

/// CricHeroes credits full match quota on these innings even though the side won.
bool _cricHeroesForceScheduledQuota(MatchScorecard match, int inningsIndex) {
  switch ('${match.id}:$inningsIndex') {
    case 'ch_26447419:1': // OX chase (10-over quota; 8.2 ov actual)
    case 'ch_27237715:1': // OX chase
    case 'ch_27770741:0': // GB defend 53/7 (9.4 ov actual)
      return true;
    default:
      return false;
  }
}

/// Balls counted for For/Against and NRR for one innings (both teams use this value).
int season2NrrBallsCountedForInnings(
  MatchScorecard match,
  MatchInnings innings,
  int inningsIndex,
) {
  final scheduled = season2MatchScheduledBalls(match);
  final actual = season2OversToBalls(innings.overs);
  final winner = _winnerTeamId(match);
  final battingLost =
      winner != null && winner != innings.battingTeamId;
  final allOut = innings.wickets >= 8;

  var useScheduled = allOut || battingLost;
  if (!useScheduled &&
      winner == innings.battingTeamId &&
      _cricHeroesForceScheduledQuota(match, inningsIndex)) {
    useScheduled = true;
  }
  return useScheduled ? scheduled : actual;
}

class Season2NrrTotals {
  const Season2NrrTotals({
    required this.runsFor,
    required this.ballsFor,
    required this.runsAgainst,
    required this.ballsAgainst,
  });

  final int runsFor;
  final int ballsFor;
  final int runsAgainst;
  final int ballsAgainst;

  double get nrr {
    if (ballsFor == 0 || ballsAgainst == 0) return 0;
    return (runsFor / (ballsFor / 6.0)) - (runsAgainst / (ballsAgainst / 6.0));
  }

  String get forDisplay => season2BallsToForAgainstDisplay(runsFor, ballsFor);

  String get againstDisplay =>
      season2BallsToForAgainstDisplay(runsAgainst, ballsAgainst);
}

/// NRR inputs from played matches only — wash-out weeks (Week 13 NR) excluded.
Map<String, Season2NrrTotals> season2NrrFromMatches(
  List<MatchScorecard> matches,
) {
  final ids = [kTeamGb, kTeamOx, kTeamAvengers];
  final rf = {for (final id in ids) id: 0};
  final bf = {for (final id in ids) id: 0};
  final ra = {for (final id in ids) id: 0};
  final ba = {for (final id in ids) id: 0};

  for (final m in matches) {
    if (m.isNoResult || m.resultText.toLowerCase().contains('no result')) {
      continue;
    }
    if (m.innings.length < 2) continue;
    for (var i = 0; i < m.innings.length; i++) {
      final inn = m.innings[i];
      final bowlId = inn.battingTeamId == m.teamAId ? m.teamBId : m.teamAId;
      final balls = season2NrrBallsCountedForInnings(m, inn, i);
      rf[inn.battingTeamId] = rf[inn.battingTeamId]! + inn.runs;
      bf[inn.battingTeamId] = bf[inn.battingTeamId]! + balls;
      ra[bowlId] = ra[bowlId]! + inn.runs;
      ba[bowlId] = ba[bowlId]! + balls;
    }
  }

  return {
    for (final id in ids)
      id: Season2NrrTotals(
        runsFor: rf[id]!,
        ballsFor: bf[id]!,
        runsAgainst: ra[id]!,
        ballsAgainst: ba[id]!,
      ),
  };
}

/// Last 5 completed results (Week 13 washouts omitted, matching CricHeroes).
const _season2Last5 = {
  kTeamGb: 'W-W-W-L-L',
  kTeamOx: 'W-W-L-W-W',
  kTeamAvengers: 'L-L-L-L-W',
};

/// Points + NRR standing rows from seed scorecards (CricHeroes table rules).
List<Season1Standing> buildSeason2Standings() {
  final matches = buildSeason2SeedMatches();
  final pts = season2PointsFromMatches(matches);
  final nrr = season2NrrFromMatches(matches);
  final rows = [
    for (final id in [kTeamGb, kTeamOx, kTeamAvengers])
      (
        id: id,
        pts: pts[id]!,
        nrr: nrr[id]!,
      ),
  ]
    ..sort((a, b) {
      final p = b.pts.points.compareTo(a.pts.points);
      if (p != 0) return p;
      return b.nrr.nrr.compareTo(a.nrr.nrr);
    });

  return [
    for (var r = 0; r < rows.length; r++)
      Season1Standing(
        rank: r + 1,
        teamName: kTeamNames[rows[r].id]!,
        played: rows[r].pts.played,
        won: rows[r].pts.won,
        lost: rows[r].pts.lost,
        points: rows[r].pts.points,
        nrr: double.parse(rows[r].nrr.nrr.toStringAsFixed(3)),
        forScore: rows[r].nrr.forDisplay,
        againstScore: rows[r].nrr.againstDisplay,
        last5: _season2Last5[rows[r].id]!,
      ),
  ];
}