import '../config.dart';
import '../models/models.dart';

/// Demo / seeded phones for captains + a few players so login works out of box.
/// Replace via More → contacts or CSV import with real numbers.
const kSeedPhones = <String, String>{
  'azhar_marmu': '9000000001',
  'anas': '9000000002',
  'm_s_rusfi': '9000000003',
  'nowfal': '9000000004',
  'mashood_a_c': '9000000005',
};

/// Season 2 auction squads.
List<FplPlayer> buildSeedPlayers() {
  const rows = <(String id, String name, String teamId, bool life, bool cap)>[
    ('azhar_marmu', 'Azhar Marmu', kTeamGb, true, true),
    ('abishek_k', 'Abishek k', kTeamGb, false, false),
    ('anas_jr', 'Anas Jr', kTeamGb, false, false),
    ('aslam_hashim', 'Aslam Hashim', kTeamGb, false, false),
    ('gokul', 'Gokul', kTeamGb, false, false),
    ('irshad_ali', 'Irshad Ali', kTeamGb, false, false),
    ('md_saif', 'MD Saif', kTeamGb, false, false),
    ('md_zabeer', 'MD Zabeer', kTeamGb, false, false),
    ('mohammed_ali_mc', 'Mohammed Ali MC', kTeamGb, true, false),
    ('mohammed_irfan', 'Mohammed Irfan', kTeamGb, false, false),
    ('munaf_cpm', 'Munaf Cpm', kTeamGb, false, false),
    ('syed_molana', 'Syed Molana', kTeamGb, false, false),
    ('vicky', 'Vicky', kTeamGb, false, false),
    ('m_s_rusfi', 'M S Rusfi', kTeamAvengers, false, true),
    ('ac_yousuf', 'AC Yousuf', kTeamAvengers, false, false),
    ('afzal_afu', 'Afzal Afu', kTeamAvengers, false, false),
    ('arif_pvh', 'Arif PVH', kTeamAvengers, false, false),
    ('arul', 'ARUL', kTeamAvengers, false, false),
    ('bava_kvs', 'Bava Kvs', kTeamAvengers, true, false),
    ('jawad_a', 'Jawad A', kTeamAvengers, false, false),
    ('mansoor_vk', 'Mansoor Vk', kTeamAvengers, true, false),
    ('mashood_a_c', 'Mashood A C', kTeamAvengers, true, false),
    ('mohammed_rafi', 'Mohammed Rafi', kTeamAvengers, false, false),
    ('mohammed_rahoof', 'Mohammed Rahoof', kTeamAvengers, false, false),
    ('mohammed_razee', 'Mohammed Razee', kTeamAvengers, false, false),
    ('mufeedh', 'Mufeedh', kTeamAvengers, false, false),
    ('niyaz', 'Niyaz', kTeamAvengers, false, false),
    ('praveen', 'Praveen', kTeamAvengers, false, false),
    ('sabith', 'Sabith', kTeamAvengers, false, false),
    ('sainul_habid', 'Sainul Habid', kTeamAvengers, false, false),
    ('syed_shibli', 'Syed Shibli', kTeamAvengers, false, false),
    ('anas', 'Anas', kTeamOx, false, true),
    ('ajeez', 'Ajeez', kTeamOx, false, false),
    ('althaf', 'Althaf', kTeamOx, false, false),
    ('aslam', 'Aslam', kTeamOx, false, false),
    ('azan', 'Azan', kTeamOx, false, false),
    ('bilal', 'Bilal', kTeamOx, false, false),
    ('faizal', 'Faizal', kTeamOx, false, false),
    ('farziii', 'Farziii', kTeamOx, false, false),
    ('fazil_farook', 'Fazil Farook', kTeamOx, false, false),
    ('imthiyas', 'Imthiyas', kTeamOx, false, false),
    ('jaseer_s', 'Jaseer S', kTeamOx, false, false),
    ('mohammad_hamza', 'Mohammad Hamza', kTeamOx, false, false),
    ('mohammed_ishak', 'Mohammed Ishak', kTeamOx, false, false),
    ('moniz', 'MONIZ', kTeamOx, false, false),
    ('mujeebh', 'Mujeebh', kTeamOx, false, false),
    ('nasir_thala', 'Nasir Thala', kTeamOx, false, false),
    ('nowfal', 'Nowfal', kTeamOx, true, false),
    ('shanu', 'Shanu', kTeamOx, false, false),
    ('siraj', 'Siraj', kTeamOx, false, false),
  ];

  return [
    for (final r in rows)
      FplPlayer(
        id: r.$1,
        name: r.$2,
        teamId: r.$3,
        teamName: kTeamNames[r.$3]!,
        phone: kSeedPhones[r.$1] ?? '',
        cricheroesUsername: r.$2,
        isLifetimeMember: r.$4,
        isCaptain: r.$5,
      ),
  ];
}

List<LeagueWeek> buildSeasonWeeks() {
  // Sundays 2 Aug 2026 – 27 Dec 2026; 8 Nov = Diwali / VPL placeholder
  final weeks = <LeagueWeek>[];
  var d = DateTime(2026, 8, 2);
  final end = DateTime(2026, 12, 27);
  var leagueIndex = 0;
  while (!d.isAfter(end)) {
    final id =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final isVpl = d.year == 2026 && d.month == 11 && d.day == 8;
    if (isVpl) {
      weeks.add(LeagueWeek(
        id: id,
        date: d,
        label: 'VPL Season 2 (Diwali week)',
        isVpl: true,
        isLeague: false,
      ));
    } else {
      leagueIndex += 1;
      weeks.add(LeagueWeek(
        id: id,
        date: d,
        label: 'League Week $leagueIndex',
        isVpl: false,
        isLeague: true,
      ));
    }
    d = d.add(const Duration(days: 7));
  }
  return weeks;
}

/// First 2 months (Aug–Sep 2026): 3 matches / Sunday, each team plays 2.
/// Opening fixture rotates so every pairing (and team) gets 1st-match turns.
List<ScheduledFixture> buildSeasonFixtures() {
  // Each row: date, ordered pairings (slot 1 = opening).
  const days = <(int y, int m, int d, List<(String, String)>)>[
    (2026, 8, 2, [(kTeamOx, kTeamGb), (kTeamGb, kTeamAvengers), (kTeamOx, kTeamAvengers)]),
    (2026, 8, 9, [(kTeamGb, kTeamAvengers), (kTeamOx, kTeamAvengers), (kTeamOx, kTeamGb)]),
    (2026, 8, 16, [(kTeamOx, kTeamAvengers), (kTeamOx, kTeamGb), (kTeamGb, kTeamAvengers)]),
    (2026, 8, 23, [(kTeamOx, kTeamGb), (kTeamOx, kTeamAvengers), (kTeamGb, kTeamAvengers)]),
    (2026, 8, 30, [(kTeamGb, kTeamAvengers), (kTeamOx, kTeamGb), (kTeamOx, kTeamAvengers)]),
    (2026, 9, 6, [(kTeamOx, kTeamAvengers), (kTeamGb, kTeamAvengers), (kTeamOx, kTeamGb)]),
    (2026, 9, 13, [(kTeamOx, kTeamGb), (kTeamGb, kTeamAvengers), (kTeamOx, kTeamAvengers)]),
    (2026, 9, 20, [(kTeamGb, kTeamAvengers), (kTeamOx, kTeamAvengers), (kTeamOx, kTeamGb)]),
    (2026, 9, 27, [(kTeamOx, kTeamAvengers), (kTeamOx, kTeamGb), (kTeamGb, kTeamAvengers)]),
  ];

  final out = <ScheduledFixture>[];
  for (final day in days) {
    final date = DateTime(day.$1, day.$2, day.$3);
    final weekId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    for (var i = 0; i < day.$4.length; i++) {
      final (a, b) = day.$4[i];
      final slot = i + 1;
      out.add(
        ScheduledFixture(
          id: '${weekId}_$slot',
          weekId: weekId,
          date: date,
          slot: slot,
          teamAId: a,
          teamBId: b,
          teamAName: kTeamNames[a]!,
          teamBName: kTeamNames[b]!,
        ),
      );
    }
  }
  return out;
}
