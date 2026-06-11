class PulseStoreProduct {
  const PulseStoreProduct({
    required this.id,
    required this.amount,
    required this.referencePrice,
    required this.promotion,
  });

  final String id;
  final int amount;
  final String referencePrice;
  final bool promotion;

  String get title => promotion ? 'Rush pack $id' : 'Prep pack $id';
}

enum PulsePurchaseState { success, cancelled, pending, failed, unavailable }

class PulsePurchaseResult {
  const PulsePurchaseResult({
    required this.state,
    required this.message,
    this.balance,
  });

  final PulsePurchaseState state;
  final String message;
  final int? balance;

  bool get credited => state == PulsePurchaseState.success;
}

const pulseStoreCatalog = <PulseStoreProduct>[
  PulseStoreProduct(
      id: '850221000', amount: 100, referencePrice: '\$0.99', promotion: false),
  PulseStoreProduct(
      id: '850221001', amount: 398, referencePrice: '\$3.99', promotion: false),
  PulseStoreProduct(
      id: '850221002', amount: 500, referencePrice: '\$4.99', promotion: false),
  PulseStoreProduct(
      id: '850221003', amount: 600, referencePrice: '\$5.99', promotion: false),
  PulseStoreProduct(
      id: '850221004', amount: 900, referencePrice: '\$8.99', promotion: false),
  PulseStoreProduct(
      id: '850221005',
      amount: 1160,
      referencePrice: '\$9.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221006',
      amount: 1200,
      referencePrice: '\$11.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221007',
      amount: 1560,
      referencePrice: '\$12.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221008',
      amount: 1980,
      referencePrice: '\$15.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221009',
      amount: 2500,
      referencePrice: '\$19.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221010',
      amount: 3160,
      referencePrice: '\$24.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221011',
      amount: 3900,
      referencePrice: '\$29.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221012',
      amount: 5600,
      referencePrice: '\$39.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221013',
      amount: 7500,
      referencePrice: '\$49.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221014',
      amount: 13600,
      referencePrice: '\$79.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221015',
      amount: 18800,
      referencePrice: '\$99.99',
      promotion: false),
  PulseStoreProduct(
      id: '850221016', amount: 580, referencePrice: '\$1.99', promotion: true),
  PulseStoreProduct(
      id: '850221017', amount: 750, referencePrice: '\$2.99', promotion: true),
  PulseStoreProduct(
      id: '850221018', amount: 1080, referencePrice: '\$4.99', promotion: true),
  PulseStoreProduct(
      id: '850221019', amount: 1280, referencePrice: '\$5.99', promotion: true),
  PulseStoreProduct(
      id: '850221020', amount: 2100, referencePrice: '\$9.99', promotion: true),
  PulseStoreProduct(
      id: '850221021',
      amount: 2560,
      referencePrice: '\$11.99',
      promotion: true),
  PulseStoreProduct(
      id: '850221022',
      amount: 2780,
      referencePrice: '\$12.99',
      promotion: true),
  PulseStoreProduct(
      id: '850221023',
      amount: 4360,
      referencePrice: '\$19.99',
      promotion: true),
  PulseStoreProduct(
      id: '850221024',
      amount: 7500,
      referencePrice: '\$39.99',
      promotion: true),
];

Set<String> get pulseStoreProductIds =>
    pulseStoreCatalog.map((product) => product.id).toSet();

PulseStoreProduct? pulseProductForId(String id) {
  for (final product in pulseStoreCatalog) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}
