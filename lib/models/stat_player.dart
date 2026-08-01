/// Cross-season stats player (CricHeroes / archive), separate from fee-squad [FplPlayer].
class CareerPlayer {
  const CareerPlayer({
    required this.id,
    required this.name,
    required this.seasons,
  });

  final String id;
  final String name;
  final Map<String, CareerSeasonStats> seasons;

  String get nameLower => name.trim().toLowerCase();

  List<String> get allTeams {
    final out = <String>{};
    for (final s in seasons.values) {
      out.addAll(s.teams);
    }
    return out.toList()..sort();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameLower': nameLower,
        'seasonIds': seasons.keys.toList(),
        'seasons': {
          for (final e in seasons.entries) e.key: e.value.toJson(),
        },
      };

  factory CareerPlayer.fromJson(Map<String, dynamic> json) {
    final raw = json['seasons'];
    final map = <String, CareerSeasonStats>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        map['${e.key}'] = CareerSeasonStats.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }
    return CareerPlayer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      seasons: map,
    );
  }
}

class CareerSeasonStats {
  const CareerSeasonStats({
    required this.seasonId,
    required this.seasonLabel,
    required this.teams,
    this.primaryTeamName = '',
    this.batting,
    this.bowling,
    this.fielding,
    this.mvp,
  });

  final String seasonId;
  final String seasonLabel;
  final List<String> teams;
  final String primaryTeamName;
  final CareerBatting? batting;
  final CareerBowling? bowling;
  final CareerFielding? fielding;
  final CareerMvp? mvp;

  Map<String, dynamic> toJson() => {
        'seasonId': seasonId,
        'seasonLabel': seasonLabel,
        'teams': teams,
        'primaryTeamName': primaryTeamName,
        if (batting != null) 'batting': batting!.toJson(),
        if (bowling != null) 'bowling': bowling!.toJson(),
        if (fielding != null) 'fielding': fielding!.toJson(),
        if (mvp != null) 'mvp': mvp!.toJson(),
      };

  factory CareerSeasonStats.fromJson(Map<String, dynamic> json) {
    return CareerSeasonStats(
      seasonId: json['seasonId'] as String? ?? '',
      seasonLabel: json['seasonLabel'] as String? ?? '',
      teams: (json['teams'] as List? ?? []).map((e) => '$e').toList(),
      primaryTeamName: json['primaryTeamName'] as String? ?? '',
      batting: json['batting'] is Map
          ? CareerBatting.fromJson(Map<String, dynamic>.from(json['batting'] as Map))
          : null,
      bowling: json['bowling'] is Map
          ? CareerBowling.fromJson(Map<String, dynamic>.from(json['bowling'] as Map))
          : null,
      fielding: json['fielding'] is Map
          ? CareerFielding.fromJson(
              Map<String, dynamic>.from(json['fielding'] as Map),
            )
          : null,
      mvp: json['mvp'] is Map
          ? CareerMvp.fromJson(Map<String, dynamic>.from(json['mvp'] as Map))
          : null,
    );
  }
}

class CareerBatting {
  const CareerBatting({
    required this.matches,
    required this.innings,
    required this.runs,
    required this.highest,
    required this.average,
    required this.strikeRate,
    required this.fours,
    required this.sixes,
  });

  final int matches;
  final int innings;
  final int runs;
  final int highest;
  final double average;
  final double strikeRate;
  final int fours;
  final int sixes;

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'innings': innings,
        'runs': runs,
        'highest': highest,
        'average': average,
        'strikeRate': strikeRate,
        'fours': fours,
        'sixes': sixes,
      };

  factory CareerBatting.fromJson(Map<String, dynamic> json) => CareerBatting(
        matches: (json['matches'] as num?)?.toInt() ?? 0,
        innings: (json['innings'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        highest: (json['highest'] as num?)?.toInt() ?? 0,
        average: (json['average'] as num?)?.toDouble() ?? 0,
        strikeRate: (json['strikeRate'] as num?)?.toDouble() ?? 0,
        fours: (json['fours'] as num?)?.toInt() ?? 0,
        sixes: (json['sixes'] as num?)?.toInt() ?? 0,
      );
}

class CareerBowling {
  const CareerBowling({
    required this.matches,
    required this.innings,
    required this.wickets,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.economy,
    required this.best,
  });

  final int matches;
  final int innings;
  final int wickets;
  final String overs;
  final int maidens;
  final int runs;
  final double economy;
  final int best;

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'innings': innings,
        'wickets': wickets,
        'overs': overs,
        'maidens': maidens,
        'runs': runs,
        'economy': economy,
        'best': best,
      };

  factory CareerBowling.fromJson(Map<String, dynamic> json) => CareerBowling(
        matches: (json['matches'] as num?)?.toInt() ?? 0,
        innings: (json['innings'] as num?)?.toInt() ?? 0,
        wickets: (json['wickets'] as num?)?.toInt() ?? 0,
        overs: '${json['overs'] ?? '0'}',
        maidens: (json['maidens'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        economy: (json['economy'] as num?)?.toDouble() ?? 0,
        best: (json['best'] as num?)?.toInt() ?? 0,
      );
}

class CareerFielding {
  const CareerFielding({
    required this.matches,
    required this.catches,
    required this.runOuts,
    required this.stumpings,
    required this.totalDismissals,
  });

  final int matches;
  final int catches;
  final int runOuts;
  final int stumpings;
  final int totalDismissals;

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'catches': catches,
        'runOuts': runOuts,
        'stumpings': stumpings,
        'totalDismissals': totalDismissals,
      };

  factory CareerFielding.fromJson(Map<String, dynamic> json) => CareerFielding(
        matches: (json['matches'] as num?)?.toInt() ?? 0,
        catches: (json['catches'] as num?)?.toInt() ?? 0,
        runOuts: (json['runOuts'] as num?)?.toInt() ?? 0,
        stumpings: (json['stumpings'] as num?)?.toInt() ?? 0,
        totalDismissals: (json['totalDismissals'] as num?)?.toInt() ?? 0,
      );
}

class CareerMvp {
  const CareerMvp({
    required this.matches,
    required this.battingPts,
    required this.bowlingPts,
    required this.fieldingPts,
    required this.total,
  });

  final int matches;
  final double battingPts;
  final double bowlingPts;
  final double fieldingPts;
  final double total;

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'battingPts': battingPts,
        'bowlingPts': bowlingPts,
        'fieldingPts': fieldingPts,
        'total': total,
      };

  factory CareerMvp.fromJson(Map<String, dynamic> json) => CareerMvp(
        matches: (json['matches'] as num?)?.toInt() ?? 0,
        battingPts: (json['battingPts'] as num?)?.toDouble() ?? 0,
        bowlingPts: (json['bowlingPts'] as num?)?.toDouble() ?? 0,
        fieldingPts: (json['fieldingPts'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}
