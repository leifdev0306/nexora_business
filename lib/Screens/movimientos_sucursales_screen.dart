// ============================================================
//  movimientos_sucursales_screen.dart · NEXORA BUSINESS
//  Historial de movimientos entre sucursales
//  · Mismo lenguaje visual que home_screen / vendedores_screen
//  · Responsive: lista en mobile, grid en desktop
//  · Slidable + acciones de invertir / cancelar
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../main.dart';
import '../responsive_helper.dart';
import 'servicio_cancelado_screen.dart';

// ============================================================
//  Acentos compartidos (idénticos al resto de la app)
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
  List<BoxShadow> glow(Color c, {double o = 0.24}) => [
        BoxShadow(
          color: c.withOpacity(dark ? o + 0.10 : o),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}

class MovimientosSucursalesScreen extends StatefulWidget {
  const MovimientosSucursalesScreen({Key? key}) : super(key: key);

  @override
  State<MovimientosSucursalesScreen> createState() =>
      _MovimientosSucursalesScreenState();
}

class _MovimientosSucursalesScreenState
    extends State<MovimientosSucursalesScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroBusqueda = '';
  bool _mostrarCancelados = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers de rol (idénticos a home_screen) ───────────────
  bool _isAdmin(AppProvider p) => p.rol == 'dueno' || p.rol == 'admin';
  bool _isManager(AppProvider p) =>
      _isAdmin(p) || p.rol == 'gerente' || p.rol == 'gestor';

  String _fmt(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return NumberFormat('#,###').format(n);
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    final esAdmin = _isAdmin(provider);
    final esManager = _isManager(provider);

    // ─── Permisos ─────────────────────────────────────────────
    if (!esManager) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(context, p, esAdmin, esManager),
        body: _emptyPermissions(p),
      );
    }

    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    // ─── Datos filtrados ─────────────────────────────────────
    var movimientos = provider.movimientos.toList();
    if (!_mostrarCancelados) {
      movimientos = movimientos.where((m) => !m.cancelado).toList();
    }
    if (_filtroBusqueda.isNotEmpty) {
      final q = _filtroBusqueda.toLowerCase();
      movimientos = movimientos.where((m) {
        final producto = provider.getProductoById(m.productoId);
        final nombre = producto?.nombre ?? '';
        final origen = provider.getSucursalNombre(m.sucursalOrigenId);
        final destino = provider.getSucursalNombre(m.sucursalDestinoId);
        return nombre.toLowerCase().contains(q) ||
            origen.toLowerCase().contains(q) ||
            destino.toLowerCase().contains(q);
      }).toList();
    }
    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));

    final activos = movimientos.where((m) => !m.cancelado).toList();
    final totalCostoActivos =
        activos.fold<double>(0.0, (s, m) => s + m.costoTotal);
    final totalUnidadesActivos =
        activos.fold<double>(0.0, (s, m) => s + m.cantidad);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, p, esAdmin, esManager),
      body: SafeArea(
        child: Column(
          children: [
            _statsRow(
              totalMovimientos: movimientos.length,
              totalCosto: totalCostoActivos,
              totalUnidades: totalUnidadesActivos,
              p: p,
            ),
            _searchAndFilters(p, esAdmin),
            Expanded(
              child: movimientos.isEmpty
                  ? _emptyState(p, _filtroBusqueda.isNotEmpty)
                  : (isDesktop
                      ? _buildDesktopGrid(
                          context, movimientos, provider, p, esAdmin, esManager)
                      : _buildMobileList(
                          context, movimientos, provider, p, esAdmin, esManager)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  APP BAR
  // ============================================================
  PreferredSizeWidget _appBar(
      BuildContext context, _P p, bool esAdmin, bool esManager) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradNetwork),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.network.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Movimientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Entre sucursales',
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
  //  STATS ROW
  // ============================================================
  Widget _statsRow({
    required int totalMovimientos,
    required double totalCosto,
    required double totalUnidades,
    required _P p,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              p: p,
              label: 'Movimientos',
              value: '$totalMovimientos',
              icon: Icons.sync_alt_rounded,
              color: _C.network,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              p: p,
              label: 'Unidades',
              value: _fmt(totalUnidades),
              icon: Icons.inventory_2_rounded,
              color: _C.info,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              p: p,
              label: 'Costo',
              value: '\$${_fmt(totalCosto)}',
              icon: Icons.attach_money_rounded,
              color: _C.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required _P p,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(.22),
                  color.withOpacity(.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
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
      ),
    );
  }

  // ============================================================
  //  SEARCH + FILTERS
  // ============================================================
  Widget _searchAndFilters(_P p, bool esAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _filtroBusqueda = v),
              style: TextStyle(
                fontSize: 13.5,
                color: p.textHigh,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar producto, origen o destino…',
                hintStyle: TextStyle(
                  color: p.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: p.textMuted),
                suffixIcon: _filtroBusqueda.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: p.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filtroBusqueda = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: p.surface2,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                      color: _C.primary, width: 1.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _toggleChip(
            p: p,
            icon: _mostrarCancelados
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            label: 'Cancelados',
            active: _mostrarCancelados,
            color: _C.danger,
            onTap: () => setState(
                () => _mostrarCancelados = !_mostrarCancelados),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required _P p,
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(.14) : p.surface2,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? color.withOpacity(.45) : p.border,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: active ? color : p.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? color : p.textMid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MOBILE LIST
  // ============================================================
  Widget _buildMobileList(
    BuildContext context,
    List<MovimientoSucursal> movimientos,
    AppProvider provider,
    _P p,
    bool esAdmin,
    bool esManager,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      itemCount: movimientos.length,
      itemBuilder: (_, i) {
        final m = movimientos[i];
        final producto = provider.getProductoById(m.productoId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Slidable(
            key: ValueKey(m.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.55,
              children: [
                if (esManager && !m.cancelado)
                  SlidableAction(
                    onPressed: (_) => _invertirMovimiento(context, m.id),
                    backgroundColor: _C.cyan,
                    foregroundColor: Colors.white,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Invertir',
                    borderRadius: BorderRadius.circular(16),
                  ),
                if (esManager && !m.cancelado)
                  SlidableAction(
                    onPressed: (_) => _cancelarMovimiento(context, m.id),
                    backgroundColor: _C.danger,
                    foregroundColor: Colors.white,
                    icon: Icons.undo_rounded,
                    label: 'Cancelar',
                    borderRadius: BorderRadius.circular(16),
                  ),
              ],
            ),
            child: _movimientoCardMobile(context, provider, p, m, producto),
          ),
        );
      },
    );
  }

  Widget _movimientoCardMobile(
    BuildContext context,
    AppProvider provider,
    _P p,
    MovimientoSucursal m,
    Producto? producto,
  ) {
    final cancelado = m.cancelado;
    final color = cancelado ? _C.danger : _C.network;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cancelado ? _C.danger.withOpacity(.35) : p.border,
          width: cancelado ? 1.4 : 1,
        ),
        boxShadow: p.shadowSm,
      ),
      padding: const EdgeInsets.all(14),
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
                    colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(.32)),
                ),
                child: Icon(
                  cancelado
                      ? Icons.block_rounded
                      : Icons.swap_horiz_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto?.nombre ?? 'Producto eliminado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.14),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: color.withOpacity(.28)),
                          ),
                          child: Text(
                            '${_fmt(m.cantidad)} unds',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                        if (cancelado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.danger.withOpacity(.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CANCELADO',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: _C.danger,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '\$${_fmt(m.costoTotal)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: cancelado ? p.textMuted : _C.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.call_split_rounded,
                    size: 13, color: p.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${provider.getSucursalNombre(m.sucursalOrigenId)}  →  ${provider.getSucursalNombre(m.sucursalDestinoId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 12, color: p.textMuted),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd/MM/yyyy · HH:mm').format(m.fecha),
                style: TextStyle(
                  fontSize: 10.5,
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
  //  DESKTOP GRID
  // ============================================================
  Widget _buildDesktopGrid(
    BuildContext context,
    List<MovimientoSucursal> movimientos,
    AppProvider provider,
    _P p,
    bool esAdmin,
    bool esManager,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols;
        if (constraints.maxWidth >= 1500) {
          cols = 4;
        } else if (constraints.maxWidth >= 1150) {
          cols = 3;
        } else {
          cols = 2;
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.45,
          ),
          itemCount: movimientos.length,
          itemBuilder: (_, i) => _movimientoCardDesktop(
            context,
            provider,
            p,
            movimientos[i],
            esManager,
          ),
        );
      },
    );
  }

  Widget _movimientoCardDesktop(
    BuildContext context,
    AppProvider provider,
    _P p,
    MovimientoSucursal m,
    bool esManager,
  ) {
    final producto = provider.getProductoById(m.productoId);
    final cancelado = m.cancelado;
    final color = cancelado ? _C.danger : _C.network;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cancelado ? _C.danger.withOpacity(.35) : p.border,
          width: cancelado ? 1.4 : 1,
        ),
        boxShadow: p.shadowSm,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacity(.32)),
                ),
                child: Icon(
                  cancelado
                      ? Icons.block_rounded
                      : Icons.swap_horiz_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto?.nombre ?? 'Producto eliminado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(.14),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: color.withOpacity(.28)),
                          ),
                          child: Text(
                            '${_fmt(m.cantidad)} unds',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                        if (cancelado) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.danger.withOpacity(.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CANCELADO',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: _C.danger,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Icon(Icons.call_split_rounded,
                    size: 14, color: p.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${provider.getSucursalNombre(m.sucursalOrigenId)}  →  ${provider.getSucursalNombre(m.sucursalDestinoId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: p.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(m.fecha),
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
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COSTO TOTAL',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${_fmt(m.costoTotal)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: cancelado ? p.textMuted : _C.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (esManager && !cancelado) ...[
                _actionBtn(
                  icon: Icons.swap_horiz_rounded,
                  color: _C.cyan,
                  tooltip: 'Invertir',
                  onTap: () => _invertirMovimiento(context, m.id),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  icon: Icons.undo_rounded,
                  color: _C.danger,
                  tooltip: 'Cancelar',
                  onTap: () => _cancelarMovimiento(context, m.id),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  EMPTY STATES
  // ============================================================
  Widget _emptyState(_P p, bool hayBusqueda) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.network.withOpacity(.16),
                  _C.primary.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hayBusqueda
                    ? Icons.search_off_rounded
                    : Icons.swap_horiz_rounded,
                size: 40,
                color: _C.network.withOpacity(.75),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hayBusqueda
                  ? 'Sin resultados'
                  : 'Sin movimientos registrados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hayBusqueda
                  ? 'Prueba con otro producto, sucursal o limpia el filtro.'
                  : 'Los movimientos entre sucursales aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPermissions(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(color: _C.danger.withOpacity(.28)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 40, color: _C.danger),
            ),
            const SizedBox(height: 18),
            Text(
              'Acceso restringido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Solo dueños y gerentes pueden ver los movimientos entre sucursales.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  ACCIONES
  // ============================================================
  Future<void> _invertirMovimiento(
      BuildContext context, String movimientoId) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final movimiento = provider.movimientoBox.get(movimientoId);
    if (movimiento == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradNetwork),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Invertir movimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Se creará un nuevo movimiento de '
          '${provider.getSucursalNombre(movimiento.sucursalDestinoId)} '
          '→ ${provider.getSucursalNombre(movimiento.sucursalOrigenId)} '
          'con la misma cantidad y costo.',
          style: TextStyle(
              color: p.textMid, fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancelar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Invertir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.registrarMovimientoInverso(movimiento);
        mostrarSnackBar(
            mensaje: 'Movimiento inverso registrado', esExito: true);
      } catch (e) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }

  Future<void> _cancelarMovimiento(
      BuildContext context, String movimientoId) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradDanger),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.undo_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cancelar movimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El movimiento quedará marcado como cancelado. '
          'Esta acción no restaura automáticamente el stock.',
          style: TextStyle(
              color: p.textMid, fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Volver', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Cancelar movimiento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<AppProvider>(context, listen: false)
            .cancelarMovimiento(movimientoId);
        if (!mounted) return;
        mostrarSnackBar(
            mensaje: 'Movimiento cancelado', esExito: true);
      } catch (e) {
        if (!mounted) return;
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }
}