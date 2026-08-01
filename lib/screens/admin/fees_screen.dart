import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../models/models.dart';
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
  final _search = TextEditingController();
  var _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final searching = _query.isNotEmpty;
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
                  child: AnimatedBuilder(
                    animation: store,
                    builder: (context, _) => Text(
                      'Add guest ₹${store.guestFeeForWeek()}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final weekFee = store.feeForWeek();
              final guest = store.guestFeeForWeek();
              final week = store.selectedWeek;
              final label = week?.label ?? store.selectedWeekId;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editWeekFees(context, store),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('$label · weekly ₹$weekFee · guest ₹$guest'),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search player by name…',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, color: Colors.white54),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A2E20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!searching)
            TabBar(
              controller: _tabs,
              labelColor: const Color(0xFFB8F27A),
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'OX'),
                Tab(text: 'GB'),
                Tab(text: 'Avengers'),
                Tab(text: 'Guests'),
              ],
            ),
          Expanded(
            child: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                if (searching) {
                  return _FeesSearchResults(store: store, query: _query);
                }
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _TeamFees(store: store, teamId: kTeamOx),
                    _TeamFees(store: store, teamId: kTeamGb),
                    _TeamFees(store: store, teamId: kTeamAvengers),
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

  Future<void> _editWeekFees(BuildContext context, FplStore store) async {
    final weeklyCtrl = TextEditingController(text: '${store.feeForWeek()}');
    final guestCtrl =
        TextEditingController(text: '${store.guestFeeForWeek()}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E20),
        title: Text(
          'Week fees · ${store.selectedWeek?.label ?? store.selectedWeekId}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weeklyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Weekly fee (₹)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: guestCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Guest fee (₹)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Applies to new marks this Sunday. '
              'Defaults: weekly ₹${store.weeklyFee}, guest ₹${store.guestFee}.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final weekly = int.tryParse(weeklyCtrl.text.trim());
      final guest = int.tryParse(guestCtrl.text.trim());
      if (weekly != null && guest != null) {
        try {
          await store.setWeekFees(
            store.selectedWeekId,
            weekly: weekly,
            guest: guest,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      }
    }
    weeklyCtrl.dispose();
    guestCtrl.dispose();
  }

  Future<void> _addGuest(BuildContext context) async {
    final name = TextEditingController();
    var teamId = kTeamOx;
    final guestAmount = widget.store.guestFeeForWeek();
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
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Save ₹$guestAmount'),
            ),
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

class _FeesSearchResults extends StatelessWidget {
  const _FeesSearchResults({required this.store, required this.query});
  final FplStore store;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final players = store.players
        .where((p) => p.active && p.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final guests = store
        .guestsForWeek()
        .where((g) => g.name.toLowerCase().contains(q))
        .toList();

    if (players.isEmpty && guests.isEmpty) {
      return const Center(
        child: Text('No matches', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView(
      children: [
        for (final p in players)
          _PlayerFeeTile(store: store, player: p, showTeam: true),
        for (final g in guests)
          ListTile(
            title: Text(g.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              'Guest · ${kTeamNames[g.teamId]} · ₹${g.amount}',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38),
              onPressed: () => store.removeGuest(g.id),
            ),
          ),
      ],
    );
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
      itemBuilder: (context, i) => _PlayerFeeTile(store: store, player: list[i]),
    );
  }
}

class _PlayerFeeTile extends StatelessWidget {
  const _PlayerFeeTile({
    required this.store,
    required this.player,
    this.showTeam = false,
  });

  final FplStore store;
  final FplPlayer player;
  final bool showTeam;

  Future<void> _toggleSubscription(BuildContext context) async {
    final p = player;
    if (p.subscriptionPaid) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: const Text(
            'Clear subscription?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Remove ${p.name}\'s subscription (₹${p.subscriptionAmount}) from the ledger?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
      if (ok == true) await store.setSubscription(p, false);
      return;
    }

    final amountCtrl = TextEditingController(text: '${store.subscriptionFee}');
    DateTime? validUntil;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1A2E20),
          title: Text(
            'Subscription · ${p.name}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  validUntil == null
                      ? 'Valid for full season'
                      : 'Until ${DateFormat('d MMM y').format(validUntil!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: validUntil ?? DateTime.now(),
                      firstDate: DateTime(2026, 8, 1),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) setLocal(() => validUntil = picked);
                  },
                  child: const Text('Set end date'),
                ),
              ),
              if (validUntil != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setLocal(() => validUntil = null),
                    child: const Text('Clear end date'),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark paid'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final amount = int.tryParse(amountCtrl.text.trim());
      if (amount != null) {
        try {
          await store.setSubscription(
            p,
            true,
            amount: amount,
            validUntil: validUntil,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        }
      }
    }
    amountCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = player;
    final el = store.eligibilityFor(p);
    final weekFee = store.feeForWeek();
    final canToggleWeekly = !p.isLifetimeMember && !p.hasActiveSubscription;
    final paidWeekly = store.hasWeeklyPayment(p.id, store.selectedWeekId);
    final status = el.label(
      weeklyFee: weekFee,
      subscriptionAmount: p.subscriptionAmount,
      subscriptionValidUntil: p.subscriptionValidUntil,
    );
    final subtitle = showTeam ? '${p.teamName} · $status' : status;

    return ListTile(
      title: Text(
        p.isCaptain ? '${p.name} (C)' : p.name,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
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
              tooltip: p.subscriptionPaid
                  ? 'Subscription ₹${p.subscriptionAmount}'
                  : 'Subscription (default ₹${store.subscriptionFee})',
              icon: Icon(
                p.subscriptionPaid
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
                color: p.subscriptionPaid ? Colors.amber : Colors.white38,
              ),
              onPressed: () => _toggleSubscription(context),
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
