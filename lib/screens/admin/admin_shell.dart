import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/fpl_store.dart';
import '../../services/io_bytes.dart';
import '../../widgets/all_time_leaders.dart';
import '../../widgets/app_brand.dart';
import '../../widgets/schedule_list.dart';
import 'add_match_screen.dart';
import 'eligible_screen.dart';
import 'fees_screen.dart';
import 'finance_screen.dart';
import 'match_detail_screen.dart';
import 'trades_screen.dart';
import '../schedule_screen.dart';
import '../tournament_stats_screen.dart';
import '../../services/stat_players_repository.dart';

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
          const AppBrandHeader(logoSize: 44),
          const SizedBox(height: 12),
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
          if (store.cloudEnabled)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Cloud sync ON',
                style: TextStyle(color: Color(0xFFB8F27A), fontSize: 12),
              ),
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
          HomeWeekSchedule(store: store),
          const SizedBox(height: 16),
          AllTimeLeaders(cloudEnabled: store.cloudEnabled),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E5A3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TournamentStatsScreen(
                  cloudEnabled: store.cloudEnabled,
                ),
              ),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Tournament stats'),
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
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleScreen(store: store),
                    ),
                  ),
                  child: const Text('Schedule'),
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
                      'No scorecards yet.\nAdd after the match / CricHeroes PDF.',
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
                          '${DateFormat('d MMM yyyy').format(m.date)}\n${m.resultText}'
                          '${m.hasStructuredCard ? " · structured" : ""}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        isThreeLine: true,
                        trailing: m.hasPdf
                            ? IconButton(
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Color(0xFFB8F27A),
                                ),
                                onPressed: () => openMatchPdf(context, m),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                color: Colors.white38,
                              ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchDetailScreen(match: m),
                          ),
                        ),
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
          if (store.cloudEnabled)
            ListTile(
              title: const Text(
                'Upload Season 1 stats to Firestore',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Admin only · enables tap-to-career for all devices',
                style: TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.cloud_upload_outlined,
                  color: Color(0xFFB8F27A)),
              onTap: () => _uploadSeason1Stats(context, store),
            ),
          ListTile(
            title: const Text(
              'Default fee amounts',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Weekly ₹${store.weeklyFee} · Sub ₹${store.subscriptionFee} · Guest ₹${store.guestFee}',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.edit_outlined, color: Colors.white54),
            onTap: () => _editFeeAmounts(context, store),
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
          ListTile(
            title: const Text('Export ledger / backup', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Copy finance CSV or full JSON backup',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _ExportScreen(store: store)),
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

class _ContactsScreen extends StatefulWidget {
  const _ContactsScreen({required this.store});
  final FplStore store;

  @override
  State<_ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<_ContactsScreen> {
  FplStore get store => widget.store;

  Future<void> _importDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E20),
        title: const Text('Import contacts CSV', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 12,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'id,name,phone,username\nazhar_marmu,Azhar Marmu,98xxxxxxxx,...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final result = await store.importContacts(controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${result.updated}, skipped ${result.skipped}'
            '${result.errors.isEmpty ? "" : " · ${result.errors.take(2).join("; ")}"}',
          ),
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _importFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.single;
    var text = '';
    if (f.bytes != null) {
      text = utf8.decode(f.bytes!);
    } else {
      text = await readPathString(f.path) ?? '';
    }
    if (text.isEmpty) return;
    final result = await store.importContacts(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated ${result.updated}, skipped ${result.skipped}'),
      ),
    );
  }

  Future<void> _editContact(BuildContext context, FplPlayer p) async {
    final phone = TextEditingController(text: p.phone);
    final email = TextEditingController(text: p.email);
    final user = TextEditingController(text: p.cricheroesUsername);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E20),
        title: Text(
          'Edit contact · ${p.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mobile',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: '9876543210',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
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
      try {
        await store.updatePlayerContact(
          playerId: p.id,
          phone: phone.text,
          email: email.text.trim(),
          username: user.text,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('ArgumentError: ', ''))),
          );
        }
      }
    }
    phone.dispose();
    email.dispose();
    user.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Player contacts'),
        actions: [
          IconButton(
            tooltip: 'Copy CSV template',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.contactsTemplateCsv()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV template copied')),
                );
              }
            },
            icon: const Icon(Icons.copy_all_outlined),
          ),
          IconButton(
            tooltip: 'Import CSV file',
            onPressed: _importFile,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'Paste CSV',
            onPressed: _importDialog,
            icon: const Icon(Icons.content_paste_go_outlined),
          ),
        ],
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
                  '${p.teamName}\n'
                  'Phone: ${p.phone.isEmpty ? "—" : p.phone} · '
                  'Email: ${p.email.isEmpty ? "—" : p.email}\n'
                  'User: ${p.cricheroesUsername}\n'
                  'Login: ${p.lastLoginAt == null ? "—" : DateFormat("d MMM, h:mm a").format(p.lastLoginAt!)} · '
                  'Updated: ${p.lastUpdatedAt == null ? "—" : DateFormat("d MMM, h:mm a").format(p.lastUpdatedAt!)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Edit mobile / email',
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFFB8F27A)),
                  onPressed: () => _editContact(context, p),
                ),
                onTap: () => _editContact(context, p),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExportScreen extends StatelessWidget {
  const _ExportScreen({required this.store});
  final FplStore store;

  Future<void> _copy(BuildContext context, String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Export / backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Copy exports to paste into Sheets or save as backup.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Finance summary CSV', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.copy, color: Colors.white54),
            onTap: () => _copy(context, 'Finance CSV', store.exportFinanceCsv()),
          ),
          ListTile(
            title: const Text('Weekly payments CSV', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.copy, color: Colors.white54),
            onTap: () => _copy(context, 'Payments CSV', store.exportPaymentsCsv()),
          ),
          ListTile(
            title: const Text('Subscriptions CSV', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.copy, color: Colors.white54),
            onTap: () =>
                _copy(context, 'Subscriptions CSV', store.exportSubscriptionsCsv()),
          ),
          ListTile(
            title: const Text('Full season JSON backup', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.copy, color: Colors.white54),
            onTap: () =>
                _copy(context, 'JSON backup', store.exportFullBackupJson()),
          ),
        ],
      ),
    );
  }
}

Future<void> _uploadSeason1Stats(BuildContext context, FplStore store) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A2E20),
      title: const Text(
        'Upload Season 1 to Firestore?',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Writes seasons/s1 + statPlayers docs from bundled CricHeroes CSVs. '
        'Sign in as Firebase admin first.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Upload'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );
  try {
    final n = await StatPlayersRepository().uploadSeason1FromAssets();
    if (context.mounted) {
      Navigator.pop(context); // loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded $n Season 1 players to Firestore')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
}

Future<void> _editFeeAmounts(BuildContext context, FplStore store) async {
  final weeklyCtrl = TextEditingController(text: '${store.weeklyFee}');
  final subCtrl = TextEditingController(text: '${store.subscriptionFee}');
  final guestCtrl = TextEditingController(text: '${store.guestFee}');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A2E20),
      title: const Text(
        'Default fee amounts',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: weeklyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _fieldDec('Default weekly fee (₹)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: subCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _fieldDec('Default subscription (₹)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: guestCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: _fieldDec('Guest fee (₹)'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Defaults for new marks only. Changing subscription default '
            '(e.g. ₹750 → ₹500 after VPL) does not rewrite players who already paid.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
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
  if (ok == true && context.mounted) {
    final weekly = int.tryParse(weeklyCtrl.text.trim());
    final sub = int.tryParse(subCtrl.text.trim());
    final guest = int.tryParse(guestCtrl.text.trim());
    if (weekly == null || sub == null || guest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amounts')),
      );
    } else {
      try {
        await store.setFeeAmounts(
          weekly: weekly,
          subscription: sub,
          guest: guest,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fees updated · weekly ₹$weekly · sub ₹$sub · guest ₹$guest',
              ),
            ),
          );
        }
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
  subCtrl.dispose();
  guestCtrl.dispose();
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
