import 'season1.dart';

/// Farm Premier League Season 2 (2 Aug 2026 – 27 Dec 2026).
/// Leaderboards from CricHeroes CSV exports; points from official table.
class Season2Meta {
  static const title = 'Farm Premier League';
  static const seasonLabel = 'Season 2';
  static const location = 'Vellore';
  static const dateRange = '2 Aug 2026 – 27 Dec 2026';
  static const totalMatches = 6;
  static const totalTeams = 3;
  static const note = 'Current season · fees apply';
}

/// Points after League Week 2 (9 Aug 2026).
const season2Standings = <Season1Standing>[
  Season1Standing(
    rank: 1,
    teamName: 'Gully Blasters',
    played: 4,
    won: 3,
    lost: 1,
    points: 6,
    nrr: 0.736,
    forScore: '235/40',
    againstScore: '197/38.2',
    last5: 'W-L-W-W',
  ),
  Season1Standing(
    rank: 2,
    teamName: 'OX CC',
    played: 4,
    won: 3,
    lost: 1,
    points: 6,
    nrr: 0.293,
    forScore: '195/35.3',
    againstScore: '208/40',
    last5: 'W-W-W-L',
  ),
  Season1Standing(
    rank: 3,
    teamName: 'Farm Avengers CC',
    played: 4,
    won: 0,
    lost: 4,
    points: 0,
    nrr: -1.060,
    forScore: '203/40',
    againstScore: '228/37.1',
    last5: 'L-L-L-L',
  ),
];

class Season2Loader {
  static Season1Archive? _cached;

  static void clearCache() => _cached = null;

  static Future<Season1Archive> load() async {
    final hit = _cached;
    if (hit != null) return hit;
    return _cached = await Season1Loader.loadFromAssetPaths(
      battingAsset: 'assets/season2/batting_leaderboard.csv',
      bowlingAsset: 'assets/season2/bowling_leaderboard.csv',
      fieldingAsset: 'assets/season2/fielding_leaderboard.csv',
      mvpAsset: 'assets/season2/mvp_leaderboard.csv',
    );
  }
}
