import '../config.dart';

class FplPlayer {
  const FplPlayer({
    required this.id,
    required this.name,
    required this.teamId,
    required this.teamName,
    this.phone = '',
    this.email = '',
    this.cricheroesUsername = '',
    this.isLifetimeMember = false,
    this.isCaptain = false,
    this.subscriptionPaid = false,
    this.subscriptionPaidAt,
    this.subscriptionAmount = 0,
    this.subscriptionValidUntil,
    this.lastLoginAt,
    this.lastUpdatedAt,
    this.active = true,
  });

  final String id;
  final String name;
  final String teamId;
  final String teamName;
  final String phone;
  final String email;
  final String cricheroesUsername;
  final bool isLifetimeMember;
  final bool isCaptain;
  final bool subscriptionPaid;
  final DateTime? subscriptionPaidAt;
  /// INR collected for this player's subscription (0 if unpaid).
  final int subscriptionAmount;
  /// If set, subscription eligibility ends after this calendar day.
  final DateTime? subscriptionValidUntil;
  /// Last time this player opened / signed into the app.
  final DateTime? lastLoginAt;
  /// Last time this player changed their own profile data.
  final DateTime? lastUpdatedAt;
  final bool active;

  /// Paid subscription that is still in its valid window (or season-long).
  bool get hasActiveSubscription {
    if (!subscriptionPaid) return false;
    final until = subscriptionValidUntil;
    if (until == null) return true;
    final today = DateTime.now();
    final end = DateTime(until.year, until.month, until.day);
    final now = DateTime(today.year, today.month, today.day);
    return !now.isAfter(end);
  }

  String get cricheroesUsernameLower => cricheroesUsername.trim().toLowerCase();

  String get normalizedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  FplPlayer copyWith({
    String? phone,
    String? email,
    String? cricheroesUsername,
    bool? isLifetimeMember,
    bool? subscriptionPaid,
    DateTime? subscriptionPaidAt,
    int? subscriptionAmount,
    DateTime? subscriptionValidUntil,
    DateTime? lastLoginAt,
    DateTime? lastUpdatedAt,
    String? teamId,
    String? teamName,
    bool clearSubscriptionDate = false,
    bool clearSubscriptionValidUntil = false,
  }) {
    return FplPlayer(
      id: id,
      name: name,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cricheroesUsername: cricheroesUsername ?? this.cricheroesUsername,
      isLifetimeMember: isLifetimeMember ?? this.isLifetimeMember,
      isCaptain: isCaptain,
      subscriptionPaid: subscriptionPaid ?? this.subscriptionPaid,
      subscriptionPaidAt: clearSubscriptionDate
          ? null
          : (subscriptionPaidAt ?? this.subscriptionPaidAt),
      subscriptionAmount: subscriptionAmount ?? this.subscriptionAmount,
      subscriptionValidUntil: clearSubscriptionValidUntil
          ? null
          : (subscriptionValidUntil ?? this.subscriptionValidUntil),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      active: active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teamId': teamId,
        'teamName': teamName,
        'phone': phone,
        'email': email,
        'cricheroesUsername': cricheroesUsername,
        'cricheroesUsernameLower': cricheroesUsernameLower,
        'isLifetimeMember': isLifetimeMember,
        'isCaptain': isCaptain,
        'subscriptionPaid': subscriptionPaid,
        'subscriptionPaidAt': subscriptionPaidAt?.toIso8601String(),
        'subscriptionAmount': subscriptionAmount,
        'subscriptionValidUntil': subscriptionValidUntil?.toIso8601String(),
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
        if (lastUpdatedAt != null)
          'lastUpdatedAt': lastUpdatedAt!.toIso8601String(),
        'active': active,
      };

  factory FplPlayer.fromJson(Map<String, dynamic> json) {
    final paid = json['subscriptionPaid'] as bool? ?? false;
    final amount = (json['subscriptionAmount'] as num?)?.toInt();
    return FplPlayer(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cricheroesUsername: json['cricheroesUsername'] as String? ??
          (json['name'] as String? ?? ''),
      isLifetimeMember: json['isLifetimeMember'] as bool? ?? false,
      isCaptain: json['isCaptain'] as bool? ?? false,
      subscriptionPaid: paid,
      subscriptionPaidAt: json['subscriptionPaidAt'] != null
          ? DateTime.tryParse(json['subscriptionPaidAt'] as String)
          : null,
      // Legacy: paid with no amount → treat as default season fee at read time in UI/finance.
      subscriptionAmount: amount ?? (paid ? kSubscriptionFee : 0),
      subscriptionValidUntil: json['subscriptionValidUntil'] != null
          ? DateTime.tryParse(json['subscriptionValidUntil'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'] as String)
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
    this.weeklyFee,
    this.guestFee,
  });

  final String id;
  final DateTime date;
  final String label;
  final bool isVpl;
  final bool isLeague;
  /// Weekly fee for this Sunday; null → use app default [kWeeklyFee] / store default.
  final int? weeklyFee;
  /// Guest fee for this Sunday; null → use app default [kGuestFee] / store default.
  final int? guestFee;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'label': label,
        'isVpl': isVpl,
        'isLeague': isLeague,
        if (weeklyFee != null) 'weeklyFee': weeklyFee,
        if (guestFee != null) 'guestFee': guestFee,
      };

  factory LeagueWeek.fromJson(Map<String, dynamic> json) => LeagueWeek(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        label: json['label'] as String,
        isVpl: json['isVpl'] as bool? ?? false,
        isLeague: json['isLeague'] as bool? ?? true,
        weeklyFee: (json['weeklyFee'] as num?)?.toInt(),
        guestFee: (json['guestFee'] as num?)?.toInt(),
      );

  LeagueWeek copyWith({
    int? weeklyFee,
    int? guestFee,
    bool clearWeeklyFee = false,
    bool clearGuestFee = false,
  }) =>
      LeagueWeek(
        id: id,
        date: date,
        label: label,
        isVpl: isVpl,
        isLeague: isLeague,
        weeklyFee: clearWeeklyFee ? null : (weeklyFee ?? this.weeklyFee),
        guestFee: clearGuestFee ? null : (guestFee ?? this.guestFee),
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
    this.pdfUrl,
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
  /// Firebase Storage download URL (when cloud sync is enabled).
  final String? pdfUrl;

  bool get hasPdf =>
      (pdfUrl != null && pdfUrl!.isNotEmpty) ||
      (pdfLocalPath != null && pdfLocalPath!.isNotEmpty);

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
        'pdfUrl': pdfUrl,
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
        pdfUrl: json['pdfUrl'] as String?,
      );
}

/// Pre-planned Sunday fixture for CricHeroes scheduling (before result entry).
class ScheduledFixture {
  const ScheduledFixture({
    required this.id,
    required this.weekId,
    required this.date,
    required this.slot,
    required this.teamAId,
    required this.teamBId,
    required this.teamAName,
    required this.teamBName,
  });

  final String id;
  final String weekId;
  final DateTime date;
  /// Match order on the day: 1 = opening, then 2, 3.
  final int slot;
  final String teamAId;
  final String teamBId;
  final String teamAName;
  final String teamBName;

  bool get isOpening => slot == 1;

  String get matchup => '$teamAName vs $teamBName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekId': weekId,
        'date': date.toIso8601String(),
        'slot': slot,
        'teamAId': teamAId,
        'teamBId': teamBId,
        'teamAName': teamAName,
        'teamBName': teamBName,
      };

  factory ScheduledFixture.fromJson(Map<String, dynamic> json) =>
      ScheduledFixture(
        id: json['id'] as String,
        weekId: json['weekId'] as String,
        date: DateTime.parse(json['date'] as String),
        slot: json['slot'] as int? ?? 1,
        teamAId: json['teamAId'] as String,
        teamBId: json['teamBId'] as String,
        teamAName: json['teamAName'] as String? ?? '',
        teamBName: json['teamBName'] as String? ?? '',
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

  String label({
    int weeklyFee = kWeeklyFee,
    int guestFee = kGuestFee,
    int? subscriptionAmount,
    DateTime? subscriptionValidUntil,
  }) {
    final subAmt = subscriptionAmount;
    final until = subscriptionValidUntil;
    return switch (reason) {
      EligibilityReason.lifetime => 'Lifetime member',
      EligibilityReason.subscription => until != null
          ? 'Subscription ₹${subAmt ?? ''} until '
              '${until.day}/${until.month}/${until.year}'
          : (subAmt != null && subAmt > 0
              ? 'Season subscription ₹$subAmt'
              : 'Season subscription'),
      EligibilityReason.weeklyPaid => 'Paid ₹$weeklyFee this week',
      EligibilityReason.unpaid => 'Unpaid',
      EligibilityReason.guest => 'Guest (₹$guestFee)',
    };
  }
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
