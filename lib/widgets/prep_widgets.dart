import 'package:flutter/material.dart';

import '../models/prep_models.dart';
import '../screens/about_screen.dart';
import '../screens/exception_queue_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/station_timeline_screen.dart';
import '../state/prep_line_state.dart';
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
        title: const Text('PrepLine Pulse'),
        backgroundColor: PrepTheme.background,
        actions: [
          IconButton(
            tooltip: 'Onboarding',
            onPressed: () =>
                Navigator.pushNamed(context, OnboardingScreen.routeName),
            icon: const Icon(Icons.school_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.routeName),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ContractMarker(contract: contract),
            hero ?? ContractHero(contract: contract),
            const SizedBox(height: 16),
            ...children,
          ],
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
  const ContractHero({required this.contract, this.assetPath, super.key});
  final PageContract contract;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final hasImage = assetPath != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2824), Color(0xFF62235B), Color(0xFF101014)],
        ),
        border: Border.all(color: PrepTheme.gold.withValues(alpha: .24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasImage)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .32,
              width: double.infinity,
              child: Image.asset(assetPath!, fit: BoxFit.cover),
            ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, hasImage ? 110 : 24, 18, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  PrepTheme.background.withValues(alpha: hasImage ? .90 : .08),
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
                ?trailing,
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
      backgroundColor: color.withValues(alpha: .16),
      side: BorderSide(color: color.withValues(alpha: .35)),
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
    final controller = PrepLineScope.of(context);
    final media = controller.mediaFor(attachedTo);
    return InfoCard(
      title: 'User media readback',
      trailing: TextButton.icon(
        onPressed: () => controller.addMedia(attachedTo),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Attach'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(item.assetPath, fit: BoxFit.cover),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  color: Colors.black.withValues(alpha: .58),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(item.label, maxLines: 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemCount: media.length,
                  ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final item in media.take(1)) ...[
                OutlinedButton.icon(
                  onPressed: () => controller.replaceMedia(item.id),
                  icon: const Icon(Icons.change_circle_outlined),
                  label: const Text('Replace'),
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
