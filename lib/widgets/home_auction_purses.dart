import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/season2_auction.dart';
import '../services/fpl_store.dart';

/// Compact Season 2 auction purses (live spent / left after releases).
class HomeAuctionPurses extends StatelessWidget {
  const HomeAuctionPurses({super.key, this.store});

  /// When null, shows seed totals only (no live trade adjustments).
  final FplStore? store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUCTION PURSE',
          style: GoogleFonts.bebasNeue(
            fontSize: 18,
            color: const Color(0xFFB8F27A),
          ),
        ),
        const Text(
          'Season 2 bidding points · budget 10,000',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        for (final seed in season2AuctionSeeds) ...[
          _PurseRow(seed: seed, store: store),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PurseRow extends StatelessWidget {
  const _PurseRow({required this.seed, this.store});
  final TeamAuctionPurseSeed seed;
  final FplStore? store;

  @override
  Widget build(BuildContext context) {
    final live = store?.auctionPurseLive(seed.teamId);
    final spent = live?.spent ?? seed.spent;
    final left = live?.left ?? (kAuctionBudgetTotal - seed.spent);
    final squad = live?.squadSize;
    final usedFrac = spent / kAuctionBudgetTotal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  seed.teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${formatAuctionPoints(spent)} / ${formatAuctionPoints(kAuctionBudgetTotal)}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: const Color(0xFFB8F27A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'C: ${seed.captainName} · Left ${formatAuctionPoints(left)}'
            '${squad != null ? ' · $squad players' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedFrac.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white12,
              color: const Color(0xFFB8F27A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail card for one team's auction purse (My team).
class TeamAuctionPurseCard extends StatelessWidget {
  const TeamAuctionPurseCard({
    super.key,
    required this.teamId,
    required this.store,
  });

  final String teamId;
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    final seed = auctionSeedForTeam(teamId);
    if (seed == null) return const SizedBox.shrink();
    final live = store.auctionPurseLive(teamId);
    final costs = store.auctionCostsByPlayerId();
    final squad = store.playersForTeam(teamId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUCTION PURSE',
            style: GoogleFonts.bebasNeue(
              fontSize: 16,
              color: const Color(0xFFB8F27A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Budget ${formatAuctionPoints(live.spent)} / ${formatAuctionPoints(kAuctionBudgetTotal)} · Left ${formatAuctionPoints(live.left)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            'Captain ${seed.captainName} · ${live.squadSize} players',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final p in squad)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.isCaptain ? '${p.name} (C)' : p.name,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    p.isCaptain
                        ? 'Captain'
                        : (costs[p.id] == 0
                            ? 'Retained'
                            : formatAuctionPoints(costs[p.id] ?? 0)),
                    style: TextStyle(
                      color: p.isCaptain || (costs[p.id] ?? 0) == 0
                          ? Colors.white54
                          : const Color(0xFFB8F27A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String auctionSubtitleFor({
  required FplStore store,
  required String teamId,
  required String playerId,
  required String playerName,
  required bool isCaptain,
}) {
  if (isCaptain) return 'Captain';
  final seed = auctionSeedForTeam(teamId);
  if (seed != null) {
    final key = auctionNameKey(playerName);
    if (seed.retained.any((r) => auctionNameKey(r) == key)) return 'Retained';
  }
  final pts = store.auctionCostFor(playerId);
  if (pts > 0) return 'Auction · ${formatAuctionPoints(pts)} pts';
  return 'Squad';
}
