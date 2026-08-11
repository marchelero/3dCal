// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/features/entitlement/data/payment_service.dart';

/// Tests basicos de la interface [PaymentService] y sus sealed results.
///
/// **Por que tan minimo**: la interface son solo data classes (sealed
/// hierarchy). Lo importante es verificar:
/// - Las subclases son exhaustive (pattern matching cubre todo).
/// - `PaymentResult` y `RestoreResult` sealed con las 3 ramas esperadas
///   (success/cancel/error, active/empty/error).
/// - Los campos se asignan y se leen correctamente.
///
/// El grueso de la logica vive en [EntitlementNotifier] (testeado en
/// `entitlement_notifier_restore_test.dart`) y en la impl de RevenueCat
/// (testeada manualmente con sandbox de Play Store — T21).
void main() {
  group('PaymentResult', () {
    test('PaymentSuccess: campos asignados + source default', () {
      final purchasedAt = DateTime.utc(2026, 7, 22, 12);
      final result = PaymentSuccess(
        productId: 'tresdcal_pro_lifetime',
        purchasedAt: purchasedAt,
      );
      expect(result, isA<PaymentResult>());

      final ok = PaymentSuccess(
        productId: 'tresdcal_pro_lifetime',
        purchasedAt: purchasedAt,
      );
      expect(ok.productId, 'tresdcal_pro_lifetime');
      expect(ok.purchasedAt, purchasedAt);
      expect(
        ok.source,
        'lifetime_purchase',
        reason: 'Source default = lifetime_purchase.',
      );
    });

    test('PaymentCancelled: instance of PaymentResult', () {
      const c = PaymentCancelled();
      expect(c, isA<PaymentResult>());
    });

    test('PaymentError: message stored', () {
      const e = PaymentError('boom');
      expect(e, isA<PaymentResult>());
      expect(e.message, 'boom');
    });

    test('pattern matching exhaustivo (success/cancelled/error)', () {
      String describe(PaymentResult r) => switch (r) {
        PaymentSuccess() => 'success',
        PaymentCancelled() => 'cancelled',
        PaymentError() => 'error',
      };

      expect(
        describe(
          PaymentSuccess(productId: 'X', purchasedAt: DateTime.utc(2026)),
        ),
        'success',
      );
      expect(describe(const PaymentCancelled()), 'cancelled');
      expect(describe(const PaymentError('x')), 'error');
    });
  });

  group('RestoreResult', () {
    test('RestoreActive: campos asignados', () {
      final purchased = DateTime.utc(2026, 1, 15);
      final validated = DateTime.utc(2026, 7, 22);
      final r = RestoreActive(
        productId: 'tresdcal_pro_lifetime',
        purchasedAt: purchased,
        validatedAt: validated,
      );
      expect(r, isA<RestoreResult>());
      expect(r.productId, 'tresdcal_pro_lifetime');
      expect(r.purchasedAt, purchased);
      expect(r.validatedAt, validated);
    });

    test('RestoreEmpty: instance of RestoreResult', () {
      const e = RestoreEmpty();
      expect(e, isA<RestoreResult>());
    });

    test('RestoreError: message stored', () {
      const e = RestoreError('boom');
      expect(e, isA<RestoreResult>());
      expect(e.message, 'boom');
    });

    test('pattern matching exhaustivo (active/empty/error)', () {
      String describe(RestoreResult r) => switch (r) {
        RestoreActive() => 'active',
        RestoreEmpty() => 'empty',
        RestoreError() => 'error',
      };

      expect(
        describe(
          RestoreActive(
            productId: 'X',
            purchasedAt: DateTime.utc(2026),
            validatedAt: DateTime.utc(2026),
          ),
        ),
        'active',
      );
      expect(describe(const RestoreEmpty()), 'empty');
      expect(describe(const RestoreError('x')), 'error');
    });
  });
}
