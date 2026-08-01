import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/models.dart';

/// Pushes / pulls FPL season data to Firestore for multi-device sync.
class FirestoreSync {
  FirestoreSync({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _pushing = false;
  bool _applyingRemote = false;
  /// Ignore snapshot pulls briefly after a local write (stale in-flight pulls).
  DateTime? _ignoreRemoteUntil;

  bool get isApplyingRemote => _applyingRemote;

  void _beginLocalWrite() {
    _pushing = true;
    _ignoreRemoteUntil = DateTime.now().add(const Duration(milliseconds: 1200));
  }

  void _endLocalWrite() {
    _pushing = false;
    _ignoreRemoteUntil = DateTime.now().add(const Duration(milliseconds: 1200));
  }

  bool get _shouldIgnoreRemote {
    if (_pushing || _applyingRemote) return true;
    final until = _ignoreRemoteUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  CollectionReference<Map<String, dynamic>> get _players =>
      _db.collection('players');
  CollectionReference<Map<String, dynamic>> get _weeks =>
      _db.collection('weeks');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get _guests =>
      _db.collection('guestPayments');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _trades =>
      _db.collection('trades');
  CollectionReference<Map<String, dynamic>> get _fixtures =>
      _db.collection('fixtures');
  DocumentReference<Map<String, dynamic>> get _config =>
      _db.collection('appConfig').doc('main');

  /// Load once. Returns true if cloud already had data.
  Future<CloudSnapshot?> pullOnce() async {
    try {
      final results = await Future.wait([
        _players.get(),
        _weeks.get(),
        _payments.get(),
        _guests.get(),
        _matches.get(),
        _trades.get(),
        _fixtures.get(),
        _config.get(),
      ]);

      final playerSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final weekSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      if (playerSnap.docs.isEmpty && weekSnap.docs.isEmpty) {
        return null;
      }

      final paymentSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final guestSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
      final matchSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
      final tradeSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
      final fixtureSnap = results[6] as QuerySnapshot<Map<String, dynamic>>;
      final configSnap = results[7] as DocumentSnapshot<Map<String, dynamic>>;

      final cfg = configSnap.data() ?? {};
      return CloudSnapshot(
        players: playerSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return FplPlayer.fromJson(m);
        }).toList(),
        weeks: weekSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return LeagueWeek.fromJson(m);
        }).toList(),
        payments: paymentSnap.docs
            .map((d) => WeeklyPayment.fromJson(d.data()))
            .toList(),
        guests: guestSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return GuestPayment.fromJson(m);
        }).toList(),
        matches: matchSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return MatchScorecard.fromJson(m);
        }).toList(),
        trades: tradeSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return PlayerTrade.fromJson(m);
        }).toList(),
        fixtures: fixtureSnap.docs.map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = m['id'] ?? d.id;
          return ScheduledFixture.fromJson(m);
        }).toList(),
        tradeOpen: cfg['tradeOpen'] as bool? ?? false,
        selectedWeekId: cfg['selectedWeekId'] as String? ?? '',
        weeklyFee: (cfg['weeklyFee'] as num?)?.toInt() ?? kWeeklyFee,
        subscriptionFee:
            (cfg['subscriptionFee'] as num?)?.toInt() ?? kSubscriptionFee,
        guestFee: (cfg['guestFee'] as num?)?.toInt() ?? kGuestFee,
      );
    } catch (e, st) {
      debugPrint('Firestore pull failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> pushPlayerPhone({
    required String playerId,
    required String phone,
    String email = '',
  }) async {
    if (_applyingRemote) return;
    _beginLocalWrite();
    try {
      final ref = _players.doc(playerId);
      final snap = await ref.get();
      if (snap.exists) {
        final data = <String, dynamic>{'phone': phone};
        if (email.trim().isNotEmpty) {
          data['email'] = email.trim();
        }
        await ref.update(data);
      } else {
        // Doc not seeded in cloud yet — skip; local persist still holds the number.
        debugPrint('Firestore player $playerId missing; phone kept local only');
      }
    } catch (e, st) {
      debugPrint('Firestore phone push failed: $e\n$st');
      rethrow;
    } finally {
      _endLocalWrite();
    }
  }

  /// Create/update a single weekly payment doc.
  Future<void> upsertPayment(WeeklyPayment payment) async {
    if (_applyingRemote) return;
    _beginLocalWrite();
    try {
      await _payments.doc(payment.id).set(payment.toJson(), SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('Firestore upsertPayment failed: $e\n$st');
      rethrow;
    } finally {
      _endLocalWrite();
    }
  }

  /// Remove a weekly payment doc (fee switch off).
  Future<void> deletePayment(String paymentId) async {
    if (_applyingRemote) return;
    _beginLocalWrite();
    try {
      await _payments.doc(paymentId).delete();
    } catch (e, st) {
      debugPrint('Firestore deletePayment failed: $e\n$st');
      rethrow;
    } finally {
      _endLocalWrite();
    }
  }

  /// Delete many payment docs (e.g. after subscription clears weekly fees).
  Future<void> deletePayments(Iterable<String> paymentIds) async {
    if (_applyingRemote) return;
    final ids = paymentIds.toList();
    if (ids.isEmpty) return;
    _beginLocalWrite();
    try {
      WriteBatch? batch;
      var n = 0;
      for (final id in ids) {
        batch ??= _db.batch();
        batch.delete(_payments.doc(id));
        n++;
        if (n >= 400) {
          await batch.commit();
          batch = null;
          n = 0;
        }
      }
      if (batch != null) await batch.commit();
    } catch (e, st) {
      debugPrint('Firestore deletePayments failed: $e\n$st');
      rethrow;
    } finally {
      _endLocalWrite();
    }
  }

  Future<void> pushAll({
    required List<FplPlayer> players,
    required List<LeagueWeek> weeks,
    required List<WeeklyPayment> payments,
    required List<GuestPayment> guests,
    required List<MatchScorecard> matches,
    required List<PlayerTrade> trades,
    required List<ScheduledFixture> fixtures,
    required bool tradeOpen,
    required String selectedWeekId,
    int weeklyFee = kWeeklyFee,
    int subscriptionFee = kSubscriptionFee,
    int guestFee = kGuestFee,
  }) async {
    if (_applyingRemote) return;
    _beginLocalWrite();
    try {
      final batch = _db.batch();
      for (final p in players) {
        batch.set(_players.doc(p.id), p.toJson(), SetOptions(merge: true));
      }
      for (final w in weeks) {
        batch.set(_weeks.doc(w.id), w.toJson(), SetOptions(merge: true));
      }
      for (final p in payments) {
        batch.set(_payments.doc(p.id), p.toJson(), SetOptions(merge: true));
      }
      for (final g in guests) {
        batch.set(_guests.doc(g.id), g.toJson(), SetOptions(merge: true));
      }
      for (final m in matches) {
        batch.set(_matches.doc(m.id), m.toJson(), SetOptions(merge: true));
      }
      for (final t in trades) {
        batch.set(_trades.doc(t.id), t.toJson(), SetOptions(merge: true));
      }
      for (final f in fixtures) {
        batch.set(_fixtures.doc(f.id), f.toJson(), SetOptions(merge: true));
      }
      batch.set(
        _config,
        {
          'tradeOpen': tradeOpen,
          'selectedWeekId': selectedWeekId,
          'weeklyFee': weeklyFee,
          'subscriptionFee': subscriptionFee,
          'guestFee': guestFee,
          'upiId': kUpiId,
          'upiDisplayName': kUpiDisplayName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      // Remove orphan payment docs deleted locally (best-effort).
      final remotePayments = await _payments.get();
      final localIds = payments.map((p) => p.id).toSet();
      WriteBatch? deleteBatch;
      var n = 0;
      for (final d in remotePayments.docs) {
        if (!localIds.contains(d.id)) {
          deleteBatch ??= _db.batch();
          deleteBatch.delete(d.reference);
          n++;
          if (n >= 400) {
            await deleteBatch.commit();
            deleteBatch = null;
            n = 0;
          }
        }
      }
      if (deleteBatch != null) await deleteBatch.commit();

      final remoteGuests = await _guests.get();
      final guestIds = guests.map((g) => g.id).toSet();
      deleteBatch = null;
      n = 0;
      for (final d in remoteGuests.docs) {
        if (!guestIds.contains(d.id)) {
          deleteBatch ??= _db.batch();
          deleteBatch.delete(d.reference);
          n++;
          if (n >= 400) {
            await deleteBatch.commit();
            deleteBatch = null;
            n = 0;
          }
        }
      }
      if (deleteBatch != null) await deleteBatch.commit();
    } catch (e, st) {
      debugPrint('Firestore push failed: $e\n$st');
      rethrow;
    } finally {
      _endLocalWrite();
    }
  }

  /// Live sync: call [onUpdate] when remote data changes (other devices).
  void listen(void Function(CloudSnapshot snap) onUpdate) {
    disposeListeners();
    void schedulePull() {
      if (_shouldIgnoreRemote) return;
      // Debounce burst of collection events by pulling full state.
      unawaited(_safePull(onUpdate));
    }

    _subs.addAll([
      _players.snapshots().listen((_) => schedulePull()),
      _weeks.snapshots().listen((_) => schedulePull()),
      _payments.snapshots().listen((_) => schedulePull()),
      _guests.snapshots().listen((_) => schedulePull()),
      _matches.snapshots().listen((_) => schedulePull()),
      _trades.snapshots().listen((_) => schedulePull()),
      _fixtures.snapshots().listen((_) => schedulePull()),
      _config.snapshots().listen((_) => schedulePull()),
    ]);
  }

  Future<void> _safePull(void Function(CloudSnapshot snap) onUpdate) async {
    if (_shouldIgnoreRemote) return;
    try {
      final snap = await pullOnce();
      // Stale in-flight pull — local write happened while we were fetching.
      if (_shouldIgnoreRemote) return;
      if (snap == null) return;
      _applyingRemote = true;
      onUpdate(snap);
    } catch (e) {
      debugPrint('Firestore listen pull failed: $e');
    } finally {
      _applyingRemote = false;
    }
  }

  void disposeListeners() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void dispose() => disposeListeners();
}

class CloudSnapshot {
  const CloudSnapshot({
    required this.players,
    required this.weeks,
    required this.payments,
    required this.guests,
    required this.matches,
    required this.trades,
    this.fixtures = const [],
    required this.tradeOpen,
    required this.selectedWeekId,
    this.weeklyFee = kWeeklyFee,
    this.subscriptionFee = kSubscriptionFee,
    this.guestFee = kGuestFee,
  });

  final List<FplPlayer> players;
  final List<LeagueWeek> weeks;
  final List<WeeklyPayment> payments;
  final List<GuestPayment> guests;
  final List<MatchScorecard> matches;
  final List<PlayerTrade> trades;
  final List<ScheduledFixture> fixtures;
  final bool tradeOpen;
  final String selectedWeekId;
  final int weeklyFee;
  final int subscriptionFee;
  final int guestFee;
}
