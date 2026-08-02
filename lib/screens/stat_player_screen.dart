import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/stat_player.dart';
import '../services/stat_players_repository.dart';

/// Player career / season stats (Firestore with asset fallback).
class StatPlayerScreen extends StatefulWidget {
  const StatPlayerScreen({
    super.key,
    this.playerId,
    this.playerName,
    this.cloudEnabled = false,
  });

  final String? playerId;
  final String? playerName;
  final bool cloudEnabled;

  @override
  State<StatPlayerScreen> createState() => _StatPlayerScreenState();
}

class _StatPlayerScreenState extends State<StatPlayerScreen> {
  late final Future<CareerPlayer?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CareerPlayer?> _load() async {
    final repo = StatPlayersRepository();
    if (widget.cloudEnabled) {
      try {
        if (widget.playerId != null && widget.playerId!.isNotEmpty) {
          final remote = await repo.getById(widget.playerId!);
          if (remote != null) return remote;
        }
        if (widget.playerName != null && widget.playerName!.isNotEmpty) {
          final byName = await repo.getByName(widget.playerName!);
          if (byName != null) return byName;
        }
      } catch (_) {
        // Fall through to assets.
      }
    }
    return StatPlayersRepository.fromBundledAssets(
      playerId: widget.playerId,
      name: widget.playerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Player stats'),
      ),
      body: FutureBuilder<CareerPlayer?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) {
            return const Center(
              child: Text(
                'No stats found for this player',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          final seasonOrder = p.seasons.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                p.name.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 32,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              Text(
                p.allTeams.isEmpty
                    ? 'Team unknown'
                    : 'Teams: ${p.allTeams.join(' · ')}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '${p.seasons.length} season${p.seasons.length == 1 ? '' : 's'} on record',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 16),
              for (final sid in seasonOrder) ...[
                _SeasonBlock(stats: p.seasons[sid]!),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SeasonBlock extends StatelessWidget {
  const _SeasonBlock({required this.stats});
  final CareerSeasonStats stats;

  @override
  Widget build(BuildContext context) {
    final b = stats.batting;
    final bowl = stats.bowling;
    final f = stats.fielding;
    final m = stats.mvp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.seasonLabel.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(
            stats.teams.isEmpty
                ? stats.primaryTeamName
                : stats.teams.join(' · '),
            style: const TextStyle(color: Colors.white54),
          ),
          if (m != null) ...[
            const SizedBox(height: 10),
            _section('MVP points'),
            Text(
              'Total ${m.total.toStringAsFixed(1)}  ·  '
              'Bat ${m.battingPts.toStringAsFixed(1)}  ·  '
              'Bowl ${m.bowlingPts.toStringAsFixed(1)}  ·  '
              'Field ${m.fieldingPts.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (b != null) ...[
            const SizedBox(height: 12),
            _section('Batting'),
            _kv('Runs', '${b.runs} (${b.innings} inn)'),
            _kv('Highest', '${b.highest}'),
            _kv('Average', '${b.average}'),
            _kv('Strike rate', '${b.strikeRate}'),
            _kv('Boundaries', '${b.fours}×4 · ${b.sixes}×6'),
            _kv('Matches', '${b.matches}'),
          ],
          if (bowl != null) ...[
            const SizedBox(height: 12),
            _section('Bowling'),
            _kv('Wickets', '${bowl.wickets}'),
            _kv('Overs', bowl.overs),
            _kv('Economy', '${bowl.economy}'),
            _kv('Best', '${bowl.best}'),
            _kv('Maidens', '${bowl.maidens}'),
            _kv('Runs conceded', '${bowl.runs}'),
          ],
          if (f != null) ...[
            const SizedBox(height: 12),
            _section('Fielding'),
            _kv('Dismissals', '${f.totalDismissals}'),
            _kv('Catches', '${f.catches}'),
            _kv('Run outs', '${f.runOuts}'),
            _kv('Stumpings', '${f.stumpings}'),
          ],
          if (b == null && bowl == null && f == null && m == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No detailed lines for this season',
                style: TextStyle(color: Colors.white38),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(k, style: const TextStyle(color: Colors.white54)),
            ),
            Text(v, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
}
