import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config.dart';
import '../../services/fpl_store.dart';

class EligibleScreen extends StatelessWidget {
  const EligibleScreen({super.key, required this.store});
  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: const Text('Eligible for CricHeroes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: store.eligibleCopyText()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final guests = store.guestsForWeek();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                store.selectedWeek?.label ?? '',
                style: GoogleFonts.bebasNeue(
                  fontSize: 24,
                  color: const Color(0xFFB8F27A),
                ),
              ),
              const SizedBox(height: 12),
              for (final teamId in [kTeamOx, kTeamGb, kTeamNew]) ...[
                Text(
                  kTeamNames[teamId]!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ...store
                    .eligiblePlayers()
                    .where((p) => p.teamId == teamId)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${p.name}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                const SizedBox(height: 14),
              ],
              if (guests.isNotEmpty) ...[
                const Text(
                  'Guests',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...guests.map(
                  (g) => Text(
                    '• ${g.name} (${kTeamNames[g.teamId]})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
