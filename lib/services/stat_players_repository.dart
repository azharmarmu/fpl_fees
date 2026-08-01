import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/season1.dart';
import '../models/stat_player.dart';

/// Firestore-backed career stats (`statPlayers/{id}`) for Season 1+ archives.
class StatPlayersRepository {
  StatPlayersRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('statPlayers');

  DocumentReference<Map<String, dynamic>> get _season1Meta =>
      _db.collection('seasons').doc('s1');

  static String nameKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String idFromName(String name) =>
      'n_${nameKey(name).replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

  Future<CareerPlayer?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return CareerPlayer.fromJson(snap.data()!);
  }

  Future<CareerPlayer?> getByName(String name) async {
    final key = nameKey(name);
    final q = await _col.where('nameLower', isEqualTo: key).limit(1).get();
    if (q.docs.isEmpty) return null;
    return CareerPlayer.fromJson(q.docs.first.data());
  }

  /// Build career docs from bundled Season 1 CSVs and write to Firestore.
  /// Requires admin Auth (rules). Returns number of player docs written.
  Future<int> uploadSeason1FromAssets() async {
    final archive = await Season1Loader.load();
    final byId = <String, CareerPlayer>{};
    final idByName = <String, String>{};

    void remember(String id, String name) {
      idByName[nameKey(name)] = id;
    }

    CareerPlayer ensure({
      required String id,
      required String name,
      required String teamName,
    }) {
      final existing = byId[id];
      if (existing != null) {
        final s1 = existing.seasons['s1'];
        if (s1 != null && teamName.isNotEmpty && !s1.teams.contains(teamName)) {
          byId[id] = CareerPlayer(
            id: existing.id,
            name: existing.name,
            seasons: {
              ...existing.seasons,
              's1': CareerSeasonStats(
                seasonId: s1.seasonId,
                seasonLabel: s1.seasonLabel,
                teams: [...s1.teams, teamName],
                primaryTeamName:
                    s1.primaryTeamName.isEmpty ? teamName : s1.primaryTeamName,
                batting: s1.batting,
                bowling: s1.bowling,
                fielding: s1.fielding,
                mvp: s1.mvp,
              ),
            },
          );
        }
        return byId[id]!;
      }
      final created = CareerPlayer(
        id: id,
        name: name,
        seasons: {
          's1': CareerSeasonStats(
            seasonId: 's1',
            seasonLabel: Season1Meta.seasonLabel,
            teams: teamName.isEmpty ? const [] : [teamName],
            primaryTeamName: teamName,
          ),
        },
      );
      byId[id] = created;
      remember(id, name);
      return created;
    }

    CareerPlayer patchS1(
      CareerPlayer p, {
      CareerBatting? batting,
      CareerBowling? bowling,
      CareerFielding? fielding,
      CareerMvp? mvp,
      String? teamName,
    }) {
      final s1 = p.seasons['s1']!;
      final teams = [...s1.teams];
      if (teamName != null &&
          teamName.isNotEmpty &&
          !teams.contains(teamName)) {
        teams.add(teamName);
      }
      final next = CareerPlayer(
        id: p.id,
        name: p.name,
        seasons: {
          ...p.seasons,
          's1': CareerSeasonStats(
            seasonId: s1.seasonId,
            seasonLabel: s1.seasonLabel,
            teams: teams,
            primaryTeamName: s1.primaryTeamName.isEmpty
                ? (teamName ?? '')
                : s1.primaryTeamName,
            batting: batting ?? s1.batting,
            bowling: bowling ?? s1.bowling,
            fielding: fielding ?? s1.fielding,
            mvp: mvp ?? s1.mvp,
          ),
        },
      );
      byId[p.id] = next;
      return next;
    }

    for (final r in archive.batting) {
      final p = ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patchS1(
        p,
        teamName: r.teamName,
        batting: CareerBatting(
          matches: r.matches,
          innings: r.innings,
          runs: r.runs,
          highest: r.highest,
          average: r.average,
          strikeRate: r.strikeRate,
          fours: r.fours,
          sixes: r.sixes,
        ),
      );
    }

    for (final r in archive.bowling) {
      final p = ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patchS1(
        p,
        teamName: r.teamName,
        bowling: CareerBowling(
          matches: r.matches,
          innings: r.innings,
          wickets: r.wickets,
          overs: r.overs,
          maidens: r.maidens,
          runs: r.runs,
          economy: r.economy,
          best: r.best,
        ),
      );
    }

    for (final r in archive.fielding) {
      final p = ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patchS1(
        p,
        teamName: r.teamName,
        fielding: CareerFielding(
          matches: r.matches,
          catches: r.catches,
          runOuts: r.runOuts,
          stumpings: r.stumpings,
          totalDismissals: r.totalDismissals,
        ),
      );
    }

    for (final r in archive.mvp) {
      final key = nameKey(r.name);
      var id = idByName[key];
      // Fuzzy: MVP names sometimes differ slightly (MONIZ vs Moniz Babs).
      if (id == null) {
        for (final e in idByName.entries) {
          if (e.key.contains(key) || key.contains(e.key)) {
            id = e.value;
            break;
          }
        }
      }
      id ??= idFromName(r.name);
      final p = ensure(id: id, name: r.name, teamName: r.teamName);
      patchS1(
        p,
        teamName: r.teamName,
        mvp: CareerMvp(
          matches: r.matches,
          battingPts: r.battingPts,
          bowlingPts: r.bowlingPts,
          fieldingPts: r.fieldingPts,
          total: r.total,
        ),
      );
    }

    // Season meta + standings.
    await _season1Meta.set({
      'id': 's1',
      'title': Season1Meta.title,
      'seasonLabel': Season1Meta.seasonLabel,
      'location': Season1Meta.location,
      'dateRange': Season1Meta.dateRange,
      'totalMatches': Season1Meta.totalMatches,
      'totalTeams': Season1Meta.totalTeams,
      'standings': [
        for (final s in season1Standings)
          {
            'rank': s.rank,
            'teamName': s.teamName,
            'played': s.played,
            'won': s.won,
            'lost': s.lost,
            'points': s.points,
            'nrr': s.nrr,
            'forScore': s.forScore,
            'againstScore': s.againstScore,
            'last5': s.last5,
          },
      ],
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final players = byId.values.toList();
    const chunk = 400;
    for (var i = 0; i < players.length; i += chunk) {
      final batch = _db.batch();
      final slice = players.skip(i).take(chunk);
      for (final p in slice) {
        batch.set(_col.doc(p.id), p.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    }

    debugPrint('Uploaded ${players.length} Season 1 statPlayers');
    return players.length;
  }

  /// Local fallback when Firestore has no doc yet (from bundled CSVs).
  static Future<CareerPlayer?> fromSeason1Assets({
    String? playerId,
    String? name,
  }) async {
    final archive = await Season1Loader.load();
    String? id = playerId;
    String resolvedName = name ?? '';
    String team = '';

    CareerBatting? batting;
    CareerBowling? bowling;
    CareerFielding? fielding;
    CareerMvp? mvp;
    final teams = <String>{};

    if (id != null) {
      for (final r in archive.batting) {
        if (r.playerId == id) {
          resolvedName = r.name;
          team = r.teamName;
          teams.add(r.teamName);
          batting = CareerBatting(
            matches: r.matches,
            innings: r.innings,
            runs: r.runs,
            highest: r.highest,
            average: r.average,
            strikeRate: r.strikeRate,
            fours: r.fours,
            sixes: r.sixes,
          );
        }
      }
      for (final r in archive.bowling) {
        if (r.playerId == id) {
          resolvedName = resolvedName.isEmpty ? r.name : resolvedName;
          teams.add(r.teamName);
          bowling = CareerBowling(
            matches: r.matches,
            innings: r.innings,
            wickets: r.wickets,
            overs: r.overs,
            maidens: r.maidens,
            runs: r.runs,
            economy: r.economy,
            best: r.best,
          );
        }
      }
      for (final r in archive.fielding) {
        if (r.playerId == id) {
          resolvedName = resolvedName.isEmpty ? r.name : resolvedName;
          teams.add(r.teamName);
          fielding = CareerFielding(
            matches: r.matches,
            catches: r.catches,
            runOuts: r.runOuts,
            stumpings: r.stumpings,
            totalDismissals: r.totalDismissals,
          );
        }
      }
    }

    final key = nameKey(resolvedName.isEmpty ? (name ?? '') : resolvedName);
    if (key.isNotEmpty) {
      for (final r in archive.mvp) {
        if (nameKey(r.name) == key ||
            nameKey(r.name).contains(key) ||
            key.contains(nameKey(r.name))) {
          teams.add(r.teamName);
          mvp = CareerMvp(
            matches: r.matches,
            battingPts: r.battingPts,
            bowlingPts: r.bowlingPts,
            fieldingPts: r.fieldingPts,
            total: r.total,
          );
          if (resolvedName.isEmpty) resolvedName = r.name;
        }
      }
    }

    if (resolvedName.isEmpty && batting == null && bowling == null) {
      return null;
    }
    id ??= idFromName(resolvedName);
    return CareerPlayer(
      id: id,
      name: resolvedName,
      seasons: {
        's1': CareerSeasonStats(
          seasonId: 's1',
          seasonLabel: Season1Meta.seasonLabel,
          teams: teams.toList(),
          primaryTeamName: team.isNotEmpty
              ? team
              : (teams.isEmpty ? '' : teams.first),
          batting: batting,
          bowling: bowling,
          fielding: fielding,
          mvp: mvp,
        ),
      },
    );
  }
}
