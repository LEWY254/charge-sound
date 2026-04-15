import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> ensureRecordingsDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/recordings');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> ensureUserFilesDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/user_files');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
