import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';
import '../data/seed.dart';
import '../data/season2_auction.dart';
import '../data/season2_matches.dart';
import '../models/models.dart';
import 'contact_import.dart';
import 'firestore_sync.dart';
import 'ledger_export.dart';
import 'pdf_storage.dart';

/// Local-first store with optional Firestore multi-device sync.
class FplStore extends ChangeNotifier {
  FplStore({
    FirestoreSync? cloud,
    PdfStorage? pdfStorage,
  })  : _cloud = cloud,
        pdfStorage = pdfStorage ?? PdfStorage();

  static const _prefsKey = 'fpl_fees_v1';
  final _uuid = const Uuid();
  FirestoreSync? _cloud;
  final PdfStorage pdfStorage;

  List<FplPlayer> players = [];
  List<LeagueWeek> weeks = [];
  List<WeeklyPayment> payments = [];
  List<GuestPayment> guests = [];
  List<MatchScorecard> matches = [];
  List<PlayerTrade> trades = [];
  List<ScheduledFixture> fixtures = [];
  bool tradeOpen = false;
  /// Seeded release ids that were undone — do not re-apply on migrate.
  final Set<String> suppressedSeedTrades = {};
  String selectedWeekId = '';
  int weeklyFee = kWeeklyFee;
  int subscriptionFee = kSubscriptionFee;
  int guestFee = kGuestFee;
  bool ready = false;
  bool cloudEnabled = false;
  String? cloudError;

  LeagueWeek? get selectedWeek {
    try {
      return weeks.firstWhere((w) => w.id == selectedWeekId);
    } catch (_) {
      return weeks.isEmpty ? null : weeks.first;
    }
  }

  /// Enable cloud after Firebase bootstrap succeeds.
  void _applyCloud(CloudSnapshot snap) {
    players = snap.players;
    weeks = snap.weeks.isNotEmpty ? snap.weeks : weeks;
    payments = snap.payments;
    guests = snap.guests;
    matches = snap.matches;
    trades = snap.trades;
    if (snap.fixtures.isNotEmpty) {
      fixtures = snap.fixtures;
    }
    tradeOpen = snap.tradeOpen;
    suppressedSeedTrades
      ..clear()
      ..addAll(snap.suppressedSeedTrades);
    weeklyFee = _sanitizeFee(snap.weeklyFee, kWeeklyFee);
    subscriptionFee = _sanitizeFee(snap.subscriptionFee, kSubscriptionFee);
    guestFee = _sanitizeFee(snap.guestFee, kGuestFee);
    if (snap.selectedWeekId.isNotEmpty) {
      selectedWeekId = snap.selectedWeekId;
    } else if (selectedWeekId.isEmpty) {
      selectedWeekId = _defaultWeekId();
    }
  }

  static int _sanitizeFee(int value, int fallback) {
    if (value < 1 || value > 100000) return fallback;
    return value;
  }

  Future<void> attachCloud(FirestoreSync sync) async {
    _cloud = sync;
    cloudEnabled = true;
    pdfStorage.cloudEnabled = true;
    try {
      final remote = await sync.pullOnce();
      if (remote != null && remote.players.isNotEmpty) {
        _applyCloud(remote);
        _backfillLifetimeFromSeed();
        final migrated = _migrateTeamIds() |
            _backfillTeamNames() |
            _backfillMissingSeedPlayers() |
            _removeNonSquadGuests() |
            _ensureFixtures() |
            _ensureSeason2Scorecards() |
            _migrateWeek4GroundFeesToWeek1() |
            _ensureTradeWindowAndReleases();
        if (migrated) {
          await _persist();
        } else {
          await _persistLocal();
        }
      } else if (players.isNotEmpty) {
        _ensureFixtures();
        _ensureSeason2Scorecards();
        _ensureTradeWindowAndReleases();
        await _pushCloud();
      }
      sync.listen((snap) {
        if (snap.players.isEmpty) return;
        _applyCloud(snap);
        _backfillLifetimeFromSeed();
        final migrated = _migrateTeamIds() |
            _backfillTeamNames() |
            _backfillMissingSeedPlayers() |
            _removeNonSquadGuests() |
            _ensureFixtures() |
            _ensureSeason2Scorecards() |
            _migrateWeek4GroundFeesToWeek1() |
            _ensureTradeWindowAndReleases();
        // Defer persist until after FirestoreSync clears isApplyingRemote.
        scheduleMicrotask(() async {
          if (migrated) {
            await _persist();
          } else {
            await _persistLocal();
          }
          notifyListeners();
        });
      });
    } catch (e) {
      cloudError = '$e';
      debugPrint('Cloud attach failed: $e');
    }
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      players = buildSeedPlayers();
      weeks = buildSeasonWeeks();
      fixtures = buildSeasonFixtures();
      matches = buildSeason2SeedMatches();
      selectedWeekId = _defaultWeekId();
      _ensureTradeWindowAndReleases();
      await _persistLocal();
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
      fixtures = (map['fixtures'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ScheduledFixture.fromJson)
          .toList();
      tradeOpen = map['tradeOpen'] as bool? ?? false;
      suppressedSeedTrades
        ..clear()
        ..addAll(
          ((map['suppressedSeedTrades'] as List?) ?? const [])
              .map((e) => '$e'),
        );
      selectedWeekId = map['selectedWeekId'] as String? ?? _defaultWeekId();
      weeklyFee = _sanitizeFee(
        (map['weeklyFee'] as num?)?.toInt() ?? kWeeklyFee,
        kWeeklyFee,
      );
      subscriptionFee = _sanitizeFee(
        (map['subscriptionFee'] as num?)?.toInt() ?? kSubscriptionFee,
        kSubscriptionFee,
      );
      guestFee = _sanitizeFee(
        (map['guestFee'] as num?)?.toInt() ?? kGuestFee,
        kGuestFee,
      );
      _backfillSeedPhones();
      _backfillLifetimeFromSeed();
      final migrated = _migrateTeamIds() |
          _backfillTeamNames() |
          _backfillMissingSeedPlayers() |
          _removeNonSquadGuests() |
          _ensureFixtures() |
          _ensureSeason2Scorecards() |
          _migrateWeek4GroundFeesToWeek1() |
          _ensureTradeWindowAndReleases();
      if (migrated) {
        await _persist();
      }
    }
    ready = true;
    notifyListeners();
  }

  /// Fill empty phones from [kSeedPhones] for installs created before seed phones existed.
  void _backfillSeedPhones() {
    var changed = false;
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      final seed = kSeedPhones[p.id];
      if (seed != null && seed.isNotEmpty && p.phone.trim().isEmpty) {
        players[i] = p.copyWith(phone: seed);
        changed = true;
      }
    }
    if (changed) {
      // Fire-and-forget local persist; cloud push happens on next mutation.
      unawaited(_persistLocal());
    }
  }

  /// Apply new lifetime flags from seed (e.g. Mohammed Ali MC) onto existing installs.
  void _backfillLifetimeFromSeed() {
    final seedLifetime = {
      for (final p in buildSeedPlayers())
        if (p.isLifetimeMember) p.id,
    };
    var changed = false;
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      if (!seedLifetime.contains(p.id) || p.isLifetimeMember) continue;
      players[i] = p.copyWith(
        isLifetimeMember: true,
        subscriptionPaid: false,
        clearSubscriptionDate: true,
      );
      payments.removeWhere((pay) => pay.playerId == p.id);
      changed = true;
    }
    if (changed) {
      unawaited(_persist());
    }
  }

  /// Add / sync players introduced in later seed revisions (e.g. Mulla guest).
  /// Returns true if any row changed (caller should persist / push).
  bool _backfillMissingSeedPlayers() {
    var changed = false;
    for (final seed in buildSeedPlayers()) {
      final i = players.indexWhere((p) => p.id == seed.id);
      if (i < 0) {
        players.add(seed);
        changed = true;
        continue;
      }
      // Keep floating guests on [kTeamGuest] + lifetime (never fee'd).
      if (seed.teamId != kTeamGuest) continue;
      final p = players[i];
      if (p.teamId == kTeamGuest &&
          p.isLifetimeMember &&
          p.teamName == seed.teamName) {
        continue;
      }
      players[i] = p.copyWith(
        teamId: kTeamGuest,
        teamName: seed.teamName,
        isLifetimeMember: true,
        subscriptionPaid: false,
        clearSubscriptionDate: true,
      );
      payments.removeWhere((pay) => pay.playerId == p.id);
      changed = true;
    }
    return changed;
  }

  /// Drop one-off match guests who were briefly seeded onto a squad (e.g. Mohammed Arif).
  bool _removeNonSquadGuests() {
    const dropIds = {'mohammed_arif'};
    final before = players.length;
    players.removeWhere((p) => dropIds.contains(p.id));
    if (players.length == before) return false;
    for (final id in dropIds) {
      payments.removeWhere((pay) => pay.playerId == id);
    }
    return true;
  }

  /// Keep trade window open, wipe mistaken auto-seeds once, then apply confirmed deals.
  bool _ensureTradeWindowAndReleases() {
    var changed = false;
    if (!tradeOpen) {
      tradeOpen = true;
      changed = true;
    }

    const wipeFlag = 's2_trades_wiped_v1';
    if (!suppressedSeedTrades.contains(wipeFlag)) {
      if (trades.isNotEmpty) {
        trades.clear();
        changed = true;
      }

      final seedById = {for (final p in buildSeedPlayers()) p.id: p};
      for (var i = 0; i < players.length; i++) {
        final seed = seedById[players[i].id];
        if (seed == null) continue;
        if (players[i].teamId == seed.teamId &&
            players[i].teamName == seed.teamName) {
          continue;
        }
        players[i] = players[i].copyWith(
          teamId: seed.teamId,
          teamName: seed.teamName,
        );
        changed = true;
      }

      suppressedSeedTrades.addAll({
        wipeFlag,
        's2_release_aslam_hashim',
        's2_release_syed_molana',
        's2_trade_aslam_to_ox',
        's2_trade_faizal_to_gb',
        's2_trade_fazil_to_gb',
        's2_t1_aslam_to_ox',
        's2_t1_faizal_to_gb',
        's2_t1_fazil_to_gb',
      });
      changed = true;
    }

    if (_ensureTrade1OxAslamPackage()) changed = true;
    return changed;
  }

  /// Trade 1: single package — OX gets Aslam for 4000 + Faizal + Fazil Farook.
  bool _ensureTrade1OxAslamPackage() {
    if (suppressedSeedTrades.contains('s2_t1_package')) return false;

    // Drop older 3-leg seed ids if present.
    final legacyIds = {
      's2_t1_aslam_to_ox',
      's2_t1_faizal_to_gb',
      's2_t1_fazil_to_gb',
    };
    final before = trades.length;
    trades.removeWhere((t) => legacyIds.contains(t.id));
    var changed = trades.length != before;

    if (trades.any((t) => t.id == 's2_t1_package')) {
      changed |= _forceTeam('aslam_hashim', kTeamOx);
      changed |= _forceTeam('faizal', kTeamGb);
      changed |= _forceTeam('fazil_farook', kTeamGb);
      return changed;
    }

    final aslam = playerById('aslam_hashim');
    final faizal = playerById('faizal');
    final fazil = playerById('fazil_farook');
    if (aslam == null || faizal == null || fazil == null) return changed;

    // Already applied on roster (e.g. partial legacy) — still record package.
    final ready = (aslam.teamId == kTeamGb || aslam.teamId == kTeamOx) &&
        (faizal.teamId == kTeamOx || faizal.teamId == kTeamGb) &&
        (fazil.teamId == kTeamOx || fazil.teamId == kTeamGb);
    if (!ready) return changed;

    trades.insert(
      0,
      PlayerTrade(
        id: 's2_t1_package',
        playerId: aslam.id,
        playerName: aslam.name,
        fromTeamId: kTeamGb,
        toTeamId: kTeamOx,
        salePriceInr: 0,
        commissionInr: 0,
        commissionCollected: false,
        tradedAt: DateTime(2026, 8, 10, 18),
        kind: TradeKind.package,
        auctionPoints: 4000,
        packageLegs: const [
          TradePackageLeg(
            playerId: 'faizal',
            playerName: 'Faizal',
            fromTeamId: kTeamOx,
            toTeamId: kTeamGb,
          ),
          TradePackageLeg(
            playerId: 'fazil_farook',
            playerName: 'Fazil Farook',
            fromTeamId: kTeamOx,
            toTeamId: kTeamGb,
          ),
        ],
        notes: 'Trade 1: Aslam worth 4000 + Faizal + Fazil Farook',
      ),
    );
    _forceTeam('aslam_hashim', kTeamOx);
    _forceTeam('faizal', kTeamGb);
    _forceTeam('fazil_farook', kTeamGb);
    return true;
  }

  bool _forceTeam(String playerId, String teamId) {
    final i = players.indexWhere((p) => p.id == playerId);
    if (i < 0 || players[i].teamId == teamId) return false;
    players[i] = players[i].copyWith(
      teamId: teamId,
      teamName: kTeamNames[teamId] ?? teamId,
    );
    return true;
  }

  /// Auction book costs + sell-side sunk / cash credits.
  /// Only [TradeKind.release] returns a player's auction cost to Left.
  /// Sell/package: outgoing cost is sunk; cash [auctionPoints] credit the seller.
  ({
    Map<String, int> costs,
    Map<String, int> sunk,
    Map<String, int> credit,
  }) _auctionLedger() {
    final costs = <String, int>{};
    final sunk = <String, int>{};
    final credit = <String, int>{};

    for (final seed in season2AuctionSeeds) {
      final byName = seed.initialCostsByName();
      for (final p in players) {
        final pts = byName[auctionNameKey(p.name)];
        if (pts != null) costs[p.id] = pts;
      }
    }

    void applyOutgoingSell({
      required String playerId,
      required String fromTeamId,
      required int newCost,
    }) {
      final prev = costs[playerId] ?? 0;
      if (fromTeamId != kTeamFreeAgent && fromTeamId != kTeamGuest) {
        sunk[fromTeamId] = (sunk[fromTeamId] ?? 0) + prev;
        if (newCost > 0) {
          credit[fromTeamId] = (credit[fromTeamId] ?? 0) + newCost;
        }
      }
      costs[playerId] = newCost;
    }

    final chronological = [...trades]
      ..sort((a, b) => a.tradedAt.compareTo(b.tradedAt));
    for (final t in chronological) {
      switch (t.kind) {
        case TradeKind.release:
          costs[t.playerId] = 0;
        case TradeKind.buy:
          costs[t.playerId] = t.auctionPoints;
        case TradeKind.sell:
          applyOutgoingSell(
            playerId: t.playerId,
            fromTeamId: t.fromTeamId,
            newCost: t.auctionPoints,
          );
        case TradeKind.package:
          applyOutgoingSell(
            playerId: t.playerId,
            fromTeamId: t.fromTeamId,
            newCost: t.auctionPoints,
          );
          for (final leg in t.packageLegs) {
            applyOutgoingSell(
              playerId: leg.playerId,
              fromTeamId: leg.fromTeamId,
              newCost: leg.auctionPoints,
            );
          }
      }
    }
    return (costs: costs, sunk: sunk, credit: credit);
  }

  /// Current auction cost per player id (seed + trade history).
  Map<String, int> auctionCostsByPlayerId() => _auctionLedger().costs;

  int auctionCostFor(String playerId) =>
      auctionCostsByPlayerId()[playerId] ?? 0;

  /// Live purse for a team after releases / buys / sells / packages.
  ({int spent, int left, int squadSize}) auctionPurseLive(String teamId) {
    final ledger = _auctionLedger();
    final squad = playersForTeam(teamId);
    var squadSpent = 0;
    for (final p in squad) {
      if (p.isCaptain) continue;
      squadSpent += ledger.costs[p.id] ?? 0;
    }
    final sunk = ledger.sunk[teamId] ?? 0;
    final credit = ledger.credit[teamId] ?? 0;
    final spent = squadSpent + sunk - credit;
    return (
      spent: spent,
      left: kAuctionBudgetTotal - spent,
      squadSize: squad.length,
    );
  }

  List<FplPlayer> freeAgents() =>
      players.where((p) => p.teamId == kTeamFreeAgent && p.active).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  bool _ensureSeason2Scorecards() {
    final seed = buildSeason2SeedMatches();
    var changed = false;
    for (final m in seed) {
      final i = matches.indexWhere((x) => x.id == m.id);
      if (i < 0) {
        matches.add(m);
        changed = true;
        continue;
      }
      final existing = matches[i];
      final needsUpgrade =
          !existing.hasStructuredCard ||
          existing.hasPdf ||
          existing.innings.length != m.innings.length ||
          existing.resultText != m.resultText ||
          existing.teamAScore != m.teamAScore ||
          existing.teamBScore != m.teamBScore;
      if (!needsUpgrade) continue;
      matches[i] = m;
      changed = true;
    }
    if (changed) {
      matches.sort((a, b) => b.date.compareTo(a.date));
    }
    return changed;
  }

  /// One-time fix: ground fees marked on League Week 4 by mistake → Week 1.
  bool _migrateWeek4GroundFeesToWeek1() {
    const fromWeek = '2026-08-23';
    const toWeek = '2026-08-02';
    var changed = false;

    final week4Pays = payments.where((p) => p.weekId == fromWeek).toList();
    if (week4Pays.isNotEmpty) {
      for (final p in week4Pays) {
        payments.removeWhere(
          (x) => x.weekId == fromWeek && x.playerId == p.playerId,
        );
        payments.removeWhere(
          (x) => x.weekId == toWeek && x.playerId == p.playerId,
        );
        payments.add(
          WeeklyPayment(
            weekId: toWeek,
            playerId: p.playerId,
            amount: p.amount,
            paidAt: p.paidAt,
          ),
        );
      }
      changed = true;
    }

    final week4Guests = guests.where((g) => g.weekId == fromWeek).toList();
    if (week4Guests.isNotEmpty) {
      for (final g in week4Guests) {
        guests.removeWhere((x) => x.id == g.id);
        guests.add(
          GuestPayment(
            id: g.id,
            weekId: toWeek,
            name: g.name,
            teamId: g.teamId,
            amount: g.amount,
            paidAt: g.paidAt,
          ),
        );
      }
      changed = true;
    }

    return changed;
  }

  /// Migrate legacy team id `new` → `avengers` across players, guests, trades, matches.
  /// Returns true if any row changed (caller should persist / push).
  bool _migrateTeamIds() {
    String mapId(String id) => id == kTeamNewLegacy ? kTeamAvengers : id;

    var changed = false;
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      if (p.teamId != kTeamNewLegacy) continue;
      players[i] = p.copyWith(
        teamId: kTeamAvengers,
        teamName: kTeamNames[kTeamAvengers]!,
      );
      changed = true;
    }

    for (var i = 0; i < guests.length; i++) {
      final g = guests[i];
      if (g.teamId != kTeamNewLegacy) continue;
      guests[i] = GuestPayment(
        id: g.id,
        weekId: g.weekId,
        name: g.name,
        teamId: kTeamAvengers,
        amount: g.amount,
        paidAt: g.paidAt,
      );
      changed = true;
    }

    for (var i = 0; i < trades.length; i++) {
      final t = trades[i];
      final from = mapId(t.fromTeamId);
      final to = mapId(t.toTeamId);
      if (from == t.fromTeamId && to == t.toTeamId) continue;
      trades[i] = t.copyWith(fromTeamId: from, toTeamId: to);
      changed = true;
    }

    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final a = mapId(m.teamAId);
      final b = mapId(m.teamBId);
      if (a == m.teamAId && b == m.teamBId) continue;
      matches[i] = MatchScorecard(
        id: m.id,
        date: m.date,
        teamAId: a,
        teamBId: b,
        teamAName: kTeamNames[a] ?? m.teamAName,
        teamBName: kTeamNames[b] ?? m.teamBName,
        teamAScore: m.teamAScore,
        teamBScore: m.teamBScore,
        resultText: m.resultText,
        tossText: m.tossText,
        ground: m.ground,
        pdfLocalPath: m.pdfLocalPath,
        pdfUrl: m.pdfUrl,
        innings: m.innings,
      );
      changed = true;
    }

    for (var i = 0; i < fixtures.length; i++) {
      final f = fixtures[i];
      final a = mapId(f.teamAId);
      final b = mapId(f.teamBId);
      if (a == f.teamAId && b == f.teamBId) continue;
      fixtures[i] = ScheduledFixture(
        id: f.id,
        weekId: f.weekId,
        date: f.date,
        slot: f.slot,
        teamAId: a,
        teamBId: b,
        teamAName: kTeamNames[a] ?? f.teamAName,
        teamBName: kTeamNames[b] ?? f.teamBName,
      );
      changed = true;
    }

    return changed;
  }

  /// Seed / merge Aug–Sep fixtures when missing (existing installs).
  bool _ensureFixtures() {
    final seed = buildSeasonFixtures();
    if (fixtures.isEmpty) {
      fixtures = List.of(seed);
      return true;
    }
    final ids = fixtures.map((f) => f.id).toSet();
    var changed = false;
    for (final f in seed) {
      if (ids.contains(f.id)) continue;
      fixtures.add(f);
      changed = true;
    }
    if (changed) {
      fixtures.sort((a, b) {
        final dc = a.date.compareTo(b.date);
        if (dc != 0) return dc;
        return a.slot.compareTo(b.slot);
      });
    }
    return changed;
  }

  /// Keep player.teamName in sync with [kTeamNames].
  /// Returns true if any row changed (caller should persist / push).
  bool _backfillTeamNames() {
    var changed = false;
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      final expected = kTeamNames[p.teamId];
      if (expected == null || p.teamName == expected) continue;
      players[i] = p.copyWith(teamName: expected);
      changed = true;
    }
    return changed;
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

  Map<String, dynamic> toBackupMap() => {
        'players': players.map((e) => e.toJson()).toList(),
        'weeks': weeks.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'guests': guests.map((e) => e.toJson()).toList(),
        'matches': matches.map((e) => e.toJson()).toList(),
        'trades': trades.map((e) => e.toJson()).toList(),
        'fixtures': fixtures.map((e) => e.toJson()).toList(),
        'tradeOpen': tradeOpen,
        'suppressedSeedTrades': suppressedSeedTrades.toList(),
        'selectedWeekId': selectedWeekId,
        'weeklyFee': weeklyFee,
        'subscriptionFee': subscriptionFee,
        'guestFee': guestFee,
      };

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toBackupMap()));
  }

  /// Season writes need Firebase Auth + `admins/{uid}`. Players / local-password
  /// admin keep data local-only until a real Firebase admin signs in.
  bool get canWriteCloud {
    if (!cloudEnabled || _cloud == null) return false;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pushCloud() async {
    final sync = _cloud;
    if (sync == null || sync.isApplyingRemote) return;
    if (!canWriteCloud) return;
    try {
      await sync.pushAll(
        players: players,
        weeks: weeks,
        payments: payments,
        guests: guests,
        matches: matches,
        trades: trades,
        fixtures: fixtures,
        tradeOpen: tradeOpen,
        suppressedSeedTrades: suppressedSeedTrades.toList(),
        selectedWeekId: selectedWeekId,
        weeklyFee: weeklyFee,
        subscriptionFee: subscriptionFee,
        guestFee: guestFee,
      );
      cloudError = null;
    } catch (e) {
      cloudError = '$e';
      debugPrint('Cloud push: $e');
    }
  }

  /// Call after Firebase admin login so migrations (scorecards, etc.) sync up.
  Future<void> syncToCloudIfAdmin() async {
    if (!canWriteCloud) return;
    await _pushCloud();
    notifyListeners();
  }

  Future<void> setFeeAmounts({
    int? weekly,
    int? subscription,
    int? guest,
  }) async {
    final nextWeekly = weekly ?? weeklyFee;
    final nextSub = subscription ?? subscriptionFee;
    final nextGuest = guest ?? guestFee;
    if (nextWeekly < 1 ||
        nextWeekly > 100000 ||
        nextSub < 1 ||
        nextSub > 100000 ||
        nextGuest < 1 ||
        nextGuest > 100000) {
      throw ArgumentError('Fees must be between ₹1 and ₹100000');
    }
    weeklyFee = nextWeekly;
    subscriptionFee = nextSub;
    guestFee = nextGuest;
    await _persist();
    notifyListeners();
  }

  /// Effective weekly fee for a Sunday (per-week override or app default).
  int feeForWeek([String? weekId]) {
    final id = weekId ?? selectedWeekId;
    try {
      final w = weeks.firstWhere((w) => w.id == id);
      return w.weeklyFee ?? weeklyFee;
    } catch (_) {
      return weeklyFee;
    }
  }

  /// Effective guest fee for a Sunday (per-week override or app default).
  int guestFeeForWeek([String? weekId]) {
    final id = weekId ?? selectedWeekId;
    try {
      final w = weeks.firstWhere((w) => w.id == id);
      return w.guestFee ?? guestFee;
    } catch (_) {
      return guestFee;
    }
  }

  Future<void> setWeekFees(
    String weekId, {
    int? weekly,
    int? guest,
  }) async {
    if (weekly != null && (weekly < 1 || weekly > 100000)) {
      throw ArgumentError('Weekly fee must be between ₹1 and ₹100000');
    }
    if (guest != null && (guest < 1 || guest > 100000)) {
      throw ArgumentError('Guest fee must be between ₹1 and ₹100000');
    }
    final i = weeks.indexWhere((w) => w.id == weekId);
    if (i < 0) return;
    weeks[i] = weeks[i].copyWith(
      weeklyFee: weekly,
      guestFee: guest,
    );
    await _persist();
    notifyListeners();
  }

  /// Convenience for callers that only set the weekly amount.
  Future<void> setWeekWeeklyFee(String weekId, int amount) =>
      setWeekFees(weekId, weekly: amount);

  Future<void> _persist() async {
    await _persistLocal();
    await _pushCloud();
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
    if (p.hasActiveSubscription) {
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

  List<ScheduledFixture> fixturesForWeek([String? weekId]) {
    final w = weekId ?? selectedWeekId;
    return fixtures.where((f) => f.weekId == w).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
  }

  /// Completed scorecard for a fixture (same calendar day + same two teams).
  MatchScorecard? matchForFixture(ScheduledFixture fixture) {
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    for (final m in matches) {
      if (!sameDay(m.date, fixture.date)) continue;
      final teams = {m.teamAId, m.teamBId};
      if (teams.contains(fixture.teamAId) && teams.contains(fixture.teamBId)) {
        return m;
      }
    }
    return null;
  }

  Future<void> setWeeklyPaid(FplPlayer player, bool paid) async {
    if (player.isLifetimeMember || player.hasActiveSubscription) return;
    final weekId = selectedWeekId;
    final paymentId = '${weekId}_${player.id}';

    payments.removeWhere(
      (p) => p.playerId == player.id && p.weekId == weekId,
    );
    WeeklyPayment? added;
    if (paid) {
      added = WeeklyPayment(
        weekId: weekId,
        playerId: player.id,
        amount: feeForWeek(weekId),
        paidAt: DateTime.now(),
      );
      payments.add(added);
    }

    // Update UI immediately before cloud I/O.
    notifyListeners();
    await _persistLocal();

    final sync = _cloud;
    if (sync != null && !sync.isApplyingRemote && canWriteCloud) {
      try {
        if (paid && added != null) {
          await sync.upsertPayment(added);
        } else {
          await sync.deletePayment(paymentId);
        }
        cloudError = null;
      } catch (e) {
        cloudError = '$e';
        debugPrint('Weekly fee cloud sync: $e');
      }
    }
  }

  Future<void> setSubscription(
    FplPlayer player,
    bool paid, {
    int? amount,
    DateTime? validUntil,
    bool clearValidUntil = false,
  }) async {
    if (player.isLifetimeMember) return;
    final i = players.indexWhere((p) => p.id == player.id);
    if (i < 0) return;

    final removedPaymentIds = <String>[];
    if (paid) {
      final amt = amount ?? subscriptionFee;
      if (amt < 1 || amt > 100000) {
        throw ArgumentError('Subscription must be between ₹1 and ₹100000');
      }
      for (final p in payments.where((p) => p.playerId == player.id)) {
        removedPaymentIds.add(p.id);
      }
      payments.removeWhere((p) => p.playerId == player.id);
      players[i] = player.copyWith(
        subscriptionPaid: true,
        subscriptionPaidAt: DateTime.now(),
        subscriptionAmount: amt,
        subscriptionValidUntil: validUntil,
        clearSubscriptionValidUntil: clearValidUntil || validUntil == null,
      );
    } else {
      players[i] = player.copyWith(
        subscriptionPaid: false,
        subscriptionAmount: 0,
        clearSubscriptionDate: true,
        clearSubscriptionValidUntil: true,
      );
    }

    notifyListeners();
    await _persistLocal();

    final sync = _cloud;
    if (sync != null && !sync.isApplyingRemote && canWriteCloud) {
      try {
        // Push player subscription fields + delete cleared weekly docs.
        await sync.pushAll(
          players: players,
          weeks: weeks,
          payments: payments,
          guests: guests,
          matches: matches,
          trades: trades,
          fixtures: fixtures,
          tradeOpen: tradeOpen,
          suppressedSeedTrades: suppressedSeedTrades.toList(),
          selectedWeekId: selectedWeekId,
          weeklyFee: weeklyFee,
          subscriptionFee: subscriptionFee,
          guestFee: guestFee,
        );
        if (removedPaymentIds.isNotEmpty) {
          await sync.deletePayments(removedPaymentIds);
        }
        cloudError = null;
      } catch (e) {
        cloudError = '$e';
        debugPrint('Subscription cloud sync: $e');
      }
    }
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
        amount: guestFeeForWeek(selectedWeekId),
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
    String? email,
    String? username,
  }) async {
    final i = players.indexWhere((p) => p.id == playerId);
    if (i < 0) return;

    String? nextPhone = phone;
    if (phone != null) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      nextPhone = digits.length >= 10
          ? digits.substring(digits.length - 10)
          : digits;
      if (nextPhone.isNotEmpty && nextPhone.length != 10) {
        throw ArgumentError('Enter a valid 10-digit mobile number');
      }
      if (nextPhone.isNotEmpty) {
        final taken = players.any(
          (p) => p.id != playerId && p.normalizedPhone == nextPhone,
        );
        if (taken) {
          throw ArgumentError('This number is already used by another player');
        }
      }
    }

    final nextEmail = email?.trim();
    if (nextEmail != null &&
        nextEmail.isNotEmpty &&
        !_emailRe.hasMatch(nextEmail)) {
      throw ArgumentError('Enter a valid email, or leave it blank');
    }

    players[i] = players[i].copyWith(
      phone: nextPhone,
      email: nextEmail,
      cricheroesUsername: username,
    );
    await _persist();
    notifyListeners();
  }

  /// Player opened / signed into the app.
  Future<void> recordPlayerLogin(String playerId) async {
    final i = players.indexWhere((p) => p.id == playerId);
    if (i < 0) return;
    final at = DateTime.now();
    players[i] = players[i].copyWith(lastLoginAt: at);
    await _persistLocal();
    notifyListeners();

    final sync = _cloud;
    if (sync != null && !sync.isApplyingRemote) {
      try {
        await sync.pushPlayerLogin(playerId: playerId, lastLoginAt: at);
        cloudError = null;
      } catch (e) {
        cloudError = '$e';
        debugPrint('Player login cloud sync: $e');
      }
    }
  }

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Player self-service: add or edit mobile (required) + optional email.
  /// Returns null on success, or an error message.
  Future<String?> updateOwnPhone({
    required String playerId,
    required String rawPhone,
    String rawEmail = '',
  }) async {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final ten =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (ten.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }

    final email = rawEmail.trim();
    if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
      return 'Enter a valid email, or leave it blank';
    }

    final i = players.indexWhere((p) => p.id == playerId);
    if (i < 0) return 'Player not found';

    // Avoid duplicate phones on the squad.
    final taken = players.any(
      (p) => p.id != playerId && p.normalizedPhone == ten,
    );
    if (taken) return 'This number is already used by another player';

    final at = DateTime.now();
    players[i] = players[i].copyWith(
      phone: ten,
      email: email,
      lastUpdatedAt: at,
    );
    await _persistLocal();
    notifyListeners();

    final sync = _cloud;
    if (sync != null && !sync.isApplyingRemote) {
      try {
        await sync.pushPlayerPhone(
          playerId: playerId,
          phone: ten,
          email: email,
          lastUpdatedAt: at,
        );
        cloudError = null;
      } catch (e) {
        cloudError = '$e';
        // Keep local save; cloud may catch up when admin seeds / rules allow.
        debugPrint('Own phone cloud sync: $e');
      }
    }
    return null;
  }

  /// Bulk update phones / usernames from CSV paste or file contents.
  Future<ContactImportResult> importContacts(String csv) async {
    final (next, result) = ContactImporter.apply(players: players, csv: csv);
    if (result.updated > 0) {
      players = next;
      await _persist();
      notifyListeners();
    }
    return result;
  }

  String contactsTemplateCsv() => ContactImporter.templateCsv(players);

  String exportFinanceCsv() => LedgerExport.financeCsv(this);

  String exportPaymentsCsv() => LedgerExport.paymentsCsv(this);

  String exportSubscriptionsCsv() => LedgerExport.subscriptionsCsv(players);

  String exportFullBackupJson() =>
      const JsonEncoder.withIndent('  ').convert(toBackupMap());

  FplPlayer? findByPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final ten =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
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
    final subs = players
        .where((p) => p.subscriptionPaid)
        .fold<int>(0, (s, p) => s + p.subscriptionAmount);
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
    for (final teamId in [kTeamOx, kTeamGb, kTeamAvengers]) {
      final list = eligiblePlayers().where((p) => p.teamId == teamId).toList();
      buf.writeln('${kTeamNames[teamId]}');
      for (final p in list) {
        buf.writeln('• ${p.name}');
      }
      buf.writeln();
    }
    final floating =
        eligiblePlayers().where((p) => p.teamId == kTeamGuest).toList();
    if (floating.isNotEmpty) {
      buf.writeln('Floating / guest (lifetime)');
      for (final p in floating) {
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

  /// Whether [trade] can be undone (must be the latest action on that player).
  /// Whether [trade] can be undone (must be the latest action on every involved player).
  bool canUndoTrade(PlayerTrade trade) {
    final involved = trade.involvedPlayerIds.toSet();
    for (final pid in involved) {
      final latest = trades.cast<PlayerTrade?>().firstWhere(
        (t) => t!.involvedPlayerIds.contains(pid),
        orElse: () => null,
      );
      if (latest == null || latest.id != trade.id) return false;
    }

    return switch (trade.kind) {
      TradeKind.release =>
        playerById(trade.playerId)?.teamId == kTeamFreeAgent,
      TradeKind.buy || TradeKind.sell =>
        playerById(trade.playerId)?.teamId == trade.toTeamId,
      TradeKind.package =>
        playerById(trade.playerId)?.teamId == trade.toTeamId &&
            trade.packageLegs.every(
              (leg) => playerById(leg.playerId)?.teamId == leg.toTeamId,
            ),
    };
  }

  Future<void> undoTrade(String tradeId) async {
    final idx = trades.indexWhere((t) => t.id == tradeId);
    if (idx < 0) throw StateError('Trade not found');
    final trade = trades[idx];
    if (!canUndoTrade(trade)) {
      throw StateError(
        'Cannot undo — a later trade moved this player, or roster changed',
      );
    }

    void restore(String playerId, String teamId) {
      final i = players.indexWhere((p) => p.id == playerId);
      if (i < 0) return;
      players[i] = players[i].copyWith(
        teamId: teamId,
        teamName: kTeamNames[teamId] ?? teamId,
      );
    }

    switch (trade.kind) {
      case TradeKind.release:
        restore(trade.playerId, trade.fromTeamId);
      case TradeKind.buy:
        restore(trade.playerId, kTeamFreeAgent);
      case TradeKind.sell:
        restore(trade.playerId, trade.fromTeamId);
      case TradeKind.package:
        restore(trade.playerId, trade.fromTeamId);
        for (final leg in trade.packageLegs) {
          restore(leg.playerId, leg.fromTeamId);
        }
    }

    trades.removeAt(idx);

    const seedIds = {
      's2_release_aslam_hashim',
      's2_release_syed_molana',
      's2_trade_aslam_to_ox',
      's2_trade_faizal_to_gb',
      's2_trade_fazil_to_gb',
      's2_t1_aslam_to_ox',
      's2_t1_faizal_to_gb',
      's2_t1_fazil_to_gb',
      's2_t1_package',
    };
    if (seedIds.contains(trade.id)) {
      suppressedSeedTrades.add(trade.id);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> setTradeOpen(bool open) async {
    tradeOpen = open;
    await _persist();
    notifyListeners();
  }

  Future<void> recordRelease({
    required FplPlayer player,
    int? auctionPoints,
    String notes = '',
  }) async {
    if (player.teamId == kTeamFreeAgent || player.teamId == kTeamGuest) {
      throw StateError('Player is not on a squad');
    }
    if (player.isCaptain) {
      throw StateError('Cannot release captain');
    }
    final pts = auctionPoints ?? auctionCostFor(player.id);
    final from = player.teamId;
    trades.insert(
      0,
      PlayerTrade(
        id: _uuid.v4(),
        playerId: player.id,
        playerName: player.name,
        fromTeamId: from,
        toTeamId: kTeamFreeAgent,
        salePriceInr: 0,
        commissionInr: 0,
        commissionCollected: false,
        tradedAt: DateTime.now(),
        kind: TradeKind.release,
        auctionPoints: pts,
        notes: notes,
      ),
    );
    final i = players.indexWhere((p) => p.id == player.id);
    if (i >= 0) {
      players[i] = players[i].copyWith(
        teamId: kTeamFreeAgent,
        teamName: kTeamNames[kTeamFreeAgent]!,
      );
    }
    await _persist();
    notifyListeners();
  }

  Future<void> recordBuy({
    required FplPlayer player,
    required String toTeamId,
    required int auctionPoints,
    String notes = '',
  }) async {
    if (player.teamId != kTeamFreeAgent) {
      throw StateError('Buy is for free agents only — use Sell for transfers');
    }
    if (toTeamId == kTeamFreeAgent || toTeamId == kTeamGuest) {
      throw StateError('Invalid buying team');
    }
    final purse = auctionPurseLive(toTeamId);
    if (auctionPoints > purse.left) {
      throw StateError(
        'Not enough points (left ${purse.left}, need $auctionPoints)',
      );
    }
    trades.insert(
      0,
      PlayerTrade(
        id: _uuid.v4(),
        playerId: player.id,
        playerName: player.name,
        fromTeamId: kTeamFreeAgent,
        toTeamId: toTeamId,
        salePriceInr: 0,
        commissionInr: 0,
        commissionCollected: false,
        tradedAt: DateTime.now(),
        kind: TradeKind.buy,
        auctionPoints: auctionPoints,
        notes: notes,
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

  Future<void> recordSell({
    required FplPlayer player,
    required String toTeamId,
    required int auctionPoints,
    String notes = '',
  }) async {
    if (player.teamId == kTeamFreeAgent || player.teamId == kTeamGuest) {
      throw StateError('Player is not on a squad — use Buy');
    }
    if (player.isCaptain) {
      throw StateError('Cannot sell captain');
    }
    if (player.teamId == toTeamId) {
      throw StateError('Player already on that team');
    }
    if (toTeamId == kTeamFreeAgent || toTeamId == kTeamGuest) {
      throw StateError('Use Release instead');
    }
    final buyerPurse = auctionPurseLive(toTeamId);
    if (auctionPoints > buyerPurse.left) {
      throw StateError(
        'Buyer short on points (left ${buyerPurse.left}, need $auctionPoints)',
      );
    }
    final from = player.teamId;
    trades.insert(
      0,
      PlayerTrade(
        id: _uuid.v4(),
        playerId: player.id,
        playerName: player.name,
        fromTeamId: from,
        toTeamId: toTeamId,
        salePriceInr: 0,
        commissionInr: 0,
        commissionCollected: false,
        tradedAt: DateTime.now(),
        kind: TradeKind.sell,
        auctionPoints: auctionPoints,
        notes: notes,
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

  /// Legacy INR trade (kept for old ledger rows / finance). Prefer [recordSell].
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
        kind: TradeKind.sell,
        auctionPoints: 0,
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

  @override
  void dispose() {
    _cloud?.dispose();
    super.dispose();
  }
}
