import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fpl_fees/config.dart';
import 'package:fpl_fees/data/seed.dart';
import 'package:fpl_fees/models/models.dart';
import 'package:fpl_fees/services/contact_import.dart';
import 'package:fpl_fees/services/fpl_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('seed', () {
    test('builds 50 players and season Sundays', () {
      final players = buildSeedPlayers();
      final weeks = buildSeasonWeeks();
      expect(players.length, 50);
      expect(weeks.first.id, '2026-08-02');
      expect(weeks.last.id, '2026-12-27');
      expect(weeks.where((w) => w.isVpl), hasLength(1));
      expect(players.where((p) => p.isLifetimeMember), hasLength(6));
      expect(
        players.firstWhere((p) => p.id == 'mohammed_ali_mc').isLifetimeMember,
        isTrue,
      );
      expect(kSeedPhones.length, greaterThanOrEqualTo(3));
      expect(
        players.firstWhere((p) => p.id == 'azhar_marmu').phone,
        '9000000001',
      );
    });

    test('Aug–Sep fixtures: 9 Sundays × 3 matches, rotating openers', () {
      final fixtures = buildSeasonFixtures();
      expect(fixtures, hasLength(27));
      expect(fixtures.first.weekId, '2026-08-02');
      expect(fixtures.first.isOpening, isTrue);
      expect(fixtures.first.teamAId, kTeamOx);
      expect(fixtures.first.teamBId, kTeamGb);
      final week2Open = fixtures.firstWhere((f) => f.id == '2026-08-09_1');
      expect(week2Open.teamAId, kTeamGb);
      expect(week2Open.teamBId, kTeamAvengers);
      // Each Sunday has slots 1–3 and every team appears twice.
      final byWeek = <String, List<ScheduledFixture>>{};
      for (final f in fixtures) {
        byWeek.putIfAbsent(f.weekId, () => []).add(f);
      }
      expect(byWeek.keys, hasLength(9));
      for (final list in byWeek.values) {
        expect(list.map((f) => f.slot).toSet(), {1, 2, 3});
        final counts = <String, int>{};
        for (final f in list) {
          counts[f.teamAId] = (counts[f.teamAId] ?? 0) + 1;
          counts[f.teamBId] = (counts[f.teamBId] ?? 0) + 1;
        }
        expect(counts[kTeamOx], 2);
        expect(counts[kTeamGb], 2);
        expect(counts[kTeamAvengers], 2);
      }
    });
  });

  group('eligibility', () {
    late FplStore store;

    setUp(() async {
      store = FplStore();
      await store.init();
    });

    test('lifetime member is eligible without payment', () {
      final p = store.playerById('azhar_marmu')!;
      final el = store.eligibilityFor(p);
      expect(el.eligible, isTrue);
      expect(el.reason, EligibilityReason.lifetime);
    });

    test('weekly pay marks eligible; unpaid otherwise', () async {
      final p = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      expect(store.eligibilityFor(p).eligible, isFalse);
      await store.setWeeklyPaid(p, true);
      expect(store.eligibilityFor(p).reason, EligibilityReason.weeklyPaid);
      await store.setWeeklyPaid(p, false);
      expect(store.hasWeeklyPayment(p.id, store.selectedWeekId), isFalse);
      expect(store.eligibilityFor(p).eligible, isFalse);
    });

    test('subscription clears weekly payments and is eligible', () async {
      final p = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      await store.setWeeklyPaid(p, true);
      await store.setSubscription(p, true);
      expect(store.hasWeeklyPayment(p.id, store.selectedWeekId), isFalse);
      expect(
        store.eligibilityFor(store.playerById(p.id)!).reason,
        EligibilityReason.subscription,
      );
    });

    test('finance totals include weekly and guest', () async {
      final p = store.players.firstWhere((x) => !x.isLifetimeMember);
      await store.setWeeklyPaid(p, true);
      await store.addGuest(name: 'Guest One', teamId: kTeamOx);
      final f = store.financeSummary();
      expect(f.weeklyTotal, kWeeklyFee);
      expect(f.guestTotal, kGuestFee);
      expect(f.seasonTotal, kWeeklyFee + kGuestFee);
    });

    test('admin can change weekly, subscription, and guest fees', () async {
      await store.setFeeAmounts(weekly: 60, subscription: 800, guest: 250);
      expect(store.weeklyFee, 60);
      expect(store.subscriptionFee, 800);
      expect(store.guestFee, 250);
      final p = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      await store.setWeeklyPaid(p, true);
      expect(store.financeSummary().weeklyTotal, 60);
      await store.setWeeklyPaid(p, false);
      await store.setSubscription(p, true);
      expect(store.financeSummary().subscriptionTotal, 800);
      await store.addGuest(name: 'Guest Two', teamId: kTeamOx);
      expect(store.financeSummary().guestTotal, 250);
    });

    test('trade commission is 25%', () async {
      await store.setTradeOpen(true);
      final p = store.playerById('anas')!;
      final from = p.teamId;
      await store.recordTrade(
        player: p,
        toTeamId: kTeamGb,
        salePriceInr: 1000,
      );
      expect(store.trades.first.commissionInr, 250);
      expect(store.playerById('anas')!.teamId, kTeamGb);
      expect(store.playerById('anas')!.teamId, isNot(from));
    });
  });

  group('contact import', () {
    test('imports clean id CSV', () {
      final players = buildSeedPlayers();
      final (next, result) = ContactImporter.apply(
        players: players,
        csv: 'id,phone,username\n'
            'anas,9111111111,AnasCaptain\n'
            'siraj,9222222222,SirajCH\n',
      );
      expect(result.updated, 2);
      expect(result.skipped, 0);
      expect(next.firstWhere((p) => p.id == 'anas').phone, '9111111111');
      expect(
        next.firstWhere((p) => p.id == 'anas').cricheroesUsername,
        'AnasCaptain',
      );
      expect(next.firstWhere((p) => p.id == 'siraj').phone, '9222222222');
    });

    test('imports by player name', () {
      final players = buildSeedPlayers();
      final (next, result) = ContactImporter.apply(
        players: players,
        csv: 'name,phone,username\n'
            'Bilal,9333333333,BilalCH\n',
      );
      expect(result.updated, 1);
      expect(next.firstWhere((p) => p.id == 'bilal').phone, '9333333333');
    });

    test('findByPhone uses last 10 digits', () async {
      final store = FplStore();
      await store.init();
      expect(store.findByPhone('9000000001')?.id, 'azhar_marmu');
      expect(store.findByPhone('+91 90000 00001')?.id, 'azhar_marmu');
    });
  });

  group('own phone', () {
    test('player can set phone when empty', () async {
      final store = FplStore();
      await store.init();
      final p = store.players.firstWhere((x) => x.phone.isEmpty);
      final err = await store.updateOwnPhone(
        playerId: p.id,
        rawPhone: '9876543210',
        rawEmail: 'player@example.com',
      );
      expect(err, isNull);
      expect(store.playerById(p.id)!.phone, '9876543210');
      expect(store.playerById(p.id)!.email, 'player@example.com');
    });

    test('optional email can be blank; invalid email rejected', () async {
      final store = FplStore();
      await store.init();
      final empty = store.players.where((x) => x.phone.isEmpty).toList();
      expect(
        await store.updateOwnPhone(
          playerId: empty.first.id,
          rawPhone: '9876543211',
          rawEmail: 'not-an-email',
        ),
        contains('email'),
      );
      final err = await store.updateOwnPhone(
        playerId: empty.first.id,
        rawPhone: '9876543211',
      );
      expect(err, isNull);
      expect(store.playerById(empty.first.id)!.email, isEmpty);
    });

    test('rejects invalid and duplicate phones', () async {
      final store = FplStore();
      await store.init();
      final empty = store.players.where((x) => x.phone.isEmpty).toList();
      expect(
        await store.updateOwnPhone(playerId: empty.first.id, rawPhone: '123'),
        isNotNull,
      );
      await store.updateOwnPhone(
        playerId: empty.first.id,
        rawPhone: '9876500001',
      );
      final err = await store.updateOwnPhone(
        playerId: empty[1].id,
        rawPhone: '9876500001',
      );
      expect(err, contains('already used'));
    });
  });
}
