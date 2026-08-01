import '../models/models.dart';
import 'fpl_store.dart';

/// CSV / text exports for season ledger backup.
class LedgerExport {
  static String financeCsv(FplStore store) {
    final f = store.financeSummary();
    final buf = StringBuffer();
    buf.writeln('section,key,amount_inr');
    buf.writeln('summary,weekly,${f.weeklyTotal}');
    buf.writeln('summary,subscription,${f.subscriptionTotal}');
    buf.writeln('summary,guest,${f.guestTotal}');
    buf.writeln('summary,trade_commission,${f.tradeCommissionTotal}');
    buf.writeln('summary,season_total,${f.seasonTotal}');
    for (final e in f.byWeek.entries) {
      buf.writeln('by_week,${e.key},${e.value}');
    }
    return buf.toString();
  }

  static String paymentsCsv(FplStore store) {
    final buf = StringBuffer('weekId,playerId,playerName,amount,paidAt\n');
    for (final p in store.payments) {
      final name = store.playerById(p.playerId)?.name ?? '';
      buf.writeln(
        '${p.weekId},${p.playerId},"${name.replaceAll('"', '""')}",${p.amount},${p.paidAt.toIso8601String()}',
      );
    }
    return buf.toString();
  }

  static String subscriptionsCsv(List<FplPlayer> players) {
    final buf =
        StringBuffer('id,name,team,subscriptionPaid,subscriptionPaidAt\n');
    for (final p in players.where((p) => p.subscriptionPaid)) {
      buf.writeln(
        '${p.id},"${p.name}",${p.teamName},true,${p.subscriptionPaidAt?.toIso8601String() ?? ""}',
      );
    }
    return buf.toString();
  }
}
