import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PreplineDocumentMediaStore {
  Future<String> saveBytes({
    required Uint8List bytes,
    required String folder,
    required String extension,
  }) async {
    final cleanFolder = folder.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleanExtension = extension.replaceAll('.', '');
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$cleanExtension';
    final relativePath = path.join(cleanFolder, fileName);
    final file = await rebuildFile(relativePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relativePath;
  }

  Future<File> rebuildFile(String relativePath) async {
    if (!isRelativePath(relativePath)) {
      throw ArgumentError('Only relative media paths are supported.');
    }
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, relativePath));
  }

  Future<void> deleteRelativePath(String relativePath) async {
    final file = await rebuildFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> saveRelativePathToGallery(String relativePath) async {
    final file = await rebuildFile(relativePath);
    await Gal.putImage(file.path, album: 'PrepLine Pulse');
  }

  bool isRelativePath(String value) =>
      value.isNotEmpty && path.isRelative(value) && !value.startsWith('..');
}
