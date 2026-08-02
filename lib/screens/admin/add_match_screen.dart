import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/fpl_store.dart';
import '../../services/pdf_storage.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key, required this.store});
  final FplStore store;

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _InningsDraft {
  _InningsDraft({required this.battingTeamId});

  String battingTeamId;
  final runs = TextEditingController();
  final wickets = TextEditingController(text: '0');
  final overs = TextEditingController();
  final batting = <BattingEntry>[];
  final bowling = <BowlingEntry>[];

  void dispose() {
    runs.dispose();
    wickets.dispose();
    overs.dispose();
  }
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  var _teamA = kTeamOx;
  var _teamB = kTeamGb;
  final _scoreA = TextEditingController();
  final _scoreB = TextEditingController();
  final _result = TextEditingController();
  final _toss = TextEditingController();
  DateTime _date = DateTime.now();
  var _busy = false;
  var _showStructured = true;
  late final List<_InningsDraft> _innings;

  @override
  void initState() {
    super.initState();
    _innings = [
      _InningsDraft(battingTeamId: _teamA),
      _InningsDraft(battingTeamId: _teamB),
    ];
  }

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    _result.dispose();
    _toss.dispose();
    for (final i in _innings) {
      i.dispose();
    }
    super.dispose();
  }

  void _syncInningsTeams() {
    _innings[0].battingTeamId = _teamA;
    _innings[1].battingTeamId = _teamB;
  }

  List<MatchInnings> _buildInnings() {
    if (!_showStructured) return const [];
    final out = <MatchInnings>[];
    for (final d in _innings) {
      final runs = int.tryParse(d.runs.text.trim()) ?? 0;
      final wickets = int.tryParse(d.wickets.text.trim()) ?? 0;
      if (d.batting.isEmpty &&
          d.bowling.isEmpty &&
          runs == 0 &&
          d.overs.text.trim().isEmpty) {
        continue;
      }
      out.add(
        MatchInnings(
          battingTeamId: d.battingTeamId,
          battingTeamName: kTeamNames[d.battingTeamId] ?? d.battingTeamId,
          runs: runs,
          wickets: wickets,
          overs: d.overs.text.trim(),
          batting: List.unmodifiable(d.batting),
          bowling: List.unmodifiable(d.bowling),
        ),
      );
    }
    return out;
  }

  Future<void> _save() async {
    if (_teamA == _teamB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick two different teams')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final id = PdfStorage.newMatchId();
      final structured = _buildInnings();
      // Prefer structured totals for summary score strings when empty.
      var scoreA = _scoreA.text.trim();
      var scoreB = _scoreB.text.trim();
      if (structured.isNotEmpty) {
        for (final inn in structured) {
          if (inn.battingTeamId == _teamA && scoreA.isEmpty) {
            scoreA = inn.scoreLabel;
          }
          if (inn.battingTeamId == _teamB && scoreB.isEmpty) {
            scoreB = inn.scoreLabel;
          }
        }
      }
      await widget.store.addMatch(
        MatchScorecard(
          id: id,
          date: _date,
          teamAId: _teamA,
          teamBId: _teamB,
          teamAName: kTeamNames[_teamA]!,
          teamBName: kTeamNames[_teamB]!,
          teamAScore: scoreA,
          teamBScore: scoreB,
          resultText: _result.text.trim(),
          tossText: _toss.text.trim(),
          innings: structured,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addBatter(_InningsDraft draft) async {
    final entry = await _editBatterDialog(draft.battingTeamId);
    if (entry != null) setState(() => draft.batting.add(entry));
  }

  Future<void> _addBowler(_InningsDraft draft) async {
    final bowlingTeamId =
        draft.battingTeamId == _teamA ? _teamB : _teamA;
    final entry = await _editBowlerDialog(bowlingTeamId);
    if (entry != null) setState(() => draft.bowling.add(entry));
  }

  Future<BattingEntry?> _editBatterDialog(String teamId) async {
    final players = widget.store.playersForTeam(teamId);
    FplPlayer? selected;
    final name = TextEditingController();
    final runs = TextEditingController(text: '0');
    final balls = TextEditingController(text: '0');
    final fours = TextEditingController(text: '0');
    final sixes = TextEditingController(text: '0');
    final dismissal = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: const Text('Add batter', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FplPlayer?>(
                  // ignore: deprecated_member_use
                  value: selected,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: _dec('Squad player (optional)'),
                  items: [
                    const DropdownMenuItem<FplPlayer?>(
                      value: null,
                      child: Text('Custom name…',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    for (final p in players)
                      DropdownMenuItem(
                        value: p,
                        child: Text(p.name,
                            style: const TextStyle(color: Colors.white)),
                      ),
                  ],
                  onChanged: (v) => setLocal(() {
                    selected = v;
                    if (v != null) name.text = v.name;
                  }),
                ),
                TextField(
                  controller: name,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Name'),
                ),
                TextField(
                  controller: runs,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Runs'),
                ),
                TextField(
                  controller: balls,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Balls'),
                ),
                TextField(
                  controller: fours,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('4s'),
                ),
                TextField(
                  controller: sixes,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('6s'),
                ),
                TextField(
                  controller: dismissal,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Dismissal (e.g. b Azhar)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final result = ok == true && name.text.trim().isNotEmpty
        ? BattingEntry(
            playerId: selected?.id,
            name: name.text.trim(),
            runs: int.tryParse(runs.text) ?? 0,
            balls: int.tryParse(balls.text) ?? 0,
            fours: int.tryParse(fours.text) ?? 0,
            sixes: int.tryParse(sixes.text) ?? 0,
            dismissal: dismissal.text.trim(),
          )
        : null;
    name.dispose();
    runs.dispose();
    balls.dispose();
    fours.dispose();
    sixes.dispose();
    dismissal.dispose();
    return result;
  }

  Future<BowlingEntry?> _editBowlerDialog(String teamId) async {
    final players = widget.store.playersForTeam(teamId);
    FplPlayer? selected;
    final name = TextEditingController();
    final overs = TextEditingController(text: '0');
    final maidens = TextEditingController(text: '0');
    final runs = TextEditingController(text: '0');
    final wickets = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: const Text('Add bowler', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FplPlayer?>(
                  // ignore: deprecated_member_use
                  value: selected,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: _dec('Squad player (optional)'),
                  items: [
                    const DropdownMenuItem<FplPlayer?>(
                      value: null,
                      child: Text('Custom name…',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    for (final p in players)
                      DropdownMenuItem(
                        value: p,
                        child: Text(p.name,
                            style: const TextStyle(color: Colors.white)),
                      ),
                  ],
                  onChanged: (v) => setLocal(() {
                    selected = v;
                    if (v != null) name.text = v.name;
                  }),
                ),
                TextField(
                  controller: name,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Name'),
                ),
                TextField(
                  controller: overs,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Overs (e.g. 2.3)'),
                ),
                TextField(
                  controller: maidens,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Maidens'),
                ),
                TextField(
                  controller: runs,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Runs'),
                ),
                TextField(
                  controller: wickets,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Wickets'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final result = ok == true && name.text.trim().isNotEmpty
        ? BowlingEntry(
            playerId: selected?.id,
            name: name.text.trim(),
            overs: overs.text.trim().isEmpty ? '0' : overs.text.trim(),
            maidens: int.tryParse(maidens.text) ?? 0,
            runs: int.tryParse(runs.text) ?? 0,
            wickets: int.tryParse(wickets.text) ?? 0,
          )
        : null;
    name.dispose();
    overs.dispose();
    maidens.dispose();
    runs.dispose();
    wickets.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Add scorecard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Enter summary from CricHeroes PDF',
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: const Color(0xFFB8F27A),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date', style: TextStyle(color: Colors.white70)),
            trailing: TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2026, 7, 1),
                  lastDate: DateTime(2027, 1, 31),
                  initialDate: _date,
                );
                if (d != null) setState(() => _date = d);
              },
              child: Text('${_date.day}/${_date.month}/${_date.year}'),
            ),
          ),
          _teamDropdown('Team A', _teamA, (v) {
            setState(() {
              _teamA = v!;
              _syncInningsTeams();
            });
          }),
          TextField(
            controller: _scoreA,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Team A score e.g. 53/6 (8.0 Ov)'),
          ),
          const SizedBox(height: 8),
          _teamDropdown('Team B', _teamB, (v) {
            setState(() {
              _teamB = v!;
              _syncInningsTeams();
            });
          }),
          TextField(
            controller: _scoreB,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Team B score'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _result,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Result e.g. OX CC won by 7 wickets'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _toss,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Toss (optional)'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Add structured batting / bowling',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Stored in Firestore under matches.innings',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: _showStructured,
            activeThumbColor: const Color(0xFFB8F27A),
            onChanged: (v) => setState(() => _showStructured = v),
          ),
          if (_showStructured) ...[
            for (var i = 0; i < _innings.length; i++)
              _inningsEditor(i, _innings[i]),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8F27A),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'SAVE MATCH'),
          ),
        ],
      ),
    );
  }

  Widget _inningsEditor(int index, _InningsDraft draft) {
    final bowlingTeamId =
        draft.battingTeamId == _teamA ? _teamB : _teamA;
    return Card(
      color: const Color(0xFF1A2E20),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'INNINGS ${index + 1}',
              style: GoogleFonts.bebasNeue(
                fontSize: 18,
                color: const Color(0xFFB8F27A),
              ),
            ),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: draft.battingTeamId,
              dropdownColor: const Color(0xFF1A2E20),
              decoration: _dec('Batting team'),
              items: [
                for (final id in [_teamA, _teamB])
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      kTeamNames[id]!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => draft.battingTeamId = v!),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.runs,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Runs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: draft.wickets,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Wkts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: draft.overs,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Overs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Batting · ${kTeamNames[draft.battingTeamId]}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            for (var bi = 0; bi < draft.batting.length; bi++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  draft.batting[bi].name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${draft.batting[bi].runs} (${draft.batting[bi].balls}) '
                  '· 4s ${draft.batting[bi].fours} · 6s ${draft.batting[bi].sixes}'
                  '${draft.batting[bi].dismissal.isEmpty ? "" : " · ${draft.batting[bi].dismissal}"}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  onPressed: () => setState(() => draft.batting.removeAt(bi)),
                ),
              ),
            TextButton.icon(
              onPressed: () => _addBatter(draft),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add batter'),
            ),
            const SizedBox(height: 4),
            Text(
              'Bowling · ${kTeamNames[bowlingTeamId]}',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            for (var bi = 0; bi < draft.bowling.length; bi++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  draft.bowling[bi].name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${draft.bowling[bi].overs}-${draft.bowling[bi].maidens}-'
                  '${draft.bowling[bi].runs}-${draft.bowling[bi].wickets}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  onPressed: () => setState(() => draft.bowling.removeAt(bi)),
                ),
              ),
            TextButton.icon(
              onPressed: () => _addBowler(draft),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add bowler'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      dropdownColor: const Color(0xFF1A2E20),
      decoration: _dec(label),
      items: [
        for (final e in kTeamNames.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, style: const TextStyle(color: Colors.white)),
          ),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A2E20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}
