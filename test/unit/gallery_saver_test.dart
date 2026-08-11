// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:tresdcal/core/share/quote_share.dart';

/// Fake que lanza [error] al guardar. Constante para poder instanciarse
/// inline en cada test.
class _ThrowingSaver extends GallerySaver {
  const _ThrowingSaver(this.error);

  final Exception error;

  @override
  Future<void> saveImage(Uint8List imageBytes, {required String name}) async {
    throw error;
  }
}

/// Fake que registra el name recibido (verifica el happy path sin plugins).
class _RecordingSaver extends GallerySaver {
  _RecordingSaver(this.names);

  final List<String> names;

  @override
  Future<void> saveImage(Uint8List imageBytes, {required String name}) async {
    names.add(name);
  }
}

void main() {
  group('saveQuoteImage (mapeo gal)', () {
    test('happy path: delega bytes + nombre cotizacion_3dcalc_<ts>', () async {
      final names = <String>[];
      final saver = _RecordingSaver(names);

      await saveQuoteImage(Uint8List.fromList([1, 2, 3]), gallerySaver: saver);

      expect(names, hasLength(1));
      expect(names.single, startsWith('cotizacion_3dcalc_'));
      // El name va sin extension (gal agrega el formato).
      expect(names.single, isNot(endsWith('.png')));
    });

    test(
      'GalException (real de gal 2.3.x) → ShareQuoteException con mensaje',
      () async {
        final saver = _ThrowingSaver(
          GalException(
            type: GalExceptionType.notEnoughSpace,
            platformException: PlatformException(
              code: 'NOT_ENOUGH_SPACE',
              message: 'storage full',
            ),
            stackTrace: StackTrace.empty,
          ),
        );

        await expectLater(
          saveQuoteImage(Uint8List(0), gallerySaver: saver),
          throwsA(
            isA<ShareQuoteException>().having(
              (e) => e.message,
              'message',
              contains('storage full'),
            ),
          ),
        );
      },
    );

    test('GalException sin message → mensaje generico', () async {
      final saver = _ThrowingSaver(
        GalException(
          type: GalExceptionType.accessDenied,
          platformException: PlatformException(code: 'ACCESS_DENIED'),
          stackTrace: StackTrace.empty,
        ),
      );

      await expectLater(
        saveQuoteImage(Uint8List(0), gallerySaver: saver),
        throwsA(
          isA<ShareQuoteException>().having(
            (e) => e.message,
            'message',
            'No se pudo guardar la imagen en la galeria.',
          ),
        ),
      );
    });

    test(
      'PlatformException (backstop) → ShareQuoteException con errorMessage',
      () async {
        final saver = _ThrowingSaver(
          PlatformException(code: 'save_failed', message: 'boom'),
        );

        await expectLater(
          saveQuoteImage(Uint8List(0), gallerySaver: saver),
          throwsA(
            isA<ShareQuoteException>().having(
              (e) => e.message,
              'message',
              contains('boom'),
            ),
          ),
        );
      },
    );

    test(
      'Plataforma sin plugin (MissingPluginException) → ShareQuoteException',
      () async {
        final saver = _ThrowingSaver(MissingPluginException());

        await expectLater(
          saveQuoteImage(Uint8List(0), gallerySaver: saver),
          throwsA(isA<ShareQuoteException>()),
        );
      },
    );

    test('excepcion inesperada → ShareQuoteException generico', () async {
      final saver = _ThrowingSaver(Exception('wat'));

      await expectLater(
        saveQuoteImage(Uint8List(0), gallerySaver: saver),
        throwsA(
          isA<ShareQuoteException>().having(
            (e) => e.message,
            'message',
            'No se pudo guardar la imagen en la galeria.',
          ),
        ),
      );
    });
  });
}
