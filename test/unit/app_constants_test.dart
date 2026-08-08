import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/constants/app_constants.dart';

void main() {
  group('Pro tier / monetization constants', () {
    test('kIsProKey es clave SP para flag is_pro', () {
      expect(kIsProKey, 'is_pro');
    });

    test('kEntitlementSourceKey es clave SP para origen del entitlement', () {
      expect(kEntitlementSourceKey, 'entitlement_source');
    });

    test('kEntitlementValidatedAtKey es clave SP para timestamp', () {
      expect(kEntitlementValidatedAtKey, 'entitlement_validated_at');
    });

    test('kFreeHistoryCap es 10 (cap de historial para free)', () {
      expect(kFreeHistoryCap, 10);
    });

    test('kProProductId apunta al product lifetime en Google Play', () {
      expect(kProProductId, 'tresdcal_pro_lifetime');
    });

    test('kProPriceUsd es 4.99 (precio displayed referencial)', () {
      expect(kProPriceUsd, 4.99);
    });
  });
}
