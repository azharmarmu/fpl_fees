import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../data/season2_auction.dart';
import '../../models/models.dart';
import '../../services/fpl_store.dart';
import '../../widgets/home_auction_purses.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key, required this.store});
  final FplStore store;

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Trades'),
        actions: [
          if (store.tradeOpen)
            PopupMenuButton<TradeKind>(
              tooltip: 'New action',
              onSelected: (kind) => _openAction(context, kind),
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: TradeKind.release, child: Text('Release')),
                PopupMenuItem(value: TradeKind.buy, child: Text('Buy')),
                PopupMenuItem(value: TradeKind.sell, child: Text('Sell')),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    'Action',
                    style: TextStyle(color: Color(0xFFB8F27A)),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (!store.tradeOpen) {
            return const Center(
              child: Text(
                'Trade window is closed.\nEnable in More.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Auction points only · no ₹ / commission yet',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),
              HomeAuctionPurses(store: store),
              const SizedBox(height: 20),
              Text(
                'HISTORY',
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              const SizedBox(height: 8),
              if (store.trades.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No trades yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                for (final t in store.trades)
                  _TradeTile(
                    trade: t,
                    canUndo: store.canUndoTrade(t),
                    onUndo: () => _undo(context, t),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _undo(BuildContext context, PlayerTrade trade) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E20),
        title: const Text('Undo this action?', style: TextStyle(color: Colors.white)),
        content: Text(
          '${trade.playerName} will move back and auction points recalculate.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await widget.store.undoTrade(trade.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Undid ${trade.playerName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _openAction(BuildContext context, TradeKind kind) async {
    switch (kind) {
      case TradeKind.release:
        await _recordRelease(context);
      case TradeKind.buy:
        await _recordBuy(context);
      case TradeKind.sell:
        await _recordSell(context);
      case TradeKind.package:
        break;
    }
  }

  Future<void> _recordRelease(BuildContext context) async {
    final store = widget.store;
    final squad = store.players
        .where(
          (p) =>
              p.active &&
              !p.isCaptain &&
              p.teamId != kTeamFreeAgent &&
              p.teamId != kTeamGuest,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (squad.isEmpty) return;

    var playerId = squad.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final p = store.playerById(playerId);
          final pts = p == null ? 0 : store.auctionCostFor(p.id);
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2E20),
            title: Text(
              'Release player',
              style: GoogleFonts.bebasNeue(color: const Color(0xFFB8F27A)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: playerId,
                  dropdownColor: const Color(0xFF1A2E20),
                  decoration: const InputDecoration(labelText: 'Player'),
                  items: [
                    for (final p in squad)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (${kTeamNames[p.teamId]})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => playerId = v ?? playerId),
                ),
                const SizedBox(height: 12),
                Text(
                  'Returns ${formatAuctionPoints(pts)} pts to Left',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Release'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final p = store.playerById(playerId);
    if (p == null) return;
    try {
      await store.recordRelease(player: p);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _recordBuy(BuildContext context) async {
    final store = widget.store;
    final agents = store.freeAgents();
    if (agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No free agents — release someone first')),
      );
      return;
    }
    var playerId = agents.first.id;
    var toTeam = kTeamOx;
    final pointsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final left = store.auctionPurseLive(toTeam).left;
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2E20),
            title: Text(
              'Buy free agent',
              style: GoogleFonts.bebasNeue(color: const Color(0xFFB8F27A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: playerId,
                    dropdownColor: const Color(0xFF1A2E20),
                    decoration: const InputDecoration(labelText: 'Player'),
                    items: [
                      for (final p in agents)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => playerId = v ?? playerId),
                  ),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: toTeam,
                    dropdownColor: const Color(0xFF1A2E20),
                    decoration: InputDecoration(
                      labelText: 'Buying team (left ${formatAuctionPoints(left)})',
                    ),
                    items: [
                      for (final id in [kTeamOx, kTeamGb, kTeamAvengers])
                        DropdownMenuItem(
                          value: id,
                          child: Text(
                            kTeamNames[id]!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => toTeam = v ?? toTeam),
                  ),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Auction points',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Buy'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final p = store.playerById(playerId);
    final pts = int.tryParse(pointsCtrl.text.trim());
    pointsCtrl.dispose();
    if (p == null || pts == null || pts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid points')),
      );
      return;
    }
    try {
      await store.recordBuy(player: p, toTeamId: toTeam, auctionPoints: pts);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _recordSell(BuildContext context) async {
    final store = widget.store;
    final squad = store.players
        .where(
          (p) =>
              p.active &&
              !p.isCaptain &&
              p.teamId != kTeamFreeAgent &&
              p.teamId != kTeamGuest,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (squad.isEmpty) return;

    var playerId = squad.first.id;
    var toTeam = kTeamOx;
    final pointsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final p = store.playerById(playerId);
          final from = p?.teamId;
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2E20),
            title: Text(
              'Sell to another team',
              style: GoogleFonts.bebasNeue(color: const Color(0xFFB8F27A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: playerId,
                    dropdownColor: const Color(0xFF1A2E20),
                    decoration: const InputDecoration(labelText: 'Player'),
                    items: [
                      for (final p in squad)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (${kTeamNames[p.teamId]})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => playerId = v ?? playerId),
                  ),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: toTeam,
                    dropdownColor: const Color(0xFF1A2E20),
                    decoration: const InputDecoration(labelText: 'To team'),
                    items: [
                      for (final id in [kTeamOx, kTeamGb, kTeamAvengers])
                        if (id != from)
                          DropdownMenuItem(
                            value: id,
                            child: Text(
                              '${kTeamNames[id]} · left ${formatAuctionPoints(store.auctionPurseLive(id).left)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                    ],
                    onChanged: (v) => setLocal(() => toTeam = v ?? toTeam),
                  ),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Auction points (buyer pays)',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sell'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final p = store.playerById(playerId);
    final pts = int.tryParse(pointsCtrl.text.trim());
    pointsCtrl.dispose();
    if (p == null || pts == null || pts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid points')),
      );
      return;
    }
    try {
      await store.recordSell(player: p, toTeamId: toTeam, auctionPoints: pts);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _TradeTile extends StatelessWidget {
  const _TradeTile({
    required this.trade,
    required this.canUndo,
    required this.onUndo,
  });

  final PlayerTrade trade;
  final bool canUndo;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (trade.kind) {
      TradeKind.release => 'Released',
      TradeKind.buy => 'Bought',
      TradeKind.sell => 'Sold',
      TradeKind.package => 'Package',
    };
    final from = kTeamNames[trade.fromTeamId] ?? trade.fromTeamId;
    final to = kTeamNames[trade.toTeamId] ?? trade.toTeamId;
    final legs = trade.packageLegs.isEmpty
        ? ''
        : '\n+ ${trade.packageLegs.map((l) => l.playerName).join(' · ')} → ${kTeamNames[trade.packageLegs.first.toTeamId] ?? trade.packageLegs.first.toTeamId}';
    final pts = trade.auctionPoints > 0
        ? '${formatAuctionPoints(trade.auctionPoints)} pts'
        : trade.salePriceInr > 0
            ? '₹${trade.salePriceInr}'
            : '0 pts';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        trade.playerName,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '$kindLabel · $from → $to · $pts$legs',
        style: const TextStyle(color: Colors.white54),
      ),
      isThreeLine: trade.isPackage,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d MMM').format(trade.tradedAt),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (canUndo) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onUndo,
              child: const Text('Undo', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
