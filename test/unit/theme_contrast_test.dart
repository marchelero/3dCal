// ignore_for_file: public_member_api_docs
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tresdcal/core/theme/app_theme.dart';

/// T2-3 (a11y): guarda los ratios de contraste WCAG 2.2 de los tokens de tema.
///
/// FÃ³rmula oficial de luminancia relativa (WCAG 2.x). Si alguien degrada un
/// token de vuelta, este test falla con el ratio exacto.
void main() {
  double luminance(Color color) {
    double lin01(double s) {
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin01(color.r) +
        0.7152 * lin01(color.g) +
        0.0722 * lin01(color.b);
  }

  double contrast(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final hi = l1 > l2 ? l1 : l2;
    final lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  void expectAAText(String label, Color fg, Color bg) {
    final ratio = contrast(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: '$label = ${ratio.toStringAsFixed(2)}:1 (AA normal >= 4.5)',
    );
  }

  void expectUILarge(String label, Color fg, Color bg) {
    final ratio = contrast(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(3.0),
      reason: '$label = ${ratio.toStringAsFixed(2)}:1 (UI/grande >= 3.0)',
    );
  }

  group('T2-3 contraste WCAG â€” light', () {
    final s = AppTheme.light().colorScheme;

    test('texto principal y secundario en todas las superficies (>= 4.5)', () {
      expectAAText('onSurface/surface', s.onSurface, s.surface);
      expectAAText('onSurfaceVariant/surface', s.onSurfaceVariant, s.surface);
      expectAAText('onSurfaceVariant/Lowest', s.onSurfaceVariant,
          s.surfaceContainerLowest);
      expectAAText(
          'onSurfaceVariant/Low', s.onSurfaceVariant, s.surfaceContainerLow);
      expectAAText('onSurfaceVariant/Container', s.onSurfaceVariant,
          s.surfaceContainer);
      expectAAText('onSurfaceVariant/High', s.onSurfaceVariant,
          s.surfaceContainerHigh);
      expectAAText('onSurfaceVariant/Highest', s.onSurfaceVariant,
          s.surfaceContainerHighest);
      expectAAText('onPrimary/primary', s.onPrimary, s.primary);
      expectAAText('error/surface', s.error, s.surface);
    });

    test('snack de exito: texto blanco sobre blueSuccess (>= 4.5)', () {
      expectAAText(
          'white/blueSuccess', const Color(0xFFFFFFFF), AppTheme.blueSuccess);
    });

    test('bordes/controles UI outline en superficies (>= 3.0)', () {
      expectUILarge('outline/surface', s.outline, s.surface);
      expectUILarge('outline/Low', s.outline, s.surfaceContainerLow);
      expectUILarge('outline/Container', s.outline, s.surfaceContainer);
      expectUILarge('outline/High', s.outline, s.surfaceContainerHigh);
    });
  });

  group('T2-3 contraste WCAG â€” dark', () {
    final s = AppTheme.dark().colorScheme;

    test('texto principal y secundario en superficies (>= 4.5)', () {
      expectAAText('onSurface/surface', s.onSurface, s.surface);
      expectAAText('onSurfaceVariant/surface', s.onSurfaceVariant, s.surface);
      expectAAText('onSurfaceVariant/High', s.onSurfaceVariant,
          s.surfaceContainerHigh);
      expectAAText('onSurfaceVariant/Highest', s.onSurfaceVariant,
          s.surfaceContainerHighest);
      expectAAText('onPrimary/primary', s.onPrimary, s.primary);
      expectAAText('error/surface', s.error, s.surface);
    });

    test('snack de exito: texto blanco sobre blueSuccess (>= 4.5)', () {
      expectAAText(
          'white/blueSuccess', const Color(0xFFFFFFFF), AppTheme.blueSuccess);
    });

    test('bordes/controles UI outline en superficie (>= 3.0)', () {
      expectUILarge('outline/surface', s.outline, s.surface);
      expectUILarge('outline/Highest', s.outline, s.surfaceContainerHighest);
    });
  });
}
