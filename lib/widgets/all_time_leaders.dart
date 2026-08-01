import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season1.dart';
import '../models/stat_player.dart';
import '../screens/stat_player_screen.dart';

class AllTimeLeader {
  const AllTimeLeader({
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

/// Most runs & most wickets across seasons (Firestore when available, else S1 CSVs).
class AllTimeLeaders extends StatelessWidget {
  const AllTimeLeaders({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  static Future<({AllTimeLeader runs, AllTimeLeader wickets})> load({
    bool cloudEnabled = false,
  }) async {
    if (cloudEnabled) {
      try {
        final fromCloud = await _fromFirestore();
        if (fromCloud != null) return fromCloud;
      } catch (_) {}
    }
    return _fromSeason1Assets();
  }

  static Future<({AllTimeLeader runs, AllTimeLeader wickets})>
      _fromSeason1Assets() async {
    final a = await Season1Loader.load();
    final bat = a.batting.first;
    final bowl = a.bowling.first;
    return (
      runs: AllTimeLeader(
        name: bat.name,
        teamLabel: bat.teamName,
        value: bat.runs,
        playerId: bat.playerId,
      ),
      wickets: AllTimeLeader(
        name: bowl.name,
        teamLabel: bowl.teamName,
        value: bowl.wickets,
        playerId: bowl.playerId,
      ),
    );
  }

  static Future<({AllTimeLeader runs, AllTimeLeader wickets})?>
      _fromFirestore() async {
    final snap =
        await FirebaseFirestore.instance.collection('statPlayers').get();
    if (snap.docs.isEmpty) return null;

    AllTimeLeader? topRuns;
    AllTimeLeader? topWkts;

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
        topRuns = AllTimeLeader(
          name: p.name,
          teamLabel: teamLabel,
          value: runs,
          playerId: p.id,
        );
      }
      if (topWkts == null || wickets > topWkts.value) {
        topWkts = AllTimeLeader(
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
    return FutureBuilder<({AllTimeLeader runs, AllTimeLeader wickets})>(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ALL-TIME LEADERS',
              style: GoogleFonts.bebasNeue(
                fontSize: 18,
                color: const Color(0xFFB8F27A),
              ),
            ),
            const Text(
              'Across all seasons',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LeaderBox(
                    title: 'Most runs',
                    leader: runs,
                    unit: 'runs',
                    cloudEnabled: cloudEnabled,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LeaderBox(
                    title: 'Most wickets',
                    leader: wickets,
                    unit: 'wkts',
                    cloudEnabled: cloudEnabled,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
  final AllTimeLeader leader;
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
