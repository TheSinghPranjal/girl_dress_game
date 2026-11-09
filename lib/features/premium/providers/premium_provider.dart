import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_providers.dart';
import '../../../services/purchase/purchase_gateway.dart';

enum PremiumPhase { loading, ready, unavailable, purchasing }

class PremiumState {
  const PremiumState({
    required this.unlocked,
    this.phase = PremiumPhase.loading,
    this.products = const [],
    this.message,
  });

  final bool unlocked;
  final PremiumPhase phase;
  final List<StoreProduct> products;
  final String? message;

  PremiumState copyWith({
    bool? unlocked,
    PremiumPhase? phase,
    List<StoreProduct>? products,
    String? message,
  }) =>
      PremiumState(
        unlocked: unlocked ?? this.unlocked,
        phase: phase ?? this.phase,
        products: products ?? this.products,
        message: message,
      );
}

const _entitlementKey = 'premium_entitled';

final premiumProvider =
    NotifierProvider<PremiumNotifier, PremiumState>(PremiumNotifier.new);

final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(premiumProvider.select((s) => s.unlocked)));

/// Unlock state. It only becomes true from a store purchase or restore event.
class PremiumNotifier extends Notifier<PremiumState> {
  StreamSubscription<StoreEvent>? _events;

  PurchaseGateway get _gateway => ref.read(purchaseGatewayProvider);

  @override
  PremiumState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _events = ref.watch(purchaseGatewayProvider).events.listen(_onEvent);
    ref.onDispose(() => _events?.cancel());
    Future.microtask(refreshStore);
    return PremiumState(unlocked: prefs.getBool(_entitlementKey) ?? false);
  }

  Future<void> refreshStore() async {
    try {
      if (!await _gateway.isAvailable()) {
        state = state.copyWith(
          phase: PremiumPhase.unavailable,
          message: 'The store is not available on this device right now.',
        );
        return;
      }
      final products = await _gateway.loadProducts();
      if (products.isEmpty) {
        state = state.copyWith(
          phase: PremiumPhase.unavailable,
          message: 'Subscriptions are not available yet. Please try again later.',
        );
        return;
      }
      state = state.copyWith(phase: PremiumPhase.ready, products: products);
    } on Exception catch (error) {
      state = state.copyWith(
        phase: PremiumPhase.unavailable,
        message: 'The store could not be reached. ($error)',
      );
    }
  }

  void _onEvent(StoreEvent event) {
    switch (event.type) {
      case StoreEventType.pending:
        state = state.copyWith(
          phase: PremiumPhase.purchasing,
          message: 'Waiting for the store to confirm…',
        );
      case StoreEventType.entitled:
        ref.read(sharedPreferencesProvider).setBool(_entitlementKey, true);
        state = state.copyWith(
          unlocked: true,
          phase: PremiumPhase.ready,
          message: 'Premium wardrobe unlocked. Enjoy!',
        );
      case StoreEventType.failed:
        state = state.copyWith(
          phase: PremiumPhase.ready,
          message: event.message ?? 'The purchase could not be completed.',
        );
      case StoreEventType.canceled:
        state = state.copyWith(
          phase: PremiumPhase.ready,
          message: 'Purchase cancelled.',
        );
    }
  }

  Future<void> buy(StoreProduct product) async {
    state = state.copyWith(phase: PremiumPhase.purchasing);
    try {
      await _gateway.buy(product);
    } on Exception catch (error) {
      state = state.copyWith(
        phase: PremiumPhase.ready,
        message: 'The purchase could not start. ($error)',
      );
    }
  }

  Future<void> restore() async {
    try {
      await _gateway.restore();
      state = state.copyWith(
        message: state.unlocked
            ? 'Your premium wardrobe is active.'
            : 'Checking the store for earlier purchases…',
      );
    } on Exception catch (error) {
      state = state.copyWith(message: 'Restore failed. ($error)');
    }
  }
}
