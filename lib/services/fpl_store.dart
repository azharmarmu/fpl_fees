import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../data/seed.dart';
import '../models/models.dart';

/// Local-first store. Swap to Firestore later when Firebase is configured.
class FplStore extends ChangeNotifier {
  FplStore();

  static const _prefsKey = 'fpl_fees_v1';
  final _uuid = const Uuid();

  List<FplPlayer> players = [];
  List<LeagueWeek> weeks = [];
  List<WeeklyPayment> payments = [];
  List<GuestPayment> guests = [];
  List<MatchScorecard> matches = [];
  List<PlayerTrade> trades = [];
  bool tradeOpen = false;
  String selectedWeekId = '';
  bool ready = false;

  LeagueWeek? get selectedWeek {
    try {
      return weeks.firstWhere((w) => w.id == selectedWeekId);
    } catch (_) {
      return weeks.isEmpty ? null : weeks.first;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      players = buildSeedPlayers();
      weeks = buildSeasonWeeks();
      selectedWeekId = _defaultWeekId();
      await _persist();
    } else {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      players = (map['players'] as List)
          .cast<Map<String, dynamic>>()
          .map(FplPlayer.fromJson)
          .toList();
      weeks = (map['weeks'] as List)
          .cast<Map<String, dynamic>>()
          .map(LeagueWeek.fromJson)
          .toList();
      payments = (map['payments'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(WeeklyPayment.fromJson)
          .toList();
      guests = (map['guests'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(GuestPayment.fromJson)
          .toList();
      matches = (map['matches'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(MatchScorecard.fromJson)
          .toList();
      trades = (map['trades'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(PlayerTrade.fromJson)
          .toList();
      tradeOpen = map['tradeOpen'] as bool? ?? false;
      selectedWeekId = map['selectedWeekId'] as String? ?? _defaultWeekId();
    }
    ready = true;
    notifyListeners();
  }

  String _defaultWeekId() {
    final today = DateTime.now();
    for (final w in weeks) {
      if (!w.date.isBefore(DateTime(today.year, today.month, today.day))) {
        return w.id;
      }
    }
    return weeks.isEmpty ? '' : weeks.last.id;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'players': players.map((e) => e.toJson()).toList(),
        'weeks': weeks.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'guests': guests.map((e) => e.toJson()).toList(),
        'matches': matches.map((e) => e.toJson()).toList(),
        'trades': trades.map((e) => e.toJson()).toList(),
        'tradeOpen': tradeOpen,
        'selectedWeekId': selectedWeekId,
      }),
    );
  }

  Future<void> selectWeek(String weekId) async {
    selectedWeekId = weekId;
    await _persist();
    notifyListeners();
  }

  FplPlayer? playerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<FplPlayer> playersForTeam(String teamId) =>
      players.where((p) => p.teamId == teamId && p.active).toList()
        ..sort((a, b) {
          if (a.isCaptain != b.isCaptain) return a.isCaptain ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

  bool hasWeeklyPayment(String playerId, String weekId) =>
      payments.any((p) => p.playerId == playerId && p.weekId == weekId);

  Eligibility eligibilityFor(FplPlayer p, {String? weekId}) {
    final w = weekId ?? selectedWeekId;
    if (p.isLifetimeMember) {
      return const Eligibility(
        eligible: true,
        reason: EligibilityReason.lifetime,
      );
    }
    if (p.subscriptionPaid) {
      return const Eligibility(
        eligible: true,
        reason: EligibilityReason.subscription,
      );
    }
    if (hasWeeklyPayment(p.id, w)) {
      return const Eligibility(
        eligible: true,
        reason: EligibilityReason.weeklyPaid,
      );
    }
    return const Eligibility(
      eligible: false,
      reason: EligibilityReason.unpaid,
    );
  }

  List<FplPlayer> eligiblePlayers({String? weekId}) {
    final w = weekId ?? selectedWeekId;
    return players
        .where((p) => p.active && eligibilityFor(p, weekId: w).eligible)
        .toList()
      ..sort((a, b) {
        final tc = a.teamId.compareTo(b.teamId);
        if (tc != 0) return tc;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  List<GuestPayment> guestsForWeek({String? weekId}) {
    final w = weekId ?? selectedWeekId;
    return guests.where((g) => g.weekId == w).toList();
  }

  Future<void> setWeeklyPaid(FplPlayer player, bool paid) async {
    if (player.isLifetimeMember || player.subscriptionPaid) return;
    payments.removeWhere(
      (p) => p.playerId == player.id && p.weekId == selectedWeekId,
    );
    if (paid) {
      payments.add(
        WeeklyPayment(
          weekId: selectedWeekId,
          playerId: player.id,
          amount: kWeeklyFee,
          paidAt: DateTime.now(),
        ),
      );
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setSubscription(FplPlayer player, bool paid) async {
    if (player.isLifetimeMember) return;
    final i = players.indexWhere((p) => p.id == player.id);
    if (i < 0) return;
    players[i] = player.copyWith(
      subscriptionPaid: paid,
      subscriptionPaidAt: paid ? DateTime.now() : null,
      clearSubscriptionDate: !paid,
    );
    if (paid) {
      payments.removeWhere((p) => p.playerId == player.id);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> addGuest({
    required String name,
    required String teamId,
  }) async {
    guests.add(
      GuestPayment(
        id: _uuid.v4(),
        weekId: selectedWeekId,
        name: name.trim(),
        teamId: teamId,
        amount: kGuestFee,
        paidAt: DateTime.now(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> removeGuest(String id) async {
    guests.removeWhere((g) => g.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> updatePlayerContact({
    required String playerId,
    String? phone,
    String? username,
  }) async {
    final i = players.indexWhere((p) => p.id == playerId);
    if (i < 0) return;
    players[i] = players[i].copyWith(
      phone: phone,
      cricheroesUsername: username,
    );
    await _persist();
    notifyListeners();
  }

  FplPlayer? findByPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final ten = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (ten.isEmpty) return null;
    try {
      return players.firstWhere((p) => p.normalizedPhone == ten);
    } catch (_) {
      return null;
    }
  }

  FplPlayer? findByUsername(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    try {
      return players.firstWhere((p) => p.cricheroesUsernameLower == key);
    } catch (_) {
      return null;
    }
  }

  FinanceSummary financeSummary() {
    final weekly = payments.fold<int>(0, (s, p) => s + p.amount);
    final subs = players.where((p) => p.subscriptionPaid).length * kSubscriptionFee;
    final guestTotal = guests.fold<int>(0, (s, g) => s + g.amount);
    final tradeTotal = trades
        .where((t) => t.commissionCollected)
        .fold<int>(0, (s, t) => s + t.commissionInr);

    final byWeek = <String, int>{};
    for (final w in weeks) {
      final wp = payments
          .where((p) => p.weekId == w.id)
          .fold<int>(0, (s, p) => s + p.amount);
      final gp = guests
          .where((g) => g.weekId == w.id)
          .fold<int>(0, (s, g) => s + g.amount);
      if (wp + gp > 0) byWeek[w.id] = wp + gp;
    }

    return FinanceSummary(
      weeklyTotal: weekly,
      subscriptionTotal: subs,
      guestTotal: guestTotal,
      tradeCommissionTotal: tradeTotal,
      byWeek: byWeek,
    );
  }

  String eligibleCopyText() {
    final buf = StringBuffer();
    buf.writeln('FPL Eligible — ${selectedWeek?.label ?? selectedWeekId}');
    buf.writeln();
    for (final teamId in [kTeamOx, kTeamGb, kTeamNew]) {
      final list = eligiblePlayers().where((p) => p.teamId == teamId).toList();
      buf.writeln('${kTeamNames[teamId]}');
      for (final p in list) {
        buf.writeln('• ${p.name}');
      }
      buf.writeln();
    }
    final g = guestsForWeek();
    if (g.isNotEmpty) {
      buf.writeln('Guests');
      for (final x in g) {
        buf.writeln('• ${x.name} (${kTeamNames[x.teamId] ?? x.teamId})');
      }
    }
    return buf.toString().trim();
  }

  Future<void> addMatch(MatchScorecard match) async {
    matches.insert(0, match);
    await _persist();
    notifyListeners();
  }

  Future<void> setTradeOpen(bool open) async {
    tradeOpen = open;
    await _persist();
    notifyListeners();
  }

  Future<void> recordTrade({
    required FplPlayer player,
    required String toTeamId,
    required int salePriceInr,
    bool commissionCollected = true,
  }) async {
    final commission = (salePriceInr * kTradeCommissionRate).round();
    final from = player.teamId;
    trades.insert(
      0,
      PlayerTrade(
        id: _uuid.v4(),
        playerId: player.id,
        playerName: player.name,
        fromTeamId: from,
        toTeamId: toTeamId,
        salePriceInr: salePriceInr,
        commissionInr: commission,
        commissionCollected: commissionCollected,
        tradedAt: DateTime.now(),
      ),
    );
    final i = players.indexWhere((p) => p.id == player.id);
    if (i >= 0) {
      players[i] = players[i].copyWith(
        teamId: toTeamId,
        teamName: kTeamNames[toTeamId] ?? toTeamId,
      );
    }
    await _persist();
    notifyListeners();
  }

  int paidCountForWeek() {
    var n = 0;
    for (final p in players) {
      if (!p.active) continue;
      if (eligibilityFor(p).eligible) n++;
    }
    return n;
  }

  int unpaidCountForWeek() {
    var n = 0;
    for (final p in players) {
      if (!p.active) continue;
      if (p.isLifetimeMember || p.subscriptionPaid) continue;
      if (!hasWeeklyPayment(p.id, selectedWeekId)) n++;
    }
    return n;
  }
}
