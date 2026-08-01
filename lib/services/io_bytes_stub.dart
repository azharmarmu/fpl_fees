Future<List<int>?> readPathBytes(String? path) async => null;

Future<String?> readPathString(String? path) async => null;

Future<String> writeAppFile({
  required String relativeDir,
  required String fileName,
  required List<int> bytes,
}) async {
  throw UnsupportedError('Local file storage is not available on this platform');
}
