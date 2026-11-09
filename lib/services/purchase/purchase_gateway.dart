import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Store product ids. These must be created in App Store Connect and Play Console.
abstract final class PremiumProducts {
  static const monthly = 'help_me_dress_premium_monthly';
  static const yearly = 'help_me_dress_premium_yearly';
  static const all = {monthly, yearly};
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    this.raw,
  });

  final String id;
  final String title;
  final String price;
  final ProductDetails? raw;
}

enum StoreEventType { pending, entitled, failed, canceled }

class StoreEvent {
  const StoreEvent(this.type, {this.message});

  final StoreEventType type;
  final String? message;
}

/// The store, behind an interface so tests never touch real billing.
abstract class PurchaseGateway {
  Stream<StoreEvent> get events;
  Future<bool> isAvailable();
  Future<List<StoreProduct>> loadProducts();
  Future<void> buy(StoreProduct product);
  Future<void> restore();
  void dispose();
}

class InAppPurchaseGateway implements PurchaseGateway {
  InAppPurchaseGateway({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance {
    _subscription = _store.purchaseStream.listen(
      _handle,
      onError: (Object error) =>
          _events.add(StoreEvent(StoreEventType.failed, message: '$error')),
    );
  }

  final InAppPurchase _store;
  final _events = StreamController<StoreEvent>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  Stream<StoreEvent> get events => _events.stream;

  Future<void> _handle(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!PremiumProducts.all.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(const StoreEvent(StoreEventType.pending));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _events.add(const StoreEvent(StoreEventType.entitled));
        case PurchaseStatus.error:
          _events.add(StoreEvent(
            StoreEventType.failed,
            message: purchase.error?.message,
          ));
        case PurchaseStatus.canceled:
          _events.add(const StoreEvent(StoreEventType.canceled));
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<List<StoreProduct>> loadProducts() async {
    final response = await _store.queryProductDetails(PremiumProducts.all);
    return [
      for (final product in response.productDetails)
        StoreProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          raw: product,
        ),
    ];
  }

  @override
  Future<void> buy(StoreProduct product) async {
    final details = product.raw;
    if (details == null) {
      throw StateError('This product did not come from the store.');
    }
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restore() => _store.restorePurchases();

  @override
  void dispose() {
    _subscription.cancel();
    _events.close();
  }
}
