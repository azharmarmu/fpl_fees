import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/fpl_store.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key, required this.store});
  final FplStore store;

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  var _teamA = kTeamOx;
  var _teamB = kTeamGb;
  final _scoreA = TextEditingController();
  final _scoreB = TextEditingController();
  final _result = TextEditingController();
  final _toss = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    _result.dispose();
    _toss.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_teamA == _teamB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick two different teams')),
      );
      return;
    }
    await widget.store.addMatch(
      MatchScorecard(
        id: const Uuid().v4(),
        date: _date,
        teamAId: _teamA,
        teamBId: _teamB,
        teamAName: kTeamNames[_teamA]!,
        teamBName: kTeamNames[_teamB]!,
        teamAScore: _scoreA.text.trim(),
        teamBScore: _scoreB.text.trim(),
        resultText: _result.text.trim(),
        tossText: _toss.text.trim(),
      ),
    );
    if (mounted) Navigator.pop(context);
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
            style: GoogleFonts.bebasNeue(fontSize: 22, color: const Color(0xFFB8F27A)),
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
          _teamDropdown('Team A', _teamA, (v) => setState(() => _teamA = v!)),
          TextField(
            controller: _scoreA,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Team A score e.g. 53/6 (8.0 Ov)'),
          ),
          const SizedBox(height: 8),
          _teamDropdown('Team B', _teamB, (v) => setState(() => _teamB = v!)),
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
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8F27A),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            child: const Text('SAVE MATCH'),
          ),
        ],
      ),
    );
  }

  Widget _teamDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
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
