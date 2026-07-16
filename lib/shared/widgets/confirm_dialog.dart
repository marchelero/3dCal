/// Helper de dialog de confirmacion con boton destructivo.
///
/// Usado para acciones irreversibles (eliminar filamento, cotizacion, etc).
/// Por default usa `Eliminar` como confirm y pinta el boton como destructive
/// (FilledButton en color `error`). Retorna `true` si el user confirma.
///
/// Centralizar este dialog evita drift de labels y asegura el mismo
/// affordance visual en todas las features.
library;

import 'package:flutter/material.dart';

/// Muestra un dialog de confirmacion. Retorna `true` si el usuario confirma.
///
/// - [title]: titulo del dialog (ej: `'Eliminar filamento'`).
/// - [message]: cuerpo (ej: `'\u00bfEliminar "${filament.name}"?'`).
/// - [confirmLabel]: label del boton de confirmacion. Default: `'Eliminar'`.
/// - [cancelLabel]: label del boton de cancelar. Default: `'Cancelar'`.
/// - [destructive]: si `true` (default), el boton usa `colorScheme.error`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
  String cancelLabel = 'Cancelar',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
