// ignore_for_file: public_member_api_docs
/// AppBar actions adaptativos para pantallas angostas.
///
/// Resuelve el overflow de AppBars con 3+ acciones en telefonos: cuando hay
/// ancho suficiente muestra [SmartAppBarActions.priority] + todas las
/// [SmartAppBarActions.menuActions] como IconButtons directos; en pantallas
/// angostas deja [SmartAppBarActions.priority] directo y colapsa el resto a
/// un [PopupMenuButton] (⋮).
///
/// El `AppBar` de Flutter da a las actions constraints SIN acotar (LayoutBuilder
/// ve ancho infinito), asi que la decision se toma con el ancho de pantalla
/// ([MediaQuery]) y una estimacion del ancho de contenido directo:
///
/// ```
/// disponible = screenWidth - reserve (leading + titulo + padding)
/// contentWidth = priorityMaxWidth + menuActions.length * 48
/// directo     = screenWidth >= breakpoint && contentWidth <= disponible
/// ```
///
/// [breakpoint] (480dp) exige pantalla suficientemente ancha; el chequeo de
/// contenido garantiza que el `Row` directo + titulo + leading entren sin
/// overflow aun cuando el titulo es largo.
library;

import 'package:flutter/material.dart';

/// Accion secundaria del [SmartAppBarActions].
///
/// Se renderiza como [IconButton] directo cuando hay ancho y como item del
/// menu overflow cuando no.
typedef SmartAppBarMenuAction = ({
  Widget icon,
  String label,
  VoidCallback onTap,
});

/// Actions de [AppBar] sin overflow (RenderFlex).
class SmartAppBarActions extends StatelessWidget {
  const SmartAppBarActions({
    super.key,
    required this.priority,
    required this.menuActions,
    this.breakpoint = 480,
    this.priorityMaxWidth = 180,
    this.overflowIcon = Icons.more_vert_rounded,
    this.overflowTooltip,
  });

  /// Widgets que SIEMPRE se intentan mostrar directos (ej: chip de total).
  final List<Widget> priority;

  /// Acciones secundarias: directas con ancho, al menu ⋮ sin el.
  final List<SmartAppBarMenuAction> menuActions;

  /// Ancho minimo de pantalla (dp) para considerar el modo directo.
  final double breakpoint;

  /// Estimacion del ancho maximo (dp) que pueden ocupar los widgets de
  /// [priority]. Se usa para decidir si todo entra sin overflow.
  final double priorityMaxWidth;

  /// Icono del boton de overflow.
  final IconData overflowIcon;

  /// Tooltip / semantics del boton de overflow.
  final String? overflowTooltip;

  /// Ancho de un IconButton del AppBar (kMinInteractiveDimension).
  static const double _iconButtonWidth = 48;

  /// Reserva (dp) para leading + titulo + padding al decidir el modo directo.
  /// El titulo del AppBar se encoge pero no desaparece del todo; un margen
  /// generoso evita overflow con titulos largos.
  static const double _directReserve = 200;

  /// Reserva (dp) para el ancho del modo colapsado: leading + titulo minimo.
  /// El titulo se encoge hasta casi desaparecer, asi que basta con reservar
  /// el leading + un titulo residual.
  static const double _collapsedReserve = 72;

  /// Convierte una accion de menu en un [IconButton] directo.
  Widget _directButton(BuildContext context, SmartAppBarMenuAction a) {
    return IconButton(icon: a.icon, tooltip: a.label, onPressed: a.onTap);
  }

  /// Items del [PopupMenuButton] de overflow.
  List<PopupMenuEntry<VoidCallback>> _menuItems(BuildContext context) {
    return [
      for (final a in menuActions)
        PopupMenuItem<VoidCallback>(
          value: a.onTap,
          child: Row(
            children: [
              SizedBox(width: 24, height: 24, child: Center(child: a.icon)),
              const SizedBox(width: 12),
              Expanded(child: Text(a.label)),
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth =
        priorityMaxWidth + menuActions.length * _iconButtonWidth;
    final available = screenWidth - _directReserve;
    final showDirect = screenWidth >= breakpoint && contentWidth <= available;

    if (showDirect) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...priority,
          for (final a in menuActions) _directButton(context, a),
        ],
      );
    }

    return _buildCollapsed(screenWidth);
  }

  /// Modo angosto: priority + menu overflow, alineados al borde derecho.
  ///
  /// El [SizedBox] ocupa el ancho de actions disponible del [AppBar]; el
  /// contenido interno (precio + boton ⋮) se alinea al borde con
  /// [OverflowBox] `centerRight` y el `ClipRect` recorta si excede (chip de
  /// total gigante o texto escalado), evitando RenderFlex overflow y
  /// dejando el conjunto pegado al borde derecho sin hueco.
  Widget _buildCollapsed(double screenWidth) {
    final budget = (screenWidth - _collapsedReserve).clamp(
      48.0,
      double.infinity,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: budget,
        height: kToolbarHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerRight,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ...priority,
                PopupMenuButton<VoidCallback>(
                  tooltip: overflowTooltip,
                  icon: Icon(overflowIcon),
                  onSelected: (cb) => cb(),
                  itemBuilder: _menuItems,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
