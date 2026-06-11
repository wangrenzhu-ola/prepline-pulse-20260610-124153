import 'package:flutter/material.dart';

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
    final reservesBottomNavigation = MediaQuery.sizeOf(context).width < 760
        ? 132.0
        : 28.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: PrepTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, reservesBottomNavigation),
          children: [
            Semantics(
              label: 'page_id source marker: $pageId',
              child: Text(
                'page_id: $pageId',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
