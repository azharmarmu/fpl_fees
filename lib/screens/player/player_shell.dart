import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/fpl_store.dart';
import '../../widgets/all_time_leaders.dart';
import '../../widgets/app_brand.dart';
import '../../widgets/fpl_nav_scaffold.dart';
import '../../widgets/home_auction_purses.dart';
import '../../widgets/home_points_table.dart';
import '../../widgets/schedule_list.dart';
import '../admin/match_detail_screen.dart';
import '../schedule_screen.dart';
import '../stat_player_screen.dart';

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
  var _phonePromptShown = false;
  var _loginRecorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordLoginOnce();
      _maybeAskForPhone();
    });
  }

  Future<void> _recordLoginOnce() async {
    if (_loginRecorded) return;
    _loginRecorded = true;
    await widget.store.recordPlayerLogin(widget.playerId);
  }

  Future<void> _maybeAskForPhone() async {
    if (!mounted || _phonePromptShown) return;
    final me = widget.store.playerById(widget.playerId);
    if (me == null || me.phone.trim().isNotEmpty) return;
    _phonePromptShown = true;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // Outside tap / system back won't dismiss — use Cancel (logs out) or Save.
      builder: (ctx) => PopScope(
        canPop: false,
        child: _ContactDialog(
          store: widget.store,
          playerId: widget.playerId,
          playerName: me.name,
          initialPhone: me.phone,
          initialEmail: me.email,
          requiredOnCancel: true,
        ),
      ),
    );
    if (!mounted) return;
    if (saved != true) {
      // Cancel or dismissed without save → logout.
      _phonePromptShown = false;
      widget.onLogout();
    }
  }

  Future<void> _editContact() async {
    final me = widget.store.playerById(widget.playerId);
    if (me == null || !mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => _ContactDialog(
        store: widget.store,
        playerId: widget.playerId,
        playerName: me.name,
        initialPhone: me.phone,
        initialEmail: me.email,
      ),
    );
  }

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

        // If cloud sync later clears phone, or first frame raced, prompt again.
        if (me.phone.trim().isEmpty && !_phonePromptShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskForPhone());
        }

        final pages = [
          _PlayerHome(store: widget.store, me: me),
          _MyTeam(store: widget.store, me: me),
          _PlayerMatches(store: widget.store),
          _PlayerProfile(
            store: widget.store,
            me: me,
            onLogout: widget.onLogout,
            onEditContact: _editContact,
          ),
        ];

        return FplScaffoldWithStatsFab(
          body: pages[_index],
          selectedIndex: _index,
          onSelect: (i) => setState(() => _index = i),
          items: const [
            FplNavItem(index: 0, icon: Icons.home_outlined, label: 'Home'),
            FplNavItem(index: 1, icon: Icons.groups_outlined, label: 'My team'),
            FplNavItem(index: 2, icon: Icons.sports_cricket, label: 'Scorecards'),
            FplNavItem(index: 3, icon: Icons.person_outline, label: 'Profile'),
          ],
          cloudEnabled: widget.store.cloudEnabled,
        );
      },
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({
    required this.store,
    required this.playerId,
    required this.playerName,
    this.initialPhone = '',
    this.initialEmail = '',
    this.requiredOnCancel = false,
  });

  final FplStore store;
  final String playerId;
  final String playerName;
  final String initialPhone;
  final String initialEmail;
  /// When true (first login), Cancel logs the player out.
  final bool requiredOnCancel;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController _phone;
  late final TextEditingController _email;
  String? _error;
  var _busy = false;

  bool get _isEdit => widget.initialPhone.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.store.updateOwnPhone(
      playerId: widget.playerId,
      rawPhone: _phone.text,
      rawEmail: _email.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  void _cancel() {
    if (_busy) return;
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2E20),
      title: Text(
        _isEdit ? 'Edit contact details' : 'Add your contact details',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.requiredOnCancel
                ? 'Hi ${widget.playerName} — mobile number is required so you can log in and so the organizer can reach you. Email is optional. Cancel will log you out.'
                : 'Update your mobile or email. Mobile is required for login.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Mobile number *',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: '9876543210',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onSubmitted: (_) => _busy ? null : _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: 'you@example.com',
              hintStyle: TextStyle(color: Colors.white30),
            ),
            onSubmitted: (_) => _busy ? null : _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _cancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save'),
        ),
      ],
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
          const AppBrandHeader(logoSize: 44),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.name.toUpperCase(),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 34,
                        height: 1.05,
                        color: const Color(0xFFB8F27A),
                      ),
                    ),
                    Text(
                      me.teamName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _GroundFeeChip(
                eligible: el.eligible,
                weekLabel: store.selectedWeek?.label ?? 'This week',
                detail: el.label(
                  weeklyFee: store.feeForWeek(),
                  subscriptionAmount: me.subscriptionAmount,
                  subscriptionValidUntil: me.subscriptionValidUntil,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HomeWeekSchedule(store: store),
          const SizedBox(height: 16),
          HomePointsTable(cloudEnabled: store.cloudEnabled),
          const SizedBox(height: 16),
          HomeAuctionPurses(store: store),
          const SizedBox(height: 16),
          SeasonLeaders(cloudEnabled: store.cloudEnabled),
          const SizedBox(height: 16),
          AllTimeLeaders(cloudEnabled: store.cloudEnabled),
          const SizedBox(height: 16),
          if (el.reason == EligibilityReason.unpaid)
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
                  Text(
                    'Pay ground fee · ₹${store.feeForWeek()}',
                    style: const TextStyle(
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

class _GroundFeeChip extends StatelessWidget {
  const _GroundFeeChip({
    required this.eligible,
    required this.weekLabel,
    required this.detail,
  });

  final bool eligible;
  final String weekLabel;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final accent =
        eligible ? const Color(0xFFB8F27A) : Colors.orangeAccent;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF163020),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              weekLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            Text(
              eligible ? 'ELIGIBLE' : 'DUE',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              detail,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
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
          if (me.teamId != kTeamGuest && me.teamId != kTeamFreeAgent) ...[
            TeamAuctionPurseCard(teamId: me.teamId, store: store),
            const SizedBox(height: 12),
          ],
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
              subtitle: Text(
                p.isLifetimeMember
                    ? 'Lifetime'
                    : auctionSubtitleFor(
                        store: store,
                        teamId: me.teamId,
                        playerId: p.id,
                        playerName: p.name,
                        isCaptain: p.isCaptain,
                      ),
                style: TextStyle(
                  color: p.isLifetimeMember
                      ? Colors.amber
                      : Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatPlayerScreen(
                    playerName: p.name,
                    cloudEnabled: store.cloudEnabled,
                  ),
                ),
              ),
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
                IconButton(
                  tooltip: 'Full schedule',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleScreen(store: store),
                    ),
                  ),
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Color(0xFFB8F27A),
                  ),
                ),
              ],
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
                        trailing: const Icon(
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

class _PlayerProfile extends StatelessWidget {
  const _PlayerProfile({
    required this.store,
    required this.me,
    required this.onLogout,
    required this.onEditContact,
  });

  final FplStore store;
  final FplPlayer me;
  final VoidCallback onLogout;
  final VoidCallback onEditContact;

  @override
  Widget build(BuildContext context) {
    final hasPhone = me.phone.trim().isNotEmpty;
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
              'Phone: ${hasPhone ? me.phone : "—"}\n'
              'Email: ${me.email.isEmpty ? "—" : me.email}\n'
              'Username: ${me.cricheroesUsername}\n'
              '${me.isLifetimeMember ? "Lifetime member" : me.subscriptionPaid ? "Subscription paid" : "Weekly fee"}',
              style: const TextStyle(color: Colors.white54),
            ),
            isThreeLine: true,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB8F27A),
              foregroundColor: Colors.black,
            ),
            onPressed: onEditContact,
            icon: Icon(hasPhone ? Icons.edit_outlined : Icons.phone_android),
            label: Text(hasPhone ? 'Edit mobile / email' : 'Add mobile / email'),
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
