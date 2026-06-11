import 'package:flutter/material.dart';

import '../models/pulse_store_models.dart';
import '../state/prep_board_controller.dart';
import '../widgets/operational_page.dart';
import '../theme/prep_theme.dart';
import '../widgets/prep_widgets.dart';

// page_id: pulse-store | route_name: /pulse-store | widget_class: PulseStoreScreen | state_key: pulseStoreState
class PulseStoreScreen extends StatelessWidget {
  const PulseStoreScreen({super.key});

  static const routeName = '/pulse-store';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final visibleProducts = pulseStoreCatalog
        .where((product) => _visibleProductIds.contains(product.id))
        .toList(growable: false);
    return OperationalPage(
      pageId: 'pulse-store',
      title: 'Store',
      showHero: false,
      children: [
        InfoCard(
          title: 'Prep credits',
          trailing: StatusChip('${controller.pulseCredits} credits'),
          child: Text(
            controller.storeReadback ??
                'Credits are used only when saving a verified batch state.',
            key: const Key('pulse-store-readback'),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 1;
            return GridView.builder(
              key: const Key('pulse-store-product-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 3.4 : 1.55,
              ),
              itemBuilder: (context, index) {
                final product = visibleProducts[index];
                return _PulseProductCard(
                  product: product,
                  busy: controller.activePurchaseProductId == product.id,
                  disabled: controller.storeBusy &&
                      controller.activePurchaseProductId != product.id,
                  onBuy: () => _confirmPurchase(context, controller, product),
                );
              },
            );
          },
        ),
      ],
    );
  }

  static const _visibleProductIds = {
    '473900',
    '473904',
    '473908',
    '473919',
    '473923',
    '473926',
  };

  Future<void> _confirmPurchase(
    BuildContext context,
    PrepBoardController controller,
    PulseStoreProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(product.title),
          content: Text(
            'Add ${product.amount} prep credits for ${product.referencePrice}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Buy'),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      await controller.purchasePulseProduct(product);
    }
  }
}

class _PulseProductCard extends StatelessWidget {
  const _PulseProductCard({
    required this.product,
    required this.busy,
    required this.disabled,
    required this.onBuy,
  });

  final PulseStoreProduct product;
  final bool busy;
  final bool disabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final color = product.promotion ? PrepTheme.gold : PrepTheme.violet;
    return Card(
      child: InkWell(
        onTap: disabled || busy ? null : onBuy,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _PulseMark(color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.amount} credits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${product.referencePrice}  #${product.id}'),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.add_circle_outline, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMark extends StatelessWidget {
  const _PulseMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.32)),
      ),
      child: SizedBox(
        height: 46,
        width: 46,
        child: CustomPaint(painter: _PulseMarkPainter(color)),
      ),
    );
  }
}

class _PulseMarkPainter extends CustomPainter {
  const _PulseMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * .50, size.height * .12)
      ..lineTo(size.width * .68, size.height * .42)
      ..lineTo(size.width * .88, size.height * .46)
      ..lineTo(size.width * .62, size.height * .62)
      ..lineTo(size.width * .54, size.height * .88)
      ..lineTo(size.width * .40, size.height * .62)
      ..lineTo(size.width * .14, size.height * .48)
      ..lineTo(size.width * .36, size.height * .42)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
