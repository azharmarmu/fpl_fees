import 'season1.dart';

/// Farm Premier League Season 2 (2 Aug 2026 – 27 Dec 2026).
/// Leaderboards from CricHeroes CSV exports; points from official table.
class Season2Meta {
  static const title = 'Farm Premier League';
  static const seasonLabel = 'Season 2';
  static const location = 'Vellore';
  static const dateRange = '2 Aug 2026 – 27 Dec 2026';
  static const totalMatches = 3;
  static const totalTeams = 3;
  static const note = 'Current season · fees apply';
}

/// Points after League Week 1 (2 Aug 2026).
const season2Standings = <Season1Standing>[
  Season1Standing(
    rank: 1,
    teamName: 'OX CC',
    played: 2,
    won: 2,
    lost: 0,
    points: 4,
    nrr: 1.055,
    forScore: '90/16.3',
    againstScore: '88/20',
    last5: 'W-W',
  ),
  Season1Standing(
    rank: 2,
    teamName: 'Gully Blasters',
    played: 2,
    won: 1,
    lost: 1,
    points: 2,
    nrr: 0.414,
    forScore: '113/20',
    againstScore: '96/18.2',
    last5: 'W-L',
  ),
  Season1Standing(
    rank: 3,
    teamName: 'Farm Avengers CC',
    played: 2,
    won: 0,
    lost: 2,
    points: 0,
    nrr: -1.545,
    forScore: '99/20',
    againstScore: '118/18.1',
    last5: 'L-L',
  ),
];

class Season2Loader {
  static Season1Archive? _cached;

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
