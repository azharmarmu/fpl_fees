import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/fpl_store.dart';
import '../widgets/schedule_list.dart';

/// Full Aug–Sep fixture list (separate from scorecards).
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key, required this.store});

  final FplStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF163020),
        title: Text(
          'SCHEDULE',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: const Color(0xFFB8F27A),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Aug–Sep · feed CricHeroes in this order (1st = opening)',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              ScheduleList(store: store),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
