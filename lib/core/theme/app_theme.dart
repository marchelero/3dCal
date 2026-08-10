/// ============================================================
/// EL PLANO TECNICO ACOTADO — contrato de direccion (impeccable, seed 4a829970)
///
/// THESIS: cotizar = dibujar el plano acotado del precio; no rellenar
/// un formulario generico.
///
/// OWN-WORLD: papel tecnico blanco azulado; tinta de plano azul para
/// cotas y accion; grafito para el cuerpo; lineas de cota con
/// extensiones como divisores; bloque de titulo como membrete; sellos
/// de revision para estados; numeros en mono tabular como dimensiones.
///
/// STORY: el vendedor dibuja el plano del precio frente al cliente; el
/// total es la cota principal enmarcada al pie; el desglose es la tabla
/// de materiales del plano; el descuento se anota como enmienda; los
/// estados son sellos de revision (REVISADO / COBRADO).
///
/// FIRST VIEWPORT: cotizador = hoja de plano con bloque de titulo
/// (COTIZACION, fecha, escala), secciones como cotas con lineas
/// de extension, caja de cota total abajo con cifra mono grande y
/// accion-sello.
///
/// FORM: candidato 5 (plano tecnico acotado; dado re-tirado 4a829970
/// asigno talonario, pin del usuario "tonos azules" gana), seed 4a829970.
///
/// unreviewed and undocumented is unfinished; this build ends with the
/// finish review, the verdict, and DESIGN.md
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_radii.dart';
import 'app_spacing.dart';

/// Tema Material 3 de tresdcal — "El Plano Tecnico Acotado".
///
/// Mundo visual: hoja de plano azulada. El papel tecnico es el lienzo,
/// la tinta azul de plano es la accion, las lineas de cota son los
/// divisores y los sellos de revision expresan estados. Todos los numeros
/// y montos usan [num] (JetBrains Mono tabular), como dimensiones de plano.
class AppTheme {
  const AppTheme._();

  /// Color semilla: tinta azul de plano.
  static const Color seedColor = Color(0xFF0B5394);

  /// Verde sello de exito ("cobrado").
  static const Color greenSuccess = Color(0xFF1F6E43);

  /// Rojo sello de error ("revisar").
  static const Color redError = Color(0xFFB3261E);

  /// Color del badge "default" (estrella). Dorado de sello.
  static const Color defaultStar = Color(0xFFB07400);

  /// Colores de fondo de los 4 slides del onboarding.
  ///
  /// Tonos profundos compartidos light/dark (funcionan sobre ambos schemes).
  /// Verificados AA ≥ 4.5:1 con texto blanco al 100%:
  ///   - azul tecnico #1B4D7A (7.6:1)
  ///   - naranja PLA oscuro #9A3412 (5.4:1) — reemplaza al #E67E22 que fallaba
  ///   - verde teal oscuro #0F766E (5.3:1) — reemplaza al #1A8A7A que fallaba
  ///   - violeta #6C3483 (7.9:1)
  static const List<Color> onboardingSlideColors = [
    Color(0xFF1B4D7A),
    Color(0xFF9A3412),
    Color(0xFF0F766E),
    Color(0xFF6C3483),
  ];

  /// Estilo para TODOS los numeros y montos: JetBrains Mono tabular.
  /// Mantiene cifras monoespaciadas y de ancho fijo (columnas de recibo).
  static TextStyle num(
    TextStyle base, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return GoogleFonts.jetBrainsMono(
      textStyle: base.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  /// Tema claro.
  static ThemeData light() {
    return _buildTheme(Brightness.light);
  }

  /// Tema oscuro.
  static ThemeData dark() {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Paleta "El Plano Tecnico Acotado".
    // Light: papel tecnico blanco azulado a plena luz.
    // Dark: el plano bajo la luz azul (negativo de blueprint, no un
    // invertido descuidado).
    final desk = isLight ? const Color(0xFFDFE6F0) : const Color(0xFF0A101C);
    final paper = isLight ? const Color(0xFFF7F9FC) : const Color(0xFF111B2C);
    final ink = isLight ? const Color(0xFF1C2431) : const Color(0xFFE6EEF9);
    final inkSoft =
        isLight ? const Color(0xFF5A6B85) : const Color(0xFF9FB2CC);
    final paperEdge =
        isLight ? const Color(0xFFC4CFE0) : const Color(0xFF2A3A55);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      primary: isLight ? const Color(0xFF0B5394) : const Color(0xFF8FC0F5),
      onPrimary: isLight ? Colors.white : const Color(0xFF082C54),
      secondary:
          isLight ? const Color(0xFF4A6FA5) : const Color(0xFF9FB8D9),
      tertiary:
          isLight ? const Color(0xFF6E7B8F) : const Color(0xFFA8B6C6),
      error: isLight ? redError : const Color(0xFFF2B8B5),
    ).copyWith(
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: inkSoft,
      outline: isLight ? const Color(0xFF7C8CA3) : const Color(0xFF8FA3BF),
      outlineVariant: paperEdge,
      surfaceContainerLowest: isLight
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF0D1523),
      surfaceContainerLow: isLight
          ? const Color(0xFFEFF3F9)
          : const Color(0xFF141F31),
      surfaceContainer: isLight
          ? const Color(0xFFE9EFF7)
          : const Color(0xFF182336),
      surfaceContainerHigh: isLight
          ? const Color(0xFFE3EAF3)
          : const Color(0xFF1D2A3E),
      surfaceContainerHighest: isLight
          ? const Color(0xFFDCE5F0)
          : const Color(0xFF22304A),
      primaryContainer:
          isLight ? const Color(0xFFD3E3F5) : const Color(0xFF1B3A66),
      onPrimaryContainer:
          isLight ? const Color(0xFF0A3D6B) : const Color(0xFFCDE2FA),
      secondaryContainer:
          isLight ? const Color(0xFFDCE6F3) : const Color(0xFF2B456B),
      onSecondaryContainer:
          isLight ? const Color(0xFF223A5E) : const Color(0xFFD9E6F5),
      tertiaryContainer:
          isLight ? const Color(0xFFDCE3EA) : const Color(0xFF3A4552),
      onTertiaryContainer:
          isLight ? const Color(0xFF2C3542) : const Color(0xFFDCE3EA),
      errorContainer: isLight
          ? const Color(0xFFF9DEDC)
          : const Color(0xFF8C1D18),
      onErrorContainer:
          isLight ? const Color(0xFF410E0B) : const Color(0xFFF9DEDC),
    );

    final textTheme = _buildTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: desk,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: desk,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        // Las tarjetas son hojas de plano sueltas sobre el tablero.
        elevation: 1,
        color: paper,
        surfaceTintColor: Colors.transparent,
        shadowColor: ink.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: paperEdge, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xxxl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
        ),
      ),
      // Inputs como lineas de cota de plano: sin caja, solo la regla
      // inferior. El touch target se conserva via contentPadding.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        border: const UnderlineInputBorder(borderSide: BorderSide.none),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: inkSoft.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        helperStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
        suffixStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 15,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl)),
          elevation: 0,
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          backgroundColor: paper,
          foregroundColor: ink,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xl)),
          side: BorderSide(color: inkSoft.withValues(alpha: 0.5)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill)),
        side: BorderSide(color: paperEdge, width: 0.5),
        backgroundColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: paperEdge,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        elevation: 3,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: colorScheme.surfaceContainer,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: inkSoft);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            );
          }
          return textTheme.labelMedium?.copyWith(color: inkSoft);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        labelType: NavigationRailLabelType.all,
        backgroundColor: colorScheme.surfaceContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: inkSoft),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
        unselectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: inkSoft),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: paperEdge),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return null;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: paper,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    // Inter como familia global (caballo de trabajo de un documento util).
    // La voz del mundo no es una display face: son MAYUSCULAS mono,
    // lineas de regla y sellos.
    final interBase = GoogleFonts.interTextTheme(base);

    return interBase.copyWith(
      displayLarge: interBase.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: interBase.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: interBase.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: interBase.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: interBase.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: interBase.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: interBase.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleMedium: interBase.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: interBase.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: interBase.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: interBase.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      bodySmall: interBase.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      labelLarge: interBase.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelMedium: interBase.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelSmall: interBase.labelSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
