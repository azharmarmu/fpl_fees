import 'package:flutter/material.dart';

import '../screens/tournament_stats_screen.dart';

/// Center-docked FAB → Tournament stats, with a notched bottom bar.
class FplScaffoldWithStatsFab extends StatelessWidget {
  const FplScaffoldWithStatsFab({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    required this.cloudEnabled,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<FplNavItem> items;
  final bool cloudEnabled;

  void _openStats(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentStatsScreen(cloudEnabled: cloudEnabled),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'Use 4 nav items (2 left + 2 right of FAB)');
    final left = items.sublist(0, 2);
    final right = items.sublist(2, 4);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openStats(context),
        backgroundColor: const Color(0xFFB8F27A),
        foregroundColor: Colors.black,
        tooltip: 'Tournament stats',
        elevation: 4,
        child: const Icon(Icons.leaderboard),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF163020),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 64,
        child: Row(
          children: [
            for (final item in left)
              Expanded(
                child: _NavBtn(
                  item: item,
                  selected: selectedIndex == item.index,
                  onTap: () => onSelect(item.index),
                ),
              ),
            const SizedBox(width: 72),
            for (final item in right)
              Expanded(
                child: _NavBtn(
                  item: item,
                  selected: selectedIndex == item.index,
                  onTap: () => onSelect(item.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FplNavItem {
  const FplNavItem({
    required this.index,
    required this.icon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final String label;
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FplNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFB8F27A) : Colors.white54;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
