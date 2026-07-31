import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../services/fpl_store.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key, required this.store});
  final FplStore store;

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Trades'),
        actions: [
          if (store.tradeOpen)
            TextButton(
              onPressed: () => _record(context),
              child: const Text('Record trade'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (!store.tradeOpen) {
            return const Center(
              child: Text(
                'Trade window is closed.\nEnable in More after VPL.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          if (store.trades.isEmpty) {
            return const Center(
              child: Text('No trades yet', style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            itemCount: store.trades.length,
            itemBuilder: (context, i) {
              final t = store.trades[i];
              return ListTile(
                title: Text(
                  t.playerName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${kTeamNames[t.fromTeamId]} → ${kTeamNames[t.toTeamId]}\n'
                  'Sale ₹${t.salePriceInr} · Commission ₹${t.commissionInr}'
                  '${t.commissionCollected ? " · collected" : " · pending"}',
                  style: const TextStyle(color: Colors.white54),
                ),
                isThreeLine: true,
                trailing: Text(
                  DateFormat('d MMM').format(t.tradedAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _record(BuildContext context) async {
    final store = widget.store;
    var playerId = store.players.first.id;
    var toTeam = kTeamOx;
    final price = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: Text(
            'Record trade (25% to organizer)',
            style: GoogleFonts.bebasNeue(color: const Color(0xFFB8F27A)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: playerId,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: const InputDecoration(labelText: 'Player'),
                  items: [
                    for (final p in store.players)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (${kTeamNames[p.teamId]})',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => playerId = v ?? playerId),
                ),
                DropdownButtonFormField<String>(
                  value: toTeam,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: const InputDecoration(labelText: 'To team'),
                  items: [
                    for (final e in kTeamNames.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, style: const TextStyle(color: Colors.white)),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => toTeam = v ?? toTeam),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sale price (₹)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      final p = store.playerById(playerId);
      final sale = int.tryParse(price.text.trim());
      if (p == null || sale == null || sale <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid trade')),
          );
        }
      } else if (p.teamId == toTeam) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player already on that team')),
          );
        }
      } else {
        await store.recordTrade(
          player: p,
          toTeamId: toTeam,
          salePriceInr: sale,
        );
      }
    }
    price.dispose();
  }
}
