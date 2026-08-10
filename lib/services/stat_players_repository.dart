import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/season1.dart';
import '../data/season2.dart';
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

  DocumentReference<Map<String, dynamic>> get _season2Meta =>
      _db.collection('seasons').doc('s2');

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

  /// Merge Season 2 CSV stats into `statPlayers` (preserves Season 1 seasons).
  Future<int> uploadSeason2FromAssets() async {
    final archive = await Season2Loader.load();
    final byId = <String, CareerSeasonStats>{};
    final idByName = <String, String>{};
    final names = <String, String>{};

    void remember(String id, String name) {
      idByName[nameKey(name)] = id;
      names[id] = name;
    }

    CareerSeasonStats ensure({
      required String id,
      required String name,
      required String teamName,
    }) {
      remember(id, name);
      final existing = byId[id];
      if (existing != null) {
        final teams = [...existing.teams];
        if (teamName.isNotEmpty && !teams.contains(teamName)) {
          teams.add(teamName);
          byId[id] = CareerSeasonStats(
            seasonId: existing.seasonId,
            seasonLabel: existing.seasonLabel,
            teams: teams,
            primaryTeamName: existing.primaryTeamName.isEmpty
                ? teamName
                : existing.primaryTeamName,
            batting: existing.batting,
            bowling: existing.bowling,
            fielding: existing.fielding,
            mvp: existing.mvp,
          );
        }
        return byId[id]!;
      }
      final created = CareerSeasonStats(
        seasonId: 's2',
        seasonLabel: Season2Meta.seasonLabel,
        teams: teamName.isEmpty ? const [] : [teamName],
        primaryTeamName: teamName,
      );
      byId[id] = created;
      return created;
    }

    void patch(
      String id, {
      CareerBatting? batting,
      CareerBowling? bowling,
      CareerFielding? fielding,
      CareerMvp? mvp,
      String? teamName,
    }) {
      final s = byId[id]!;
      final teams = [...s.teams];
      if (teamName != null &&
          teamName.isNotEmpty &&
          !teams.contains(teamName)) {
        teams.add(teamName);
      }
      byId[id] = CareerSeasonStats(
        seasonId: s.seasonId,
        seasonLabel: s.seasonLabel,
        teams: teams,
        primaryTeamName: s.primaryTeamName.isEmpty
            ? (teamName ?? '')
            : s.primaryTeamName,
        batting: batting ?? s.batting,
        bowling: bowling ?? s.bowling,
        fielding: fielding ?? s.fielding,
        mvp: mvp ?? s.mvp,
      );
    }

    for (final r in archive.batting) {
      ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patch(
        r.playerId,
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
      ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patch(
        r.playerId,
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
      ensure(id: r.playerId, name: r.name, teamName: r.teamName);
      patch(
        r.playerId,
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
      if (id == null) {
        for (final e in idByName.entries) {
          if (e.key.contains(key) || key.contains(e.key)) {
            id = e.value;
            break;
          }
        }
      }
      id ??= idFromName(r.name);
      ensure(id: id, name: r.name, teamName: r.teamName);
      patch(
        id,
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

    await _season2Meta.set({
      'id': 's2',
      'title': Season2Meta.title,
      'seasonLabel': Season2Meta.seasonLabel,
      'location': Season2Meta.location,
      'dateRange': Season2Meta.dateRange,
      'totalMatches': Season2Meta.totalMatches,
      'totalTeams': Season2Meta.totalTeams,
      'standings': [
        for (final s in season2Standings)
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

    // Deep-merge seasons maps (Firestore top-level merge replaces `seasons`).
    final ids = byId.keys.toList();
    const chunk = 200;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.skip(i).take(chunk).toList();
      final snaps = await Future.wait(slice.map((id) => _col.doc(id).get()));
      final batch = _db.batch();
      for (var j = 0; j < slice.length; j++) {
        final id = slice[j];
        final snap = snaps[j];
        final existing = snap.data() ?? <String, dynamic>{};
        final seasonsRaw = existing['seasons'];
        final seasons = <String, dynamic>{};
        if (seasonsRaw is Map) {
          for (final e in seasonsRaw.entries) {
            seasons['${e.key}'] = e.value;
          }
        }
        seasons['s2'] = byId[id]!.toJson();
        final name = names[id] ?? '${existing['name'] ?? id}';
        final seasonIds = <String>{
          ...((existing['seasonIds'] as List?) ?? []).map((e) => '$e'),
          's2',
        }.toList();
        batch.set(
          _col.doc(id),
          {
            'id': id,
            'name': name,
            'nameLower': nameKey(name),
            'seasonIds': seasonIds,
            'seasons': seasons,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }

    debugPrint('Uploaded ${ids.length} Season 2 statPlayers');
    return ids.length;
  }

  static bool _nameMatch(String a, String b) {
    final x = nameKey(a);
    final y = nameKey(b);
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    // "Moniz Babs" ↔ "MONIZ", "Mohammed Ali Mc" ↔ "Mohammed Ali MC"
    if (x.startsWith(y) || y.startsWith(x)) return true;
    final xt = x.split(' ');
    final yt = y.split(' ');
    if (xt.isNotEmpty && yt.isNotEmpty && xt.first == yt.first && xt.first.length >= 4) {
      return true;
    }
    return false;
  }

  /// Local fallback when Firestore has no doc yet (from bundled CSVs).
  static Future<CareerPlayer?> fromSeason1Assets({
    String? playerId,
    String? name,
  }) =>
      _fromArchiveAssets(
        archive: Season1Loader.load(),
        seasonId: 's1',
        seasonLabel: Season1Meta.seasonLabel,
        playerId: playerId,
        name: name,
      );

  static Future<CareerPlayer?> fromSeason2Assets({
    String? playerId,
    String? name,
  }) =>
      _fromArchiveAssets(
        archive: Season2Loader.load(),
        seasonId: 's2',
        seasonLabel: Season2Meta.seasonLabel,
        playerId: playerId,
        name: name,
      );

  /// Prefer Season 2 + Season 1 merged for offline career view.
  static Future<CareerPlayer?> fromBundledAssets({
    String? playerId,
    String? name,
  }) async {
    final s2 = await fromSeason2Assets(playerId: playerId, name: name);
    final s1 = await fromSeason1Assets(playerId: playerId, name: name);
    if (s1 == null) return s2;
    if (s2 == null) return s1;
    return CareerPlayer(
      id: s2.id.isNotEmpty ? s2.id : s1.id,
      name: s2.name.isNotEmpty ? s2.name : s1.name,
      seasons: {...s1.seasons, ...s2.seasons},
    );
  }

  static Future<CareerPlayer?> _fromArchiveAssets({
    required Future<Season1Archive> archive,
    required String seasonId,
    required String seasonLabel,
    String? playerId,
    String? name,
  }) async {
    final data = await archive;
    String? id = playerId;
    String resolvedName = name ?? '';
    String team = '';

    CareerBatting? batting;
    CareerBowling? bowling;
    CareerFielding? fielding;
    CareerMvp? mvp;
    final teams = <String>{};

    final nameQuery = name;
    bool hitId(String rowId) => id != null && id.isNotEmpty && rowId == id;
    bool hitName(String rowName) =>
        nameQuery != null &&
        nameQuery.isNotEmpty &&
        _nameMatch(rowName, nameQuery);

    for (final r in data.batting) {
      if (hitId(r.playerId) || hitName(r.name)) {
        id ??= r.playerId;
        resolvedName = r.name;
        team = r.teamName;
        teams.add(r.teamName);
        final prev = batting;
        batting = CareerBatting(
          matches: (prev?.matches ?? 0) + r.matches,
          innings: (prev?.innings ?? 0) + r.innings,
          runs: (prev?.runs ?? 0) + r.runs,
          highest: prev == null
              ? r.highest
              : (prev.highest >= r.highest ? prev.highest : r.highest),
          average: r.average,
          strikeRate: r.strikeRate,
          fours: (prev?.fours ?? 0) + r.fours,
          sixes: (prev?.sixes ?? 0) + r.sixes,
        );
      }
    }
    for (final r in data.bowling) {
      if (hitId(r.playerId) || hitName(r.name)) {
        id ??= r.playerId;
        resolvedName = resolvedName.isEmpty ? r.name : resolvedName;
        teams.add(r.teamName);
        final prev = bowling;
        bowling = CareerBowling(
          matches: (prev?.matches ?? 0) + r.matches,
          innings: (prev?.innings ?? 0) + r.innings,
          wickets: (prev?.wickets ?? 0) + r.wickets,
          overs: r.overs,
          maidens: (prev?.maidens ?? 0) + r.maidens,
          runs: (prev?.runs ?? 0) + r.runs,
          economy: r.economy,
          best: prev == null
              ? r.best
              : (prev.best >= r.best ? prev.best : r.best),
        );
      }
    }
    for (final r in data.fielding) {
      if (hitId(r.playerId) || hitName(r.name)) {
        id ??= r.playerId;
        resolvedName = resolvedName.isEmpty ? r.name : resolvedName;
        teams.add(r.teamName);
        final prev = fielding;
        fielding = CareerFielding(
          matches: (prev?.matches ?? 0) + r.matches,
          catches: (prev?.catches ?? 0) + r.catches,
          runOuts: (prev?.runOuts ?? 0) + r.runOuts,
          stumpings: (prev?.stumpings ?? 0) + r.stumpings,
          totalDismissals: (prev?.totalDismissals ?? 0) + r.totalDismissals,
        );
      }
    }

    final key = nameKey(resolvedName.isEmpty ? (name ?? '') : resolvedName);
    if (key.isNotEmpty) {
      for (final r in data.mvp) {
        if (_nameMatch(r.name, key) ||
            nameKey(r.name) == key ||
            nameKey(r.name).contains(key) ||
            key.contains(nameKey(r.name))) {
          teams.add(r.teamName);
          final prev = mvp;
          mvp = CareerMvp(
            matches: prev == null
                ? r.matches
                : (prev.matches >= r.matches ? prev.matches : r.matches),
            battingPts: (prev?.battingPts ?? 0) + r.battingPts,
            bowlingPts: (prev?.bowlingPts ?? 0) + r.bowlingPts,
            fieldingPts: (prev?.fieldingPts ?? 0) + r.fieldingPts,
            total: (prev?.total ?? 0) + r.total,
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
        seasonId: CareerSeasonStats(
          seasonId: seasonId,
          seasonLabel: seasonLabel,
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
