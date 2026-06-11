import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_brand.dart';
import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';

class PrimaryProofHero extends StatelessWidget {
  const PrimaryProofHero({
    required this.attachedTo,
    required this.title,
    super.key,
  });

  final String attachedTo;
  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final media = controller.primaryUserMediaFor(attachedTo);
    final exporting =
        media != null && controller.activeAlbumExportMediaId == media.id;
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < 600;
    final height = (viewport.height * (compact ? .50 : .42))
        .clamp(compact ? 380.0 : 340.0, compact ? 520.0 : 500.0)
        .toDouble();
    return Container(
      key: Key('primary-proof-hero-$attachedTo'),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PrepTheme.gold.withOpacity(.30)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF211719),
            Color(0xFF111C18),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media == null)
            _EmptyProofSurface(attachedTo: attachedTo)
          else
            _DocumentProofImage(record: media, attachedTo: attachedTo),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.05),
                    Colors.black.withOpacity(.76),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  media == null
                      ? 'Upload one proof photo for Board, Batch, and Photos.'
                      : controller.mediaReadback ??
                          'Shared proof photo. Export creates a proof card.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (media == null)
                      FilledButton.icon(
                        key: Key('primary-proof-upload-$attachedTo'),
                        onPressed: () => controller.uploadMedia(attachedTo),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Upload proof photo'),
                      )
                    else ...[
                      OutlinedButton.icon(
                        key: Key('primary-proof-save-$attachedTo'),
                        onPressed: exporting
                            ? null
                            : () => _exportToPhotos(
                                  context,
                                  controller,
                                  media,
                                ),
                        icon: exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label:
                            Text(exporting ? 'Exporting...' : 'Export proof'),
                      ),
                      OutlinedButton.icon(
                        key: Key('primary-proof-upload-$attachedTo'),
                        onPressed: () => controller.uploadMedia(attachedTo),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Replace photo'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPhotos(
    BuildContext context,
    PrepBoardController controller,
    MediaRecord media,
  ) async {
    final exported = await controller.exportProofCardToAlbum(media.id);
    if (!context.mounted) {
      return;
    }
    final message = controller.mediaReadback ??
        (exported
            ? 'Exported proof card to Photos album: ${AppBrand.photosAlbumName}.'
            : 'Export failed.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _EmptyProofSurface extends StatelessWidget {
  const _EmptyProofSurface({required this.attachedTo});

  final String attachedTo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('primary-proof-empty-$attachedTo'),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.1,
          colors: [
            Color(0xFF3A2C1E),
            Color(0xFF151416),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PrepTheme.gold.withOpacity(.35)),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 38,
            color: PrepTheme.gold,
          ),
        ),
      ),
    );
  }
}

class _DocumentProofImage extends StatelessWidget {
  const _DocumentProofImage({
    required this.record,
    required this.attachedTo,
  });

  final MediaRecord record;
  final String attachedTo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: PrepBoardScope.of(context).fullMediaPath(record),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return Image.file(
          File(path),
          key: Key('primary-proof-image-$attachedTo'),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: PrepTheme.elevated,
            child: Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}

class SavedProofThumbnail extends StatelessWidget {
  const SavedProofThumbnail({
    required this.log,
    this.compact = false,
    super.key,
  });

  final PrepLog log;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final proofPath = log.proofImagePath;
    if (proofPath == null || proofPath.isEmpty) {
      return Row(
        key: Key('saved-proof-empty-${log.savedAt}-${log.batchId}'),
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image_not_supported_outlined, size: 16),
          SizedBox(width: 6),
          Text('No saved photo'),
        ],
      );
    }
    final controller = PrepBoardScope.of(context);
    final record = MediaRecord(
      id: 'saved-proof-${log.savedAt}-${log.batchId}',
      assetPath: proofPath,
      label: 'Saved proof photo',
      attachedTo: 'saved-record',
      storedInDocuments: true,
    );
    return FutureBuilder<String>(
      future: controller.fullMediaPath(record),
      builder: (context, snapshot) {
        final path = snapshot.data;
        final viewport = MediaQuery.sizeOf(context);
        final height = compact
            ? 56.0
            : (viewport.height * .24).clamp(180.0, 260.0).toDouble();
        return ClipRRect(
          key: Key('saved-proof-thumbnail-${log.savedAt}-${log.batchId}'),
          borderRadius: BorderRadius.circular(8),
          child: path == null
              ? SizedBox(
                  key: Key('saved-proof-loading-${log.savedAt}-${log.batchId}'),
                  height: height,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Image.file(
                  File(path),
                  key: Key('saved-proof-image-${log.savedAt}-${log.batchId}'),
                  height: height,
                  width: compact ? 84 : double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: height,
                    width: compact ? 84 : double.infinity,
                    color: PrepTheme.error.withOpacity(.12),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
        );
      },
    );
  }
}

class PrepMediaPreview extends StatelessWidget {
  const PrepMediaPreview({required this.record, super.key});

  final MediaRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.storedInDocuments) {
      return _DocumentImageMediaPreview(record: record);
    }
    if (_isImage(record.assetPath)) {
      return _AssetImageHiddenPreview(record: record);
    }
    return FutureBuilder<String>(
      future: rootBundle.loadString(record.assetPath),
      builder: (context, snapshot) {
        final exists = snapshot.hasData;
        final preview =
            exists ? snapshot.data!.split('\n').first : 'Loading asset';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PrepTheme.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PrepTheme.gold.withOpacity(.26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PrepTheme.gold.withOpacity(.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  exists ? Icons.text_snippet_outlined : Icons.hourglass_empty,
                  color: PrepTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Asset: ${record.assetPath}'),
                    const SizedBox(height: 6),
                    Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isImage(String assetPath) {
    final lower = assetPath.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}

class _DocumentImageMediaPreview extends StatelessWidget {
  const _DocumentImageMediaPreview({required this.record});

  final MediaRecord record;

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    return FutureBuilder<String>(
      future: controller.fullMediaPath(record),
      builder: (context, snapshot) {
        final path = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PrepTheme.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PrepTheme.gold.withOpacity(.26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: path == null
                    ? const SizedBox(
                        width: 96,
                        height: 72,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Image.file(
                        File(path),
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 96,
                          height: 72,
                          color: PrepTheme.error.withOpacity(.12),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Relative image: ${record.assetPath}'),
                    const SizedBox(height: 6),
                    Text('Attached to ${record.attachedTo}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssetImageHiddenPreview extends StatelessWidget {
  const _AssetImageHiddenPreview({required this.record});

  final MediaRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PrepTheme.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PrepTheme.gold.withOpacity(.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PrepTheme.gold.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PrepTheme.gold.withOpacity(.24)),
            ),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload required',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text('Built-in asset images are hidden.'),
                const SizedBox(height: 6),
                Text('Attached to ${record.attachedTo}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
