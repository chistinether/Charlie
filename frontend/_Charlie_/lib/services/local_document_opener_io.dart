import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// Mobile/desktop: documents are only kept as bytes (see UserDocument),
// since that's what we persist locally. To open one with the OS's normal
// viewer/app via open_filex, write it out to a temp file first, then open
// that file's path.
Future<bool> openLocalDocument(String name, Uint8List bytes) async {
  try {
    final dir = await getTemporaryDirectory();
    final safeName = name.replaceAll(RegExp(r'[\\/]'), "_");
    final file = File("${dir.path}/$safeName");

    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}
