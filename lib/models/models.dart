import '../config.dart';

class FplPlayer {
  const FplPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.teamName,
    this.phone = '',
    this.cricheroesUsername = '',
    this.isLifetimeMember = false,
    this.isCaptain = false,
    this.subscriptionPaid = false,
    this.subscriptionPaidAt,
    this.active = true,
  });

  final String id;
  final String name;
  final String teamId;
  final String teamName;
  final String phone;
  final String cricheroesUsername;
  final bool isLifetimeMember;
  final bool isCaptain;
  final bool subscriptionPaid;
  final DateTime? subscriptionPaidAt;
  final bool active;

  String get cricheroesUsernameLower => cricheroesUsername.trim().toLowerCase();

  String get normalizedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  FplPlayer copyWith({
    String? phone,
    String? cricheroesUsername,
    bool? isLifetimeMember,
    bool? subscriptionPaid,
    DateTime? subscriptionPaidAt,
    String? teamId,
    String? teamName,
    bool clearSubscriptionDate = false,
  }) {
    return FplPlayer(
      id: id,
      name: name,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      phone: phone ?? this.phone,
      cricheroesUsername: cricheroesUsername ?? this.cricheroesUsername,
      isLifetimeMember: isLifetimeMember ?? this.isLifetimeMember,
      isCaptain: isCaptain,
      subscriptionPaid: subscriptionPaid ?? this.subscriptionPaid,
      subscriptionPaidAt: clearSubscriptionDate
          ? null
          : (subscriptionPaidAt ?? this.subscriptionPaidAt),
      active: active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teamId': teamId,
        'teamName': teamName,
        'phone': phone,
        'cricheroesUsername': cricheroesUsername,
        'cricheroesUsernameLower': cricheroesUsernameLower,
        'isLifetimeMember': isLifetimeMember,
        'isCaptain': isCaptain,
        'subscriptionPaid': subscriptionPaid,
        'subscriptionPaidAt': subscriptionPaidAt?.toIso8601String(),
        'active': active,
      };

  factory FplPlayer.fromJson(Map<String, dynamic> json) {
    return FplPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cricheroesUsername: json['cricheroesUsername'] as String? ??
          (json['name'] as String? ?? ''),
      isLifetimeMember: json['isLifetimeMember'] as bool? ?? false,
      isCaptain: json['isCaptain'] as bool? ?? false,
      subscriptionPaid: json['subscriptionPaid'] as bool? ?? false,
      subscriptionPaidAt: json['subscriptionPaidAt'] != null
          ? DateTime.tryParse(json['subscriptionPaidAt'] as String)
          : null,
      active: json['active'] as bool? ?? true,
    );
  }
}

class LeagueWeek {
  const LeagueWeek({
    required this.id,
    required this.date,
    required this.label,
    this.isVpl = false,
    this.isLeague = true,
  });

  final String id;
  final DateTime date;
  final String label;
  final bool isVpl;
  final bool isLeague;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'label': label,
        'isVpl': isVpl,
        'isLeague': isLeague,
      };

  factory LeagueWeek.fromJson(Map<String, dynamic> json) => LeagueWeek(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        label: json['label'] as String,
        isVpl: json['isVpl'] as bool? ?? false,
        isLeague: json['isLeague'] as bool? ?? true,
      );
}

class WeeklyPayment {
  const WeeklyPayment({
    required this.weekId,
    required this.playerId,
    required this.amount,
    required this.paidAt,
  });

  final String weekId;
  final String playerId;
  final int amount;
  final DateTime paidAt;

  String get id => '${weekId}_$playerId';

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'playerId': playerId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
      };

  factory WeeklyPayment.fromJson(Map<String, dynamic> json) => WeeklyPayment(
        weekId: json['weekId'] as String,
        playerId: json['playerId'] as String,
        amount: json['amount'] as int? ?? 50,
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}

class GuestPayment {
  const GuestPayment({
    required this.id,
    required this.weekId,
    required this.name,
    required this.teamId,
    required this.amount,
    required this.paidAt,
  });

  final String id;
  final String weekId;
  final String name;
  final String teamId;
  final int amount;
  final DateTime paidAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekId': weekId,
        'name': name,
        'teamId': teamId,
        'amount': amount,
        'paidAt': paidAt.toIso8601String(),
      };

  factory GuestPayment.fromJson(Map<String, dynamic> json) => GuestPayment(
        id: json['id'] as String,
        weekId: json['weekId'] as String,
        name: json['name'] as String,
        teamId: json['teamId'] as String,
        amount: json['amount'] as int? ?? 200,
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}

class MatchScorecard {
  const MatchScorecard({
    required this.id,
    required this.date,
    required this.teamAId,
    required this.teamBId,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamBScore,
    required this.resultText,
    this.tossText = '',
    this.ground = 'Farm MCK, Vellore',
    this.pdfLocalPath,
  });

  final String id;
  final DateTime date;
  final String teamAId;
  final String teamBId;
  final String teamAName;
  final String teamBName;
  final String teamAScore;
  final String teamBScore;
  final String resultText;
  final String tossText;
  final String ground;
  final String? pdfLocalPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'teamAId': teamAId,
        'teamBId': teamBId,
        'teamAName': teamAName,
        'teamBName': teamBName,
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'resultText': resultText,
        'tossText': tossText,
        'ground': ground,
        'pdfLocalPath': pdfLocalPath,
      };

  factory MatchScorecard.fromJson(Map<String, dynamic> json) => MatchScorecard(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        teamAId: json['teamAId'] as String,
        teamBId: json['teamBId'] as String,
        teamAName: json['teamAName'] as String,
        teamBName: json['teamBName'] as String,
        teamAScore: json['teamAScore'] as String,
        teamBScore: json['teamBScore'] as String,
        resultText: json['resultText'] as String,
        tossText: json['tossText'] as String? ?? '',
        ground: json['ground'] as String? ?? '',
        pdfLocalPath: json['pdfLocalPath'] as String?,
      );
}

class PlayerTrade {
  const PlayerTrade({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.fromTeamId,
    required this.toTeamId,
    required this.salePriceInr,
    required this.commissionInr,
    required this.commissionCollected,
    required this.tradedAt,
    this.notes = '',
  });

  final String id;
  final String playerId;
  final String playerName;
  final String fromTeamId;
  final String toTeamId;
  final int salePriceInr;
  final int commissionInr;
  final bool commissionCollected;
  final DateTime tradedAt;
  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'playerName': playerName,
        'fromTeamId': fromTeamId,
        'toTeamId': toTeamId,
        'salePriceInr': salePriceInr,
        'commissionInr': commissionInr,
        'commissionCollected': commissionCollected,
        'tradedAt': tradedAt.toIso8601String(),
        'notes': notes,
      };

  factory PlayerTrade.fromJson(Map<String, dynamic> json) => PlayerTrade(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
        fromTeamId: json['fromTeamId'] as String,
        toTeamId: json['toTeamId'] as String,
        salePriceInr: json['salePriceInr'] as int,
        commissionInr: json['commissionInr'] as int,
        commissionCollected: json['commissionCollected'] as bool? ?? false,
        tradedAt: DateTime.parse(json['tradedAt'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

enum EligibilityReason { lifetime, subscription, weeklyPaid, unpaid, guest }

class Eligibility {
  const Eligibility({required this.eligible, required this.reason});
  final bool eligible;
  final EligibilityReason reason;

  String get label => switch (reason) {
        EligibilityReason.lifetime => 'Lifetime member',
        EligibilityReason.subscription => 'Season subscription',
        EligibilityReason.weeklyPaid => 'Paid ₹$kWeeklyFee this week',
        EligibilityReason.unpaid => 'Unpaid',
        EligibilityReason.guest => 'Guest (₹$kGuestFee)',
      };
}

class FinanceSummary {
  const FinanceSummary({
    required this.weeklyTotal,
    required this.subscriptionTotal,
    required this.guestTotal,
    required this.tradeCommissionTotal,
    required this.byWeek,
  });

  final int weeklyTotal;
  final int subscriptionTotal;
  final int guestTotal;
  final int tradeCommissionTotal;
  final Map<String, int> byWeek;

  int get seasonTotal =>
      weeklyTotal + subscriptionTotal + guestTotal + tradeCommissionTotal;
}
