import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tempo/config/constants/pro_config.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';

enum StoreStatus { loading, ready, unavailable, purchasing }

class PurchaseState {
  final StoreStatus status;
  final String? price;
  final String? message;

  const PurchaseState({
    this.status = StoreStatus.loading,
    this.price,
    this.message,
  });

  PurchaseState copyWith({
    StoreStatus? status,
    String? price,
    String? message,
    bool clearMessage = false,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      price: price ?? this.price,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  PurchaseNotifier(this._ref) : super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = const PurchaseState(
          status: StoreStatus.unavailable,
          message: 'La tienda no está disponible en este momento.',
        );
        return;
      }

      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          debugPrint('[Purchase] Error en el flujo de compras: $e');
        },
      );

      final response = await _iap.queryProductDetails({ProConfig.productId});
      if (response.productDetails.isEmpty) {
        state = const PurchaseState(
          status: StoreStatus.unavailable,
          message: 'Tempo Pro aún no está disponible para comprar.',
        );
      } else {
        _product = response.productDetails.first;
        state = PurchaseState(
          status: StoreStatus.ready,
          price: _product!.price,
        );
      }

      // Si aún no es Pro, busca compras anteriores de esta cuenta de Google
      if (!_ref.read(isProProvider)) {
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('[Purchase] No se pudo iniciar la tienda: $e');
      state = const PurchaseState(
        status: StoreStatus.unavailable,
        message: 'No se pudo conectar con la tienda.',
      );
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != ProConfig.productId) continue;

      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            status: StoreStatus.purchasing,
            message: 'Procesando el pago...',
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _ref.read(isProProvider.notifier).setPro(true);
          state = state.copyWith(
            status: StoreStatus.ready,
            message: '¡Tempo Pro activado!',
          );
        case PurchaseStatus.error:
          state = state.copyWith(
            status: StoreStatus.ready,
            message: 'No se pudo completar la compra. No se te cobró.',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(
            status: StoreStatus.ready,
            clearMessage: true,
          );
      }

      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> buy() async {
    final product = _product;
    if (product == null || state.status != StoreStatus.ready) return;

    state = state.copyWith(status: StoreStatus.purchasing, clearMessage: true);
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        state = state.copyWith(
          status: StoreStatus.ready,
          message: 'No se pudo iniciar la compra.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: StoreStatus.ready,
        message: 'No se pudo iniciar la compra.',
      );
    }
  }

  Future<void> restore() async {
    try {
      state = state.copyWith(
        message:
            'Buscando compras anteriores. Si ya compraste Tempo Pro con esta cuenta de Google, se activará en unos segundos.',
      );
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(message: 'No se pudo consultar la tienda.');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  return PurchaseNotifier(ref);
});