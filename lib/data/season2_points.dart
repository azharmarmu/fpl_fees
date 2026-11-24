import '../config.dart';
import '../models/models.dart';
/// Win = 2 pts; loss = 0; no result = 1 pt each (see [Season2Meta.schedulePolicy]).
const kSeason2PointsPerWin = 2;
const kSeason2PointsPerNoResult = 1;

class Season2TeamPoints {
  const Season2TeamPoints({
    required this.teamId,
    required this.played,
    required this.won,
    required this.lost,
    required this.noResults,
    required this.points,
  });

  final String teamId;
  final int played;
  final int won;
  final int lost;
  final int noResults;
  final int points;
}

/// Week 13 (25 Oct 2026) washouts are kept as schedule scorecards but are no
/// longer in the CricHeroes official table (NR = 0, no 1-point awards).
bool season2CountsInOfficialTable(MatchScorecard m) =>
    !m.id.startsWith('2026-10-25');

/// Official league points from seed scorecards (matches CricHeroes table rules).
Map<String, Season2TeamPoints> season2PointsFromMatches(
  List<MatchScorecard> matches,
) {
  final ids = [kTeamGb, kTeamOx, kTeamAvengers];
  final played = {for (final id in ids) id: 0};
  final won = {for (final id in ids) id: 0};
  final lost = {for (final id in ids) id: 0};
  final nr = {for (final id in ids) id: 0};
  final points = {for (final id in ids) id: 0};

  String? winnerTeamName(String resultText) {
    final t = resultText.trim();
    if (t.isEmpty || t.toLowerCase().contains('no result')) return null;
    final idx = t.toLowerCase().indexOf(' won by');
    if (idx <= 0) return null;
    return t.substring(0, idx).trim();
  }

  String? teamIdForName(String name) {
    for (final e in kTeamNames.entries) {
      if (e.value == name) return e.key;
    }
    return null;
  }

  for (final m in matches) {
    if (!season2CountsInOfficialTable(m)) continue;
    if (m.isNoResult ||
        m.resultText.toLowerCase().contains('no result')) {
      played[m.teamAId] = played[m.teamAId]! + 1;
      played[m.teamBId] = played[m.teamBId]! + 1;
      nr[m.teamAId] = nr[m.teamAId]! + 1;
      nr[m.teamBId] = nr[m.teamBId]! + 1;
      points[m.teamAId] = points[m.teamAId]! + kSeason2PointsPerNoResult;
      points[m.teamBId] = points[m.teamBId]! + kSeason2PointsPerNoResult;
      continue;
    }
    final winnerName = winnerTeamName(m.resultText);
    if (winnerName == null) continue;
    final wId = teamIdForName(winnerName);
    if (wId == null) continue;
    final loserId =
        m.teamAId == wId ? m.teamBId : (m.teamBId == wId ? m.teamAId : null);
    if (loserId == null) continue;
    played[wId] = played[wId]! + 1;
    played[loserId] = played[loserId]! + 1;
    won[wId] = won[wId]! + 1;
    lost[loserId] = lost[loserId]! + 1;
    points[wId] = points[wId]! + kSeason2PointsPerWin;
  }

  return {
    for (final id in ids)
      id: Season2TeamPoints(
        teamId: id,
        played: played[id]!,
        won: won[id]!,
        lost: lost[id]!,
        noResults: nr[id]!,
        points: points[id]!,
      ),
  };
}