import 'io_bytes_stub.dart'
    if (dart.library.io) 'io_bytes_io.dart' as impl;

Future<List<int>?> readPathBytes(String? path) => impl.readPathBytes(path);

Future<String?> readPathString(String? path) => impl.readPathString(path);

Future<String> writeAppFile({
  required String relativeDir,
  required String fileName,
  required List<int> bytes,
}) =>
    impl.writeAppFile(
      relativeDir: relativeDir,
      fileName: fileName,
      bytes: bytes,
    );
