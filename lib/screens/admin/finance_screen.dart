import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/fpl_store.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key, required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final f = store.financeSummary();
          final df = DateFormat('d MMM');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'FINANCE',
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Season total received',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              ),
              Text(
                '₹${f.seasonTotal}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 48,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              const SizedBox(height: 16),
              _row('Weekly fees (ledger)', f.weeklyTotal),
              _row('Subscriptions (ledger)', f.subscriptionTotal),
              _row('Guest fees (ledger)', f.guestTotal),
              _row('Trade commissions (25%)', f.tradeCommissionTotal),
              const SizedBox(height: 8),
              Text(
                'Defaults: weekly ₹${store.weeklyFee} · sub ₹${store.subscriptionFee} · guest ₹${store.guestFee}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Week-wise (weekly + guests)',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (f.byWeek.isEmpty)
                const Text('No collections yet', style: TextStyle(color: Colors.white38))
              else
                ...f.byWeek.entries.map((e) {
                  String label = e.key;
                  try {
                    final week = store.weeks.firstWhere((w) => w.id == e.key);
                    final weekFee = week.weeklyFee ?? store.weeklyFee;
                    final guestFee = week.guestFee ?? store.guestFee;
                    label =
                        '${week.label} · ${df.format(week.date)} (₹$weekFee / guest ₹$guestFee)';
                  } catch (_) {}
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: const TextStyle(color: Colors.white)),
                    trailing: Text(
                      '₹${e.value}',
                      style: const TextStyle(color: Color(0xFFB8F27A)),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              const Text(
                'Subscriptions',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              ...store.players.where((p) => p.subscriptionPaid).map(
                    (p) {
                      final until = p.subscriptionValidUntil;
                      final sub = until == null
                          ? 'Season'
                          : 'Until ${df.format(until)}';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          sub,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          '₹${p.subscriptionAmount}',
                          style: const TextStyle(color: Color(0xFFB8F27A)),
                        ),
                      );
                    },
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          Text('₹$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
