// ============================================================
//  home_screen.dart  ·  NEXORA BUSINESS
//  Home v5.2 · "Command Center"
//  · Carrusel de más vendidos con imágenes y efectos
//  · Panel "Tienda en línea" (Mi tienda + Red Nexora)
//  · Panel "Más acciones" con el resto de módulos
//  · Command bar simplificada (solo lo esencial)
//  · Manejo de actualización (obligatoria / opcional)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nexora_business/Screens/mi_tienda_screen.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'about_screen.dart';
import 'servicio_cancelado_screen.dart';
import 'terms_screen.dart';
import 'user_guide_screen.dart';

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
  static const gold      = Color(0xFFCA8A04);
  static const orange    = Color(0xFFF97316);
  static const teal      = Color(0xFF14B8A6);
  static const muted     = Color(0xFF607B9E);

  static const network    = Color(0xFF06B6D4);
  static const myBusiness = Color(0xFF8B5CF6);

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm    = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const gradDanger  = [Color(0xFFEF4444), Color(0xFFEC4899)];
  static const gradGold    = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
  static const gradPurple  = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const gradPremium = [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)];
  static const gradNetwork = [Color(0xFF06B6D4), Color(0xFF3B82F6)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg =>
      dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface =>
      dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3 =>
      dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);
  Color get textHigh =>
      dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid =>
      dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted =>
      dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border =>
      dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong =>
      dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);
  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.42)
              : const Color(0xFF0A1A33).withOpacity(.10),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];
  List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.55)
              : const Color(0xFF0A1A33).withOpacity(.16),
          blurRadius: 42,
          offset: const Offset(0, 18),
        ),
      ];
  List<BoxShadow> glow(Color c, {double o = 0.24}) => [
        BoxShadow(
          color: c.withOpacity(dark ? o + 0.10 : o),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}

class _QuickAction {
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final Color color;
  final String? badge;
  const _QuickAction({
    required this.label,
    required this.sub,
    required this.icon,
    required this.route,
    required this.color,
    this.badge,
  });
}

class _CommandItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final String? badge;
  final int level;
  const _CommandItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
    this.level = 4,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _KEY_ULTIMO_AVISO_PAGO = 'ultimoAvisoPagoFecha';
  static const String _KEY_FORCE_UPDATE_DISMISSED = 'forceUpdateDismissedV';

  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.mostrarGuia) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserGuideScreen()),
        ).then((_) => provider.marcarGuiaVista());
      }
      _checkPaymentReminder(provider);
      _checkForceUpdate(provider);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  bool _isAdmin(AppProvider p) => p.rol == 'dueno' || p.rol == 'admin';
  bool _isManager(AppProvider p) =>
      _isAdmin(p) || p.rol == 'gerente' || p.rol == 'gestor';

  String _roleLabel(String? rol) {
    switch (rol) {
      case 'dueno':
      case 'admin':
        return 'Dueño';
      case 'gerente':
      case 'gestor':
        return 'Gerente';
      case 'vendedor':
        return 'Vendedor';
      default:
        return 'Usuario';
    }
  }

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return NumberFormat('#,###').format(n);
    return NumberFormat('#,##0.00').format(n);
  }

  String _fmtCompact(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  double _getMetaPeriodo(AppProvider provider) {
    if (provider.meta == null) return 1000.0;
    switch (provider.periodoSeleccionado) {
      case 1:
        return provider.meta!.metaSemanal;
      case 2:
        return provider.meta!.metaMensual;
      default:
        return provider.meta!.metaDiaria;
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // ─── Trial ───────────────────────────────────────────────────
  bool _trialActivo(AppProvider provider) {
    if (!_isAdmin(provider)) return false;
    if (provider.fechaRegistro == null) return false;

    final fAprob =
        provider.settingsBox?.get(AppProvider.KEY_FECHA_APROBACION_PAGO);
    if (fAprob != null) return false;

    final fVenc = provider.settingsBox?.get(AppProvider.KEY_FECHA_VENCIMIENTO);
    if (fVenc != null) return false;

    final dias =
        DateTime.now().difference(provider.fechaRegistro!).inDays;
    return dias < DIAS_PRUEBA;
  }

  int _diasTrialRestantes(AppProvider provider) {
    if (provider.fechaRegistro == null) return 0;
    final usados =
        DateTime.now().difference(provider.fechaRegistro!).inDays;
    return (DIAS_PRUEBA - usados).clamp(0, DIAS_PRUEBA);
  }

  // ─── Tienda en línea ─────────────────────────────────────────
  bool _tieneTiendaActiva(AppProvider provider) {
    if (provider.empresaId == null) return false;
    try {
      final raw = provider.catalogosBox
          .get(keyTiendaDeEmpresa(provider.empresaId!));
      if (raw == null) return false;
      if (raw is Map) {
        final activa = raw['activa'];
        if (activa is bool) return activa;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Update ──────────────────────────────────────────────────
  // Marca como obligatoria si el major de la versión más nueva
  // es mayor que el actual (ej. 2.x → 3.x). Además, si el server
  // expone `force_update = true` (campo en app_versions), el
  // provider debería exponerlo — pero mientras tanto usamos esta
  // heurística segura.
  bool _isForceUpdate(AppProvider provider) {
    if (!provider.hasUpdate) return false;
    final remote = provider.latestVersion;
    final current = provider.currentVersion;
    if (remote == null || current.isEmpty) return false;
    try {
      final r = remote.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      if (r.isEmpty || c.isEmpty) return false;
      return r[0] > c[0];
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkForceUpdate(AppProvider provider) async {
    if (!_isForceUpdate(provider)) return;
    final v = provider.latestVersion ?? '';
    // Si ya lo descartó para esta versión, no molestar de nuevo
    final dismissed =
        provider.settingsBox?.get(_KEY_FORCE_UPDATE_DISMISSED) as String?;
    if (dismissed == v) return;
    if (!mounted) return;
    _showForceUpdateDialog(provider);
  }

  Future<void> _showForceUpdateDialog(AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final version = provider.latestVersion ?? '';
    final changelog = provider.changelog ?? '';
    final url = provider.downloadUrl ?? '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: p.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: _C.gradSuccess),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _C.success.withOpacity(.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.system_update_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actualización obligatoria',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: p.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Versión v$version',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: p.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Debes actualizar para seguir usando Nexora Business. '
                  'Esta versión corrige errores críticos y mejora la seguridad.',
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textMid,
                    height: 1.45,
                  ),
                ),
                if (changelog.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAMBIOS DE LA VERSIÓN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: p.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          changelog,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textMid,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (url.isNotEmpty) {
                      try {
                        await Share.share(url);
                      } catch (_) {}
                    }
                    if (provider.settingsBox != null && version.isNotEmpty) {
                      await provider.settingsBox!
                          .put(_KEY_FORCE_UPDATE_DISMISSED, version);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Actualizar ahora',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  QUICK ACTIONS
  // ============================================================
  List<_QuickAction> _primaryActions(AppProvider provider) {
    final isManager = _isManager(provider);
    final usaCierre = provider.usaCierreDiario;

    return [
      _QuickAction(
        label: usaCierre ? 'Cierre diario' : 'Nueva venta',
        sub: usaCierre ? 'Registrar jornada' : 'Registrar operación',
        icon: usaCierre
            ? Icons.event_available_rounded
            : Icons.point_of_sale_rounded,
        route: usaCierre ? '/cierre-diario' : '/nueva-venta',
        color: usaCierre ? _C.warning : _C.primary,
      ),
      _QuickAction(
        label: 'Historial',
        sub: 'Últimas ventas',
        icon: Icons.history_rounded,
        route: '/historial',
        color: _C.purple,
      ),
      if (isManager)
        _QuickAction(
          label: 'Inventario',
          sub: 'Productos y stock',
          icon: Icons.inventory_2_rounded,
          route: '/productos',
          color: _C.info,
          badge: () {
            final agotados =
                provider.productos.where((x) => x.stock <= 0).length;
            return agotados > 0 ? '$agotados' : null;
          }(),
        )
      else
        _QuickAction(
          label: 'Mi tienda',
          sub: 'Catálogo público',
          icon: Icons.storefront_rounded,
          route: '/mi-tienda',
          color: _C.indigo,
        ),
      if (isManager)
        _QuickAction(
          label: 'Reportes',
          sub: 'Analiza tu negocio',
          icon: Icons.insights_rounded,
          route: '/reportes',
          color: _C.teal,
        )
      else
        _QuickAction(
          label: 'Metas',
          sub: 'Tu progreso',
          icon: Icons.flag_rounded,
          route: '/metas',
          color: _C.gold,
        ),
    ];
  }

  /// Acciones que aparecen en el panel "Más acciones".
  /// Se excluyen las que ya están en la command bar o en el panel
  /// de Tienda en línea (Mi tienda / Red Nexora).
  List<_QuickAction> _secondaryActions(AppProvider provider) {
    final isManager = _isManager(provider);
    final isAdmin = _isAdmin(provider);

    final excluir = {
      '/mi-tienda',
      '/tiendas',
      '/historial',
      '/productos',
      '/nueva-venta',
      '/cierre-diario',
      '/reabastecer',
    };

    final todo = <_QuickAction>[
      if (isManager)
        _QuickAction(
          label: 'Clientes',
          sub: 'Contactos',
          icon: Icons.people_alt_rounded,
          route: '/clientes',
          color: _C.cyan,
        ),
      if (isManager)
        _QuickAction(
          label: 'Gastos',
          sub: 'Egresos',
          icon: Icons.receipt_long_rounded,
          route: '/gastos',
          color: _C.pink,
        ),
      if (isManager)
        _QuickAction(
          label: 'Reportes',
          sub: 'Análisis',
          icon: Icons.insights_rounded,
          route: '/reportes',
          color: _C.teal,
        ),
      if (isManager)
        _QuickAction(
          label: 'Metas',
          sub: 'Objetivos',
          icon: Icons.flag_rounded,
          route: '/metas',
          color: _C.gold,
        ),
      if (isManager)
        _QuickAction(
          label: 'Mermas',
          sub: 'Pérdidas',
          icon: Icons.warning_amber_rounded,
          route: '/mermas',
          color: _C.orange,
        ),
      if (isManager)
        _QuickAction(
          label: 'Movimientos',
          sub: 'Sucursales',
          icon: Icons.swap_horiz_rounded,
          route: '/movimientos-sucursales',
          color: _C.indigo,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Deudas',
          sub: 'Por cobrar',
          icon: Icons.money_off_rounded,
          route: '/deudas',
          color: _C.danger,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Vendedores',
          sub: 'Equipo',
          icon: Icons.people_outline_rounded,
          route: '/vendedores',
          color: _C.purple,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Estadísticas',
          sub: 'Ranking',
          icon: Icons.leaderboard_rounded,
          route: '/estadisticas-vendedores',
          color: _C.success,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Sucursales',
          sub: 'Puntos',
          icon: Icons.store_mall_directory_rounded,
          route: '/sucursales',
          color: _C.teal,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Nóminas',
          sub: 'Pagos',
          icon: Icons.payments_rounded,
          route: '/nominas',
          color: _C.success,
        ),
      if (isManager)
        _QuickAction(
          label: 'Facturación',
          sub: 'XML/Ticket',
          icon: Icons.receipt_rounded,
          route: '/facturacion',
          color: _C.indigo,
        ),
      if (isManager)
        _QuickAction(
          label: 'Módulo fiscal',
          sub: 'Impuestos',
          icon: Icons.request_quote_rounded,
          route: '/fiscal',
          color: _C.primary,
        ),
      if (isAdmin)
        _QuickAction(
          label: 'Realizar pago',
          sub: 'Suscripción',
          icon: Icons.account_balance_wallet_rounded,
          route: '/pago',
          color: _C.warning,
        ),
      _QuickAction(
        label: 'Soporte',
        sub: 'Ayuda',
        icon: Icons.support_agent_rounded,
        route: '/soporte',
        color: _C.primary,
      ),
      if (isAdmin)
        _QuickAction(
          label: 'Configuración',
          sub: 'Ajustes',
          icon: Icons.settings_rounded,
          route: '/settings',
          color: _C.muted,
        ),
    ];

    return todo.where((a) => !excluir.contains(a.route)).toList();
  }

  // ============================================================
  //  COMMAND BAR · orden derecha → izquierda por importancia
  //  Se prioriza: Venta · Inventario · Historial · Mi tienda · Red
  // ============================================================
  List<_CommandItem> _commandItems(AppProvider provider) {
    final agotados =
        provider.productos.where((x) => x.stock <= 0).length;

    // Se listan en orden IZQUIERDA → DERECHA; el más importante
    // queda más cerca del botón de venta (extremo derecho).
    return [
      _CommandItem(
        label: 'Red Nexora',
        icon: Icons.hub_rounded,
        color: _C.network,
        route: '/tiendas',
        level: 3,
      ),
      _CommandItem(
        label: 'Mi tienda',
        icon: Icons.storefront_rounded,
        color: _C.myBusiness,
        route: '/mi-tienda',
        level: 3,
      ),
      _CommandItem(
        label: 'Historial',
        icon: Icons.history_rounded,
        color: _C.purple,
        route: '/historial',
        level: 2,
      ),
      _CommandItem(
        label: 'Inventario',
        icon: Icons.inventory_2_rounded,
        color: _C.info,
        route: '/productos',
        badge: agotados > 0 ? '$agotados' : null,
        level: 2,
      ),
    ];
  }

  // ============================================================
  //  RECORDATORIO DE PAGO
  // ============================================================
  Future<void> _checkPaymentReminder(AppProvider provider) async {
    try {
      if (!_isAdmin(provider)) return;
      final info = _getPaymentInfo(provider);
      if (info == null) return;

      final proximo = info['proximoPago'] as DateTime;
      final dias = proximo.difference(DateTime.now()).inDays;
      if (dias > 3) return;

      final hoyStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final ultimo =
          provider.settingsBox?.get(_KEY_ULTIMO_AVISO_PAGO) as String?;
      if (ultimo == hoyStr) return;

      final tipo = info['tipo'] as String;
      String title;
      String body;

      if (dias < 0) {
        title = '⚠️ Pago vencido';
        body = tipo == 'prueba'
            ? 'Tu prueba finalizó. Realiza tu primer pago.'
            : 'Tu pago venció. Renueva para seguir usando Nexora.';
      } else if (dias == 0) {
        title = '💳 Pago vence hoy';
        body = tipo == 'prueba'
            ? 'Hoy termina tu prueba gratuita.'
            : 'Hoy vence tu pago mensual.';
      } else {
        title = '💳 Pago próximo';
        body = 'Vence en $dias día${dias == 1 ? '' : 's'}. '
            'Fecha: ${DateFormat('dd/MM/yyyy').format(proximo)}.';
      }

      await NotificationService.showNotification(
        id: 9001,
        title: title,
        body: body,
        payload: 'pago',
      );

      if (provider.settingsBox != null) {
        await provider.settingsBox!.put(_KEY_ULTIMO_AVISO_PAGO, hoyStr);
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _getPaymentInfo(AppProvider provider) {
    if (!_isAdmin(provider)) return null;
    final fAprobStr = provider.settingsBox
        ?.get(AppProvider.KEY_FECHA_APROBACION_PAGO) as String?;
    if (fAprobStr != null) {
      final fAprob = DateTime.tryParse(fAprobStr);
      if (fAprob != null) {
        return {
          'tipo': 'pago',
          'proximoPago': fAprob.add(Duration(days: DIAS_PAGO_VIGENCIA)),
          'vencimiento': fAprob.add(Duration(days: DIAS_TOTAL_VIGENCIA)),
        };
      }
    }
    if (provider.fechaRegistro != null) {
      return {
        'tipo': 'prueba',
        'proximoPago':
            provider.fechaRegistro!.add(Duration(days: DIAS_PRUEBA)),
        'vencimiento': provider.fechaRegistro!
            .add(Duration(days: DIAS_PRUEBA + DIAS_TOTAL_VIGENCIA)),
      };
    }
    return null;
  }

  // ============================================================
  //  LOGOUT
  // ============================================================
  void _mostrarLogout(BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final pendientes = provider.contarPendientes;
    final hayPendientes = provider.hayPendientes;

    if (hayPendientes) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.warning.withOpacity(.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    color: _C.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Operaciones pendientes',
                    style: TextStyle(
                        color: p.textHigh,
                        fontWeight: FontWeight.w900,
                        fontSize: 17)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienes $pendientes operación${pendientes == 1 ? '' : 'es'} sin sincronizar. '
                'Si cierras sesión ahora, esos datos podrían perderse.',
                style: TextStyle(
                    color: p.textMid, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.warning.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.warning.withOpacity(.30)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _C.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recomendamos sincronizar antes de salir.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: p.textMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancelar', style: TextStyle(color: p.textMid)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await provider.logout();
              },
              style: TextButton.styleFrom(foregroundColor: _C.danger),
              child: const Text('Salir sin sincronizar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await provider.sincronizarManual();
                  if (provider.pendientesBox.isEmpty) {
                    if (context.mounted) {
                      _mostrarLogout(context, provider);
                    }
                  } else {
                    mostrarSnackBar(
                      mensaje: 'Aún quedan pendientes por sincronizar.',
                      esExito: false,
                    );
                  }
                } catch (_) {
                  mostrarSnackBar(
                    mensaje: 'No se pudo sincronizar. Intenta de nuevo.',
                    esExito: false,
                  );
                }
              },
              icon: const Icon(Icons.sync_rounded, size: 17),
              label: const Text('Sincronizar y salir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: _C.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Cerrar sesión',
                style: TextStyle(
                    color: p.textHigh,
                    fontWeight: FontWeight.w900,
                    fontSize: 17)),
          ],
        ),
        content: Text('¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: p.textMid, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
            },
            icon: const Icon(Icons.logout_rounded, size: 17),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarInvitar(BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final nombre = provider.nombreEmpresa ?? 'Mi Empresa';
    final mensaje = '📢 ¡Te invito a usar $APP_NAME!\n\n'
        '$nombre ya usa $APP_NAME para gestionar su negocio.\n\n'
        'Regístrate gratis en: https://leifdev0306.github.io/Tu-MiPyme/';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Invitar amigos',
                style: TextStyle(
                    color: p.textHigh,
                    fontWeight: FontWeight.w900,
                    fontSize: 17)),
          ],
        ),
        content: Text('Comparte Nexora Business con tus contactos.',
            style: TextStyle(color: p.textMid, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Share.share(mensaje);
            },
            icon: const Icon(Icons.share_rounded, size: 17),
            label: const Text('Compartir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final isDesktop = ResponsiveHelper.isDesktop();
    return FadeTransition(
      opacity:
          CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
      child: isDesktop
          ? _buildDesktop(context, provider)
          : _buildMobile(context, provider),
    );
  }

  // ============================================================
  //  LOGO
  // ============================================================
  Widget _logo(
      {double size = 42,
      double radius = 13,
      bool withShadow = false,
      _P? p}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow && p != null
            ? p.glow(_C.primary, o: 0.28)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: _C.gradBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
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
            CustomPaint(
              size: Size.infinite,
              painter: _GridPatternPainter(
                color: (p.dark ? Colors.white : _C.primary)
                    .withOpacity(p.dark ? 0.025 : 0.018),
              ),
            ),
            Positioned(
              top: -200,
              left: -150,
              child: _Orb(
                  size: 520,
                  color: _C.primary.withOpacity(p.dark ? .20 : .14)),
            ),
            Positioned(
              top: -140,
              right: -180,
              child: _Orb(
                  size: 460,
                  color: _C.cyan.withOpacity(p.dark ? .16 : .11)),
            ),
            Positioned(
              bottom: -240,
              left: -120,
              child: _Orb(
                  size: 480,
                  color: _C.info.withOpacity(p.dark ? .10 : .07)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  MOBILE
  // ============================================================
  Widget _buildMobile(BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: p.bg,
      drawer: _buildDrawer(context, provider),
      body: Stack(
        children: [
          _background(p),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _mobileTopBar(context, provider, p)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _staggered(0, _pendingBanner(context, provider, p)),
                      _staggered(1, _updateBanner(context, provider, p)),
                      if (provider.ultimoAnuncio != null)
                        _staggered(2, _announcement(context, provider, p)),
                      _staggered(3, _paymentReminder(provider, false, p)),

                      _mobileSectionHeader(
                        p: p,
                        title: 'Tendencia',
                        subtitle: 'Últimos 7 días',
                        trailing: _periodSelector(provider, p),
                      ),
                      const SizedBox(height: 12),
                      _staggered(4, _mobileChart(provider, p)),
                      const SizedBox(height: 20),

                      _staggered(5, _compactSummary(context, provider, p)),
                      const SizedBox(height: 20),

                      // ─── Panel · Tienda en línea
                      _staggered(
                          6, _tiendaEnLineaPanel(context, provider, p)),
                      const SizedBox(height: 20),

                      // ─── Más vendidos (carrusel con imágenes)
                      if (provider
                          .getProductosMasVendidos(
                              provider.inicioPeriodo, provider.finPeriodo)
                          .isNotEmpty) ...[
                        _mobileSectionHeader(
                          p: p,
                          title: 'Más vendidos',
                          subtitle: 'Top del período',
                          trailing: TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/reportes'),
                            style: TextButton.styleFrom(
                              foregroundColor: _C.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('Ver más',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _staggered(7, _topProductsCarousel(context, provider, p)),
                        const SizedBox(height: 22),
                      ],

                      // ─── Panel · Más acciones
                      _staggered(8, _moreActionsPanel(context, provider, p)),
                      const SizedBox(height: 22),

                      _staggered(9, _mobileOperationsBar(provider, p)),
                      const SizedBox(height: 22),

                      _staggered(10, _mobileInsight(provider, p)),
                      const SizedBox(height: 22),

                      _staggered(
                          11, _mobileRecentActivity(context, provider, p)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _mobileBottomNav(context, provider, p),
      floatingActionButton: _enhancedFab(context, provider, p),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _staggered(int index, Widget child) {
    if (child is SizedBox && child.child == null) return child;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 380 + index * 60),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (_, value, __) => Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
    );
  }

  // ============================================================
  //  TOP BAR
  // ============================================================
  Widget _mobileTopBar(
      BuildContext context, AppProvider provider, _P p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => Material(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.borderStrong, width: 1),
                    boxShadow: p.shadowSm,
                  ),
                  child: Icon(Icons.menu_rounded,
                      size: 21, color: p.textHigh),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _logo(size: 46, radius: 14, withShadow: true, p: p),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        provider.nombreEmpresa ?? 'Mi Empresa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: p.textHigh,
                        ),
                      ),
                    ),
                    if (_trialActivo(provider)) ...[
                      const SizedBox(width: 6),
                      _trialPill(provider, p),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _onlineDot(provider),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${_roleLabel(provider.rol)} · ${_greeting()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _iconButton(
                p: p,
                icon: provider.syncing
                    ? Icons.sync_rounded
                    : Icons.sync_disabled_rounded,
                onTap: provider.syncing
                    ? null
                    : () => provider.sincronizarManual(),
              ),
              if (provider.hayPendientes && !provider.syncing)
                Positioned(
                  right: 4,
                  top: 4,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _C.warning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _C.warning.withOpacity(
                                0.40 + 0.30 * _pulseCtrl.value),
                            blurRadius: 6 + 4 * _pulseCtrl.value,
                          ),
                        ],
                      ),
                      child: Text(
                        provider.contarPendientes > 9
                            ? '9+'
                            : '${provider.contarPendientes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trialPill(AppProvider provider, _P p) {
    final dias = _diasTrialRestantes(provider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.warning.withOpacity(.18),
            _C.orange.withOpacity(.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.warning.withOpacity(.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 9, color: _C.warning),
          const SizedBox(width: 4),
          Text(
            '$dias d',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _C.warning,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _onlineDot(AppProvider provider) {
    final online = provider.isOnline;
    final color = online ? _C.success : _C.danger;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.7),
              blurRadius: 6,
              spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _iconButton({
    required _P p,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.borderStrong),
            boxShadow: p.shadowSm,
          ),
          child: Icon(icon, size: 20, color: p.textHigh),
        ),
      ),
    );
  }

  // ============================================================
  //  BANNER · PENDIENTES
  // ============================================================
  Widget _pendingBanner(
      BuildContext context, AppProvider provider, _P p) {
    if (!provider.hayPendientes) return const SizedBox.shrink();
    final n = provider.contarPendientes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final glow = 0.35 + 0.35 * _pulseCtrl.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.warning.withOpacity(.14),
                  _C.orange.withOpacity(.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _C.warning.withOpacity(glow),
                width: 1.4,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradWarm),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _C.warning.withOpacity(glow),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cloud_off_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$n operación${n == 1 ? '' : 'es'} pendiente${n == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: p.textHigh,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.isOnline
                            ? 'Toca para sincronizar ahora'
                            : 'Sin conexión — se enviarán al recuperar red',
                        style:
                            TextStyle(fontSize: 11.5, color: p.textMid),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _C.warning,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: provider.syncing
                        ? null
                        : () => provider.sincronizarManual(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: provider.syncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded,
                              size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //  BANNER · ACTUALIZACIÓN
  // ============================================================
  Widget _updateBanner(
      BuildContext context, AppProvider provider, _P p) {
    if (!provider.hasUpdate) return const SizedBox.shrink();
    // Si ya se mostró el diálogo forzado, no insistir en el banner
    if (_isForceUpdate(provider)) return const SizedBox.shrink();

    final version = provider.latestVersion ?? '';
    final changelog = provider.changelog ?? '';
    final url = provider.downloadUrl ?? '';
    final puedeDescargar = url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.success.withOpacity(.12),
              _C.cyan.withOpacity(.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.success.withOpacity(.32), width: 1.3),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradSuccess),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withOpacity(.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.system_update_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Actualización disponible',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: p.textHigh,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: _C.gradSuccess),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v$version',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Versión actual: v${provider.currentVersion}',
                        style: TextStyle(
                            fontSize: 11, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (changelog.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: p.surface.withOpacity(.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 13, color: _C.success),
                        const SizedBox(width: 6),
                        Text(
                          'CAMBIOS DE LA VERSIÓN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      changelog,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: p.textMid,
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: puedeDescargar
                    ? () async {
                        try {
                          await Share.share(url);
                        } catch (_) {
                          mostrarSnackBar(
                            mensaje:
                                'No se pudo abrir la descarga. Copia este enlace: $url',
                            esExito: false,
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Actualizar',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      p.textMuted.withOpacity(.32),
                  disabledForegroundColor:
                      p.textHigh.withOpacity(.6),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  RESUMEN COMPACTO
  // ============================================================
  Widget _compactSummary(
      BuildContext context, AppProvider provider, _P p) {
    final isManager = _isManager(provider);
    final ventas = provider.getTotalVentas(
        provider.inicioPeriodo, provider.finPeriodo);
    final ops = provider.getNumVentas(
        provider.inicioPeriodo, provider.finPeriodo);
    final ganancia = provider.getGananciaNeta(
        provider.inicioPeriodo, provider.finPeriodo);
    final gastos = provider.getTotalGastos(
        provider.inicioPeriodo, provider.finPeriodo);

    final stats = <Map<String, dynamic>>[
      {
        'label': 'Ventas',
        'value': '\$${_fmtCompact(ventas)}',
        'icon': Icons.trending_up_rounded,
        'color': _C.success,
      },
      {
        'label': 'Ops',
        'value': '$ops',
        'icon': Icons.receipt_long_rounded,
        'color': _C.primary,
      },
      if (isManager)
        {
          'label': 'Ganancia',
          'value': '\$${_fmtCompact(ganancia)}',
          'icon': Icons.savings_rounded,
          'color': _C.cyan,
        }
      else
        {
          'label': 'Productos',
          'value': '${provider.productos.length}',
          'icon': Icons.inventory_2_rounded,
          'color': _C.purple,
        },
      if (isManager)
        {
          'label': 'Gastos',
          'value': '\$${_fmtCompact(gastos)}',
          'icon': Icons.shopping_bag_rounded,
          'color': _C.warning,
        }
      else
        {
          'label': 'Stock',
          'value':
              '${provider.productos.fold<double>(0, (s, x) => s + x.stock).toInt()}',
          'icon': Icons.warehouse_rounded,
          'color': _C.info,
        },
    ];

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradBrand),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: p.glow(_C.primary, o: 0.25),
                  ),
                  child: const Icon(Icons.analytics_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resumen del negocio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: p.textHigh,
                    ),
                  ),
                ),
                _periodSegmented(provider, p),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  Expanded(
                    child: _compactStat(
                      p: p,
                      icon: stats[i]['icon'] as IconData,
                      label: stats[i]['label'] as String,
                      value: stats[i]['value'] as String,
                      color: stats[i]['color'] as Color,
                    ),
                  ),
                  if (i != stats.length - 1)
                    Container(
                      width: 1,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: p.border,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodSegmented(AppProvider provider, _P p) {
    Widget item(int value, String label) {
      final selected = provider.periodoSeleccionado == value;
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => provider.setPeriodo(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? _C.primary.withOpacity(p.dark ? .20 : .12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? _C.primary.withOpacity(.44)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: selected ? _C.primary : p.textMuted,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(0, 'Hoy'),
        const SizedBox(width: 4),
        item(1, 'Sem'),
        const SizedBox(width: 4),
        item(2, 'Mes'),
      ],
    );
  }

  Widget _compactStat({
    required _P p,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(.22), color.withOpacity(.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: p.textHigh,
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  CHART
  // ============================================================
  Widget _mobileChart(AppProvider provider, _P p) {
    final datos = provider.getDatosGraficoVentas();
    double maxY = 0;
    double total = 0;
    for (final d in datos) {
      final v = (d['ventas'] as double?) ?? 0;
      if (v > maxY) maxY = v;
      total += v;
    }
    if (maxY <= 0) maxY = 1;

    int mejorIdx = 0;
    double mejorVal = 0;
    for (int i = 0; i < datos.length; i++) {
      final v = (datos[i]['ventas'] as double?) ?? 0;
      if (v > mejorVal) {
        mejorVal = v;
        mejorIdx = i;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventas acumuladas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${_fmt(total)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: p.textHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: p.glow(_C.primary, o: 0.28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Mejor día',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(datos.length, (i) {
                final d = datos[i];
                final ventas = (d['ventas'] as double?) ?? 0;
                final altura = (ventas / maxY).clamp(0.06, 1.0);
                final esHoy = i == datos.length - 1;
                final esMejor = i == mejorIdx && mejorVal > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: ventas > 0 ? 1 : 0,
                          child: Text(
                            _fmtCompact(ventas),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: esMejor
                                  ? _C.gold
                                  : (esHoy ? _C.primary : p.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (_, cst) => Align(
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                duration:
                                    Duration(milliseconds: 600 + i * 80),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0, end: altura),
                                builder: (_, v, __) => Container(
                                  width: double.infinity,
                                  height: cst.maxHeight * v,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: esMejor
                                          ? _C.gradGold
                                          : (esHoy
                                              ? _C.gradBrand
                                              : [
                                                  _C.primary
                                                      .withOpacity(.28),
                                                  _C.primary
                                                      .withOpacity(.10),
                                                ]),
                                    ),
                                    borderRadius:
                                        const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                      bottom: Radius.circular(3),
                                    ),
                                    boxShadow: (esHoy || esMejor)
                                        ? p.glow(
                                            esMejor
                                                ? _C.gold
                                                : _C.primary,
                                            o: 0.35)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (d['periodo'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: (esHoy || esMejor)
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: esMejor
                                ? _C.gold
                                : (esHoy ? _C.primary : p.textMuted),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  OPERATIONS BAR
  // ============================================================
  Widget _mobileOperationsBar(AppProvider provider, _P p) {
    final pendientes = provider.contarPendientes;
    final online = provider.isOnline;
    final syncing = provider.syncing;

    Color estadoColor;
    IconData estadoIcon;
    String estadoLabel;

    if (syncing) {
      estadoColor = _C.primary;
      estadoIcon = Icons.sync_rounded;
      estadoLabel = 'Sincronizando';
    } else if (pendientes > 0) {
      estadoColor = _C.warning;
      estadoIcon = Icons.cloud_off_rounded;
      estadoLabel = 'Pendientes';
    } else if (!online) {
      estadoColor = _C.danger;
      estadoIcon = Icons.wifi_off_rounded;
      estadoLabel = 'Sin conexión';
    } else {
      estadoColor = _C.success;
      estadoIcon = Icons.cloud_done_rounded;
      estadoLabel = 'Al día';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: estadoColor.withOpacity(.28)),
            ),
            child: Icon(estadoIcon, size: 18, color: estadoColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estadoLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendientes > 0
                      ? '$pendientes operación${pendientes == 1 ? '' : 'es'} por sincronizar'
                      : online
                          ? 'Todo sincronizado correctamente'
                          : 'Los cambios se guardan localmente',
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (pendientes > 0 && !syncing)
            Material(
              color: estadoColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => provider.sincronizarManual(),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Icon(Icons.sync_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //  PANEL · TIENDA EN LÍNEA
  //  Divide en Mi tienda + Red Nexora
  //  Si no hay tienda, muestra modo "promo / anuncio"
  // ============================================================
  Widget _tiendaEnLineaPanel(
      BuildContext context, AppProvider provider, _P p) {
    final tieneTienda = _tieneTiendaActiva(provider);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _C.myBusiness,
                      _C.network,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: _C.myBusiness.withOpacity(.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienda en línea',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu catálogo y la red de negocios',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.myBusiness, _C.network],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NUEVO',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _miTiendaCard(context, provider, p, tieneTienda),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _redNexoraCard(context, provider, p),
                ),
              ],
            )
          else ...[
            _miTiendaCard(context, provider, p, tieneTienda),
            const SizedBox(height: 12),
            _redNexoraCard(context, provider, p),
          ],
        ],
      ),
    );
  }

  // ─── Card · Mi tienda ───────────────────────────────────────
  Widget _miTiendaCard(BuildContext context, AppProvider provider, _P p,
      bool tieneTienda) {
    if (tieneTienda) {
      return _businessTile(
        context: context,
        p: p,
        onTap: () => Navigator.pushNamed(context, '/mi-tienda'),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        glowColor: _C.myBusiness,
        icon: Icons.storefront_rounded,
        badge: 'ACTIVA',
        badgeColor: _C.success,
        title: 'Mi tienda',
        subtitle: 'Gestiona tu catálogo público',
        bullets: const [
          'Publica productos',
          'Recibe pedidos',
          'Comparte tu enlace',
        ],
        ctaLabel: 'Abrir tienda',
      );
    }

    // Modo promocional (sin tienda activa)
    return _businessPromoCard(
      context: context,
      p: p,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.storefront_rounded,
      eyebrow: 'NUEVO',
      title: 'Activa tu tienda online',
      subtitle:
          'Muestra tus productos al mundo, recibe pedidos y haz crecer tu negocio sin costo adicional.',
      bullets: const [
        'Muestra hasta 50 productos',
        'Comparte por WhatsApp y redes',
        'Recibe pedidos en tiempo real',
      ],
      ctaLabel: 'Activar tienda',
      onTap: () => Navigator.pushNamed(context, '/mi-tienda'),
    );
  }

  // ─── Card · Red Nexora ──────────────────────────────────────
  Widget _redNexoraCard(
      BuildContext context, AppProvider provider, _P p) {
    // Contar tiendas activas en la red (si están cacheadas)
    int totalRed = 0;
    try {
      final list = provider.catalogosBox.get('network_stores');
      if (list is List) totalRed = list.length;
    } catch (_) {}

    return _businessTile(
      context: context,
      p: p,
      onTap: () => Navigator.pushNamed(context, '/tiendas'),
      gradient: const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: _C.network,
      icon: Icons.hub_rounded,
      badge: totalRed > 0 ? '$totalRed en la red' : 'EXPLORAR',
      badgeColor: _C.network,
      title: 'Red Nexora',
      subtitle: 'Descubre negocios y crea alianzas',
      bullets: const [
        'Explora negocios cercanos',
        'Crea alianzas comerciales',
        'Invita y gana recompensas',
      ],
      ctaLabel: 'Explorar red',
    );
  }

  // ─── Tile base (una mitad del panel) ────────────────────────
  Widget _businessTile({
    required BuildContext context,
    required _P p,
    required VoidCallback onTap,
    required LinearGradient gradient,
    required Color glowColor,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required List<String> bullets,
    required String ctaLabel,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                glowColor.withOpacity(p.dark ? .16 : .09),
                glowColor.withOpacity(p.dark ? .05 : .025),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: glowColor.withOpacity(.32), width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(.34)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
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
              const SizedBox(height: 12),
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: glowColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    ctaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: glowColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: glowColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Variante promo (ad-style) ──────────────────────────────
  Widget _businessPromoCard({
    required BuildContext context,
    required _P p,
    required LinearGradient gradient,
    required IconData icon,
    required String eyebrow,
    required String title,
    required String subtitle,
    required List<String> bullets,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withOpacity(p.dark ? .20 : .12),
                const Color(0xFFEC4899).withOpacity(p.dark ? .06 : .03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(.38),
                width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(.38),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      eyebrow,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: p.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                  label: Text(
                    ctaLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  PANEL · MÁS ACCIONES
  // ============================================================
  Widget _moreActionsPanel(
      BuildContext context, AppProvider provider, _P p) {
    final actions = _secondaryActions(provider);
    if (actions.isEmpty) return const SizedBox.shrink();

    final isDesktop = ResponsiveHelper.isDesktop();
    final cols = isDesktop ? 6 : 4;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: p.glow(_C.primary, o: 0.25),
                ),
                child: const Icon(Icons.apps_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Más acciones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: p.textHigh,
                  ),
                ),
              ),
              Text(
                '${actions.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemCount: actions.length,
            itemBuilder: (_, i) => _moreActionTile(context, p, actions[i]),
          ),
        ],
      ),
    );
  }

  Widget _moreActionTile(BuildContext context, _P p, _QuickAction a) {
    final tieneBadge = a.badge != null && a.badge!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, a.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: a.color.withOpacity(.28)),
                    ),
                    child: Icon(a.icon, color: a.color, size: 17),
                  ),
                  if (tieneBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: a.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: a.color.withOpacity(.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          a.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                a.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  CARRUSEL · MÁS VENDIDOS (con imágenes y efectos)
  // ============================================================
  Widget _topProductsCarousel(
      BuildContext context, AppProvider provider, _P p,
      {bool isDesktop = false}) {
    final inicio = provider.inicioPeriodo;
    final fin = provider.finPeriodo;
    final top = provider.getProductosMasVendidos(inicio, fin);
    if (top.isEmpty) return const SizedBox.shrink();
    final items = top.take(isDesktop ? 12 : 8).toList();

    final cardW = isDesktop ? 200.0 : 168.0;
    final cardH = isDesktop ? 260.0 : 230.0;

    return SizedBox(
      height: cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          final productoId = item['id'] as String? ?? '';
          final producto = provider.getProductoById(productoId);
          final imageUrl = producto?.imageUrl;
          return _ProductTopCard(
            width: cardW,
            height: cardH,
            index: i,
            nombre: (item['nombre'] as String?) ?? 'Producto',
            cantidad: (item['cantidad'] as num?)?.toDouble() ?? 0,
            total: (item['total'] as num?)?.toDouble() ?? 0,
            imageUrl: imageUrl,
            p: p,
            onTap: () {
              if (productoId.isNotEmpty) {
                Navigator.pushNamed(context, '/productos');
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  //  INSIGHT
  // ============================================================
  Widget _mobileInsight(AppProvider provider, _P p) {
    final isManager = _isManager(provider);
    if (!isManager) return const SizedBox.shrink();

    final ventas = provider.getTotalVentas(
        provider.inicioPeriodo, provider.finPeriodo);
    final meta = _getMetaPeriodo(provider);
    final progress = meta <= 0 ? 0.0 : (ventas / meta).clamp(0.0, 1.0);
    final pct =
        meta <= 0 ? 0 : ((ventas / meta) * 100).clamp(0, 100).round();
    final reached = progress >= 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: reached ? _C.gradSuccess : _C.gradBrand,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: p.glow(
                    reached ? _C.success : _C.primary,
                    o: 0.28,
                  ),
                ),
                child: Icon(
                  reached
                      ? Icons.emoji_events_rounded
                      : Icons.flag_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reached ? 'Meta alcanzada' : 'Progreso de meta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reached
                          ? '¡Excelente trabajo!'
                          : 'Vas por buen camino',
                      style:
                          TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: reached ? _C.gradSuccess : _C.gradBrand,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: p.dark
                      ? Colors.white.withOpacity(.06)
                      : _C.primary.withOpacity(.08),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: progress),
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              reached ? _C.gradSuccess : _C.gradBrand,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '\$${_fmt(ventas)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'de \$${_fmt(meta)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
  //  RECENT ACTIVITY
  // ============================================================
  Widget _mobileRecentActivity(
      BuildContext context, AppProvider provider, _P p) {
    final ventas = provider.ventas.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividad reciente',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: p.textHigh,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tus últimas operaciones',
                    style:
                        TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            if (ventas.isNotEmpty)
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/historial'),
                style: TextButton.styleFrom(
                  foregroundColor: _C.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Ver todo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: ventas.isEmpty
              ? _emptyActivity(p)
              : Column(
                  children: [
                    for (int i = 0; i < ventas.length; i++) ...[
                      _activityRow(p, ventas[i]),
                      if (i != ventas.length - 1)
                        Divider(height: 1, indent: 68, color: p.border),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyActivity(_P p) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.primary.withOpacity(.16),
                  _C.cyan.withOpacity(.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 28, color: _C.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Aún no hay ventas',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: p.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra tu primera venta desde el botón central.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(_P p, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.primary.withOpacity(.22),
                  _C.cyan.withOpacity(.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.primary.withOpacity(.22)),
            ),
            child: Text(
              '${v.cantidad}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _C.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.productoNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM · HH:mm').format(v.fecha)} · ${v.metodoPago}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${_fmt(v.total)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _C.success,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BOTTOM NAV (mobile) · 4 items + FAB
  // ============================================================
  Widget _mobileBottomNav(
      BuildContext context, AppProvider provider, _P p) {
    final isManager = _isManager(provider);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: p.shadowMd,
      ),
      child: BottomAppBar(
        height: 74,
        padding: EdgeInsets.zero,
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          children: [
            Expanded(
              child: _bottomItem(
                p: p,
                icon: Icons.inventory_2_rounded,
                label: 'Inventario',
                onTap: () {
                  if (isManager) {
                    Navigator.pushNamed(context, '/productos');
                  } else {
                    Navigator.pushNamed(context, '/historial');
                  }
                },
              ),
            ),
            Expanded(
              child: _bottomItem(
                p: p,
                icon: Icons.history_rounded,
                label: 'Historial',
                onTap: () => Navigator.pushNamed(context, '/historial'),
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: _bottomItem(
                p: p,
                icon: Icons.storefront_rounded,
                label: 'Tienda',
                onTap: () => Navigator.pushNamed(context, '/mi-tienda'),
                active: false,
              ),
            ),
            Expanded(
              child: _bottomItem(
                p: p,
                icon: Icons.hub_rounded,
                label: 'Red',
                onTap: () => Navigator.pushNamed(context, '/tiendas'),
                active: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem({
    required _P p,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final color = active ? _C.primary : p.textMid;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? _C.primary.withOpacity(.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: color,
                letterSpacing: .1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  FAB MEJORADO · Ventas
  // ============================================================
  Widget _enhancedFab(
      BuildContext context, AppProvider provider, _P p) {
    final usaCierre = provider.usaCierreDiario;
    final colors = usaCierre
        ? const [Color(0xFFF59E0B), Color(0xFFEF4444)]
        : _C.gradBrand;
    final colorPrimary = usaCierre ? _C.warning : _C.primary;

    return SizedBox(
      width: 74,
      height: 74,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final pulse = _pulseCtrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 68 + pulse * 8,
                height: 68 + pulse * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorPrimary.withOpacity(0.10 - pulse * 0.04),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimary.withOpacity(0.45),
                      blurRadius: 24 + pulse * 8,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: colorPrimary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              FloatingActionButton(
                heroTag: 'home_sale_fab',
                elevation: 0,
                highlightElevation: 0,
                backgroundColor: Colors.transparent,
                onPressed: () => Navigator.pushNamed(
                  context,
                  usaCierre ? '/cierre-diario' : '/nueva-venta',
                ),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        usaCierre
                            ? Icons.event_available_rounded
                            : Icons.bolt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        usaCierre ? 'CIERRE' : 'VENTA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mobileSectionHeader({
    required _P p,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: p.textHigh,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing,
        ],
      ],
    );
  }

  Widget _periodSelector(AppProvider provider, _P p) {
    return PopupMenuButton<int>(
      tooltip: 'Cambiar período',
      onSelected: provider.setPeriodo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: p.surface,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Text('Hoy', style: TextStyle(color: p.textHigh)),
        ),
        PopupMenuItem(
          value: 1,
          child:
              Text('Esta semana', style: TextStyle(color: p.textHigh)),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Este mes', style: TextStyle(color: p.textHigh)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: p.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 14, color: _C.primary),
            const SizedBox(width: 6),
            Text(
              provider.getPeriodoLabel(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 15, color: p.textMuted),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DESKTOP
  // ============================================================
  Widget _buildDesktop(BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          _background(p),
          Row(
            children: [
              _desktopSidebar(context, provider, p),
              Expanded(
                child: Column(
                  children: [
                    _desktopTopBar(context, provider, p),
                    Expanded(
                        child: _desktopContent(context, provider, p)),
                    _desktopCommandBar(context, provider, p),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _desktopSidebar(
      BuildContext context, AppProvider provider, _P p) {
    final isAdmin = _isAdmin(provider);
    final isManager = _isManager(provider);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.primary.withOpacity(.14),
                      _C.cyan.withOpacity(.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _C.primary.withOpacity(.24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _logo(
                            size: 42,
                            radius: 13,
                            withShadow: true,
                            p: p),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.nombreEmpresa ?? 'Mi Empresa',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: p.textHigh,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _onlineDot(provider),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _roleLabel(provider.rol),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: p.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: provider.plan == 'premium'
                                  ? _C.gradPremium
                                  : const [
                                      Color(0xFF64748B),
                                      Color(0xFF475569),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.plan == 'premium'
                                    ? Icons.workspace_premium_rounded
                                    : Icons.verified_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                provider.plan == 'premium'
                                    ? 'PREMIUM'
                                    : 'NORMAL',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (_trialActivo(provider))
                          _trialPill(provider, p),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                children: [
                  _sideItem(context, provider, 'Inicio',
                      Icons.home_rounded, '/', p),

                  const SizedBox(height: 10),
                  _sideSection(
                    p,
                    label: 'OPERACIONES',
                    color: _C.primary,
                  ),
                  _sideItem(context, provider, 'Historial',
                      Icons.history_rounded, '/historial', p),
                  if (isManager)
                    _sideItem(context, provider, 'Inventario',
                        Icons.inventory_2_rounded, '/productos', p),
                  if (isManager)
                    _sideItem(context, provider, 'Reabastecer',
                        Icons.add_box_rounded, '/reabastecer', p),
                  if (isManager)
                    _sideItem(context, provider, 'Clientes',
                        Icons.people_alt_rounded, '/clientes', p),
                  if (isManager)
                    _sideItem(context, provider, 'Gastos',
                        Icons.receipt_long_rounded, '/gastos', p),
                  if (isManager)
                    _sideItem(context, provider, 'Mermas',
                        Icons.warning_amber_rounded, '/mermas', p),
                  if (isManager)
                    _sideItem(context, provider, 'Movimientos',
                        Icons.swap_horiz_rounded,
                        '/movimientos-sucursales', p),
                  if (isAdmin)
                    _sideItem(context, provider, 'Deudas',
                        Icons.money_off_rounded, '/deudas', p),
                  if (isAdmin)
                    _sideItem(context, provider, 'Facturación',
                        Icons.receipt_rounded, '/facturacion', p),

                  const SizedBox(height: 10),
                  _sideSection(
                    p,
                    label: 'ANÁLISIS',
                    color: _C.teal,
                  ),
                  if (isManager)
                    _sideItem(context, provider, 'Reportes',
                        Icons.insights_rounded, '/reportes', p),
                  if (isManager)
                    _sideItem(context, provider, 'Metas',
                        Icons.flag_rounded, '/metas', p),

                  const SizedBox(height: 14),
                  _sideSection(
                    p,
                    label: 'MI NEGOCIO',
                    color: _C.myBusiness,
                    destacado: true,
                  ),
                  _sideItem(
                    context,
                    provider,
                    'Mi tienda',
                    Icons.storefront_rounded,
                    '/mi-tienda',
                    p,
                    accent: _C.myBusiness,
                  ),
                  if (isManager)
                    _sideItem(
                      context,
                      provider,
                      'Productos publicados',
                      Icons.inventory_rounded,
                      '/productos-publicados',
                      p,
                      accent: _C.myBusiness,
                    ),
                  if (isManager)
                    _sideItem(
                      context,
                      provider,
                      'Publicar producto',
                      Icons.cloud_upload_rounded,
                      '/publicar-producto',
                      p,
                      accent: _C.myBusiness,
                    ),

                  const SizedBox(height: 14),
                  _sideSection(
                    p,
                    label: 'RED NEXORA',
                    color: _C.network,
                    destacado: true,
                  ),
                  _sideItem(
                    context,
                    provider,
                    'Explorar negocios',
                    Icons.travel_explore_rounded,
                    '/tiendas',
                    p,
                    accent: _C.network,
                  ),
                  _sideItem(
                    context,
                    provider,
                    'Alianzas',
                    Icons.handshake_rounded,
                    '/alianzas',
                    p,
                    accent: _C.network,
                  ),
                  _sideItem(
                    context,
                    provider,
                    'Referidos',
                    Icons.card_giftcard_rounded,
                    '/referidos',
                    p,
                    accent: _C.network,
                  ),
                  _sideItem(
                    context,
                    provider,
                    'Transferencias',
                    Icons.receipt_long_rounded,
                    '/transferencias',
                    p,
                    accent: _C.network,
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    _sideSection(
                      p,
                      label: 'ADMINISTRACIÓN',
                      color: _C.purple,
                    ),
                    _sideItem(context, provider, 'Vendedores',
                        Icons.people_outline_rounded, '/vendedores', p),
                    _sideItem(context, provider, 'Estadísticas',
                        Icons.leaderboard_rounded,
                        '/estadisticas-vendedores', p),
                    _sideItem(context, provider, 'Sucursales',
                        Icons.storefront_rounded, '/sucursales', p),
                    _sideItem(context, provider, 'Nóminas',
                        Icons.payments_rounded, '/nominas', p),
                    _sideItem(context, provider, 'Realizar pago',
                        Icons.account_balance_wallet_rounded, '/pago', p),
                    _sideItem(context, provider, 'Configuración',
                        Icons.settings_rounded, '/settings', p),
                  ],
                  if (isManager)
                    _sideItem(context, provider, 'Módulo fiscal',
                        Icons.request_quote_rounded, '/fiscal', p),

                  const SizedBox(height: 10),
                  _sideSection(
                    p,
                    label: 'AYUDA',
                    color: _C.muted,
                  ),
                  _sideItem(context, provider, 'Invitar amigos',
                      Icons.share_rounded, '__invite__', p),
                  _sideItem(context, provider, 'Soporte',
                      Icons.support_agent_rounded, '/soporte', p),
                  _sideItem(context, provider, 'Guía de usuario',
                      Icons.menu_book_rounded, '/user-guide', p),
                  _sideItem(context, provider, 'Sobre nosotros',
                      Icons.info_outline_rounded, '__about__', p),
                  _sideItem(context, provider, 'Términos',
                      Icons.description_outlined, '__terms__', p),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: provider.isOnline
                                ? _C.success
                                : _C.danger,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (provider.isOnline
                                        ? _C.success
                                        : _C.danger)
                                    .withOpacity(.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.isOnline
                                ? 'Conectado'
                                : 'Sin conexión',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.textMid,
                            ),
                          ),
                        ),
                        Text(
                          'v${provider.currentVersion}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () =>
                            _mostrarLogout(context, provider),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Cerrar sesión'),
                        style: TextButton.styleFrom(
                          foregroundColor: p.textMid,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideSection(
    _P p, {
    required String label,
    required Color color,
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Container(
            width: destacado ? 8 : 5,
            height: destacado ? 8 : 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: destacado
                  ? [
                      BoxShadow(
                        color: color.withOpacity(.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: destacado ? 10 : 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: destacado ? color : p.textMuted,
            ),
          ),
          if (destacado) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.32),
                      color.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sideItem(
    BuildContext context,
    AppProvider provider,
    String label,
    IconData icon,
    String route,
    _P p, {
    Color? accent,
  }) {
    final isActive = route == '/';
    final activeColor = accent ?? _C.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: isActive
            ? activeColor.withOpacity(.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            if (route == '__invite__') {
              _mostrarInvitar(context, provider);
              return;
            }
            if (route == '__about__') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
              return;
            }
            if (route == '__terms__') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              );
              return;
            }
            if (route == '/') return;
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeColor : p.textMid,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? p.textHigh : p.textMid,
                      letterSpacing: -.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopTopBar(
      BuildContext context, AppProvider provider, _P p) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Panel de control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                        color: p.textHigh,
                      ),
                    ),
                    if (_trialActivo(provider)) ...[
                      const SizedBox(width: 8),
                      _trialPill(provider, p),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_greeting()} · ${DateFormat('EEEE d MMMM', 'es').format(DateTime.now())}',
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (provider.hasUpdate && !_isForceUpdate(provider))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: _C.success.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final url = provider.downloadUrl ?? '';
                    if (url.isEmpty) return;
                    try {
                      await Share.share(url);
                    } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _C.success.withOpacity(.32),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.system_update_rounded,
                            size: 14, color: _C.success),
                        const SizedBox(width: 6),
                        Text(
                          'v${provider.latestVersion ?? ''} disponible',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _C.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (provider.hayPendientes)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final glow = 0.35 + 0.35 * _pulseCtrl.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: _C.warning.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: provider.syncing
                          ? null
                          : () => provider.sincronizarManual(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _C.warning.withOpacity(glow),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 14, color: _C.warning),
                            const SizedBox(width: 6),
                            Text(
                              '${provider.contarPendientes} pendientes',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _C.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: provider.syncing
                ? null
                : () => provider.sincronizarManual(),
            icon: Icon(Icons.sync_rounded, color: p.textMid),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  DESKTOP CONTENT
  // ============================================================
  Widget _desktopContent(
      BuildContext context, AppProvider provider, _P p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1250;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              wide ? 30 : 22, 22, wide ? 30 : 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.hayPendientes) ...[
                _pendingBanner(context, provider, p),
                const SizedBox(height: 4),
              ],
              _updateBanner(context, provider, p),
              if (provider.ultimoAnuncio != null) ...[
                _announcement(context, provider, p),
                const SizedBox(height: 12),
              ],
              _paymentReminder(provider, true, p),
              const SizedBox(height: 4),

              // ── CHART + RESUMEN
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: wide ? 7 : 6,
                    child: _desktopChart(provider, p),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: wide ? 5 : 4,
                    child: _compactSummary(context, provider, p),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── PANEL TIENDA EN LÍNEA
              _tiendaEnLineaPanel(context, provider, p),
              const SizedBox(height: 22),

              // ── MÁS VENDIDOS (carrusel con imágenes)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: p.border),
                  boxShadow: p.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(colors: _C.gradGold),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Más vendidos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  color: p.textHigh,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Productos estrella de este período',
                                style: TextStyle(
                                    fontSize: 11, color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _C.primary.withOpacity(.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _C.primary.withOpacity(.24)),
                          ),
                          child: Text(
                            provider.getPeriodoLabel().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: _C.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _topProductsCarousel(context, provider, p,
                        isDesktop: true),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── MÁS ACCIONES
              _moreActionsPanel(context, provider, p),
              const SizedBox(height: 22),

              // ── ESTADO + ACTIVIDAD
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: wide ? 5 : 4,
                    child: Column(
                      children: [
                        _desktopStatusPanel(provider, p),
                        const SizedBox(height: 18),
                        _desktopInsight(provider, p),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: wide ? 7 : 6,
                    child: _desktopActivity(context, provider, p),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //  DESKTOP · COMMAND BAR simplificada
  //  Solo: Venta · Inventario · Historial · Mi tienda · Red Nexora
  // ============================================================
  Widget _desktopCommandBar(
      BuildContext context, AppProvider provider, _P p) {
    final items = _commandItems(provider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: p.shadowMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _commandChip(
                  context: context,
                  p: p,
                  item: items[i],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _bigSaleButton(context, provider, p),
        ],
      ),
    );
  }

  Widget _commandChip({
    required BuildContext context,
    required _P p,
    required _CommandItem item,
  }) {
    final color = item.color;
    final level = item.level;
    final tieneBadge = item.badge != null && item.badge!.isNotEmpty;

    late Color bg;
    late Color borderColor;
    late Color labelColor;
    late double borderWidth;
    late double iconBoxSize;
    late double iconSize;
    late double chipWidth;

    switch (level) {
      case 2:
        bg = color.withOpacity(p.dark ? .16 : .10);
        borderColor = color.withOpacity(.48);
        labelColor = color;
        borderWidth = 1.6;
        iconBoxSize = 38;
        iconSize = 18;
        chipWidth = 88;
        break;
      case 3:
        bg = color.withOpacity(p.dark ? .10 : .06);
        borderColor = color.withOpacity(.30);
        labelColor = p.textHigh;
        borderWidth = 1.3;
        iconBoxSize = 36;
        iconSize = 17;
        chipWidth = 86;
        break;
      default:
        bg = p.surface2;
        borderColor = p.border;
        labelColor = p.textHigh;
        borderWidth = 1;
        iconBoxSize = 34;
        iconSize = 16;
        chipWidth = 84;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, item.route),
        child: Container(
          width: chipWidth,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(level == 2 ? .24 : .14),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: color.withOpacity(level == 2 ? .42 : .28),
                        width: level == 2 ? 1.4 : 1,
                      ),
                    ),
                    child: Icon(item.icon, color: color, size: iconSize),
                  ),
                  if (tieneBadge)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      level == 2 ? FontWeight.w900 : FontWeight.w800,
                  letterSpacing: -0.1,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigSaleButton(
      BuildContext context, AppProvider provider, _P p) {
    final usaCierre = provider.usaCierreDiario;
    final colors = usaCierre
        ? const [Color(0xFFF59E0B), Color(0xFFEF4444)]
        : _C.gradBrand;
    final route = usaCierre ? '/cierre-diario' : '/nueva-venta';
    final icon = usaCierre
        ? Icons.event_available_rounded
        : Icons.point_of_sale_rounded;
    final label = usaCierre ? 'Cierre diario' : 'Nueva venta';
    final sub = usaCierre ? 'Registrar jornada' : 'Registrar operación';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          width: 240,
          height: 78,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(.38),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: colors[0].withOpacity(.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.22),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  DESKTOP · CHART
  // ============================================================
  Widget _desktopChart(AppProvider provider, _P p) {
    final datos = provider.getDatosGraficoVentas();
    double maxY = 0;
    double total = 0;
    for (final d in datos) {
      final v = (d['ventas'] as double?) ?? 0;
      if (v > maxY) maxY = v;
      total += v;
    }
    if (maxY <= 0) maxY = 1;

    int mejorIdx = 0;
    double mejorVal = 0;
    for (int i = 0; i < datos.length; i++) {
      final v = (datos[i]['ventas'] as double?) ?? 0;
      if (v > mejorVal) {
        mejorVal = v;
        mejorIdx = i;
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: p.glow(_C.primary, o: 0.28),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventas últimos 7 días',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total acumulado: \$${_fmt(total)}',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              if (mejorVal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradGold),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Mejor: ${datos[mejorIdx]['periodo']} · \$${_fmtCompact(mejorVal)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(datos.length, (i) {
                final d = datos[i];
                final ventas = (d['ventas'] as double?) ?? 0;
                final altura = (ventas / maxY).clamp(0.06, 1.0);
                final esHoy = i == datos.length - 1;
                final esMejor = i == mejorIdx && mejorVal > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: ventas > 0 ? 1 : 0,
                          child: Text(
                            _fmtCompact(ventas),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: esMejor
                                  ? _C.gold
                                  : (esHoy
                                      ? _C.primary
                                      : p.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (_, cst) => Align(
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                duration: Duration(
                                    milliseconds: 600 + i * 80),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0, end: altura),
                                builder: (_, v, __) => Container(
                                  width: double.infinity,
                                  height: cst.maxHeight * v,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: esMejor
                                          ? _C.gradGold
                                          : (esHoy
                                              ? _C.gradBrand
                                              : [
                                                  _C.primary
                                                      .withOpacity(.28),
                                                  _C.primary
                                                      .withOpacity(.10),
                                                ]),
                                    ),
                                    borderRadius:
                                        const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                      bottom: Radius.circular(4),
                                    ),
                                    boxShadow: (esHoy || esMejor)
                                        ? p.glow(
                                            esMejor
                                                ? _C.gold
                                                : _C.primary,
                                            o: 0.35)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (d['periodo'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: (esHoy || esMejor)
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: esMejor
                                ? _C.gold
                                : (esHoy ? _C.primary : p.textMuted),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopStatusPanel(AppProvider provider, _P p) {
    final pendientes = provider.contarPendientes;
    final online = provider.isOnline;
    final syncing = provider.syncing;
    final totalOps = provider.getNumVentas(
        provider.inicioPeriodo, provider.finPeriodo);
    final ventasTotal = provider.getTotalVentas(
        provider.inicioPeriodo, provider.finPeriodo);

    Color estadoColor;
    IconData estadoIcon;
    String estadoLabel;

    if (syncing) {
      estadoColor = _C.primary;
      estadoIcon = Icons.sync_rounded;
      estadoLabel = 'Sincronizando…';
    } else if (pendientes > 0) {
      estadoColor = _C.warning;
      estadoIcon = Icons.cloud_off_rounded;
      estadoLabel = 'Pendientes';
    } else if (!online) {
      estadoColor = _C.danger;
      estadoIcon = Icons.wifi_off_rounded;
      estadoLabel = 'Sin conexión';
    } else {
      estadoColor = _C.success;
      estadoIcon = Icons.cloud_done_rounded;
      estadoLabel = 'Sincronizado';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(.14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: estadoColor.withOpacity(.28)),
                ),
                child: Icon(estadoIcon, size: 15, color: estadoColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estado del sistema',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: p.textHigh,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estadoLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: estadoColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _deskOpTile(
                  p: p,
                  label: 'Ops período',
                  value: '$totalOps',
                  icon: Icons.receipt_long_rounded,
                  color: _C.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _deskOpTile(
                  p: p,
                  label: 'Pendientes',
                  value: '$pendientes',
                  icon: Icons.cloud_off_rounded,
                  color: pendientes > 0 ? _C.warning : _C.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _deskOpTile(
                  p: p,
                  label: 'Monto total',
                  value: '\$${_fmtCompact(ventasTotal)}',
                  icon: Icons.attach_money_rounded,
                  color: _C.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _deskOpTile(
                  p: p,
                  label: 'Conexión',
                  value: online ? 'Online' : 'Offline',
                  icon: online
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  color: online ? _C.success : _C.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deskOpTile({
    required _P p,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(.20), color.withOpacity(.06)],
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: p.textHigh,
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

  Widget _desktopActivity(
      BuildContext context, AppProvider provider, _P p) {
    final ventas = provider.ventas.reversed.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimas ventas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Actividad reciente de tu negocio',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/historial'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Ver historial'),
                style: TextButton.styleFrom(
                  foregroundColor: _C.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 34),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ventas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.primary.withOpacity(.16),
                            _C.cyan.withOpacity(.06),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 28, color: _C.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no hay ventas registradas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...ventas.map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _C.primary.withOpacity(.20),
                              _C.cyan.withOpacity(.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: _C.primary.withOpacity(.22)),
                        ),
                        child: Text(
                          '${v.cantidad}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _C.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.productoNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.textHigh,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd/MM · HH:mm').format(v.fecha)} · ${v.metodoPago}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${_fmt(v.total)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _C.success,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _desktopInsight(AppProvider provider, _P p) {
    final ventas = provider.getTotalVentas(
        provider.inicioPeriodo, provider.finPeriodo);
    final meta = _getMetaPeriodo(provider);
    final progress = meta <= 0 ? 0.0 : (ventas / meta).clamp(0.0, 1.0);
    final pct = meta <= 0
        ? '0'
        : ((ventas / meta) * 100).clamp(0, 100).toStringAsFixed(0);
    final reached = progress >= 1;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rendimiento',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Progreso frente a tu meta',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: reached ? _C.gradSuccess : _C.gradBrand,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: p.glow(
                    reached ? _C.success : _C.primary,
                    o: 0.28,
                  ),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  '\$${_fmt(ventas)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: p.textHigh,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'de \$${_fmt(meta)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: p.dark
                      ? Colors.white.withOpacity(.06)
                      : _C.primary.withOpacity(.08),
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: progress),
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: reached
                              ? _C.gradSuccess
                              : _C.gradBrand,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                reached
                    ? Icons.check_circle_rounded
                    : Icons.flag_rounded,
                size: 15,
                color: reached ? _C.success : _C.warning,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reached
                      ? '¡Meta alcanzada! Excelente trabajo.'
                      : 'Sigue así para alcanzar tu meta.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textMid,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentReminder(
      AppProvider provider, bool isDesktop, _P p) {
    if (!_isAdmin(provider)) return const SizedBox.shrink();
    final info = _getPaymentInfo(provider);
    if (info == null) return const SizedBox.shrink();

    final proximo = info['proximoPago'] as DateTime;
    final tipo = info['tipo'] as String;
    final hoy = DateTime.now();
    final dias = DateTime(proximo.year, proximo.month, proximo.day)
        .difference(DateTime(hoy.year, hoy.month, hoy.day))
        .inDays;
    if (dias > 7) return const SizedBox.shrink();

    if (tipo == 'prueba' && dias > 0) return const SizedBox.shrink();

    Color color;
    IconData icon;
    if (dias < 0) {
      color = _C.danger;
      icon = Icons.error_rounded;
    } else if (dias <= 3) {
      color = _C.warning;
      icon = Icons.warning_amber_rounded;
    } else {
      color = _C.warning;
      icon = Icons.schedule_rounded;
    }

    String titulo;
    if (tipo == 'prueba') {
      titulo = dias < 0
          ? 'Prueba vencida'
          : dias == 0
              ? 'Prueba termina hoy'
              : 'Prueba gratis — $dias día${dias == 1 ? '' : 's'}';
    } else {
      titulo = dias < 0
          ? 'Pago vencido hace ${-dias} día${(-dias) == 1 ? '' : 's'}'
          : dias == 0
              ? 'El pago vence hoy'
              : 'Próximo pago en $dias día${dias == 1 ? '' : 's'}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 14),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 14,
        vertical: isDesktop ? 12 : 11,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.32), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.18),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.32)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vence: ${DateFormat('dd/MM/yyyy').format(proximo)}',
                  style: TextStyle(fontSize: 11, color: p.textMid),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/pago'),
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
            child: Row(
              children: [
                Text(
                  dias < 0 ? 'Pagar ya' : 'Pagar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded,
                    size: 13, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _announcement(
      BuildContext context, AppProvider provider, _P p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.primary.withOpacity(.12),
              _C.cyan.withOpacity(.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.primary.withOpacity(.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(11),
                boxShadow: p.glow(_C.primary, o: 0.32),
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.ultimoAnuncio!.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: p.textHigh,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    provider.ultimoAnuncio!.contenido,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: p.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DRAWER
  // ============================================================
  Widget _buildDrawer(BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isAdmin = _isAdmin(provider);
    final isManager = _isManager(provider);

    return Drawer(
      backgroundColor: p.bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 48, 22, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: _C.gradBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _logo(size: 46, radius: 14, withShadow: false),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nexora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                            ),
                          ),
                          Text(
                            'BUSINESS SUITE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.nombreEmpresa ?? 'Mi Empresa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _roleLabel(provider.rol),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.plan == 'premium' ? 'PREMIUM' : 'NORMAL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _drawerItem(
              context, provider, 'Inicio', Icons.home_rounded, null, p),

          _drawerLabelColored(p, 'OPERACIONES', _C.primary),
          _drawerItem(context, provider, 'Historial',
              Icons.history_rounded, '/historial', p),
          if (isManager)
            _drawerItem(context, provider, 'Inventario',
                Icons.inventory_2_rounded, '/productos', p),
          if (isManager)
            _drawerItem(context, provider, 'Reabastecer',
                Icons.add_box_rounded, '/reabastecer', p),
          if (isManager)
            _drawerItem(context, provider, 'Clientes',
                Icons.people_alt_rounded, '/clientes', p),
          if (isManager)
            _drawerItem(context, provider, 'Gastos',
                Icons.receipt_long_rounded, '/gastos', p),
          if (isManager)
            _drawerItem(context, provider, 'Mermas',
                Icons.warning_amber_rounded, '/mermas', p),
          if (isManager)
            _drawerItem(context, provider, 'Movimientos',
                Icons.swap_horiz_rounded, '/movimientos-sucursales', p),
          if (isAdmin)
            _drawerItem(context, provider, 'Deudas',
                Icons.money_off_rounded, '/deudas', p),
          if (isAdmin)
            _drawerItem(context, provider, 'Facturación',
                Icons.receipt_rounded, '/facturacion', p),

          _drawerLabelColored(p, 'ANÁLISIS', _C.teal),
          if (isManager)
            _drawerItem(context, provider, 'Reportes',
                Icons.insights_rounded, '/reportes', p),
          if (isManager)
            _drawerItem(context, provider, 'Metas',
                Icons.flag_rounded, '/metas', p),

          _drawerLabelColored(p, 'MI NEGOCIO', _C.myBusiness,
              destacado: true),
          _drawerItem(context, provider, 'Mi tienda',
              Icons.storefront_rounded, '/mi-tienda', p,
              accent: _C.myBusiness),
          if (isManager)
            _drawerItem(context, provider, 'Productos publicados',
                Icons.inventory_rounded, '/productos-publicados', p,
                accent: _C.myBusiness),
          if (isManager)
            _drawerItem(context, provider, 'Publicar producto',
                Icons.cloud_upload_rounded, '/publicar-producto', p,
                accent: _C.myBusiness),

          _drawerLabelColored(p, 'RED NEXORA', _C.network, destacado: true),
          _drawerItem(context, provider, 'Explorar negocios',
              Icons.travel_explore_rounded, '/tiendas', p,
              accent: _C.network),
          _drawerItem(context, provider, 'Alianzas',
              Icons.handshake_rounded, '/alianzas', p,
              accent: _C.network),
          _drawerItem(context, provider, 'Referidos',
              Icons.card_giftcard_rounded, '/referidos', p,
              accent: _C.network),
          _drawerItem(context, provider, 'Transferencias',
              Icons.receipt_long_rounded, '/transferencias', p,
              accent: _C.network),

          if (isAdmin) ...[
            _drawerLabelColored(p, 'ADMINISTRACIÓN', _C.purple),
            _drawerItem(context, provider, 'Vendedores',
                Icons.people_outline_rounded, '/vendedores', p),
            _drawerItem(context, provider, 'Estadísticas',
                Icons.leaderboard_rounded, '/estadisticas-vendedores', p),
            _drawerItem(context, provider, 'Sucursales',
                Icons.storefront_rounded, '/sucursales', p),
            _drawerItem(context, provider, 'Nóminas',
                Icons.payments_rounded, '/nominas', p),
            _drawerItem(context, provider, 'Realizar pago',
                Icons.account_balance_wallet_rounded, '/pago', p),
            _drawerItem(context, provider, 'Configuración',
                Icons.settings_rounded, '/settings', p),
          ],
          if (isManager)
            _drawerItem(context, provider, 'Módulo fiscal',
                Icons.request_quote_rounded, '/fiscal', p),

          _drawerLabelColored(p, 'AYUDA', _C.muted),
          _drawerItem(context, provider, 'Invitar amigos',
              Icons.share_rounded, '__invite__', p),
          _drawerItem(context, provider, 'Soporte',
              Icons.support_agent_rounded, '/soporte', p),
          _drawerItem(context, provider, 'Guía de usuario',
              Icons.menu_book_rounded, '/user-guide', p),
          _drawerItem(context, provider, 'Sobre nosotros',
              Icons.info_outline_rounded, '__about__', p),
          _drawerItem(context, provider, 'Términos',
              Icons.description_outlined, '__terms__', p),

          Divider(color: p.border, height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: _C.danger),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _C.danger,
                fontSize: 13.5,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _mostrarLogout(context, provider);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerLabelColored(
    _P p,
    String text,
    Color color, {
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 4),
      child: Row(
        children: [
          Container(
            width: destacado ? 8 : 5,
            height: destacado ? 8 : 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: destacado
                  ? [
                      BoxShadow(
                        color: color.withOpacity(.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: destacado ? 10 : 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: destacado ? color : p.textMuted,
            ),
          ),
          if (destacado) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.32),
                      color.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    AppProvider provider,
    String label,
    IconData icon,
    String? route,
    _P p, {
    Color? accent,
  }) {
    final color = accent ?? p.textMid;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textHigh,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route == null) return;
        if (route == '__invite__') {
          _mostrarInvitar(context, provider);
          return;
        }
        if (route == '__about__') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          );
          return;
        }
        if (route == '__terms__') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          );
          return;
        }
        Navigator.pushNamed(context, route);
      },
    );
  }
}

// ============================================================
//  WIDGET · TARJETA DE PRODUCTO TOP (carrusel)
// ============================================================
class _ProductTopCard extends StatefulWidget {
  final double width;
  final double height;
  final int index;
  final String nombre;
  final double cantidad;
  final double total;
  final String? imageUrl;
  final _P p;
  final VoidCallback onTap;

  const _ProductTopCard({
    Key? key,
    required this.width,
    required this.height,
    required this.index,
    required this.nombre,
    required this.cantidad,
    required this.total,
    required this.imageUrl,
    required this.p,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_ProductTopCard> createState() => _ProductTopCardState();
}

class _ProductTopCardState extends State<_ProductTopCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final esTop = widget.index == 0;
    final color = esTop ? _C.gold : _C.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: esTop ? _C.gold.withOpacity(.55) : p.border,
              width: esTop ? 1.8 : 1.2,
            ),
            boxShadow: esTop
                ? [
                    BoxShadow(
                      color: _C.gold.withOpacity(_pressed ? .30 : .22),
                      blurRadius: _pressed ? 22 : 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : p.shadowSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ─── Imagen del producto
                _buildImage(p),

                // ─── Overlay gradiente inferior
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.05),
                          Colors.black.withOpacity(.75),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // ─── Badge de ranking (top-left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _rankBadge(esTop),
                ),

                // ─── Badge de cantidad (top-right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(.18),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          _fmt(widget.cantidad),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Contenido inferior
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(.45),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '\$${_fmtCompact(widget.total)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              esTop ? 'TOP VENTAS' : 'Puesto ${widget.index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white.withOpacity(.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankBadge(bool esTop) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: esTop
            ? const LinearGradient(colors: _C.gradGold)
            : LinearGradient(
                colors: [
                  Colors.black.withOpacity(.55),
                  Colors.black.withOpacity(.35),
                ],
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esTop ? Colors.white.withOpacity(.35) : Colors.white24,
          width: 1.2,
        ),
        boxShadow: esTop
            ? [
                BoxShadow(
                  color: _C.gold.withOpacity(.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: esTop
          ? const Icon(Icons.emoji_events_rounded,
              color: Colors.white, size: 15)
          : Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  Widget _buildImage(_P p) {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      return _placeholder(p);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // Fade-in suave cuando carga
      frameBuilder: (ctx, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return _placeholder(p, loading: true);
      },
      errorBuilder: (_, __, ___) => _placeholder(p),
    );
  }

  Widget _placeholder(_P p, {bool loading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _C.primary.withOpacity(.20),
            _C.cyan.withOpacity(.08),
          ],
        ),
      ),
      child: Center(
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white.withOpacity(.7),
                ),
              )
            : Icon(
                Icons.inventory_2_rounded,
                color: Colors.white.withOpacity(.55),
                size: 42,
              ),
      ),
    );
  }

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return NumberFormat('#,###').format(n);
    return NumberFormat('#,##0.#').format(n);
  }

  String _fmtCompact(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// ============================================================
//  HELPERS DE FONDO
// ============================================================
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color color;
  _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 42.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = .8;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}