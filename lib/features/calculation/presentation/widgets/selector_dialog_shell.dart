/// Shell base para los selectores de catalogo del cotizador.
///
/// Reutiliza el patron comun de los selectores (AlertDialog + buscador +
/// ListView filtrable + boton Cancelar) para que cada selector aporte solo
/// su identidad visual via [itemBuilder].
///
/// Retorna el item elegido con `Navigator.pop(item)`, o `null` si el usuario
/// cancela.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/es_bo.dart';

/// Abre un selector con buscador.
///
/// - [items]: lista completa a filtrar.
/// - [matches]: retorna `true` si el item matchea el query (ya en lowercase).
/// - [itemBuilder]: construye el ListTile del item. Recibe `select` para
///   elegir el item (hace pop con el valor) y `context`.
/// - [footer]: widget opcional al final de la lista (ej: botón "Crear nuevo").
Future<T?> showSelectorDialog<T>({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<T> items,
  required bool Function(T item, String query) matches,
  required Widget Function(BuildContext context, T item, void Function() select)
  itemBuilder,
  Widget? footer,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      var filtered = items;

      void applyFilter(String q) {
        if (q.isEmpty) {
          filtered = items;
        } else {
          final lower = q.toLowerCase();
          filtered = items.where((e) => matches(e, lower)).toList();
        }
      }

      void select(T item) => Navigator.of(ctx).pop(item);

      return StatefulBuilder(
        builder: (context, setInnerState) {
          final viewport = MediaQuery.sizeOf(context);
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: math.min(560, viewport.width * 0.92),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setInnerState(() => applyFilter(v)),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.min(480, viewport.height * 0.72),
                    ),
                    child: filtered.isEmpty && footer == null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text(EsBO.commonNoResults)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length + (footer != null ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i < filtered.length) {
                                final item = filtered[i];
                                return itemBuilder(
                                  context,
                                  item,
                                  () => select(item),
                                );
                              }
                              // Footer item (botón crear nuevo, etc.)
                              return footer!;
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(EsBO.commonCancel),
              ),
            ],
          );
        },
      );
    },
  );
}
