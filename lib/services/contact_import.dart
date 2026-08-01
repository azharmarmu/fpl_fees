import '../models/models.dart';

/// Result of importing phones / usernames from CSV or pasted lines.
class ContactImportResult {
  const ContactImportResult({
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int updated;
  final int skipped;
  final List<String> errors;
}

/// Parses CSV / TSV / "name,phone,username" paste for bulk contact update.
///
/// Supported headers (case-insensitive):
/// - `id,phone,username`
/// - `name,phone,username`
/// - `id,name,phone,username`
///
/// Without a header, each line is treated as `name,phone[,username]`.
class ContactImporter {
  /// Apply [csv] onto [players]; returns updated player list + stats.
  static (List<FplPlayer> players, ContactImportResult result) apply({
    required List<FplPlayer> players,
    required String csv,
  }) {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();

    if (lines.isEmpty) {
      return (
        players,
        const ContactImportResult(
          updated: 0,
          skipped: 0,
          errors: ['Nothing to import'],
        ),
      );
    }

    var start = 0;
    var mode = _Mode.namePhoneUser;
    final header = lines.first.toLowerCase();
    if (header.contains('phone') || header.contains('id') || header.contains('name')) {
      mode = _detectMode(header);
      start = 1;
    }

    final out = [...players];
    var updated = 0;
    var skipped = 0;
    final errors = <String>[];

    for (var i = start; i < lines.length; i++) {
      final cols = _splitRow(lines[i]);
      if (cols.isEmpty) continue;

      String? id;
      String? name;
      String? phone;
      String? username;

      switch (mode) {
        case _Mode.idPhoneUser:
          if (cols.length < 2) {
            errors.add('Line ${i + 1}: need id,phone');
            skipped++;
            continue;
          }
          id = cols[0].trim();
          phone = cols[1].trim();
          username = cols.length > 2 ? cols[2].trim() : null;
        case _Mode.namePhoneUser:
          if (cols.length < 2) {
            errors.add('Line ${i + 1}: need name,phone');
            skipped++;
            continue;
          }
          name = cols[0].trim();
          phone = cols[1].trim();
          username = cols.length > 2 ? cols[2].trim() : null;
        case _Mode.idNamePhoneUser:
          if (cols.length < 3) {
            errors.add('Line ${i + 1}: need id,name,phone');
            skipped++;
            continue;
          }
          id = cols[0].trim();
          name = cols[1].trim();
          phone = cols[2].trim();
          username = cols.length > 3 ? cols[3].trim() : null;
      }

      final idx = _findIndex(out, id: id, name: name);
      if (idx < 0) {
        errors.add(
          'Line ${i + 1}: no match for ${id ?? name ?? "?"}',
        );
        skipped++;
        continue;
      }

      final p = out[idx];
      out[idx] = p.copyWith(
        phone: phone,
        cricheroesUsername:
            (username == null || username.isEmpty) ? p.cricheroesUsername : username,
      );
      updated++;
    }

    return (
      out,
      ContactImportResult(updated: updated, skipped: skipped, errors: errors),
    );
  }

  /// CSV template for admins to fill.
  static String templateCsv(List<FplPlayer> players) {
    final buf = StringBuffer('id,name,phone,username\n');
    final sorted = [...players]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final p in sorted) {
      buf.writeln(
        '${_esc(p.id)},${_esc(p.name)},${_esc(p.phone)},${_esc(p.cricheroesUsername)}',
      );
    }
    return buf.toString();
  }

  static String _esc(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static _Mode _detectMode(String header) {
    final parts = _splitRow(header).map((e) => e.toLowerCase().trim()).toList();
    final hasId = parts.contains('id');
    final hasName = parts.contains('name');
    if (hasId && hasName) return _Mode.idNamePhoneUser;
    if (hasId) return _Mode.idPhoneUser;
    return _Mode.namePhoneUser;
  }

  static int _findIndex(
    List<FplPlayer> players, {
    String? id,
    String? name,
  }) {
    if (id != null && id.isNotEmpty) {
      final i = players.indexWhere((p) => p.id == id);
      if (i >= 0) return i;
    }
    if (name != null && name.isNotEmpty) {
      final key = name.toLowerCase();
      final i = players.indexWhere((p) => p.name.toLowerCase() == key);
      if (i >= 0) return i;
    }
    return -1;
  }

  static List<String> _splitRow(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if ((c == ',' || c == '\t' || c == ';') && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }
}

enum _Mode { idPhoneUser, namePhoneUser, idNamePhoneUser }
