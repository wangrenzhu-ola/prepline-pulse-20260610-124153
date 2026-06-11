import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pulse_store_models.dart';

class PulseWalletLedger {
  static const initialBalance = 100;
  static const stateSaveCost = 10;
  static const _balanceKey = 'prepLinePulseCreditBalance';
  static const _deliveryKey = 'prepLinePulseDeliveredPurchases';

  Future<int> readBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? initialBalance;
  }

  Future<int> writeBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, balance);
    return balance;
  }

  Future<int> addCredits(int amount) async {
    final current = await readBalance();
    return writeBalance(current + amount);
  }

  Future<bool> delivered(String deliveryKey) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deliveryKey) ?? const [])
        .contains(deliveryKey);
  }

  Future<int> addPurchaseOnce({
    required String deliveryKey,
    required int amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final deliveredKeys = prefs.getStringList(_deliveryKey) ?? <String>[];
    if (deliveredKeys.contains(deliveryKey)) {
      return prefs.getInt(_balanceKey) ?? initialBalance;
    }
    final nextBalance = (prefs.getInt(_balanceKey) ?? initialBalance) + amount;
    deliveredKeys.add(deliveryKey);
    await prefs.setStringList(_deliveryKey, deliveredKeys);
    await prefs.setInt(_balanceKey, nextBalance);
    return nextBalance;
  }
}

class PreplinePurchaseService {
  PreplinePurchaseService({
    required this.walletLedger,
    InAppPurchase? purchaseClient,
  }) : _purchaseClient = purchaseClient ?? InAppPurchase.instance;

  final PulseWalletLedger walletLedger;
  final InAppPurchase _purchaseClient;
  final Map<String, ProductDetails> _productDetailsById = {};
  final Map<String, Completer<PulsePurchaseResult>> _inFlightByProduct = {};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _availabilityChecked = false;
  bool _storeAvailable = false;

  bool get hasActivePurchase => _inFlightByProduct.isNotEmpty;

  Future<void> prepareStore() async {
    await _checkAvailability();
    await _ensurePurchaseListener();
    unawaited(_queryProductsWithRetry());
  }

  Future<PulsePurchaseResult> buyProduct(PulseStoreProduct product) async {
    await prepareStore();
    if (!_storeAvailable) {
      return const PulsePurchaseResult(
        state: PulsePurchaseState.unavailable,
        message: 'Store is temporarily unavailable.',
      );
    }
    final existing = _inFlightByProduct[product.id];
    if (existing != null) {
      return existing.future;
    }
    final productDetails = await _detailsFor(product);
    if (productDetails == null) {
      return PulsePurchaseResult(
        state: PulsePurchaseState.failed,
        message: 'Product ${product.id} is not available yet.',
      );
    }
    final completer = Completer<PulsePurchaseResult>();
    _inFlightByProduct[product.id] = completer;
    try {
      final started = await _purchaseClient.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
        autoConsume: true,
      );
      if (!started) {
        _clearInFlight(product.id);
        return const PulsePurchaseResult(
          state: PulsePurchaseState.failed,
          message: 'Purchase could not be started.',
        );
      }
      return completer.future.timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          _clearInFlight(product.id);
          return const PulsePurchaseResult(
            state: PulsePurchaseState.pending,
            message: 'Purchase is still pending.',
          );
        },
      );
    } catch (error) {
      _clearInFlight(product.id);
      final text = error.toString().toLowerCase();
      if (_looksCancelled(text)) {
        return const PulsePurchaseResult(
          state: PulsePurchaseState.cancelled,
          message: 'Purchase cancelled.',
        );
      }
      if (_looksDuplicateOrPending(text)) {
        return const PulsePurchaseResult(
          state: PulsePurchaseState.pending,
          message: 'A purchase is already pending.',
        );
      }
      if (error is PlatformException) {
        return PulsePurchaseResult(
          state: PulsePurchaseState.failed,
          message: 'Purchase failed: ${error.code}.',
        );
      }
      return const PulsePurchaseResult(
        state: PulsePurchaseState.failed,
        message: 'Purchase failed. Please try again.',
      );
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
  }

  Future<void> _checkAvailability() async {
    if (_availabilityChecked) {
      return;
    }
    _availabilityChecked = true;
    try {
      _storeAvailable = await _purchaseClient
          .isAvailable()
          .timeout(const Duration(seconds: 120), onTimeout: () => false);
    } catch (_) {
      _storeAvailable = false;
    }
  }

  Future<void> _ensurePurchaseListener() async {
    _purchaseSubscription ??= _purchaseClient.purchaseStream.listen(
      _handlePurchaseEvents,
      onError: (_) {
        for (final entry in _inFlightByProduct.entries.toList()) {
          entry.value.complete(
            const PulsePurchaseResult(
              state: PulsePurchaseState.failed,
              message: 'Purchase listener failed.',
            ),
          );
          _clearInFlight(entry.key);
        }
      },
    );
  }

  Future<void> _queryProductsWithRetry() async {
    const delays = [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8)
    ];
    for (var attempt = 0; attempt < delays.length; attempt += 1) {
      try {
        final response = await _purchaseClient
            .queryProductDetails(pulseStoreProductIds)
            .timeout(const Duration(seconds: 180));
        for (final details in response.productDetails) {
          _productDetailsById[details.id] = details;
        }
        return;
      } catch (_) {
        if (attempt == delays.length - 1) {
          return;
        }
        await Future<void>.delayed(delays[attempt]);
      }
    }
  }

  Future<ProductDetails?> _detailsFor(PulseStoreProduct product) async {
    final cached = _productDetailsById[product.id];
    if (cached != null) {
      return cached;
    }
    try {
      final response = await _purchaseClient.queryProductDetails(
          {product.id}).timeout(const Duration(seconds: 60));
      if (response.productDetails.isEmpty) {
        return null;
      }
      final details = response.productDetails.first;
      _productDetailsById[details.id] = details;
      return details;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handlePurchaseEvents(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          await _completePurchased(purchase);
          break;
        case PurchaseStatus.restored:
          await _finishPlatformTransaction(purchase);
          _completeFor(
            purchase.productID,
            const PulsePurchaseResult(
              state: PulsePurchaseState.pending,
              message: 'Restored transaction finished without credit.',
            ),
          );
          break;
        case PurchaseStatus.error:
          await _finishPlatformTransaction(purchase);
          final errorText = purchase.error?.message.toLowerCase() ?? '';
          _completeFor(
            purchase.productID,
            PulsePurchaseResult(
              state: _looksCancelled(errorText)
                  ? PulsePurchaseState.cancelled
                  : PulsePurchaseState.failed,
              message: _looksCancelled(errorText)
                  ? 'Purchase cancelled.'
                  : 'Purchase failed. Please try again.',
            ),
          );
          break;
        case PurchaseStatus.canceled:
          await _finishPlatformTransaction(purchase);
          _completeFor(
            purchase.productID,
            const PulsePurchaseResult(
              state: PulsePurchaseState.cancelled,
              message: 'Purchase cancelled.',
            ),
          );
          break;
      }
    }
  }

  Future<void> _completePurchased(PurchaseDetails purchase) async {
    final product = pulseProductForId(purchase.productID);
    if (product == null) {
      await _finishPlatformTransaction(purchase);
      _completeFor(
        purchase.productID,
        const PulsePurchaseResult(
          state: PulsePurchaseState.failed,
          message: 'Purchased product is not in the catalog.',
        ),
      );
      return;
    }
    final deliveryKey = _deliveryKeyFor(purchase);
    final balance = await walletLedger.addPurchaseOnce(
      deliveryKey: deliveryKey,
      amount: product.amount,
    );
    await _finishPlatformTransaction(purchase);
    _completeFor(
      purchase.productID,
      PulsePurchaseResult(
        state: PulsePurchaseState.success,
        message: 'Added ${product.amount} prep credits.',
        balance: balance,
      ),
    );
  }

  Future<void> _finishPlatformTransaction(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _purchaseClient.completePurchase(purchase);
    }
  }

  void _completeFor(String productId, PulsePurchaseResult result) {
    final completer = _inFlightByProduct[productId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
    _clearInFlight(productId);
  }

  void _clearInFlight(String productId) {
    _inFlightByProduct.remove(productId);
  }

  String _deliveryKeyFor(PurchaseDetails purchase) {
    if ((purchase.purchaseID ?? '').isNotEmpty) {
      return purchase.purchaseID!;
    }
    final local = purchase.verificationData.localVerificationData;
    final server = purchase.verificationData.serverVerificationData;
    final source = local.isNotEmpty
        ? local
        : server.isNotEmpty
            ? server
            : '${purchase.productID}:${purchase.transactionDate ?? ''}';
    return sha1.convert(utf8.encode(source)).toString();
  }

  bool _looksCancelled(String text) =>
      text.contains('cancelled') ||
      text.contains('canceled') ||
      text.contains('user_cancel') ||
      text.contains('paymentcancelled') ||
      text.contains('sheet dismissed');

  bool _looksDuplicateOrPending(String text) =>
      text.contains('duplicate') ||
      text.contains('pending') ||
      text.contains('unfinished') ||
      text.contains('already');
}
