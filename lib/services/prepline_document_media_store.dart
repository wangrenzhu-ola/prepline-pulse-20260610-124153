import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:gal/gal.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../config/app_brand.dart';

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

  Future<void> exportProofCardToGallery({
    required String photoRelativePath,
    required String batchId,
    required String batchName,
    required String station,
    required String state,
    required String owner,
    required String note,
    required String exportedAt,
  }) async {
    final photoFile = await rebuildFile(photoRelativePath);
    final photo = await _decodeImage(await photoFile.readAsBytes());
    final cardBytes = await _buildProofCardPng(
      photo: photo,
      batchId: batchId,
      batchName: batchName,
      station: station,
      state: state,
      owner: owner,
      note: note,
      exportedAt: exportedAt,
    );
    final output = await _temporaryExportFile();
    await output.parent.create(recursive: true);
    await output.writeAsBytes(cardBytes, flush: true);
    await Gal.putImage(output.path, album: AppBrand.photosAlbumName);
  }

  bool isRelativePath(String value) =>
      value.isNotEmpty && path.isRelative(value) && !value.startsWith('..');

  Future<File> _temporaryExportFile() async {
    final directory = await getTemporaryDirectory();
    return File(
      path.join(
        directory.path,
        'telta_proof_${DateTime.now().microsecondsSinceEpoch}.png',
      ),
    );
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _buildProofCardPng({
    required ui.Image photo,
    required String batchId,
    required String batchName,
    required String station,
    required String state,
    required String owner,
    required String note,
    required String exportedAt,
  }) async {
    const width = 1080.0;
    const height = 1500.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(width, height);
    final photoRect = const Rect.fromLTWH(0, 0, width, 860);

    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF101014),
      )
      ..drawImageRect(
        photo,
        _coverSourceRect(photo, photoRect),
        photoRect,
        Paint()..filterQuality = FilterQuality.high,
      )
      ..drawRect(
        photoRect,
        Paint()..color = const Color(0x66000000),
      );

    final panel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(54, 660, 972, 720),
      const Radius.circular(36),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = const Color(0xEE1B1A22),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x66E09B46),
    );

    _drawText(
      canvas,
      AppBrand.proofCardTitle,
      const Offset(90, 710),
      maxWidth: 900,
      fontSize: 34,
      color: const Color(0xFFE09B46),
      weight: FontWeight.w800,
    );
    _drawText(
      canvas,
      '$batchId $batchName',
      const Offset(90, 775),
      maxWidth: 900,
      fontSize: 54,
      color: const Color(0xFFF4EFE7),
      weight: FontWeight.w900,
      maxLines: 2,
    );
    _drawText(
      canvas,
      '$state  |  $station  |  Owner $owner',
      const Offset(90, 920),
      maxWidth: 900,
      fontSize: 36,
      color: const Color(0xFFF4EFE7),
      weight: FontWeight.w700,
      maxLines: 2,
    );
    _drawText(
      canvas,
      'Exported $exportedAt',
      const Offset(90, 1012),
      maxWidth: 900,
      fontSize: 30,
      color: const Color(0xFFBDB6AA),
      weight: FontWeight.w600,
    );
    _drawText(
      canvas,
      note,
      const Offset(90, 1095),
      maxWidth: 900,
      fontSize: 36,
      color: const Color(0xFFE8E1D6),
      weight: FontWeight.w600,
      maxLines: 4,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Rect _coverSourceRect(ui.Image image, Rect destination) {
    final imageRatio = image.width / image.height;
    final destinationRatio = destination.width / destination.height;
    if (imageRatio > destinationRatio) {
      final sourceWidth = image.height * destinationRatio;
      final left = (image.width - sourceWidth) / 2;
      return Rect.fromLTWH(left, 0, sourceWidth, image.height.toDouble());
    }
    final sourceHeight = image.width / destinationRatio;
    final top = (image.height - sourceHeight) / 2;
    return Rect.fromLTWH(0, top, image.width.toDouble(), sourceHeight);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w400,
    int maxLines = 1,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.16,
        ),
      ),
      maxLines: maxLines,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }
}
