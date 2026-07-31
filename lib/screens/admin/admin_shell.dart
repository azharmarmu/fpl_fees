import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/fpl_store.dart';
import 'add_match_screen.dart';
import 'eligible_screen.dart';
import 'fees_screen.dart';
import 'finance_screen.dart';
import 'trades_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.store, required this.onLogout});

  final FplStore store;
  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  var _index = 0;

  FplStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pages = [
          _Dashboard(
            store: store,
            onOpenFees: () => setState(() => _index = 1),
            onOpenFinance: () => setState(() => _index = 3),
            onOpenMatches: () => setState(() => _index = 2),
            onOpenEligible: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EligibleScreen(store: store)),
            ),
          ),
          FeesScreen(store: store),
          _MatchesTab(store: store),
          FinanceScreen(store: store),
          _MoreTab(store: store, onLogout: widget.onLogout),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF0F1A12),
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF163020),
            indicatorColor: const Color(0xFF2E5A3C),
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Fees'),
              NavigationDestination(icon: Icon(Icons.sports_cricket), label: 'Matches'),
              NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finance'),
              NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.store,
    required this.onOpenFees,
    required this.onOpenFinance,
    required this.onOpenMatches,
    required this.onOpenEligible,
  });

  final FplStore store;
  final VoidCallback onOpenFees;
  final VoidCallback onOpenFinance;
  final VoidCallback onOpenMatches;
  final VoidCallback onOpenEligible;

  @override
  Widget build(BuildContext context) {
    final week = store.selectedWeek;
    final finance = store.financeSummary();
    final df = DateFormat('d MMM yyyy');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ADMIN',
            style: GoogleFonts.bebasNeue(
              fontSize: 36,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(
            week == null
                ? 'No week'
                : '${week.label} · ${df.format(week.date)}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (store.tradeOpen)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Trade window OPEN',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: store.selectedWeekId.isEmpty ? null : store.selectedWeekId,
            dropdownColor: const Color(0xFF1A2E20),
            decoration: _fieldDec('Select Sunday'),
            items: [
              for (final w in store.weeks)
                DropdownMenuItem(
                  value: w.id,
                  child: Text(
                    '${w.label} (${DateFormat('d MMM').format(w.date)})',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) store.selectWeek(id);
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Card(
                title: 'Fees today',
                value: '${store.paidCountForWeek()} paid · ${store.unpaidCountForWeek()} unpaid',
                onTap: onOpenFees,
              ),
              _Card(
                title: 'Eligible',
                value: '${store.eligiblePlayers().length} players',
                onTap: onOpenEligible,
              ),
              _Card(
                title: 'Scorecards',
                value: '${store.matches.length} matches',
                onTap: onOpenMatches,
              ),
              _Card(
                title: 'Finance',
                value: '₹${finance.seasonTotal}',
                onTap: onOpenFinance,
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8F27A),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.eligibleCopyText()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Eligible list copied')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy eligible for WhatsApp'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Material(
        color: const Color(0xFF163020),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFB8F27A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'SCORECARDS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28,
                      color: const Color(0xFFB8F27A),
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB8F27A),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMatchScreen(store: store),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: store.matches.isEmpty
                ? const Center(
                    child: Text(
                      'No matches yet.\nAdd after uploading CricHeroes PDF summary.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: store.matches.length,
                    itemBuilder: (context, i) {
                      final m = store.matches[i];
                      return ListTile(
                        title: Text(
                          '${m.teamAName} vs ${m.teamBName}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMM yyyy').format(m.date)}\n${m.resultText}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.store, required this.onLogout});
  final FplStore store;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'MORE',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: const Color(0xFFB8F27A),
            ),
          ),
          SwitchListTile(
            title: const Text('Trade window open', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Enable after VPL',
              style: TextStyle(color: Colors.white54),
            ),
            value: store.tradeOpen,
            activeThumbColor: const Color(0xFFB8F27A),
            onChanged: (v) => store.setTradeOpen(v),
          ),
          ListTile(
            title: const Text('Trades', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TradesScreen(store: store)),
            ),
          ),
          ListTile(
            title: const Text('Edit player phones / usernames', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Needed for player login',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _ContactsScreen(store: store)),
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ContactsScreen extends StatelessWidget {
  const _ContactsScreen({required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Player contacts'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final list = [...store.players]
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${p.teamName}\nPhone: ${p.phone.isEmpty ? "—" : p.phone} · User: ${p.cricheroesUsername}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                isThreeLine: true,
                onTap: () async {
                  final phone = TextEditingController(text: p.phone);
                  final user = TextEditingController(text: p.cricheroesUsername);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A2E20),
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextField(
                            controller: user,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'CricHeroes username',
                              labelStyle: TextStyle(color: Colors.white70),
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
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await store.updatePlayerContact(
                      playerId: p.id,
                      phone: phone.text,
                      username: user.text,
                    );
                  }
                  phone.dispose();
                  user.dispose();
                },
              );
            },
          );
        },
      ),
    );
  }
}

InputDecoration _fieldDec(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A2E20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
    );
