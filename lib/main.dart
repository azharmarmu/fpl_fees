import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/fpl_store.dart';
import 'services/session_service.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FplStore();
  final session = SessionService();
  await Future.wait([store.init(), session.load()]);
  runApp(FplFeesApp(store: store, session: session));
}

class FplFeesApp extends StatefulWidget {
  const FplFeesApp({super.key, required this.store, required this.session});

  final FplStore store;
  final SessionService session;

  @override
  State<FplFeesApp> createState() => _FplFeesAppState();
}

class _FplFeesAppState extends State<FplFeesApp> {
  void _refresh() => setState(() {});

  Future<void> _logout() async {
    await widget.session.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FPL Fees',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),
      home: !widget.store.ready
          ? const Scaffold(
              backgroundColor: Color(0xFF0F1A12),
              body: Center(child: CircularProgressIndicator()),
            )
          : widget.session.role == AppRole.none
              ? LoginScreen(
                  store: widget.store,
                  session: widget.session,
                  onLoggedIn: _refresh,
                )
              : RoleGate(
                  store: widget.store,
                  session: widget.session,
                  onLogout: _logout,
                ),
    );
  }
}
