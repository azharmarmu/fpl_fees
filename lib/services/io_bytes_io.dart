import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<List<int>?> readPathBytes(String? path) async {
  if (path == null || path.isEmpty) return null;
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}

Future<String?> readPathString(String? path) async {
  if (path == null || path.isEmpty) return null;
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsString();
}

Future<String> writeAppFile({
  required String relativeDir,
  required String fileName,
  required List<int> bytes,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final folder = Directory('${dir.path}/$relativeDir');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  final safe = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  final local = File('${folder.path}/$safe');
  await local.writeAsBytes(bytes, flush: true);
  return local.path;
}
