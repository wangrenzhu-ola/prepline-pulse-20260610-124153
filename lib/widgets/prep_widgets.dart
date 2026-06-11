import 'dart:io';

import 'package:flutter/material.dart';

import '../config/app_brand.dart';
import '../models/prep_models.dart';
import '../screens/about_screen.dart';
import '../screens/exception_queue_screen.dart';
import '../screens/station_timeline_screen.dart';
import '../state/prep_board_controller.dart';
import '../theme/prep_theme.dart';

class PrepScaffold extends StatelessWidget {
  const PrepScaffold({
    required this.contract,
    required this.children,
    this.hero,
    super.key,
  });

  final PageContract contract;
  final Widget? hero;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppBrand.name),
        backgroundColor: PrepTheme.background,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF171219),
              PrepTheme.background,
              Color(0xFF111C18),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              ContractMarker(contract: contract),
              hero ?? ContractHero(contract: contract),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class ContractMarker extends StatelessWidget {
  const ContractMarker({required this.contract, super.key});
  final PageContract contract;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'page_id=${contract.pageId}; route_name=${contract.routeName}; widget_class=${contract.widgetClass}; state_key=${contract.stateKey}',
      child: const SizedBox.shrink(),
    );
  }
}

class ContractHero extends StatelessWidget {
  const ContractHero({required this.contract, super.key});
  final PageContract contract;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2824), Color(0xFF62235B), Color(0xFF101014)],
        ),
        border: Border.all(color: PrepTheme.gold.withOpacity(.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .34,
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.2,
                  colors: [
                    Color(0xFF38221E),
                    Color(0xFF101014),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 42,
                  color: PrepTheme.gold.withOpacity(.70),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 110, 18, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  PrepTheme.background.withOpacity(.90),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract.pageId,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  contract.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(contract.purpose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {this.color = PrepTheme.gold, super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(.16),
      side: BorderSide(color: color.withOpacity(.35)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class MediaRecordPanel extends StatelessWidget {
  const MediaRecordPanel({
    required this.attachedTo,
    required this.hero,
    super.key,
  });
  final String attachedTo;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final media = controller.mediaFor(attachedTo);
    return InfoCard(
      title: 'User media readback',
      trailing: TextButton.icon(
        onPressed: () => controller.uploadMedia(attachedTo),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Upload'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.mediaReadback != null) ...[
            Text(
              controller.mediaReadback!,
              key: const Key('media-readback'),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: hero ? 220 : 120,
            child: media.isEmpty
                ? const Center(child: Text('No media attached'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = media[index];
                      return SizedBox(
                        width: hero ? 260 : 150,
                        child: _MediaTile(item: item),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: media.length,
                  ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final item in media.take(1)) ...[
                OutlinedButton.icon(
                  onPressed: item.storedInDocuments
                      ? null
                      : () => controller.replaceMedia(item.id),
                  icon: const Icon(Icons.change_circle_outlined),
                  label: const Text('Replace'),
                ),
                OutlinedButton.icon(
                  onPressed: item.storedInDocuments
                      ? () => _exportToPhotos(context, controller, item)
                      : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Export proof'),
                ),
                OutlinedButton.icon(
                  onPressed: () => controller.deleteMedia(item.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ],
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

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item});

  final MediaRecord item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.storedInDocuments)
            FutureBuilder<String>(
              future: PrepBoardScope.of(context).fullMediaPath(item),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                    color: PrepTheme.elevated,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                );
              },
            )
          else
            const ColoredBox(
              color: PrepTheme.elevated,
              child: Icon(Icons.image_not_supported_outlined),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              color: Colors.black.withOpacity(.58),
              padding: const EdgeInsets.all(8),
              child: Text(item.label, maxLines: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class BatchSummary extends StatelessWidget {
  const BatchSummary({required this.batch, super.key});
  final PrepBatch batch;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusChip(
          batch.state,
          color: batch.blocked ? PrepTheme.error : PrepTheme.success,
        ),
        StatusChip(batch.station),
        StatusChip('Owner ${batch.owner}'),
        StatusChip('${batch.quantity} portions'),
        StatusChip(batch.serviceWindow),
      ],
    );
  }
}

class UtilityLinks extends StatelessWidget {
  const UtilityLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, StationTimelineScreen.routeName),
          child: const Text('Timeline'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, ExceptionQueueScreen.routeName),
          child: const Text('Exceptions'),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AboutScreen.routeName),
          child: const Text('About'),
        ),
      ],
    );
  }
}
