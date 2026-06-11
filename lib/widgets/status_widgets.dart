import 'package:flutter/material.dart';

import '../theme/prep_theme.dart';

class PrepStatusPill extends StatelessWidget {
  const PrepStatusPill(
    this.label, {
    this.color = PrepTheme.gold,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmationBanner extends StatelessWidget {
  const ConfirmationBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Visible confirmation: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PrepTheme.success.withOpacity(.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PrepTheme.success.withOpacity(.34)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: PrepTheme.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
