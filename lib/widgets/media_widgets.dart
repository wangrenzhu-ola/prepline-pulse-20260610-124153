import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prep_models.dart';
import '../theme/prep_theme.dart';

class PrepMediaPreview extends StatelessWidget {
  const PrepMediaPreview({required this.record, super.key});

  final MediaRecord record;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(record.assetPath),
      builder: (context, snapshot) {
        final exists = snapshot.hasData;
        final preview = exists ? snapshot.data!.split('\n').first : 'Loading asset';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PrepTheme.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PrepTheme.gold.withValues(alpha: .26)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PrepTheme.gold.withValues(alpha: .14),
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
}
