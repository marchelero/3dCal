// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_locale.dart';
import '../../../../l10n/es_bo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/max_width_scroll_view.dart';
import '../widgets/progress_pills.dart';
import '../widgets/ticket_preview_card.dart';
import 'steps/filament_step.dart';
import 'steps/printer_step.dart';
import 'steps/profit_step.dart';
import 'steps/style_currency_step.dart';
import 'steps/summary_step.dart';
import 'steps/welcome_language_step.dart';

/// Flujo continuo de setup de primera ejecución (rediseño onboarding 2026-10).
///
/// Un solo PageView deslizable de 6 pantallas:
/// 0. Bienvenida + idioma ([WelcomeLanguageStep], sin ticket preview).
/// 1–4. Decisiones ([StyleCurrencyStep], [PrinterStep], [FilamentStep],
/// [ProfitStep]) con [TicketPreviewCard].
/// 5. Cierre ([SummaryStep], terminal; sin ticket preview).
///
/// Fondo con gradiente animado por página ([AppTheme.onboardingSlideColors],
/// 400 ms easeInOut, texto blanco AA verificado), [ProgressPills] tappables
/// y back del sistema = página anterior (en el paso 0 permite pop).
/// Sin botones "Guardar" (AC-07): cada elección persiste al tocar vía los
/// notifiers existentes. **Cambio de criterio 2026-10-11 (usuario)**: se
/// agregan botones discretos "Atrás"/"Siguiente" en una barra inferior
/// (FilledButton.tonal + FilledButton — no compiten con el CTA del cierre);
/// se ven en los pasos 0–4 (paso 0 solo "Siguiente"; el cierre no la
/// muestra). Conviven con swipe y pills; los botones van CENTRADOS con un
/// gap [AppSpacing.md] entre ambos. "Siguiente" se PINTA (primario) cuando
/// el gate deja avanzar y queda tonal mientras falte impresora/filamento —
/// señal visual de "ya podés proseguir".
///
/// **Borradores sin auto-guard (cambio 2026-10-11)**: los formularios de
/// impresora/presets (página 2) y filamento (página 3) se persisten SOLO
/// al navegar: `_goToPage` hace `commitDraft()` del paso que se deja (con
/// await, antes del gate, para que "Siguiente" registre y luego pase) y un
/// `NotificationListener` con `ScrollStartNotification` (`dragDetails !=
/// null`) lo hace al arrancar un swipe del usuario.
///
/// **Gate de obligatoriedad (cambio de alcance 2026-10-11)**: impresora
/// (página 2) y filamento (página 3) son obligatorios — sin impresora
/// default no se puede avanzar más allá de la página 2, y sin filamento
/// default más allá de la 3. El avance bloqueado (swipe, pill o botón
/// "Siguiente") muestra un SnackBar hint (`setupNeedPrinter` /
/// `setupNeedFilament`) y hace snap-back a la página actual (con el botón
/// "Siguiente" no hay cambio de página, solo el hint); retroceder siempre
/// está permitido. Los pasos 0, 1 y 4 no tienen gate (tienen defaults
/// auto-seleccionables).
class SetupFlowPage extends ConsumerStatefulWidget {
  const SetupFlowPage({super.key});

  @override
  ConsumerState<SetupFlowPage> createState() => _SetupFlowPageState();
}

class _SetupFlowPageState extends ConsumerState<SetupFlowPage> {
  final _pageCtrl = PageController();

  // Llaves para el commit del borrador de cada paso al navegar (sin
  // auto-guard con debounce): PrinterStep (página 2) y FilamentStep
  // (página 3). `currentState` es null si el step no está montado.
  final _printerKey = GlobalKey<PrinterStepState>();
  final _filamentKey = GlobalKey<FilamentStepState>();

  // BUG-006: el índice de página es estado UI local efímero (no es estado de
  // negocio); setState está permitido bajo la excepción documentada.
  int _currentPage = 0;

  /// MED-3 (auditoría 2026-10-14): Future del commit-on-swipe en curso.
  /// El gesto lo dispara fire-and-forget (no se bloquea el drag), pero el
  /// container conserva el Future para poder esperarlo en [onPageChanged]
  /// antes de evaluar el gate — sin esto el create corre en background y
  /// el gate comparaba contra el provider aún vacío → snap-back + hint
  /// engañoso aunque el form estuviera completo.
  Future<void>? _pendingSwipeCommit;

  /// Colores por página. Single source of truth en
  /// [AppTheme.onboardingSlideColors] (AA 4.5:1 con texto blanco).
  static List<Color> get _pageColors => AppTheme.onboardingSlideColors;

  /// Páginas 1–4 muestran el ticket preview (paso 0 y cierre no).
  bool get _showTicketPreview => _currentPage >= 1 && _currentPage <= 4;

  /// Página máxima permitida por el gate de obligatoriedad. Se relee en cada
  /// navegación (no cacheada): al registrarse la impresora/filamento el gate
  /// se abre al instante (swipe/pill/"Siguiente" posterior lo permiten).
  int get _maxAllowedPage {
    if (ref.read(defaultPrinterProvider) == null) return 2;
    if (ref.read(defaultFilamentProvider) == null) return 3;
    return 5;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// SnackBar hint del gate: dice qué falta registrar para poder avanzar.
  void _showGateHint() {
    final hint = ref.read(defaultPrinterProvider) == null
        ? EsBO.setupNeedPrinter
        : EsBO.setupNeedFilament;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(AppSnackBar.info(context, hint));
  }

  /// Va a [index] tras hacer commit del borrador de la página que se deja.
  /// El commit se AWAITA antes del gate: si el usuario escribió la marca/
  /// precio y tocó "Siguiente" sin salir del campo, el registro se persiste
  /// primero y el gate recién entonces se evalúa (el default queda en el
  /// provider al leer `_maxAllowedPage`).
  Future<void> _goToPage(int index) async {
    if (!_pageCtrl.hasClients) return;
    if (index != _currentPage) {
      // `currentState` es null si el step no está montado — siempre `?.`.
      // commitDraft también espera un commit fire-and-forget en curso
      // (MED-3: swipe + "Siguiente" rápido), así que el await de abajo
      // cubre ambos caminos antes de evaluar el gate.
      if (_currentPage == 2) await _printerKey.currentState?.commitDraft();
      if (_currentPage == 3) await _filamentKey.currentState?.commitDraft();
      if (!mounted) return;
    }
    if (index > _maxAllowedPage) {
      _showGateHint();
      return;
    }
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// MED-3: handler de cambio de página (swipe/pills). Espera el commit
  /// fire-and-forget del swipe pendiente (si lo hay) ANTES de evaluar el
  /// gate: el create es async (drift) y sin este await el gate comparaba
  /// contra el provider aún vacío y rebotaba el swipe con un hint
  /// engañoso. Decisión: await directo del Future del commit (un solo
  /// INSERT/UPDATE) en lugar de poll/retry post-frame — el costo es el de
  /// la escritura y el resultado es determinista.
  Future<void> _handlePageChanged(int i) async {
    final pending = _pendingSwipeCommit;
    if (pending != null) {
      _pendingSwipeCommit = null;
      await pending;
      if (!mounted) return;
    }
    // Gate de obligatoriedad: un swipe que cruce el límite (impresora/
    // filamento sin registrar) rebota a la página actual + SnackBar hint.
    // Retroceso siempre OK.
    if (i > _maxAllowedPage) {
      _showGateHint();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageCtrl.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }
    setState(() => _currentPage = i);
  }

  /// Envuelve cada paso con el scroll (teclado/web safe) y el ancho máximo
  /// centrado en viewports grandes — patrón de initial_config_page. El
  /// padding inferior (96) reserva el espacio de la barra Atrás/Siguiente
  /// para que el último elemento de cada paso quede visible/scrollable.
  Widget _stepBox(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: MaxWidthScrollView(maxWidth: 480, child: child),
    );
  }

  /// Barra inferior de navegación discreta (pasos 0–4): "Atrás"
  /// (FilledButton.tonal) y "Siguiente" CENTRADOS con un gap
  /// [AppSpacing.md] entre ambos; no compiten con el CTA del cierre.
  /// Paso 0 sin "Atrás" (solo "Siguiente" centrado); el cierre (página 5)
  /// no la muestra — su CTA es `configStartButton`.
  ///
  /// **Semáforo de "Siguiente" (usuario 2026-10-11)**: el botón se PINTA
  /// (FilledButton primario) cuando el gate permite avanzar — es la señal
  /// visual de "ya podés proseguir"; en páginas con gate sin cumplir
  /// (impresora/filamento sin registrar) queda tonal (sin color). Sigue
  /// siendo tappable en ambos estados: si está bloqueado y lo tocás muestra
  /// el hint del gate (`_goToPage`).
  Widget _buildNavBar() {
    // watch (no read): al registrarse impresora/filament el botón se repinta
    // al instante sin esperar otra interacción.
    final printer = ref.watch(defaultPrinterProvider);
    final filament = ref.watch(defaultFilamentProvider);
    final canProceed = switch (_currentPage) {
      2 => printer != null,
      3 => filament != null,
      _ => true,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          if (_currentPage > 0)
            FilledButton.tonal(
              key: const ValueKey('setup-nav-back'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _goToPage(_currentPage - 1),
              child: Text(EsBO.setupBack),
            ),
          // Estilo local: el tema global define FilledButton con
          // minimumSize width=Infinity (CTAs full-width); dentro de un Row
          // eso provoca un crash de layout (BoxConstraints w=Infinity).
          // Primario cuando puede avanzar; tonal cuando el gate bloquea.
          // Wrap (no Row): en ventanas extremas (320 px) Atrás+Siguiente no
          // entran en una línea y el Wrap los baja en vez de overflowear.
          if (canProceed)
            FilledButton(
              key: const ValueKey('setup-nav-next'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _goToPage(_currentPage + 1),
              child: Text(EsBO.setupNext),
            )
          else
            FilledButton.tonal(
              key: const ValueKey('setup-nav-next'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _goToPage(_currentPage + 1),
              child: Text(EsBO.setupNext),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild global al cambiar idioma (EsBO delega en el impl activo).
    ref.watch(localeProvider);
    final bgColor = _pageColors[_currentPage % _pageColors.length];

    return PopScope<void>(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        // Back del sistema: retrocede un paso sin salir del flujo; en el
        // paso 0 canPop=true deja que el pop continúe normalmente.
        if (didPop || _currentPage == 0) return;
        _goToPage(_currentPage - 1);
      },
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgColor,
                bgColor.withValues(alpha: 0.85),
                bgColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
                  ),
                  child: ProgressPills(current: _currentPage, onTap: _goToPage),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    // Arranque de swipe del usuario (dragDetails != null):
                    // commit del borrador de la página actual. El commit es
                    // fire-and-forget (el gesto continúa) pero su Future se
                    // guarda en [_pendingSwipeCommit] para que
                    // [onPageChanged] lo espere antes de evaluar el gate
                    // (MED-3).
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        // `currentState` es null si el step no está montado.
                        if (_currentPage == 2) {
                          _pendingSwipeCommit = _printerKey.currentState
                              ?.commitDraft();
                        }
                        if (_currentPage == 3) {
                          _pendingSwipeCommit = _filamentKey.currentState
                              ?.commitDraft();
                        }
                      }
                      return false;
                    },
                    child: PageView(
                      controller: _pageCtrl,
                      onPageChanged: _handlePageChanged,
                      children: [
                        _stepBox(const WelcomeLanguageStep()),
                        _stepBox(const StyleCurrencyStep()),
                        // Sin auto-avance (2026-10-11): registrar muestra
                        // SnackBar + tarjeta saved; el usuario navega con la
                        // barra Atrás/Siguiente, swipe o pills. El borrador
                        // del form se persiste solo al navegar (commitDraft).
                        _stepBox(PrinterStep(key: _printerKey)),
                        _stepBox(FilamentStep(key: _filamentKey)),
                        _stepBox(const ProfitStep()),
                        _stepBox(const SummaryStep()),
                      ],
                    ),
                  ),
                ),
                if (_showTicketPreview)
                  // Slot al fondo del Column (no overlay): el PageView vive
                  // en un Expanded arriba, así que el ticket nunca tapa el
                  // scroll y su altura está acotada por el viewport. Key por
                  // página: cambiar de página re-monta el ticket y lo deja
                  // colapsado (estado expand/collapse UI-local efímero).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                    ),
                    child: TicketPreviewCard(
                      key: ValueKey('setup-ticket-$_currentPage'),
                    ),
                  ),
                // Barra Atrás/Siguiente: visible en pasos 0–4; el cierre la
                // omite (su acción es el CTA configStartButton).
                if (_currentPage < 5) _buildNavBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
