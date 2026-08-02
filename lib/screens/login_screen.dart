import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../services/fpl_store.dart';
import '../services/session_service.dart';
import 'admin/admin_shell.dart';
import 'player/player_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.store,
    required this.session,
    required this.onLoggedIn,
    this.firebaseEnabled = false,
  });

  final FplStore store;
  final SessionService session;
  final VoidCallback onLoggedIn;
  final bool firebaseEnabled;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _asAdmin = false;
  var _playerModePhone = true;
  final _adminPass = TextEditingController();
  late final TextEditingController _adminEmail;
  final _playerInput = TextEditingController();
  final _playerFocus = FocusNode();
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Never prefill admin email in release builds.
    _adminEmail = TextEditingController(
      text: kDebugMode ? kFirebaseAdminEmail : '',
    );
  }

  @override
  void dispose() {
    _adminPass.dispose();
    _adminEmail.dispose();
    _playerInput.dispose();
    _playerFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_asAdmin) {
        final err = await widget.session.authService.signInAdmin(
          password: _adminPass.text,
          email: widget.firebaseEnabled ? _adminEmail.text.trim() : null,
        );
        if (err != null) throw Exception(err);
        await widget.session.setAdmin();
        // Push local migrations (scorecards, fees) once Firebase admin is live.
        await widget.store.syncToCloudIfAdmin();
      } else {
        final raw = _playerInput.text.trim();
        if (raw.isEmpty) throw Exception('Enter phone or username');
        final player = _playerModePhone
            ? widget.store.findByPhone(raw)
            : widget.store.findByUsername(raw);
        if (player == null) {
          throw Exception('Not registered. Ask admin to add you.');
        }
        await widget.session.setPlayer(player.id);
      }
      widget.onLoggedIn();
    } catch (e) {
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFirebaseEmail = widget.firebaseEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Image.asset(
                    kAppLogoAsset,
                    width: 128,
                    height: 128,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  kAppName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 48,
                    color: const Color(0xFFB8F27A),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.store.cloudEnabled
                      ? 'Season 2 · Fees · Eligible · Cloud sync'
                      : 'Season 2 · Fees · Eligible · Scorecards',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Player')),
                    ButtonSegment(value: true, label: Text('Admin')),
                  ],
                  selected: {_asAdmin},
                  onSelectionChanged: (s) => setState(() {
                    _asAdmin = s.first;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 24),
                if (_asAdmin) ...[
                  if (showFirebaseEmail) ...[
                    TextField(
                      controller: _adminEmail,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _dec('Admin email'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _adminPass,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec(
                      showFirebaseEmail
                          ? 'Password'
                          : 'Admin password',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showFirebaseEmail
                        ? (kDebugMode
                            ? 'Firebase Auth email/password.\nDebug fallback: local password fpladmin'
                            : 'Sign in with your admin email and password')
                        : 'Local mode password: fpladmin',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ] else ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Phone')),
                      ButtonSegment(value: false, label: Text('Username')),
                    ],
                    selected: {_playerModePhone},
                    onSelectionChanged: (s) {
                      final next = s.first;
                      if (next == _playerModePhone) return;
                      setState(() {
                        _playerModePhone = next;
                        _error = null;
                      });
                      // Force keyboard type change (Flutter keeps old IME otherwise).
                      _playerFocus.unfocus();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _playerFocus.requestFocus();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: ValueKey<bool>(_playerModePhone),
                    controller: _playerInput,
                    focusNode: _playerFocus,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: _playerModePhone
                        ? TextInputType.phone
                        : TextInputType.text,
                    textCapitalization: _playerModePhone
                        ? TextCapitalization.none
                        : TextCapitalization.none,
                    autocorrect: !_playerModePhone,
                    decoration: _dec(
                      _playerModePhone
                          ? 'Phone number'
                          : 'CricHeroes username',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _playerModePhone
                        ? 'No OTP — number must be saved by admin'
                        : 'Not case-sensitive (e.g. Anas / anas)',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB8F27A),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy ? '…' : 'CONTINUE',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
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
}

class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.store,
    required this.session,
    required this.onLogout,
  });

  final FplStore store;
  final SessionService session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return switch (session.role) {
      AppRole.admin => AdminShell(
          store: store,
          onLogout: onLogout,
        ),
      AppRole.player => PlayerShell(
          store: store,
          playerId: session.playerId!,
          onLogout: onLogout,
        ),
      AppRole.none => const SizedBox.shrink(),
    };
  }
}
