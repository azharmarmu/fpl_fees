import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/fpl_store.dart';

class PlayerShell extends StatefulWidget {
  const PlayerShell({
    super.key,
    required this.store,
    required this.playerId,
    required this.onLogout,
  });

  final FplStore store;
  final String playerId;
  final VoidCallback onLogout;

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final me = widget.store.playerById(widget.playerId);
        if (me == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F1A12),
            body: Center(
              child: TextButton(
                onPressed: widget.onLogout,
                child: const Text('Player missing — logout'),
              ),
            ),
          );
        }

        final pages = [
          _PlayerHome(store: widget.store, me: me),
          _MyTeam(store: widget.store, me: me),
          _PlayerMatches(store: widget.store),
          _PlayerProfile(me: me, onLogout: widget.onLogout),
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
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                label: 'My team',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_cricket),
                label: 'Scorecards',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerHome extends StatelessWidget {
  const _PlayerHome({required this.store, required this.me});
  final FplStore store;
  final FplPlayer me;

  @override
  Widget build(BuildContext context) {
    final el = store.eligibilityFor(me);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            me.name.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 34,
              color: const Color(0xFFB8F27A),
            ),
          ),
          Text(me.teamName, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF163020),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.selectedWeek?.label ?? 'This week',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Text(
                  el.eligible ? 'ELIGIBLE' : 'NOT ELIGIBLE',
                  style: TextStyle(
                    color: el.eligible
                        ? const Color(0xFFB8F27A)
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                Text(el.label, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay ground fee',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pay here, then admin will mark you Paid.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  kUpiId,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    color: const Color(0xFFB8F27A),
                  ),
                ),
                const Text(
                  kUpiDisplayName,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: kUpiId),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('UPI copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy UPI'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final uri = Uri.parse(
                          'upi://pay?pa=$kUpiId&pn=${Uri.encodeComponent(kUpiDisplayName)}&cu=INR',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text('Open UPI'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTeam extends StatelessWidget {
  const _MyTeam({required this.store, required this.me});
  final FplStore store;
  final FplPlayer me;

  @override
  Widget build(BuildContext context) {
    final list = store.playersForTeam(me.teamId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            me.teamName.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: const Color(0xFFB8F27A),
            ),
          ),
          const SizedBox(height: 8),
          for (final p in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                p.isCaptain ? '${p.name} (C)' : p.name,
                style: TextStyle(
                  color:
                      p.id == me.id ? const Color(0xFFB8F27A) : Colors.white,
                  fontWeight:
                      p.id == me.id ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              subtitle: p.isLifetimeMember
                  ? const Text(
                      'Lifetime',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _PlayerMatches extends StatelessWidget {
  const _PlayerMatches({required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'SCORECARDS',
              style: GoogleFonts.bebasNeue(
                fontSize: 28,
                color: const Color(0xFFB8F27A),
              ),
            ),
          ),
          Expanded(
            child: store.matches.isEmpty
                ? const Center(
                    child: Text(
                      'No scorecards yet',
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

class _PlayerProfile extends StatelessWidget {
  const _PlayerProfile({required this.me, required this.onLogout});
  final FplPlayer me;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'PROFILE',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: const Color(0xFFB8F27A),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(me.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${me.teamName}\n'
              'Phone: ${me.phone.isEmpty ? "—" : me.phone}\n'
              'Username: ${me.cricheroesUsername}\n'
              '${me.isLifetimeMember ? "Lifetime member" : me.subscriptionPaid ? "Subscription paid" : "Weekly fee"}',
              style: const TextStyle(color: Colors.white54),
            ),
            isThreeLine: true,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onLogout,
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
