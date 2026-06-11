import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prep_models.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';

class PrepMediaPreview extends StatelessWidget {
  const PrepMediaPreview({required this.record, super.key});

  final MediaRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.storedInDocuments) {
      return _DocumentImageMediaPreview(record: record);
    }
    if (_isImage(record.assetPath)) {
      return _ImageMediaPreview(record: record);
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

class _ImageMediaPreview extends StatelessWidget {
  const _ImageMediaPreview({required this.record});

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              record.assetPath,
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
                Text('Image: ${record.assetPath}'),
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
