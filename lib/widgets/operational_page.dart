import 'package:flutter/material.dart';

import '../theme/prep_theme.dart';
import 'media_widgets.dart';

class OperationalPage extends StatelessWidget {
  const OperationalPage({
    required this.pageId,
    required this.title,
    required this.children,
    this.actions = const [],
    this.mediaTarget,
    this.showHero = true,
    super.key,
  });

  final String pageId;
  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final String? mediaTarget;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
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
              if (showHero) ...[
                if (mediaTarget == null)
                  _OperationalHero(pageId: pageId, title: title)
                else
                  PrimaryProofHero(attachedTo: mediaTarget!, title: title),
                const SizedBox(height: 12),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationalHero extends StatelessWidget {
  const _OperationalHero({
    required this.pageId,
    required this.title,
  });

  final String pageId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'page_id source marker: $pageId',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      Color(0xFF39261C),
                      Color(0xFF141517),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.dataset_outlined,
                    size: 42,
                    color: PrepTheme.gold.withOpacity(.72),
                  ),
                ),
              ),
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
