import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config.dart';
import '../../services/fpl_store.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key, required this.store});
  final FplStore store;

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'FEES',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28,
                      color: const Color(0xFFB8F27A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _addGuest(context),
                  child: const Text('Add guest ₹200'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: const Color(0xFFB8F27A),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'OX'),
              Tab(text: 'GB'),
              Tab(text: 'Rusfi'),
              Tab(text: 'Guests'),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _TeamFees(store: store, teamId: kTeamOx),
                    _TeamFees(store: store, teamId: kTeamGb),
                    _TeamFees(store: store, teamId: kTeamNew),
                    _GuestsList(store: store),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addGuest(BuildContext context) async {
    final name = TextEditingController();
    var teamId = kTeamOx;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: const Text('Guest player', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              DropdownButton<String>(
                value: teamId,
                dropdownColor: const Color(0xFF1A2E20),
                items: [
                  for (final e in kTeamNames.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(color: Colors.white)),
                    ),
                ],
                onChanged: (v) => setLocal(() => teamId = v ?? teamId),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save ₹200')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await widget.store.addGuest(name: name.text, teamId: teamId);
    }
    name.dispose();
  }
}

class _TeamFees extends StatelessWidget {
  const _TeamFees({required this.store, required this.teamId});
  final FplStore store;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final list = store.playersForTeam(teamId);
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final p = list[i];
        final el = store.eligibilityFor(p);
        final canToggleWeekly =
            !p.isLifetimeMember && !p.subscriptionPaid;
        final paidWeekly = store.hasWeeklyPayment(p.id, store.selectedWeekId);

        return ListTile(
          title: Text(
            p.isCaptain ? '${p.name} (C)' : p.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            el.label,
            style: TextStyle(
              color: el.eligible ? const Color(0xFFB8F27A) : Colors.orangeAccent,
              fontSize: 12,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!p.isLifetimeMember)
                IconButton(
                  tooltip: 'Subscription ₹$kSubscriptionFee',
                  icon: Icon(
                    p.subscriptionPaid ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                    color: p.subscriptionPaid ? Colors.amber : Colors.white38,
                  ),
                  onPressed: () => store.setSubscription(p, !p.subscriptionPaid),
                ),
              if (canToggleWeekly)
                Switch(
                  value: paidWeekly,
                  activeThumbColor: const Color(0xFFB8F27A),
                  onChanged: (v) => store.setWeeklyPaid(p, v),
                )
              else
                const Icon(Icons.check_circle, color: Color(0xFFB8F27A)),
            ],
          ),
        );
      },
    );
  }
}

class _GuestsList extends StatelessWidget {
  const _GuestsList({required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    final list = store.guestsForWeek();
    if (list.isEmpty) {
      return const Center(
        child: Text('No guests this week', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final g = list[i];
        return ListTile(
          title: Text(g.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${kTeamNames[g.teamId]} · ₹${g.amount}',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white38),
            onPressed: () => store.removeGuest(g.id),
          ),
        );
      },
    );
  }
}
