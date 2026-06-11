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

class PrepCostNotice extends StatelessWidget {
  const PrepCostNotice({
    required this.cost,
    required this.balance,
    super.key,
  });

  final int cost;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final hasEnoughCredits = balance >= cost;
    final balanceAfter = balance - cost;
    final color = hasEnoughCredits ? PrepTheme.warning : PrepTheme.error;
    final title = hasEnoughCredits
        ? 'Spend $cost credits before saving'
        : 'Need $cost credits to save';
    final detail = hasEnoughCredits
        ? 'Balance after save: $balanceAfter credits.'
        : 'Current balance: $balance credits. Add credits in Store first.';

    return Semantics(
      liveRegion: true,
      label: '$title. $detail',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.46)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasEnoughCredits
                  ? Icons.local_activity_outlined
                  : Icons.error_outline,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
