import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

enum AppRole { none, admin, player }

class SessionService {
  SessionService({AuthService? auth}) : authService = auth ?? AuthService();

  static const _roleKey = 'session_role';
  static const _playerIdKey = 'session_player_id';

  final AuthService authService;

  AppRole role = AppRole.none;
  String? playerId;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final r = prefs.getString(_roleKey);
    role = switch (r) {
      'admin' => AppRole.admin,
      'player' => AppRole.player,
      _ => AppRole.none,
    };
    playerId = prefs.getString(_playerIdKey);
  }

  Future<void> setAdmin() async {
    role = AppRole.admin;
    playerId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'admin');
    await prefs.remove(_playerIdKey);
  }

  Future<void> setPlayer(String id) async {
    role = AppRole.player;
    playerId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'player');
    await prefs.setString(_playerIdKey, id);
  }

  Future<void> clear() async {
    await authService.signOut();
    role = AppRole.none;
    playerId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_playerIdKey);
  }
}
