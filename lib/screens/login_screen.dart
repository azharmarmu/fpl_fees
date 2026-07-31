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
  });

  final FplStore store;
  final SessionService session;
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _asAdmin = false;
  var _playerModePhone = true;
  final _adminPass = TextEditingController();
  final _playerInput = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _adminPass.dispose();
    _playerInput.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_asAdmin) {
        if (_adminPass.text.trim() != kLocalAdminPassword) {
          throw Exception('Wrong admin password');
        }
        await widget.session.setAdmin();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'FPL SEASON 2',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 42,
                    color: const Color(0xFFB8F27A),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fees · Eligible · Scorecards',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
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
                  TextField(
                    controller: _adminPass,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dec('Admin password'),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Local mode password: fpladmin\n(Replace with Firebase Auth after setup)',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ] else ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Phone')),
                      ButtonSegment(value: false, label: Text('Username')),
                    ],
                    selected: {_playerModePhone},
                    onSelectionChanged: (s) => setState(() {
                      _playerModePhone = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _playerInput,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: _playerModePhone
                        ? TextInputType.phone
                        : TextInputType.text,
                    textCapitalization: _playerModePhone
                        ? TextCapitalization.none
                        : TextCapitalization.none,
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
