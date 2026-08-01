import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season1.dart';
import 'stat_player_screen.dart';

class _SeasonOption {
  const _SeasonOption({
    required this.id,
    required this.label,
    required this.subtitle,
  });
  final String id;
  final String label;
  final String subtitle;
}

const _seasons = <_SeasonOption>[
  _SeasonOption(
    id: 's2',
    label: 'Season 2 (current)',
    subtitle: '2 Aug 2026 – 27 Dec 2026 · 3 teams',
  ),
  _SeasonOption(
    id: 's1',
    label: 'Season 1',
    subtitle: '23 Jul 2025 – 26 Jul 2026 · archive',
  ),
];

/// Tournament stats with season switcher (batting, bowling, fielding, MVP, points).
class TournamentStatsScreen extends StatefulWidget {
  const TournamentStatsScreen({
    super.key,
    this.cloudEnabled = false,
    this.initialSeasonId = 's2',
  });

  final bool cloudEnabled;
  final String initialSeasonId;

  @override
  State<TournamentStatsScreen> createState() => _TournamentStatsScreenState();
}

class _TournamentBundle {
  const _TournamentBundle({
    required this.standings,
    required this.batting,
    required this.bowling,
    required this.fielding,
    required this.mvp,
  });

  final List<Season1Standing> standings;
  final List<Season1BattingRow> batting;
  final List<Season1BowlingRow> bowling;
  final List<Season1FieldingRow> fielding;
  final List<Season1MvpRow> mvp;

  bool get isEmpty =>
      standings.isEmpty &&
      batting.isEmpty &&
      bowling.isEmpty &&
      fielding.isEmpty &&
      mvp.isEmpty;
}

class _TournamentStatsScreenState extends State<TournamentStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late String _seasonId;
  late Future<_TournamentBundle> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _seasonId = _seasons.any((s) => s.id == widget.initialSeasonId)
        ? widget.initialSeasonId
        : 's2';
    _future = _load(_seasonId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_TournamentBundle> _load(String seasonId) async {
    if (seasonId == 's1') {
      final a = await Season1Loader.load();
      return _TournamentBundle(
        standings: season1Standings,
        batting: a.batting,
        bowling: a.bowling,
        fielding: a.fielding,
        mvp: a.mvp,
      );
    }
    // Season 2 — populated as weekly stats are imported later.
    return const _TournamentBundle(
      standings: [],
      batting: [],
      bowling: [],
      fielding: [],
      mvp: [],
    );
  }

  void _selectSeason(String? id) {
    if (id == null || id == _seasonId) return;
    setState(() {
      _seasonId = id;
      _future = _load(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final season = _seasons.firstWhere((s) => s.id == _seasonId);
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Tournament stats'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _seasonId,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: InputDecoration(
                    labelText: 'Season',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F1A12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    for (final s in _seasons)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.label,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                  onChanged: _selectSeason,
                ),
              ),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                labelColor: const Color(0xFFB8F27A),
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Batting'),
                  Tab(text: 'Bowling'),
                  Tab(text: 'Fielding'),
                  Tab(text: 'MVP'),
                  Tab(text: 'Points'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              season.subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: FutureBuilder<_TournamentBundle>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      '${snap.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data!;
                void openPlayer({String? id, String? name}) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatPlayerScreen(
                        playerId: id,
                        playerName: name,
                        cloudEnabled: widget.cloudEnabled,
                      ),
                    ),
                  );
                }

                if (data.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _seasonId == 's2'
                            ? 'Season 2 leaderboards will appear here after weekly stats are imported (points table, bat, bowl, field, MVP).'
                            : 'No stats for this season yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabs,
                  children: [
                    _BattingTab(rows: data.batting, onOpenPlayer: openPlayer),
                    _BowlingTab(rows: data.bowling, onOpenPlayer: openPlayer),
                    _FieldingTab(rows: data.fielding, onOpenPlayer: openPlayer),
                    _MvpTab(rows: data.mvp, onOpenPlayer: openPlayer),
                    _PointsTab(standings: data.standings),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsTab extends StatelessWidget {
  const _PointsTab({required this.standings});
  final List<Season1Standing> standings;

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return const Center(
        child: Text('No points table yet', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'POINTS TABLE',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: const Color(0xFFB8F27A),
          ),
        ),
        const SizedBox(height: 12),
        for (final s in standings)
          Card(
            color: const Color(0xFF1A2E20),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2E5A3C),
                child: Text(
                  '#${s.rank}',
                  style: const TextStyle(color: Color(0xFFB8F27A)),
                ),
              ),
              title: Text(s.teamName, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                'P ${s.played} · W ${s.won} · L ${s.lost} · '
                'NRR ${s.nrr.toStringAsFixed(3)}\n'
                'For ${s.forScore} · Against ${s.againstScore}\n'
                'Last 5: ${s.last5}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              isThreeLine: true,
              trailing: Text(
                '${s.points}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: const Color(0xFFB8F27A),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MvpTab extends StatelessWidget {
  const _MvpTab({required this.rows, required this.onOpenPlayer});
  final List<Season1MvpRow> rows;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'MVP',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: const Color(0xFFB8F27A),
              ),
            ),
          );
        }
        final r = rows[i - 1];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text('$i', style: const TextStyle(color: Colors.white38)),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · Bat ${r.battingPts.toStringAsFixed(1)} · '
            'Bowl ${r.bowlingPts.toStringAsFixed(1)} · '
            'Field ${r.fieldingPts.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Text(
            r.total.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFFB8F27A),
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onOpenPlayer(name: r.name),
        );
      },
    );
  }
}

class _BattingTab extends StatelessWidget {
  const _BattingTab({required this.rows, required this.onOpenPlayer});
  final List<Season1BattingRow> rows;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'BATSMEN',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: const Color(0xFFB8F27A),
              ),
            ),
          );
        }
        final r = rows[i - 1];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text('$i', style: const TextStyle(color: Colors.white38)),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.innings} inn · HS ${r.highest} · '
            'SR ${r.strikeRate}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Text(
            '${r.runs}',
            style: const TextStyle(
              color: Color(0xFFB8F27A),
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onOpenPlayer(id: r.playerId, name: r.name),
        );
      },
    );
  }
}

class _BowlingTab extends StatelessWidget {
  const _BowlingTab({required this.rows, required this.onOpenPlayer});
  final List<Season1BowlingRow> rows;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'BOWLERS',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: const Color(0xFFB8F27A),
              ),
            ),
          );
        }
        final r = rows[i - 1];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text('$i', style: const TextStyle(color: Colors.white38)),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.overs} ov · econ ${r.economy}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Text(
            '${r.wickets}',
            style: const TextStyle(
              color: Color(0xFFB8F27A),
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onOpenPlayer(id: r.playerId, name: r.name),
        );
      },
    );
  }
}

class _FieldingTab extends StatelessWidget {
  const _FieldingTab({required this.rows, required this.onOpenPlayer});
  final List<Season1FieldingRow> rows;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'FIELDERS',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: const Color(0xFFB8F27A),
              ),
            ),
          );
        }
        final r = rows[i - 1];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text('$i', style: const TextStyle(color: Colors.white38)),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.catches} catches · ${r.runOuts} RO',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          trailing: Text(
            '${r.totalDismissals}',
            style: const TextStyle(
              color: Color(0xFFB8F27A),
              fontWeight: FontWeight.w700,
            ),
          ),
          onTap: () => onOpenPlayer(id: r.playerId, name: r.name),
        );
      },
    );
  }
}
