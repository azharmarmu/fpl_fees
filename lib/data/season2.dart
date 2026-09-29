import 'season1.dart';
import 'season2_stats.dart';

/// Farm Premier League Season 2 (2 Aug 2026 – 27 Dec 2026).
/// Leaderboards from CricHeroes CSV exports + scorecard cross-check;
/// points from official table.
class Season2Meta {
  static const title = 'Farm Premier League';
  static const seasonLabel = 'Season 2';
  static const location = 'Vellore';
  static const dateRange = '2 Aug 2026 – 27 Dec 2026';
  static const totalMatches = 27;
  static const totalTeams = 3;
  static const note = 'Current season · fees apply';
}

/// Points after League Week 9 (27 Sep 2026) — from CricHeroes points table.
const season2Standings = <Season1Standing>[
  Season1Standing(
    rank: 1,
    teamName: 'Gully Blasters',
    played: 18,
    won: 10,
    lost: 8,
    points: 20,
    nrr: 0.361,
    forScore: '994/173',
    againstScore: '928/172.2',
    last5: 'L-W-L-L-L',
  ),
  Season1Standing(
    rank: 2,
    teamName: 'OX CC',
    played: 18,
    won: 10,
    lost: 8,
    points: 20,
    nrr: -0.325,
    forScore: '930/175.1',
    againstScore: '985/174.5',
    last5: 'W-L-W-W-W',
  ),
  Season1Standing(
    rank: 3,
    teamName: 'Farm Avengers CC',
    played: 18,
    won: 7,
    lost: 11,
    points: 14,
    nrr: -0.033,
    forScore: '915/172.5',
    againstScore: '926/173.5',
    last5: 'L-L-W-L-W',
  ),
];

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
