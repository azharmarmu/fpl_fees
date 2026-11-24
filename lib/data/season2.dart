import 'season1.dart';
import 'season2_nrr.dart';
import 'season2_stats.dart';

/// Farm Premier League Season 2 (2 Aug 2026 – 27 Dec 2026).
/// Leaderboards from CricHeroes CSV exports + scorecard cross-check;
/// points from official table.
class Season2Meta {
  static const title = 'Farm Premier League';
  static const seasonLabel = 'Season 2';
  static const location = 'Vellore';
  static const dateRange = '2 Aug 2026 – 27 Dec 2026';
  static const totalMatches = 42;
  static const totalTeams = 3;
  static const note = 'Current season · fees apply';

  /// Shown on schedule / stats — rain, power, buffer weeks.
  static const schedulePolicy =
      'Week 12 (18 Oct) postponed again — play date TBD (e.g. a holiday weekday). '
      'VPL Season 2 only on 1 Nov and 8 Nov (no FPL those Sundays). '
      'If a week cannot be played and there is no buffer left: each affected match '
      'is No Result and each team gets 1 point (no reschedule). '
      'CricHeroes later dropped the Week 13 (25 Oct) washouts from the official '
      'table (NR = 0, no points); standings follow that table.';
}

/// Points after latest seeded scorecards — NRR/for/against from [buildSeason2Standings].
List<Season1Standing> get season2Standings => buildSeason2Standings();

/// Official week award — best team (W–L / week NRR) + best player (CricHeroes MVP that week).
class Season2WeekAward {
  const Season2WeekAward({
    required this.weekIndex,
    required this.weekId,
    required this.dateLabel,
    required this.bestTeamName,
    required this.bestTeamSummary,
    required this.bestPlayerName,
    required this.bestPlayerTeamName,
    required this.bestPlayerSummary,
  });

  final int weekIndex;
  final String weekId;
  final String dateLabel;
  final String bestTeamName;
  final String bestTeamSummary;
  final String bestPlayerName;
  final String bestPlayerTeamName;
  final String bestPlayerSummary;
}

/// Maintained after each league Sunday. Player = top CricHeroes MVP gain that week.
const season2WeekAwards = <Season2WeekAward>[
  Season2WeekAward(
    weekIndex: 1,
    weekId: '2026-08-02',
    dateLabel: '2 Aug 2026',
    bestTeamName: 'OX CC',
    bestTeamSummary: '2–0',
    bestPlayerName: 'MONIZ',
    bestPlayerTeamName: 'OX CC',
    bestPlayerSummary: 'MVP 7.0',
  ),
  Season2WeekAward(
    weekIndex: 2,
    weekId: '2026-08-09',
    dateLabel: '9 Aug 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '2–0',
    bestPlayerName: 'M S Rusfi',
    bestPlayerTeamName: 'Farm Avengers CC',
    bestPlayerSummary: 'MVP +6.8',
  ),
  Season2WeekAward(
    weekIndex: 3,
    weekId: '2026-08-16',
    dateLabel: '16 Aug 2026',
    bestTeamName: 'Farm Avengers CC',
    bestTeamSummary: '2–0',
    bestPlayerName: 'Azhar Marmu',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP +8.2 · 48*',
  ),
  Season2WeekAward(
    weekIndex: 4,
    weekId: '2026-08-23',
    dateLabel: '23 Aug 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '1–1 · best NRR',
    bestPlayerName: 'Azhar Marmu',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP +6.6 · 50',
  ),
  Season2WeekAward(
    weekIndex: 5,
    weekId: '2026-08-30',
    dateLabel: '30 Aug 2026',
    bestTeamName: 'OX CC',
    bestTeamSummary: '1–1 · best NRR',
    bestPlayerName: 'Sadam',
    bestPlayerTeamName: 'OX CC',
    bestPlayerSummary: 'MVP +6.7',
  ),
  Season2WeekAward(
    weekIndex: 6,
    weekId: '2026-09-06',
    dateLabel: '6 Sep 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '2–0',
    bestPlayerName: 'M S Rusfi',
    bestPlayerTeamName: 'Farm Avengers CC',
    bestPlayerSummary: 'MVP +9.6',
  ),
  Season2WeekAward(
    weekIndex: 7,
    weekId: '2026-09-13',
    dateLabel: '13 Sep 2026',
    bestTeamName: 'OX CC',
    bestTeamSummary: '2–0',
    bestPlayerName: 'Munaf Cpm',
    bestPlayerTeamName: 'Farm Avengers CC',
    bestPlayerSummary: 'MVP +8.1',
  ),
  Season2WeekAward(
    weekIndex: 8,
    weekId: '2026-09-20',
    dateLabel: '20 Sep 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '1–1 · best NRR',
    bestPlayerName: 'MD Saif',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP +6.3 · 3/5',
  ),
  Season2WeekAward(
    weekIndex: 9,
    weekId: '2026-09-27',
    dateLabel: '27 Sep 2026',
    bestTeamName: 'OX CC',
    bestTeamSummary: '2–0',
    bestPlayerName: 'Ajaz',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP +9.7 · 3/9 & 2/12',
  ),
  Season2WeekAward(
    weekIndex: 10,
    weekId: '2026-10-04',
    dateLabel: '4 Oct 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '2–0 · 8-over day',
    bestPlayerName: 'Azhar Marmu',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP +8.7 · 32* & 28*',
  ),
  Season2WeekAward(
    weekIndex: 11,
    weekId: '2026-10-11',
    dateLabel: '11 Oct 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '1–1 · best NRR',
    bestPlayerName: 'Munaf Cpm',
    bestPlayerTeamName: 'Farm Avengers CC',
    bestPlayerSummary: 'MVP +6.7 · 25 & 2/3',
  ),
  Season2WeekAward(
    weekIndex: 14,
    weekId: '2026-11-15',
    dateLabel: '15 Nov 2026',
    bestTeamName: 'Gully Blasters',
    bestTeamSummary: '2–0',
    bestPlayerName: 'Immu',
    bestPlayerTeamName: 'Gully Blasters',
    bestPlayerSummary: 'MVP · 5/8 (0.00 eco)',
  ),
  Season2WeekAward(
    weekIndex: 15,
    weekId: '2026-11-22',
    dateLabel: '22 Nov 2026',
    bestTeamName: 'OX CC',
    bestTeamSummary: '2–0',
    bestPlayerName: 'Munaf Cpm',
    bestPlayerTeamName: 'Farm Avengers CC',
    bestPlayerSummary: '26* & 23* · 1/5',
  ),
];

class Season2Loader {
  static Season1Archive? _cached;

  static void clearCache() => _cached = null;

  static Future<Season1Archive> load() async {
    final hit = _cached;
    if (hit != null) return hit;
    final csv = await Season1Loader.loadFromAssetPaths(
      battingAsset: 'assets/season2/batting_leaderboard.csv',
      bowlingAsset: 'assets/season2/bowling_leaderboard.csv',
      fieldingAsset: 'assets/season2/fielding_leaderboard.csv',
      mvpAsset: 'assets/season2/mvp_leaderboard.csv',
    );
    // Bat/bowl verified against structured scorecards; teams reflect trades.
    return _cached = season2ArchiveWithScorecardTruth(csv);
  }
}
