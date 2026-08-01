import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config.dart';
import 'screens/login_screen.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_sync.dart';
import 'services/fpl_store.dart';
import 'services/session_service.dart';
import 'widgets/app_viewport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await FirebaseBootstrap.init();
  final store = FplStore();
  final session = SessionService();
  session.authService.cloudEnabled = bootstrap.enabled;
  await Future.wait([store.init(), session.load()]);
  if (bootstrap.enabled) {
    await store.attachCloud(FirestoreSync());
  }
  runApp(
    FplFeesApp(
      store: store,
      session: session,
      firebaseEnabled: bootstrap.enabled,
      firebaseNote: bootstrap.error,
    ),
  );
}

class FplFeesApp extends StatefulWidget {
  const FplFeesApp({
    super.key,
    required this.store,
    required this.session,
    this.firebaseEnabled = false,
    this.firebaseNote,
  });

  final FplStore store;
  final SessionService session;
  final bool firebaseEnabled;
  final String? firebaseNote;

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
      title: kAppName,
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
      home: AppViewport(
        child: !widget.store.ready
            ? const Scaffold(
                backgroundColor: Color(0xFF0F1A12),
                body: Center(child: CircularProgressIndicator()),
              )
            : widget.session.role == AppRole.none
                ? LoginScreen(
                    store: widget.store,
                    session: widget.session,
                    onLoggedIn: _refresh,
                    firebaseEnabled: widget.firebaseEnabled,
                  )
                : RoleGate(
                    store: widget.store,
                    session: widget.session,
                    onLogout: _logout,
                  ),
      ),
    );
  }
}
