import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fpl_fees/config.dart';
import 'package:fpl_fees/data/season1.dart';
import 'package:fpl_fees/data/season2.dart';
import 'package:fpl_fees/data/season2_matches.dart';
import 'package:fpl_fees/data/seed.dart';
import 'package:fpl_fees/models/models.dart';
import 'package:fpl_fees/services/contact_import.dart';
import 'package:fpl_fees/services/fpl_store.dart';
import 'package:fpl_fees/services/stat_players_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('seed', () {
    test('builds 57 players and season Sundays', () {
      final players = buildSeedPlayers();
      final weeks = buildSeasonWeeks();
      expect(players.length, 57);
      expect(weeks.first.id, '2026-08-02');
      expect(weeks.last.id, '2026-12-27');
      expect(weeks.where((w) => w.isVpl), hasLength(1));
      expect(players.where((p) => p.isLifetimeMember), hasLength(7));
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

    test('per-week fee is stored on payment; defaults unchanged', () async {
      await store.setWeekWeeklyFee(store.selectedWeekId, 100);
      expect(store.feeForWeek(), 100);
      expect(store.weeklyFee, kWeeklyFee);
      final p = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      await store.setWeeklyPaid(p, true);
      expect(store.payments.single.amount, 100);
      expect(store.financeSummary().weeklyTotal, 100);
    });

    test('per-week guest fee is stored on guest payment', () async {
      await store.setWeekFees(store.selectedWeekId, weekly: 50, guest: 150);
      expect(store.guestFeeForWeek(), 150);
      expect(store.guestFee, kGuestFee);
      await store.addGuest(name: 'Guest Week', teamId: kTeamOx);
      expect(store.guests.single.amount, 150);
      expect(store.financeSummary().guestTotal, 150);
    });

    test('per-player subscription amount and period', () async {
      final a = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      final b = store.players.firstWhere(
        (x) =>
            !x.isLifetimeMember &&
            !x.subscriptionPaid &&
            x.id != a.id,
      );
      await store.setSubscription(a, true, amount: 500);
      await store.setSubscription(
        b,
        true,
        amount: 300,
        validUntil: DateTime(2026, 9, 30),
      );
      expect(store.playerById(a.id)!.subscriptionAmount, 500);
      expect(store.playerById(a.id)!.subscriptionValidUntil, isNull);
      expect(store.financeSummary().subscriptionTotal, 800);
      expect(store.eligibilityFor(store.playerById(b.id)!).eligible, isTrue);

      final expired = store.playerById(b.id)!.copyWith(
        subscriptionValidUntil: DateTime(2026, 7, 1),
      );
      final i = store.players.indexWhere((p) => p.id == b.id);
      store.players[i] = expired;
      expect(store.eligibilityFor(expired).eligible, isFalse);
      expect(expired.hasActiveSubscription, isFalse);
    });

    test('lowering default subscription does not rewrite paid amounts', () async {
      final p = store.players.firstWhere(
        (x) => !x.isLifetimeMember && !x.subscriptionPaid,
      );
      await store.setSubscription(p, true, amount: 750);
      await store.setFeeAmounts(subscription: 500);
      expect(store.subscriptionFee, 500);
      expect(store.playerById(p.id)!.subscriptionAmount, 750);
      expect(store.financeSummary().subscriptionTotal, 750);

      final q = store.players.firstWhere(
        (x) =>
            !x.isLifetimeMember &&
            !x.subscriptionPaid &&
            x.id != p.id,
      );
      await store.setSubscription(q, true);
      expect(store.playerById(q.id)!.subscriptionAmount, 500);
      expect(store.financeSummary().subscriptionTotal, 1250);
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

    test('records lastUpdatedAt when player sets phone', () async {
      final store = FplStore();
      await store.init();
      final p = store.players.firstWhere((x) => x.phone.isEmpty);
      expect(p.lastUpdatedAt, isNull);
      await store.updateOwnPhone(
        playerId: p.id,
        rawPhone: '9876543210',
      );
      expect(store.playerById(p.id)!.lastUpdatedAt, isNotNull);
    });
    test('player can edit phone after it was set', () async {
      final store = FplStore();
      await store.init();
      final p = store.players.firstWhere((x) => x.phone.isEmpty);
      await store.updateOwnPhone(
        playerId: p.id,
        rawPhone: '9876543210',
        rawEmail: 'a@b.com',
      );
      final err = await store.updateOwnPhone(
        playerId: p.id,
        rawPhone: '9876543211',
        rawEmail: 'new@b.com',
      );
      expect(err, isNull);
      expect(store.playerById(p.id)!.phone, '9876543211');
      expect(store.playerById(p.id)!.email, 'new@b.com');
    });
  });

  group('player activity', () {
    test('recordPlayerLogin sets lastLoginAt', () async {
      final store = FplStore();
      await store.init();
      final p = store.players.first;
      expect(p.lastLoginAt, isNull);
      await store.recordPlayerLogin(p.id);
      expect(store.playerById(p.id)!.lastLoginAt, isNotNull);
    });
  });

  group('season1 archive', () {
    test('loads CricHeroes CSV leaderboards from assets', () async {
      final data = await Season1Loader.load();
      expect(data.batting, isNotEmpty);
      expect(data.batting.first.name, 'Azhar Marmu');
      expect(data.bowling.first.name, 'Anas');
      expect(data.fielding.first.name, 'Mohammed Razee');
      expect(data.mvp.first.name, 'Azhar Marmu');
      expect(data.heroes, hasLength(4));
      expect(season1Standings.first.teamName, 'OX CC');
      expect(season1Standings.first.points, 80);
    });

    test('builds career player from Season 1 assets', () async {
      final p = await StatPlayersRepository.fromSeason1Assets(
        playerId: '13346088',
        name: 'Azhar Marmu',
      );
      expect(p, isNotNull);
      expect(p!.seasons['s1']!.batting!.runs, 807);
      expect(p.seasons['s1']!.bowling!.wickets, 30);
      expect(p.allTeams, contains('Gully Blasters'));
    });
  });

  group('season2', () {
    test('loads Week 4 leaderboards and points', () async {
      Season2Loader.clearCache();
      final data = await Season2Loader.load();
      expect(data.batting, isNotEmpty);
      expect(data.batting.first.name, 'Azhar Marmu');
      expect(data.batting.first.runs, 201);
      expect(data.bowling.first.name, 'Siraj');
      expect(data.bowling.first.wickets, 7);
      expect(data.mvp.first.name, 'Azhar Marmu');
      expect(season2Standings.first.teamName, 'Gully Blasters');
      expect(season2Standings.first.points, 10);
      expect(season2Standings[1].points, 8);
      expect(season2Standings[2].points, 6);
      expect(season2Standings.length, 3);
      expect(Season2Meta.totalMatches, 12);
    });

    test('Aslam Hashim / Faizal / Fazil match CricHeroes Week 4 + scorecards',
        () async {
      Season2Loader.clearCache();
      final data = await Season2Loader.load();

      Season1BattingRow bat(String name) =>
          data.batting.firstWhere((r) => r.name == name);
      Season1BowlingRow bowl(String name) =>
          data.bowling.firstWhere((r) => r.name == name);

      expect(bat('Aslam Hashim').runs, 76);
      expect(bat('Aslam Hashim').innings, 6);
      expect(bat('Aslam Hashim').playerId, '3456038');
      expect(bowl('Aslam Hashim').wickets, 1);
      expect(bat('Aslam Hashim').teamName, 'OX CC');

      expect(bat('Faizal').runs, 12);
      expect(bat('Faizal').playerId, '27379139');
      expect(bowl('Faizal').wickets, 1);
      expect(bat('Faizal').teamName, 'Gully Blasters');

      expect(bat('Fazil Farook').runs, 0);
      expect(bat('Fazil Farook').playerId, '41754588');
      expect(bowl('Fazil Farook').wickets, 1);
      expect(bat('Fazil Farook').teamName, 'Gully Blasters');
    });

    test('Aslam and Aslam Hashim stay separate in career stats', () async {
      expect(StatPlayersRepository.nameMatch('Aslam', 'Aslam Hashim'), isFalse);

      final hashim = await StatPlayersRepository.fromBundledAssets(
        name: 'Aslam Hashim',
      );
      final aslam = await StatPlayersRepository.fromSeason1Assets(
        name: 'Aslam',
      );
      expect(hashim, isNotNull);
      expect(aslam, isNotNull);
      expect(hashim!.id, '3456038');
      expect(aslam!.id, '45134281');
      expect(hashim.seasons['s2']!.batting!.runs, 76);
      expect(aslam.seasons['s1']!.batting!.runs, 97);
      // Must not pull Hashim's S2 into OX Aslam.
      expect(aslam.seasons['s2']?.batting?.runs ?? 0, 0);
    });

    test('seeds twelve Sunday scorecards with innings', () {
      final matches = buildSeason2SeedMatches();
      expect(matches, hasLength(12));
      expect(
        matches.map((m) => m.id),
        containsAll([
          'ch_26445586',
          'ch_26446857',
          'ch_26447419',
          'ch_26553505',
          'ch_26555293',
          'ch_26556294',
          'ch_26678906',
          'ch_26680511',
          'ch_26681579',
          'ch_26787322',
          'ch_26788610',
          'ch_26789418',
        ]),
      );
      for (final m in matches) {
        expect(m.hasStructuredCard, isTrue);
        expect(m.hasPdf, isFalse);
        expect(m.innings, hasLength(2));
      }
    });

    test('Mulla is lifetime guest (no squad fees)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FplStore();
      await store.init();
      final mulla = store.playerById('mulla');
      expect(mulla, isNotNull);
      expect(mulla!.isLifetimeMember, isTrue);
      expect(mulla.teamId, kTeamGuest);
      expect(store.playersForTeam(kTeamOx).any((p) => p.id == 'mulla'), isFalse);
      expect(store.eligibilityFor(mulla).eligible, isTrue);
    });

    test('Mohammed Arif is not on GB squad (match guest only)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FplStore();
      await store.init();
      expect(store.playerById('mohammed_arif'), isNull);
      expect(
        store.playersForTeam(kTeamGb).any((p) => p.name == 'Mohammed Arif'),
        isFalse,
      );
      final gbOx = buildSeason2Week2Matches()
          .firstWhere((m) => m.id == 'ch_26556294');
      expect(
        gbOx.innings.first.batting.any((b) => b.name == 'Mohammed Arif'),
        isTrue,
      );
    });

    test('trade window open with Trade 1 + Trade 2 packages applied', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FplStore();
      await store.init();
      expect(store.tradeOpen, isTrue);
      // Trade 1
      expect(store.playerById('aslam_hashim')!.teamId, kTeamOx);
      expect(store.playerById('syed_molana')!.teamId, kTeamGb);
      expect(store.playerById('faizal')!.teamId, kTeamGb);
      expect(store.playerById('fazil_farook')!.teamId, kTeamGb);
      expect(store.auctionCostFor('aslam_hashim'), 4000);
      expect(store.auctionCostFor('faizal'), 0);
      expect(store.auctionCostFor('fazil_farook'), 0);
      // Trade 2
      expect(store.playerById('munaf_cpm')!.teamId, kTeamAvengers);
      expect(store.playerById('mashood_a_c')!.teamId, kTeamGb);
      expect(store.auctionCostFor('munaf_cpm'), 3000);
      expect(store.auctionCostFor('mashood_a_c'), 0);
      // Releases then mini auction
      expect(store.playerById('arif_pvh')!.teamId, kTeamFreeAgent);
      expect(store.playerById('farziii')!.teamId, kTeamGb);
      expect(store.auctionCostFor('arif_pvh'), 0);
      expect(store.auctionCostFor('farziii'), 100);
      expect(store.playerById('ejaz')!.teamId, kTeamGb);
      expect(store.playerById('imran')!.teamId, kTeamGb);
      expect(store.playerById('anju')!.teamId, kTeamGb);
      expect(store.playerById('sadam')!.teamId, kTeamOx);
      expect(store.playerById('gopi')!.teamId, kTeamAvengers);
      expect(store.playerById('arif_kvh')!.teamId, kTeamGb);
      expect(store.auctionCostFor('ejaz'), 1950);
      expect(store.auctionCostFor('imran'), 1050);
      expect(store.auctionCostFor('anju'), 1050);
      expect(store.auctionCostFor('sadam'), 1950);
      expect(store.auctionCostFor('gopi'), 500);
      expect(store.auctionCostFor('arif_kvh'), 300);
      // OX: left 1950 − SADAM 1950 = 0
      expect(store.auctionPurseLive(kTeamOx).spent, 10000);
      expect(store.auctionPurseLive(kTeamOx).left, 0);
      // GB: mini 6650 + Arif KVH 300 = 6950
      expect(store.auctionPurseLive(kTeamGb).spent, 6950);
      expect(store.auctionPurseLive(kTeamGb).left, 3050);
      // Avengers: Arif KVH sell credits 300 → left 300
      expect(store.auctionPurseLive(kTeamAvengers).spent, 9700);
      expect(store.auctionPurseLive(kTeamAvengers).left, 300);
      expect(store.trades.where((t) => t.kind == TradeKind.package), hasLength(2));
      expect(store.trades.where((t) => t.kind == TradeKind.release), hasLength(2));
      expect(store.trades.where((t) => t.kind == TradeKind.buy), hasLength(7));
      expect(store.trades.where((t) => t.kind == TradeKind.sell), hasLength(1));
    });

    test('release then undo restores squad and purse', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FplStore();
      await store.init();
      final molana = store.playerById('syed_molana')!;
      await store.recordRelease(player: molana);
      expect(store.playerById('syed_molana')!.teamId, kTeamFreeAgent);
      // Release returns Molana's 50: 6650 − 50 = 6600 (post mini auction)
      expect(store.auctionPurseLive(kTeamGb).spent, 6600);
      final release = store.trades.first;
      expect(store.canUndoTrade(release), isTrue);
      await store.undoTrade(release.id);
      expect(store.playerById('syed_molana')!.teamId, kTeamGb);
      expect(store.auctionPurseLive(kTeamGb).spent, 6650);
    });

    test('merges mid-season trade stats by player id for awards', () {
      final merged = Season1Loader.mergeBattingForTest([
        const Season1BattingRow(
          playerId: '3456038',
          name: 'Aslam Hashim',
          teamName: 'Gully Blasters',
          matches: 2,
          innings: 2,
          runs: 40,
          highest: 21,
          average: 20,
          strikeRate: 100,
          fours: 2,
          sixes: 0,
        ),
        const Season1BattingRow(
          playerId: '3456038',
          name: 'Aslam Hashim',
          teamName: 'OX CC',
          matches: 2,
          innings: 2,
          runs: 33,
          highest: 28,
          average: 16.5,
          strikeRate: 110,
          fours: 1,
          sixes: 0,
        ),
      ]);
      expect(merged, hasLength(1));
      expect(merged.first.runs, 73);
      expect(merged.first.teamName, 'OX CC');
      expect(merged.first.matches, 4);

      final bowl = Season1Loader.mergeBowlingForTest([
        const Season1BowlingRow(
          playerId: '1',
          name: 'Siraj',
          teamName: 'OX CC',
          matches: 2,
          innings: 2,
          wickets: 2,
          overs: '4.0',
          maidens: 0,
          runs: 20,
          economy: 5,
          best: 1,
        ),
        const Season1BowlingRow(
          playerId: '1',
          name: 'Siraj',
          teamName: 'OX CC',
          matches: 2,
          innings: 2,
          wickets: 2,
          overs: '3.5',
          maidens: 0,
          runs: 16,
          economy: 4.2,
          best: 1,
        ),
      ]);
      expect(bowl.single.wickets, 4);
      expect(bowl.single.overs, '7.5');

      final mvp = Season1Loader.mergeMvpForTest([
        const Season1MvpRow(
          name: 'Aslam Hashim',
          teamName: 'Gully Blasters',
          matches: 2,
          battingPts: 4,
          bowlingPts: 1,
          fieldingPts: 0.5,
          total: 5.5,
        ),
        const Season1MvpRow(
          name: 'Aslam Hashim',
          teamName: 'OX CC',
          matches: 2,
          battingPts: 3,
          bowlingPts: 0,
          fieldingPts: 1,
          total: 4,
        ),
      ]);
      expect(mvp.single.total, 9.5);
      expect(mvp.single.teamName, 'OX CC');
    });
  });

  group('structured scorecard', () {
    test('innings round-trip in match JSON', () {
      final match = MatchScorecard(
        id: 'm1',
        date: DateTime(2026, 8, 2),
        teamAId: kTeamOx,
        teamBId: kTeamGb,
        teamAName: 'OX CC',
        teamBName: 'Gully Blasters',
        teamAScore: '53/6 (8.0 Ov)',
        teamBScore: '48/8',
        resultText: 'OX CC won',
        innings: [
          MatchInnings(
            battingTeamId: kTeamOx,
            battingTeamName: 'OX CC',
            runs: 53,
            wickets: 6,
            overs: '8.0',
            batting: const [
              BattingEntry(
                playerId: 'anas',
                name: 'Anas',
                runs: 20,
                balls: 15,
                fours: 2,
                sixes: 1,
                dismissal: 'b Siraj',
              ),
            ],
            bowling: const [
              BowlingEntry(
                playerId: 'siraj',
                name: 'Siraj',
                overs: '2.0',
                maidens: 0,
                runs: 12,
                wickets: 2,
              ),
            ],
          ),
        ],
      );
      final round = MatchScorecard.fromJson(match.toJson());
      expect(round.hasStructuredCard, isTrue);
      expect(round.innings, hasLength(1));
      expect(round.innings.first.batting.single.runs, 20);
      expect(round.innings.first.bowling.single.wickets, 2);
      expect(round.innings.first.scoreLabel, '53/6 (8.0 Ov)');
    });

    test('legacy match without innings still loads', () {
      final m = MatchScorecard.fromJson({
        'id': 'old',
        'date': '2026-08-02T00:00:00.000',
        'teamAId': kTeamOx,
        'teamBId': kTeamGb,
        'teamAName': 'OX',
        'teamBName': 'GB',
        'teamAScore': '10/0',
        'teamBScore': '9/1',
        'resultText': 'OX won',
      });
      expect(m.innings, isEmpty);
      expect(m.hasStructuredCard, isFalse);
    });
  });
}
