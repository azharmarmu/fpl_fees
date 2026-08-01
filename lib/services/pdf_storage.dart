import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'io_bytes.dart';

/// Stores match scorecard PDFs locally and optionally on Firebase Storage.
class PdfStorage {
  PdfStorage({FirebaseStorage? storage}) : _storage = storage;

  FirebaseStorage? _storage;
  bool cloudEnabled = false;

  FirebaseStorage get storage => _storage ??= FirebaseStorage.instance;

  /// Persist [bytes] under a stable local path; upload to Storage when cloud on.
  Future<({String localPath, String? pdfUrl})> saveMatchPdf({
    required String matchId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    String localPath;
    try {
      localPath = await writeAppFile(
        relativeDir: 'scorecards',
        fileName: '${matchId}_$safe',
        bytes: bytes,
      );
    } catch (_) {
      localPath = 'memory:$matchId/$safe';
    }

    String? url;
    if (cloudEnabled) {
      try {
        final ref = storage.ref('scorecards/$matchId/$safe');
        await ref.putData(
          Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'application/pdf'),
        );
        url = await ref.getDownloadURL();
      } catch (e, st) {
        debugPrint('PDF Storage upload failed: $e\n$st');
      }
    }

    return (localPath: localPath, pdfUrl: url);
  }

  static String newMatchId() => const Uuid().v4();
}
