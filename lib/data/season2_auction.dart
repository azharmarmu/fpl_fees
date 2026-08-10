import '../config.dart';

/// Season 2 auction purse (bidding points). Source: post-auction squad sheet.
const kAuctionBudgetTotal = 10000;

class AuctionPurchase {
  const AuctionPurchase({required this.name, required this.points});

  final String name;
  final int points;
}

class TeamAuctionPurseSeed {
  const TeamAuctionPurseSeed({
    required this.teamId,
    required this.captainName,
    required this.spent,
    required this.retained,
    required this.buys,
  });

  final String teamId;
  final String captainName;
  final int spent;
  final List<String> retained;
  final List<AuctionPurchase> buys;

  String get teamName => kTeamNames[teamId] ?? teamId;

  /// Initial auction cost by normalized player name (retained → 0).
  Map<String, int> initialCostsByName() {
    final map = <String, int>{};
    for (final r in retained) {
      map[_norm(r)] = 0;
    }
    for (final b in buys) {
      map[_norm(b.name)] = b.points;
    }
    return map;
  }
}

String auctionNameKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _norm(String s) => auctionNameKey(s);

const season2AuctionSeeds = <TeamAuctionPurseSeed>[
  TeamAuctionPurseSeed(
    teamId: kTeamOx,
    captainName: 'Anas',
    spent: 4300,
    retained: ['MONIZ', 'Shanu', 'Siraj'],
    buys: [
      AuctionPurchase(name: 'Fazil Farook', points: 1600),
      AuctionPurchase(name: 'Jaseer S', points: 1000),
      AuctionPurchase(name: 'Faizal', points: 300),
      AuctionPurchase(name: 'Nowfal', points: 300),
      AuctionPurchase(name: 'Farziii', points: 250),
      AuctionPurchase(name: 'Mohammad Hamza', points: 250),
      AuctionPurchase(name: 'Nasir Thala', points: 200),
      AuctionPurchase(name: 'Aslam', points: 50),
      AuctionPurchase(name: 'Azan', points: 50),
      AuctionPurchase(name: 'Mohammed Ishak', points: 50),
      AuctionPurchase(name: 'Ajeez', points: 50),
      AuctionPurchase(name: 'Althaf', points: 50),
      AuctionPurchase(name: 'Mujeebh', points: 50),
      AuctionPurchase(name: 'Imthiyas', points: 50),
      AuctionPurchase(name: 'Bilal', points: 50),
    ],
  ),
  TeamAuctionPurseSeed(
    teamId: kTeamGb,
    captainName: 'Azhar Marmu',
    spent: 9500,
    retained: ['Gokul', 'Mohammed Ali MC', 'Munaf Cpm'],
    buys: [
      AuctionPurchase(name: 'Aslam Hashim', points: 6200),
      AuctionPurchase(name: 'MD Zabeer', points: 2550),
      AuctionPurchase(name: 'Irshad Ali', points: 350),
      AuctionPurchase(name: 'Abishek k', points: 150),
      AuctionPurchase(name: 'Syed Molana', points: 50),
      AuctionPurchase(name: 'Anas Jr', points: 50),
      AuctionPurchase(name: 'Vicky', points: 50),
      AuctionPurchase(name: 'Mohammed Irfan', points: 50),
      AuctionPurchase(name: 'MD Saif', points: 50),
    ],
  ),
  TeamAuctionPurseSeed(
    teamId: kTeamAvengers,
    captainName: 'M S Rusfi',
    spent: 6000,
    retained: ['Bava Kvs', 'Mansoor Vk', 'Mohammed Razee'],
    buys: [
      AuctionPurchase(name: 'Afzal Afu', points: 2250),
      AuctionPurchase(name: 'Syed Shibli', points: 950),
      AuctionPurchase(name: 'Mufeedh', points: 550),
      AuctionPurchase(name: 'AC Yousuf', points: 500),
      AuctionPurchase(name: 'Mohammed Rahoof', points: 450),
      AuctionPurchase(name: 'Praveen', points: 350),
      AuctionPurchase(name: 'Niyaz', points: 300),
      AuctionPurchase(name: 'Mashood A C', points: 200),
      AuctionPurchase(name: 'ARUL', points: 150),
      AuctionPurchase(name: 'Jawad A', points: 100),
      AuctionPurchase(name: 'Arif PVH', points: 50),
      AuctionPurchase(name: 'Sabith', points: 50),
      AuctionPurchase(name: 'Mohammed Rafi', points: 50),
      AuctionPurchase(name: 'Sainul Habid', points: 50),
    ],
  ),
];

TeamAuctionPurseSeed? auctionSeedForTeam(String teamId) {
  for (final s in season2AuctionSeeds) {
    if (s.teamId == teamId) return s;
  }
  return null;
}

String formatAuctionPoints(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
