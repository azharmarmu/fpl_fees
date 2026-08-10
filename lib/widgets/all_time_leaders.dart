import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season1.dart';
import '../data/season2.dart';
import '../models/stat_player.dart';
import '../screens/stat_player_screen.dart';

class StatLeader {
  const StatLeader({
    required this.name,
    required this.teamLabel,
    required this.value,
    this.playerId,
  });

  final String name;
  final String teamLabel;
  final int value;
  final String? playerId;
}

/// Season 2 top batter & bowler from bundled CSVs (updated each deploy).
/// Firestore career docs can lag until admin re-uploads — do not prefer them here.
class SeasonLeaders extends StatelessWidget {
  const SeasonLeaders({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  static Future<({StatLeader runs, StatLeader wickets})?> load({
    bool cloudEnabled = false,
  }) async {
    try {
      return await _fromSeason2Assets();
    } catch (_) {
      if (!cloudEnabled) return null;
      try {
        return await _fromFirestoreSeason('s2');
      } catch (_) {
        return null;
      }
    }
  }

  static Future<({StatLeader runs, StatLeader wickets})>
      _fromSeason2Assets() async {
    final a = await Season2Loader.load();
    if (a.batting.isEmpty || a.bowling.isEmpty) {
      throw StateError('Season 2 leaderboards empty');
    }
    final bat = a.batting.first;
    final bowl = a.bowling.first;
    return (
      runs: StatLeader(
        name: bat.name,
        teamLabel: bat.teamName,
        value: bat.runs,
        playerId: bat.playerId,
      ),
      wickets: StatLeader(
        name: bowl.name,
        teamLabel: bowl.teamName,
        value: bowl.wickets,
        playerId: bowl.playerId,
      ),
    );
  }

  static Future<({StatLeader runs, StatLeader wickets})?>
      _fromFirestoreSeason(String seasonId) async {
    final snap =
        await FirebaseFirestore.instance.collection('statPlayers').get();
    if (snap.docs.isEmpty) return null;

    StatLeader? topRuns;
    StatLeader? topWkts;

    for (final doc in snap.docs) {
      final p = CareerPlayer.fromJson(doc.data());
      final s = p.seasons[seasonId];
      if (s == null) continue;
      final runs = s.batting?.runs ?? 0;
      final wickets = s.bowling?.wickets ?? 0;
      final teamLabel = s.primaryTeamName.isNotEmpty
          ? s.primaryTeamName
          : (s.teams.isEmpty ? '' : s.teams.first);
      if (runs > 0 && (topRuns == null || runs > topRuns.value)) {
        topRuns = StatLeader(
          name: p.name,
          teamLabel: teamLabel,
          value: runs,
          playerId: p.id,
        );
      }
      if (wickets > 0 && (topWkts == null || wickets > topWkts.value)) {
        topWkts = StatLeader(
          name: p.name,
          teamLabel: teamLabel,
          value: wickets,
          playerId: p.id,
        );
      }
    }

    if (topRuns == null || topWkts == null) return null;
    return (runs: topRuns, wickets: topWkts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({StatLeader runs, StatLeader wickets})?>(
      future: load(cloudEnabled: cloudEnabled),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        return _LeadersSection(
          heading: 'THIS SEASON',
          subtitle: 'Season 2 · top batter & bowler',
          runsTitle: 'Top batsman',
          wicketsTitle: 'Top bowler',
          runs: data.runs,
          wickets: data.wickets,
          cloudEnabled: cloudEnabled,
        );
      },
    );
  }
}

/// Most runs & wickets across seasons from bundled CSVs (S1 + S2).
/// Firestore career docs can lag until admin re-uploads.
class AllTimeLeaders extends StatelessWidget {
  const AllTimeLeaders({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  static Future<({StatLeader runs, StatLeader wickets})> load({
    bool cloudEnabled = false,
  }) async {
    try {
      return await _fromBundledAssets();
    } catch (_) {
      if (cloudEnabled) {
        try {
          final fromCloud = await _fromFirestore();
          if (fromCloud != null) return fromCloud;
        } catch (_) {}
      }
      return _fromSeason1Assets();
    }
  }

  /// Aggregate S1 + S2 leaderboard CSVs by player id / name.
  static Future<({StatLeader runs, StatLeader wickets})>
      _fromBundledAssets() async {
    final s1 = await Season1Loader.load();
    final s2 = await Season2Loader.load();

    final runsByKey = <String, StatLeader>{};
    final wktsByKey = <String, StatLeader>{};

    void addRuns(String id, String name, String team, int runs) {
      if (runs <= 0) return;
      final key = id.isNotEmpty ? id : name.toLowerCase();
      final prev = runsByKey[key];
      final teams = <String>{
        if (prev != null && prev.teamLabel.isNotEmpty)
          ...prev.teamLabel.split(' · '),
        if (team.isNotEmpty) team,
      };
      runsByKey[key] = StatLeader(
        name: name,
        teamLabel: teams.join(' · '),
        value: (prev?.value ?? 0) + runs,
        playerId: id.isNotEmpty ? id : prev?.playerId,
      );
    }

    void addWkts(String id, String name, String team, int wickets) {
      if (wickets <= 0) return;
      final key = id.isNotEmpty ? id : name.toLowerCase();
      final prev = wktsByKey[key];
      final teams = <String>{
        if (prev != null && prev.teamLabel.isNotEmpty)
          ...prev.teamLabel.split(' · '),
        if (team.isNotEmpty) team,
      };
      wktsByKey[key] = StatLeader(
        name: name,
        teamLabel: teams.join(' · '),
        value: (prev?.value ?? 0) + wickets,
        playerId: id.isNotEmpty ? id : prev?.playerId,
      );
    }

    for (final r in s1.batting) {
      addRuns(r.playerId, r.name, r.teamName, r.runs);
    }
    for (final r in s2.batting) {
      addRuns(r.playerId, r.name, r.teamName, r.runs);
    }
    for (final r in s1.bowling) {
      addWkts(r.playerId, r.name, r.teamName, r.wickets);
    }
    for (final r in s2.bowling) {
      addWkts(r.playerId, r.name, r.teamName, r.wickets);
    }

    if (runsByKey.isEmpty || wktsByKey.isEmpty) {
      throw StateError('Bundled all-time leaderboards empty');
    }

    final topRuns = runsByKey.values.reduce((a, b) => a.value >= b.value ? a : b);
    final topWkts = wktsByKey.values.reduce((a, b) => a.value >= b.value ? a : b);
    return (runs: topRuns, wickets: topWkts);
  }

  static Future<({StatLeader runs, StatLeader wickets})>
      _fromSeason1Assets() async {
    final a = await Season1Loader.load();
    final bat = a.batting.first;
    final bowl = a.bowling.first;
    return (
      runs: StatLeader(
        name: bat.name,
        teamLabel: bat.teamName,
        value: bat.runs,
        playerId: bat.playerId,
      ),
      wickets: StatLeader(
        name: bowl.name,
        teamLabel: bowl.teamName,
        value: bowl.wickets,
        playerId: bowl.playerId,
      ),
    );
  }

  static Future<({StatLeader runs, StatLeader wickets})?>
      _fromFirestore() async {
    final snap =
        await FirebaseFirestore.instance.collection('statPlayers').get();
    if (snap.docs.isEmpty) return null;

    StatLeader? topRuns;
    StatLeader? topWkts;

    for (final doc in snap.docs) {
      final p = CareerPlayer.fromJson(doc.data());
      var runs = 0;
      var wickets = 0;
      final teams = <String>{};
      for (final s in p.seasons.values) {
        teams.addAll(s.teams);
        runs += s.batting?.runs ?? 0;
        wickets += s.bowling?.wickets ?? 0;
      }
      final teamLabel = teams.isEmpty ? '' : teams.join(' · ');
      if (topRuns == null || runs > topRuns.value) {
        topRuns = StatLeader(
          name: p.name,
          teamLabel: teamLabel,
          value: runs,
          playerId: p.id,
        );
      }
      if (topWkts == null || wickets > topWkts.value) {
        topWkts = StatLeader(
          name: p.name,
          teamLabel: teamLabel,
          value: wickets,
          playerId: p.id,
        );
      }
    }

    if (topRuns == null || topWkts == null) return null;
    if (topRuns.value == 0 && topWkts.value == 0) return null;
    return (runs: topRuns, wickets: topWkts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({StatLeader runs, StatLeader wickets})>(
      future: load(cloudEnabled: cloudEnabled),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final runs = snap.data!.runs;
        final wickets = snap.data!.wickets;
        return _LeadersSection(
          heading: 'ALL-TIME LEADERS',
          subtitle: 'Across all seasons',
          runsTitle: 'Most runs',
          wicketsTitle: 'Most wickets',
          runs: runs,
          wickets: wickets,
          cloudEnabled: cloudEnabled,
        );
      },
    );
  }
}

class _LeadersSection extends StatelessWidget {
  const _LeadersSection({
    required this.heading,
    required this.subtitle,
    required this.runsTitle,
    required this.wicketsTitle,
    required this.runs,
    required this.wickets,
    required this.cloudEnabled,
  });

  final String heading;
  final String subtitle;
  final String runsTitle;
  final String wicketsTitle;
  final StatLeader runs;
  final StatLeader wickets;
  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: GoogleFonts.bebasNeue(
            fontSize: 18,
            color: const Color(0xFFB8F27A),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LeaderBox(
                title: runsTitle,
                leader: runs,
                unit: 'runs',
                cloudEnabled: cloudEnabled,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LeaderBox(
                title: wicketsTitle,
                leader: wickets,
                unit: 'wkts',
                cloudEnabled: cloudEnabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeaderBox extends StatelessWidget {
  const _LeaderBox({
    required this.title,
    required this.leader,
    required this.unit,
    required this.cloudEnabled,
  });

  final String title;
  final StatLeader leader;
  final String unit;
  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2E20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatPlayerScreen(
              playerId: leader.playerId,
              playerName: leader.name,
              cloudEnabled: cloudEnabled,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${leader.value}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 36,
                  height: 1,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                leader.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (leader.teamLabel.isNotEmpty)
                Text(
                  leader.teamLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
