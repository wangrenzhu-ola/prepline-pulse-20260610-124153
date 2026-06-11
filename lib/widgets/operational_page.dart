import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../theme/prep_theme.dart';

class OperationalPage extends StatelessWidget {
  const OperationalPage({
    required this.pageId,
    required this.title,
    required this.children,
    this.actions = const [],
    super.key,
  });

  final String pageId;
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final visualAsset = _visualAssetFor(pageId);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _OperationalHero(
                pageId: pageId,
                title: title,
                assetPath: visualAsset,
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  String _visualAssetFor(String pageId) {
    switch (pageId) {
      case 'batch-detail':
      case 'batch-detail_detail':
      case 'state-entry':
      case 'state-entry_detail':
        return batchAsset;
      case 'line-board':
      case 'line-board_detail':
      case 'station-timeline':
      case 'exception-queue':
      case 'prep-rules':
      default:
        return heroAsset;
    }
  }
}

class _OperationalHero extends StatelessWidget {
  const _OperationalHero({
    required this.pageId,
    required this.title,
    required this.assetPath,
  });

  final String pageId;
  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'page_id source marker: $pageId',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.asset(assetPath, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.08),
                      PrepTheme.background.withOpacity(.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'page_id: $pageId',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
