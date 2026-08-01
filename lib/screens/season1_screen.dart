import 'package:flutter/material.dart';

import 'tournament_stats_screen.dart';

/// Opens tournament stats focused on Season 1 (kept for older navigation).
class Season1Screen extends StatelessWidget {
  const Season1Screen({super.key, this.cloudEnabled = false});

  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    return TournamentStatsScreen(
      cloudEnabled: cloudEnabled,
      initialSeasonId: 's1',
    );
  }
}
