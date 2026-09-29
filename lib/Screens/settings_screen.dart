// ============================================================
//  settings_screen.dart  ·  NEXORA BUSINESS
//  Configuración premium con panel de sincronización
// ============================================================

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../responsive_helper.dart';

// ============================================================
//  Acentos compartidos
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const pink      = Color(0xFFEC4899);
  static const indigo    = Color(0xFF6366F1);
  static const textMuted = Color(0xFF607B9E);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg          => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface     => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2    => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh    => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid     => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted   => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border      => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _taxaVentasController = TextEditingController();
  final TextEditingController _taxaUtilidadesController = TextEditingController();
  final TextEditingController _tasaCambioController = TextEditingController();

  String _themeMode = 'system';

  late AnimationController _animationController;

  bool _exportando = false;
  bool _reintentando = false;
  bool _limpiando = false;

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<AppProvider>(context, listen: false);

    _taxaVentasController.text = provider.taxaVentas.toStringAsFixed(2);
    _taxaUtilidadesController.text =
        provider.taxaUtilidades.toStringAsFixed(2);
    _tasaCambioController.text = provider.tasaCambioUSD.toStringAsFixed(2);

    final mode = provider.themeMode;
    if (mode == ThemeMode.light) {
      _themeMode = 'light';
    } else if (mode == ThemeMode.dark) {
      _themeMode = 'dark';
    } else {
      _themeMode = 'system';
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _taxaVentasController.dispose();
    _taxaUtilidadesController.dispose();
    _tasaCambioController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          FadeTransition(
            opacity: CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 14,
                14,
                isDesktop ? 32 : 14,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isDesktop ? 1050 : 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroHeader(provider, p, isDesktop),
                      const SizedBox(height: 24),
                      _sectionTitle(p, Icons.point_of_sale_rounded,
                          'Modo de ventas',
                          'Define cómo quieres registrar las operaciones.'),
                      const SizedBox(height: 12),
                      _salesMode(provider, p, isDesktop),
                      const SizedBox(height: 26),
                      _sectionTitle(p, Icons.cloud_sync_rounded,
                          'Sincronización',
                          'Revisa el estado de la cola de operaciones pendientes.'),
                      const SizedBox(height: 12),
                      _syncSection(provider, p, isDesktop),
                      const SizedBox(height: 26),
                      _sectionTitle(p, Icons.currency_exchange_rounded,
                          'Valores del negocio',
                          'Configura tasas e impuestos de la aplicación.'),
                      const SizedBox(height: 12),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _exchangeCard(provider, p)),
                            const SizedBox(width: 16),
                            Expanded(child: _taxesCard(provider, p)),
                          ],
                        )
                      else ...[
                        _exchangeCard(provider, p),
                        const SizedBox(height: 14),
                        _taxesCard(provider, p),
                      ],
                      const SizedBox(height: 26),
                      _sectionTitle(p, Icons.palette_outlined, 'Apariencia',
                          'Personaliza cómo se muestra Nexora.'),
                      const SizedBox(height: 12),
                      _themeCard(provider, p),
                      const SizedBox(height: 30),
                      _versionFooter(provider, p),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FONDO
  // ============================================================
  Widget _background(_P p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -160,
              child: _orb(420, _C.primary.withOpacity(p.dark ? .12 : .07)),
            ),
            Positioned(
              bottom: -220,
              left: -140,
              child: _orb(440, _C.cyan.withOpacity(p.dark ? .10 : .06)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  APP BAR
  // ============================================================
  PreferredSizeWidget _appBar(_P p) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Configuración',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Personaliza tu experiencia',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  HERO HEADER
  // ============================================================
  Widget _heroHeader(AppProvider provider, _P p, bool isDesktop) {
    final isCierre = provider.usaCierreDiario;
    final modeColor = isCierre ? _C.warning : _C.primary;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _C.gradBrand,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.42),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 60 : 54,
            height: isDesktop ? 60 : 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
            child: const Icon(Icons.tune_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajustes de Nexora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Adapta los valores y preferencias a la forma en que trabajas.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.90),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(.32)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCierre ? 'Cierre diario' : 'Tiempo real',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION TITLE
  // ============================================================
  Widget _sectionTitle(
      _P p, IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _C.primary.withOpacity(.20),
                _C.primary.withOpacity(.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.primary.withOpacity(.24)),
          ),
          child: Icon(icon, size: 17, color: _C.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: p.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  SALES MODE
  // ============================================================
  Widget _salesMode(AppProvider provider, _P p, bool isDesktop) {
    final tiempoReal = provider.modoVentas == AppProvider.MODO_TIEMPO_REAL;
    final cierreDiario = provider.modoVentas == AppProvider.MODO_CIERRE_DIARIO;

    final cards = [
      _modeCard(
        p: p,
        selected: tiempoReal,
        color: _C.primary,
        icon: Icons.point_of_sale_rounded,
        title: 'Tiempo real',
        subtitle: 'Registra cada venta al instante',
        description:
            'Cada operación se registra inmediatamente y el inventario se actualiza en el momento.',
        bullets: const [
          'Stock actualizado automáticamente',
          'Método de pago por operación',
          'Facturación inmediata',
        ],
        onTap: () =>
            provider.setModoVentas(AppProvider.MODO_TIEMPO_REAL),
      ),
      _modeCard(
        p: p,
        selected: cierreDiario,
        color: _C.warning,
        icon: Icons.event_available_rounded,
        title: 'Cierre diario',
        subtitle: 'Calcula las ventas por diferencia',
        description:
            'Registra el stock al comenzar y al finalizar la jornada. Nexora calcula automáticamente lo vendido.',
        bullets: const [
          'Stock inicial al abrir',
          'Stock restante al cerrar',
          'Ventas calculadas automáticamente',
        ],
        onTap: () =>
            provider.setModoVentas(AppProvider.MODO_CIERRE_DIARIO),
      ),
    ];

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        ),
      );
    }
    return Column(
      children: [
        cards[0],
        const SizedBox(height: 12),
        cards[1],
      ],
    );
  }

  Widget _modeCard({
    required _P p,
    required bool selected,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<String> bullets,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(p.dark ? .14 : .06)
                : p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : p.border,
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: [color, color.withOpacity(.75)])
                          : null,
                      color: selected ? null : color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(.32),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: p.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : Colors.transparent,
                      border: Border.all(
                        color: selected ? color : p.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: p.textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: p.border),
              const SizedBox(height: 10),
              ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded,
                            size: 15, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.textMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  SYNC SECTION
  // ============================================================
  Widget _syncSection(AppProvider provider, _P p, bool isDesktop) {
    final pendientes = provider.pendientesDetalle;
    final total = pendientes.length;
    final bloqueados = provider.contarPendientesBloqueados;

    if (total == 0) {
      return _card(
        p,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.success.withOpacity(.22),
                    _C.cyan.withOpacity(.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _C.success.withOpacity(.28)),
              ),
              child: const Icon(Icons.cloud_done_rounded,
                  color: _C.success, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Todo sincronizado',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: p.textHigh,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'No hay operaciones pendientes.',
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradSuccess),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: _C.success.withOpacity(.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final hayBloqueados = bloqueados > 0;
    final color = hayBloqueados ? _C.danger : _C.warning;

    return _card(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacity(.28)),
                ),
                child: Icon(
                  hayBloqueados
                      ? Icons.error_rounded
                      : Icons.sync_problem_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total operación${total == 1 ? '' : 'es'} pendiente${total == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hayBloqueados
                          ? '$bloqueados con error · revísalas'
                          : 'Pulsa "Reintentar" para procesarlas',
                      style: TextStyle(fontSize: 11.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: color.withOpacity(.32)),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: p.border),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _syncBtn(
                label: _exportando ? 'Exportando…' : 'Exportar .json',
                icon: Icons.download_rounded,
                color: _C.info,
                loading: _exportando,
                onPressed:
                    _exportando ? null : () => _exportarPendientes(provider),
              ),
              _syncBtn(
                label: 'Copiar JSON',
                icon: Icons.copy_rounded,
                color: _C.cyan,
                onPressed: () => _copiarJSON(provider),
              ),
              _syncBtn(
                label: _reintentando ? 'Reintentando…' : 'Reintentar',
                icon: Icons.refresh_rounded,
                color: _C.purple,
                loading: _reintentando,
                onPressed:
                    _reintentando ? null : () => _reintentarTodo(provider),
              ),
              _syncBtn(
                label: 'Ver detalles',
                icon: Icons.list_alt_rounded,
                color: _C.indigo,
                onPressed: () => _verDetallePendientes(provider),
              ),
              if (hayBloqueados)
                _syncBtn(
                  label: _limpiando
                      ? 'Limpiando…'
                      : 'Limpiar ($bloqueados)',
                  icon: Icons.cleaning_services_rounded,
                  color: _C.danger,
                  loading: _limpiando,
                  onPressed:
                      _limpiando ? null : () => _limpiarBloqueados(provider),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(p.dark ? .10 : .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si el reintento falla, exporta el archivo .json y envíalo a soporte. Ellos lo procesarán manualmente.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: p.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Material(
      color: color.withOpacity(.12),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onPressed,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  ACCIONES SYNC
  // ============================================================
  Future<void> _exportarPendientes(AppProvider provider) async {
    setState(() => _exportando = true);
    try {
      final path = await provider.exportarPendientesAFile();
      if (!mounted) return;

      if (path == null) {
        _snack('No se pudo exportar el archivo', error: true);
        return;
      }

      try {
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Cola de pendientes Nexora',
          text: 'Adjunto la cola de pendientes para diagnóstico.',
        );
      } catch (_) {}

      if (!mounted) return;
      _snack('Archivo exportado en: $path');
    } catch (e) {
      if (!mounted) return;
      _snack('Error al exportar: $e', error: true);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _copiarJSON(AppProvider provider) async {
    try {
      final jsonStr = provider.exportarPendientesJSON();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (!mounted) return;
      _snack(
          'JSON copiado (${provider.pendientesDetalle.length} pendientes)');
    } catch (e) {
      if (!mounted) return;
      _snack('Error al copiar: $e', error: true);
    }
  }

  Future<void> _reintentarTodo(AppProvider provider) async {
    setState(() => _reintentando = true);
    try {
      final total = await provider.reiniciarTodosLosIntentos();
      if (!mounted) return;
      _snack('Reintentando $total operación${total == 1 ? '' : 'es'}…');
      await provider.sincronizarManual();
      if (!mounted) return;
      final restantes = provider.pendientesDetalle.length;
      if (restantes == 0) {
        _snack('¡Todo sincronizado!');
      } else {
        _snack('Quedan $restantes pendientes.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error al reintentar: $e', error: true);
    } finally {
      if (mounted) setState(() => _reintentando = false);
    }
  }

  Future<void> _limpiarBloqueados(AppProvider provider) async {
    final bloqueados = provider.contarPendientesBloqueados;
    if (bloqueados == 0) return;

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.cleaning_services_rounded,
                  color: _C.danger, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Limpiar bloqueados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: Text(
          'Se eliminarán $bloqueados operaciones que fallaron más de 5 veces.\n\n'
          '⚠️ Esta acción no se puede deshacer.',
          style: TextStyle(color: p.textMid, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _limpiando = true);
    try {
      final eliminados = await provider.limpiarPendientesConError();
      if (!mounted) return;
      _snack('Se eliminaron $eliminados pendientes bloqueados');
    } catch (e) {
      if (!mounted) return;
      _snack('Error al limpiar: $e', error: true);
    } finally {
      if (mounted) setState(() => _limpiando = false);
    }
  }

  void _verDetallePendientes(AppProvider provider) {
    final pendientes = provider.pendientesDetalle;
    if (pendientes.isEmpty) {
      _snack('No hay pendientes para mostrar');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _PendientesDialog(
        provider: provider,
        pendientesIniciales: pendientes,
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    mostrarSnackBar(
      mensaje: msg,
      esExito: !error,
    );
  }

  // ============================================================
  //  EXCHANGE CARD
  // ============================================================
  Widget _exchangeCard(AppProvider provider, _P p) {
    return _card(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(p, Icons.currency_exchange_rounded, 'Tasa de cambio',
              'Conversión utilizada para operaciones en USD.', _C.success),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.success.withOpacity(p.dark ? .14 : .08),
                  _C.cyan.withOpacity(p.dark ? .06 : .03),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _C.success.withOpacity(.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradSuccess),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withOpacity(.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.attach_money_rounded,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1 USD equivale a',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: p.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${provider.tasaCambioUSD.toStringAsFixed(2)} CUP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: p.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _inputField(
            p: p,
            controller: _tasaCambioController,
            label: 'Nueva tasa en CUP',
            icon: Icons.edit_rounded,
            color: _C.success,
            suffix: 'CUP',
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val > 0) provider.setTasaCambioUSD(val);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  TAXES CARD
  // ============================================================
  Widget _taxesCard(AppProvider provider, _P p) {
    return _card(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(p, Icons.receipt_long_rounded, 'Impuestos',
              'Valores orientativos para el módulo fiscal.', _C.purple),
          const SizedBox(height: 16),
          _taxField(
            p: p,
            controller: _taxaVentasController,
            label: 'Impuesto sobre ventas',
            color: _C.purple,
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) provider.setTaxaVentas(val);
            },
          ),
          const SizedBox(height: 12),
          _taxField(
            p: p,
            controller: _taxaUtilidadesController,
            label: 'Impuesto sobre utilidades',
            color: _C.indigo,
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) provider.setTaxaUtilidades(val);
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: p.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estos porcentajes son orientativos. Verifica siempre las obligaciones fiscales aplicables.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: p.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxField({
    required _P p,
    required TextEditingController controller,
    required String label,
    required Color color,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.22)),
          ),
          child: Icon(Icons.percent_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _inputField(
            p: p,
            controller: controller,
            label: label,
            icon: null,
            color: color,
            suffix: '%',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  THEME CARD
  // ============================================================
  Widget _themeCard(AppProvider provider, _P p) {
    return _card(
      p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.pink.withOpacity(.22),
                      _C.purple.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.pink.withOpacity(.24)),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: _C.pink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo de apariencia',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Selecciona cómo quieres visualizar la aplicación.',
                      style: TextStyle(
                          fontSize: 11.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _themeBtn(
                  p: p,
                  value: 'light',
                  label: 'Claro',
                  icon: Icons.light_mode_rounded,
                  provider: provider,
                  color: _C.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeBtn(
                  p: p,
                  value: 'dark',
                  label: 'Oscuro',
                  icon: Icons.dark_mode_rounded,
                  provider: provider,
                  color: _C.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeBtn(
                  p: p,
                  value: 'system',
                  label: 'Sistema',
                  icon: Icons.brightness_auto_rounded,
                  provider: provider,
                  color: _C.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeBtn({
    required _P p,
    required String value,
    required String label,
    required IconData icon,
    required AppProvider provider,
    required Color color,
  }) {
    final selected = _themeMode == value;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _themeMode = value);
          if (value == 'light') {
            provider.setThemeMode(ThemeMode.light);
          } else if (value == 'dark') {
            provider.setThemeMode(ThemeMode.dark);
          } else {
            provider.setThemeMode(ThemeMode.system);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(p.dark ? .16 : .08)
                : p.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : p.border,
              width: selected ? 1.6 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(.20),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? color : p.textMuted,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight:
                      selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? color : p.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  COMPONENTES
  // ============================================================
  Widget _card(_P p, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: child,
    );
  }

  Widget _cardHeader(
      _P p, IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required _P p,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required Color color,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: p.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: p.textMuted) : null,
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: color, width: 1.6),
        ),
      ),
    );
  }

  Widget _versionFooter(AppProvider provider, _P p) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 20, color: p.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            'Nexora Business',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: p.textHigh,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Versión ${provider.currentVersion}',
            style: TextStyle(
              fontSize: 10.5,
              color: p.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

// ============================================================
//  DIÁLOGO DE PENDIENTES
// ============================================================
class _PendientesDialog extends StatefulWidget {
  final AppProvider provider;
  final List<Map<String, dynamic>> pendientesIniciales;

  const _PendientesDialog({
    required this.provider,
    required this.pendientesIniciales,
  });

  @override
  State<_PendientesDialog> createState() => _PendientesDialogState();
}

class _PendientesDialogState extends State<_PendientesDialog> {
  late List<Map<String, dynamic>> _pendientes;

  @override
  void initState() {
    super.initState();
    _pendientes =
        List<Map<String, dynamic>>.from(widget.pendientesIniciales);
  }

  void _refrescar() {
    setState(() {
      _pendientes = List<Map<String, dynamic>>.from(
        widget.provider.pendientesDetalle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    return Dialog(
      backgroundColor: p.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _C.indigo.withOpacity(.22),
                          _C.indigo.withOpacity(.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _C.indigo.withOpacity(.24)),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        color: _C.indigo, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cola de pendientes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: p.textHigh,
                          ),
                        ),
                        Text(
                          '${_pendientes.length} operación${_pendientes.length == 1 ? '' : 'es'} en cola',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: p.textMid),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            Expanded(
              child: _pendientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _C.success.withOpacity(.20),
                                  _C.cyan.withOpacity(.06),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                size: 42, color: _C.success),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '¡Todo sincronizado!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: p.textHigh,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _pendientes.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: p.border,
                      ),
                      itemBuilder: (_, i) =>
                          _pendienteTile(_pendientes[i], p),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendienteTile(Map<String, dynamic> p, _P palette) {
    final tabla = p['tabla']?.toString() ?? '—';
    final accion = p['accion']?.toString() ?? '—';
    final id = p['id']?.toString() ?? '—';
    final key = p['_key']?.toString() ?? '';
    final intentos = (p['intentos'] ?? 0) as int;
    final error = p['ultimoError']?.toString();
    final errorFecha = p['ultimoErrorFecha']?.toString();
    final timestamp = p['timestamp']?.toString() ?? '—';

    final color = intentos >= 5
        ? _C.danger
        : (intentos > 0 ? _C.warning : _C.primary);

    return ExpansionTile(
      tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(.22),
              color.withOpacity(.06),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(.28)),
        ),
        child: Icon(
          intentos >= 5
              ? Icons.error_rounded
              : (intentos > 0
                  ? Icons.warning_amber_rounded
                  : Icons.sync_rounded),
          color: color,
          size: 18,
        ),
      ),
      title: Text(
        '$tabla · $accion',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
          color: palette.textHigh,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          'ID: ${id.length > 12 ? '${id.substring(0, 12)}…' : id} · '
          'Intentos: $intentos',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textMuted,
          ),
        ),
      ),
      children: [
        _infoLine(palette, 'Clave interna', key),
        _infoLine(palette, 'Timestamp', timestamp),
        if (errorFecha != null)
          _infoLine(palette, 'Último error', errorFecha),
        if (error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.danger.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.danger.withOpacity(.24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: _C.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    error,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: _C.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await widget.provider.reiniciarIntentosPendiente(key);
                  _refrescar();
                  if (mounted) {
                    mostrarSnackBar(
                        mensaje: 'Intentos reiniciados', esExito: true);
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.purple,
                  side: BorderSide(color: _C.purple.withOpacity(.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: palette.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text('Eliminar pendiente',
                          style: TextStyle(
                              color: palette.textHigh,
                              fontWeight: FontWeight.w900)),
                      content: Text(
                          '¿Eliminar esta operación de $tabla?\n\nSe perderá del historial.',
                          style: TextStyle(color: palette.textMid)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: Text('Cancelar',
                              style: TextStyle(color: palette.textMid)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar',
                              style:
                                  TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  await widget.provider.eliminarPendiente(key);
                  _refrescar();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.danger,
                  side: BorderSide(color: _C.danger.withOpacity(.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoLine(_P p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.textMuted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: p.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}