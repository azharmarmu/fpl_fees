import '../config.dart';
import '../models/models.dart';

/// Season 2 auction squads. Phones empty until you share the list.
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
    ('mohammed_ali_mc', 'Mohammed Ali MC', kTeamGb, false, false),
    ('mohammed_irfan', 'Mohammed Irfan', kTeamGb, false, false),
    ('munaf_cpm', 'Munaf Cpm', kTeamGb, false, false),
    ('syed_molana', 'Syed Molana', kTeamGb, false, false),
    ('vicky', 'Vicky', kTeamGb, false, false),
    ('m_s_rusfi', 'M S Rusfi', kTeamNew, false, true),
    ('ac_yousuf', 'AC Yousuf', kTeamNew, false, false),
    ('afzal_afu', 'Afzal Afu', kTeamNew, false, false),
    ('arif_pvh', 'Arif PVH', kTeamNew, false, false),
    ('arul', 'ARUL', kTeamNew, false, false),
    ('bava_kvs', 'Bava Kvs', kTeamNew, true, false),
    ('jawad_a', 'Jawad A', kTeamNew, false, false),
    ('mansoor_vk', 'Mansoor Vk', kTeamNew, true, false),
    ('mashood_a_c', 'Mashood A C', kTeamNew, true, false),
    ('mohammed_rafi', 'Mohammed Rafi', kTeamNew, false, false),
    ('mohammed_rahoof', 'Mohammed Rahoof', kTeamNew, false, false),
    ('mohammed_razee', 'Mohammed Razee', kTeamNew, false, false),
    ('mufeedh', 'Mufeedh', kTeamNew, false, false),
    ('niyaz', 'Niyaz', kTeamNew, false, false),
    ('praveen', 'Praveen', kTeamNew, false, false),
    ('sabith', 'Sabith', kTeamNew, false, false),
    ('sainul_habid', 'Sainul Habid', kTeamNew, false, false),
    ('syed_shibli', 'Syed Shibli', kTeamNew, false, false),
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
