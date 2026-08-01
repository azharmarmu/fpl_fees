import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season1.dart';
import 'stat_player_screen.dart';

/// Read-only Season 1 archive — visible to admin and players (no fees).
class Season1Screen extends StatefulWidget {
  const Season1Screen({super.key, this.cloudEnabled = false});

  /// When true, player detail prefers Firestore `statPlayers`.
  final bool cloudEnabled;

  @override
  State<Season1Screen> createState() => _Season1ScreenState();
}

class _Season1ScreenState extends State<Season1Screen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final Future<Season1Archive> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _future = Season1Loader.load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Season 1 archive'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: const Color(0xFFB8F27A),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Points'),
            Tab(text: 'Heroes'),
            Tab(text: 'Batting'),
            Tab(text: 'Bowling'),
            Tab(text: 'Fielding'),
          ],
        ),
      ),
      body: FutureBuilder<Season1Archive>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Could not load Season 1: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
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

          return TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(data: data, onOpenPlayer: openPlayer),
              const _PointsTab(),
              _HeroesTab(
                heroes: data.heroes,
                mvp: data.mvp,
                onOpenPlayer: openPlayer,
              ),
              _BattingTab(rows: data.batting, onOpenPlayer: openPlayer),
              _BowlingTab(rows: data.bowling, onOpenPlayer: openPlayer),
              _FieldingTab(rows: data.fielding, onOpenPlayer: openPlayer),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data, required this.onOpenPlayer});
  final Season1Archive data;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          Season1Meta.seasonLabel.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: const Color(0xFFB8F27A),
          ),
        ),
        Text(
          Season1Meta.title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          '${Season1Meta.location} · ${Season1Meta.dateRange}',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          Season1Meta.note,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statTile('${Season1Meta.totalMatches}', 'Total matches'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile('${Season1Meta.totalTeams}', 'Teams'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile('${data.batting.length}', 'Batters listed'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile('${data.bowling.length}', 'Bowlers listed'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Champion',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            season1Standings.first.teamName,
            style: const TextStyle(color: Color(0xFFB8F27A), fontSize: 20),
          ),
          subtitle: Text(
            '${season1Standings.first.points} pts · '
            '${season1Standings.first.won}W–${season1Standings.first.lost}L · '
            'NRR ${season1Standings.first.nrr}',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        if (data.heroes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Tournament heroes',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          for (final h in data.heroes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(h.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${h.title} · ${h.teamName}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => onOpenPlayer(name: h.name),
            ),
        ],
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.bebasNeue(
              fontSize: 36,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _PointsTab extends StatelessWidget {
  const _PointsTab();

  @override
  Widget build(BuildContext context) {
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
        const Text(
          'League matches · final standings',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final s in season1Standings)
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
              title: Text(
                s.teamName,
                style: const TextStyle(color: Colors.white),
              ),
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

class _HeroesTab extends StatelessWidget {
  const _HeroesTab({
    required this.heroes,
    required this.mvp,
    required this.onOpenPlayer,
  });
  final List<Season1Hero> heroes;
  final List<Season1MvpRow> mvp;
  final void Function({String? id, String? name}) onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'HEROES',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: const Color(0xFFB8F27A),
          ),
        ),
        const SizedBox(height: 8),
        for (final h in heroes)
          Card(
            color: const Color(0xFF1A2E20),
            child: ListTile(
              title: Text(
                h.title,
                style: const TextStyle(
                  color: Color(0xFFB8F27A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${h.name}\n${h.teamName}\n${h.summary}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              isThreeLine: true,
              onTap: () => onOpenPlayer(name: h.name),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'MVP leaderboard (top 20)',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < mvp.length && i < 20; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text(
              '${i + 1}',
              style: const TextStyle(color: Colors.white38),
            ),
            title: Text(
              mvp[i].name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              mvp[i].teamName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Text(
              mvp[i].total.toStringAsFixed(1),
              style: const TextStyle(color: Color(0xFFB8F27A)),
            ),
            onTap: () => onOpenPlayer(name: mvp[i].name),
          ),
      ],
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
              'BATTING',
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
          leading: Text(
            '$i',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.innings} inn · HS ${r.highest} · '
            '4s ${r.fours} · 6s ${r.sixes} · SR ${r.strikeRate}',
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
              'BOWLING',
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
          leading: Text(
            '$i',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.overs} ov · ${r.maidens} M · '
            'econ ${r.economy} · best ${r.best}',
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
              'FIELDING',
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
          leading: Text(
            '$i',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          title: Text(r.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${r.teamName} · ${r.catches} catches · '
            '${r.runOuts} RO · ${r.stumpings} st',
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
