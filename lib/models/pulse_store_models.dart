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
      id: '473900', amount: 110, referencePrice: '\$0.99', promotion: false),
  PulseStoreProduct(
      id: '473901', amount: 210, referencePrice: '\$1.99', promotion: false),
  PulseStoreProduct(
      id: '473902', amount: 310, referencePrice: '\$2.99', promotion: false),
  PulseStoreProduct(
      id: '473903', amount: 400, referencePrice: '\$3.99', promotion: false),
  PulseStoreProduct(
      id: '473904', amount: 520, referencePrice: '\$4.99', promotion: false),
  PulseStoreProduct(
      id: '473905', amount: 630, referencePrice: '\$5.99', promotion: false),
  PulseStoreProduct(
      id: '473906', amount: 740, referencePrice: '\$6.99', promotion: false),
  PulseStoreProduct(
      id: '473907', amount: 1000, referencePrice: '\$8.99', promotion: false),
  PulseStoreProduct(
      id: '473908', amount: 1200, referencePrice: '\$9.99', promotion: false),
  PulseStoreProduct(
      id: '473909', amount: 1600, referencePrice: '\$12.99', promotion: false),
  PulseStoreProduct(
      id: '473910', amount: 2000, referencePrice: '\$15.99', promotion: false),
  PulseStoreProduct(
      id: '473911', amount: 2600, referencePrice: '\$19.99', promotion: false),
  PulseStoreProduct(
      id: '473912', amount: 3300, referencePrice: '\$24.99', promotion: false),
  PulseStoreProduct(
      id: '473913', amount: 4200, referencePrice: '\$29.99', promotion: false),
  PulseStoreProduct(
      id: '473914', amount: 4900, referencePrice: '\$34.99', promotion: false),
  PulseStoreProduct(
      id: '473915', amount: 6000, referencePrice: '\$39.99', promotion: false),
  PulseStoreProduct(
      id: '473916', amount: 8000, referencePrice: '\$49.99', promotion: false),
  PulseStoreProduct(
      id: '473917', amount: 14000, referencePrice: '\$79.99', promotion: false),
  PulseStoreProduct(
      id: '473918', amount: 14998, referencePrice: '\$99.99', promotion: false),
  PulseStoreProduct(
      id: '473919', amount: 520, referencePrice: '\$1.99', promotion: true),
  PulseStoreProduct(
      id: '473920', amount: 800, referencePrice: '\$2.99', promotion: true),
  PulseStoreProduct(
      id: '473921', amount: 1300, referencePrice: '\$4.99', promotion: true),
  PulseStoreProduct(
      id: '473922', amount: 1500, referencePrice: '\$5.99', promotion: true),
  PulseStoreProduct(
      id: '473923', amount: 2700, referencePrice: '\$11.99', promotion: true),
  PulseStoreProduct(
      id: '473924', amount: 2900, referencePrice: '\$12.99', promotion: true),
  PulseStoreProduct(
      id: '473925', amount: 7200, referencePrice: '\$34.99', promotion: true),
  PulseStoreProduct(
      id: '473926', amount: 17000, referencePrice: '\$79.99', promotion: true),
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
