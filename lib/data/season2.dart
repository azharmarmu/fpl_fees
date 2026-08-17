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
  static const totalMatches = 9;
  static const totalTeams = 3;
  static const note = 'Current season · fees apply';
}

/// Points after League Week 3 (16 Aug 2026).
const season2Standings = <Season1Standing>[
  Season1Standing(
    rank: 1,
    teamName: 'Gully Blasters',
    played: 6,
    won: 4,
    lost: 2,
    points: 8,
    nrr: 0.481,
    forScore: '392/60',
    againstScore: '349/57.4',
    last5: 'L-W-W-L-W',
  ),
  Season1Standing(
    rank: 2,
    teamName: 'OX CC',
    played: 6,
    won: 3,
    lost: 3,
    points: 6,
    nrr: -0.404,
    forScore: '318/55.3',
    againstScore: '368/60',
    last5: 'W-W-L-L-L',
  ),
  Season1Standing(
    rank: 3,
    teamName: 'Farm Avengers CC',
    played: 6,
    won: 2,
    lost: 4,
    points: 4,
    nrr: -0.090,
    forScore: '333/59.2',
    againstScore: '326/57.1',
    last5: 'L-L-L-W-W',
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
