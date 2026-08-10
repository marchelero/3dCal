/// SnackBar semantico con icono + color por tipo.
///
/// Centraliza el feedback de acciones (guardar, eliminar, error de red, etc)
/// para que el usuario identifique el tipo de un vistazo:
///   - [AppSnackBar.success] verde con check, duracion 2s
///   - [AppSnackBar.error]   rojo con icono error, duracion 4s
///   - [AppSnackBar.warning] amarillo con icono warning, duracion 3s
///   - [AppSnackBar.info]    color primario con icono info, duracion 2s
///
/// Reemplaza el uso directo de `SnackBar` para evitar drift de estilo y
/// asegurar el mismo affordance visual en todas las features.
///
/// Ejemplo:
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   AppSnackBar.success('Cotizacion guardada.'),
/// );
/// ```
library;
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// SnackBar con icono + color semantico.
///
/// Construir siempre via los factories nombrados:
/// `AppSnackBar.success(...)`, `.error(...)`, `.warning(...)`, `.info(...)`.
class AppSnackBar extends SnackBar {
  AppSnackBar._({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required super.duration,
    SnackBarAction? action,
  }) : super(
         content: Row(
           children: [
             Icon(icon, color: foregroundColor, size: 24),
             SizedBox(width: AppSpacing.md),
             Expanded(
               child: Text(message, style: TextStyle(color: foregroundColor)),
             ),
           ],
         ),
         backgroundColor: backgroundColor,
         // El `behavior` lo define el theme (snackBarTheme: floating).
         // No forzar aqui: en tests sin AppTheme quedaria floating y el
         // action no recibe taps durante la animacion de entrada.
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(AppRadii.md),
         ),
         action: action == null
             ? null
             : SnackBarAction(
                 label: action.label,
                 onPressed: action.onPressed,
                 textColor: foregroundColor,
               ),
       );

  /// Feedback positivo (accion exitosa). Verde + check, 2s.
  factory AppSnackBar.success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppSnackBar._(
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppTheme.greenSuccess,
      foregroundColor: Colors.white,
      duration: const Duration(seconds: 2),
      action: _buildAction(actionLabel, onAction),
    );
  }

  /// Feedback de error. Rojo + icono error, 4s (mas tiempo para leer).
  factory AppSnackBar.error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppSnackBar._(
      message: message,
      icon: Icons.error,
      backgroundColor: AppTheme.redError,
      foregroundColor: Colors.white,
      duration: const Duration(seconds: 4),
      action: _buildAction(actionLabel, onAction),
    );
  }

  /// Feedback de advertencia (estado borderline). Amarillo + warning, 3s.
  factory AppSnackBar.warning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppSnackBar._(
      message: message,
      icon: Icons.warning_amber,
      backgroundColor: AppTheme.defaultStar,
      foregroundColor: Colors.black,
      duration: const Duration(seconds: 3),
      action: _buildAction(actionLabel, onAction),
    );
  }

  /// Feedback informativo. Color primario del tema + info, 2s.
  ///
  /// Requiere [context] para resolver `colorScheme.primary` /
  /// `colorScheme.onPrimary` (no son parte de la paleta fija del theme).
  factory AppSnackBar.info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AppSnackBar._(
      message: message,
      icon: Icons.info,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      duration: const Duration(seconds: 2),
      action: _buildAction(actionLabel, onAction),
    );
  }

  /// Arma la [SnackBarAction] opcional de los factories. Si falta el label
  /// o el callback, no hay accion (null) y el SnackBar queda solo texto.
  static SnackBarAction? _buildAction(
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    if (actionLabel == null || onAction == null) return null;
    return SnackBarAction(label: actionLabel, onPressed: onAction);
  }
}
