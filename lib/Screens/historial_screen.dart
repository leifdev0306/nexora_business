// ============================================================
//  historial_screen.dart  ·  NEXORA BUSINESS
//  Historial premium con KPIs, agrupación por fecha y detalle
//  Tema: Azul Eléctrico #1A5CFF + Cyan #06B6D4
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../responsive_helper.dart';
import 'servicio_cancelado_screen.dart';
import 'facturacion_screen.dart';

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

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm    = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const gradDanger  = [Color(0xFFEF4444), Color(0xFFEC4899)];
}

// ============================================================
//  Paleta theme-aware
// ============================================================
class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg            => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface       => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2      => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh      => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid       => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted     => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border        => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong  => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(.30) : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> glow(Color c, {double o = 0.24}) => [
        BoxShadow(
          color: c.withOpacity(dark ? o + 0.10 : o),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ============================================================
//  SCREEN
// ============================================================
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _filtroBusqueda = '';
  String _filtroMetodo = 'Todos';
  String? _sucursalSeleccionada;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  bool _mostrarCanceladas = false;
  String _rangoRapido = 'Mes';

  int _visibleCount = 20;
  final int _incrementCount = 20;
  final _searchCtrl = TextEditingController();

  bool get _esVendedor =>
      Provider.of<AppProvider>(context, listen: false).rol == 'vendedor';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final isAdmin = provider.rol == 'admin' || provider.rol == 'dueno';
      if (isAdmin && provider.sucursales.isNotEmpty) {
        setState(() {
          _sucursalSeleccionada = provider.sucursales.first.id;
        });
      }
      if (_esVendedor) {
        final hoy = DateTime.now();
        setState(() {
          _fechaInicio = DateTime(hoy.year, hoy.month, hoy.day);
          _fechaFin = DateTime(hoy.year, hoy.month, hoy.day + 1);
          _rangoRapido = 'Hoy';
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isAdmin(AppProvider p) => p.rol == 'admin' || p.rol == 'dueno';
  bool _isManager(AppProvider p) =>
      _isAdmin(p) || p.rol == 'gerente' || p.rol == 'gestor';

  void _aplicarRangoRapido(String tipo) {
    final now = DateTime.now();
    setState(() {
      _rangoRapido = tipo;
      switch (tipo) {
        case 'Hoy':
          _fechaInicio = DateTime(now.year, now.month, now.day);
          _fechaFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Semana':
          final ini = now.subtract(Duration(days: now.weekday - 1));
          _fechaInicio = DateTime(ini.year, ini.month, ini.day);
          _fechaFin = now;
          break;
        case 'Mes':
          _fechaInicio = DateTime(now.year, now.month, 1);
          _fechaFin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Año':
          _fechaInicio = DateTime(now.year, 1, 1);
          _fechaFin = now;
          break;
      }
      _visibleCount = 20;
    });
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

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    final isAdmin = _isAdmin(provider);
    final isManager = _isManager(provider);
    final isVendedor = provider.rol == 'vendedor';

    // Filtrado
    var ventas = _mostrarCanceladas
        ? provider.ventasPermitidas.toList()
        : provider.ventasPermitidas.where((v) => v.costoTotal > 0).toList();

    if (_filtroBusqueda.isNotEmpty) {
      final q = _filtroBusqueda.toLowerCase().trim();
      ventas = ventas.where((v) {
        final nombre = v.productoNombre.toLowerCase();
        if (nombre.contains(q)) return true;
        if (v.clienteId != null) {
          try {
            final c = provider.clientes
                .firstWhere((c) => c.id == v.clienteId);
            if (c.nombre.toLowerCase().contains(q)) return true;
          } catch (_) {}
        }
        if (v.metodoPago.toLowerCase().contains(q)) return true;
        return false;
      }).toList();
    }

    if (_filtroMetodo != 'Todos') {
      ventas = ventas.where((v) => v.metodoPago == _filtroMetodo).toList();
    }

    if (isAdmin && _sucursalSeleccionada != null) {
      ventas =
          ventas.where((v) => v.sucursalId == _sucursalSeleccionada).toList();
    }

    ventas = ventas
        .where((v) =>
            v.fecha.isAfter(_fechaInicio) && v.fecha.isBefore(_fechaFin))
        .toList();

    ventas.sort((a, b) => b.fecha.compareTo(a.fecha));

    final totalVentas = ventas.length;
    final mostrarMas = totalVentas > _visibleCount;
    final ventasMostradas = ventas.take(_visibleCount).toList();

    // KPIs
    double montoTotal = 0;
    double gananciaTotal = 0;
    for (final v in ventas) {
      montoTotal += v.total;
      gananciaTotal += (v.total - v.costoTotal);
    }
    final double ticketProm =
        totalVentas > 0 ? montoTotal / totalVentas : 0;

    // Agrupación por fecha
    final grupos = <String, List<Venta>>{};
    for (final v in ventasMostradas) {
      final key = _fechaKey(v.fecha);
      grupos.putIfAbsent(key, () => []).add(v);
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, provider, p, isVendedor, isManager),
      body: Stack(
        children: [
          _background(p),
          RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 14, 12, isDesktop ? 24 : 14, 0),
                    child: Column(
                      children: [
                        _searchBar(p),
                        const SizedBox(height: 12),
                        _periodoChips(p, isVendedor),
                        if (isAdmin) ...[
                          const SizedBox(height: 10),
                          _sucursalFilter(context, provider, p),
                        ],
                        const SizedBox(height: 14),
                        _kpiStrip(p, totalVentas, montoTotal, gananciaTotal,
                            ticketProm, isManager),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (ventasMostradas.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(p, isVendedor),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildListDelegate(
                      grupos.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                              isDesktop ? 24 : 14,
                              10,
                              isDesktop ? 24 : 14,
                              0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fechaHeader(context, entry.key, entry.value, p),
                              const SizedBox(height: 8),
                              ...entry.value
                                  .map((v) => _ventaCard(
                                      context, v, provider, p, isAdmin)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (mostrarMas)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 24 : 14, 16, isDesktop ? 24 : 14, 16),
                        child: _cargarMasButton(p, totalVentas),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ],
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
              top: -200,
              right: -160,
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _C.primary.withOpacity(p.dark ? .14 : .08),
                      _C.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -240,
              left: -140,
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _C.cyan.withOpacity(p.dark ? .12 : .07),
                      _C.cyan.withOpacity(0),
                    ],
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
  //  APP BAR
  // ============================================================
  PreferredSizeWidget _appBar(
    BuildContext context,
    AppProvider provider,
    _P p,
    bool isVendedor,
    bool isManager,
  ) {
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
              boxShadow: p.glow(_C.primary, o: 0.28),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isVendedor ? 'Mis ventas' : 'Historial',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                isVendedor ? 'Del día de hoy' : 'Todas las operaciones',
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
      actions: [
        if (isManager)
          IconButton(
            tooltip: 'Exportar',
            onPressed: () => _exportarResumen(context, provider),
            icon: Icon(Icons.share_outlined, color: p.textHigh),
          ),
        IconButton(
          tooltip: 'Filtros',
          onPressed: () => _mostrarDialogoFiltros(context),
          icon: Icon(Icons.tune_rounded, color: p.textHigh),
        ),
      ],
    );
  }

  // ============================================================
  //  SEARCH BAR
  // ============================================================
  Widget _searchBar(_P p) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {
          _filtroBusqueda = v;
          _visibleCount = 20;
        }),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textHigh,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por producto, cliente o método…',
          hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
          suffixIcon: _filtroBusqueda.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: p.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _filtroBusqueda = '';
                      _visibleCount = 20;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ============================================================
  //  PERIODO CHIPS
  // ============================================================
  Widget _periodoChips(_P p, bool isVendedor) {
    final opciones =
        isVendedor ? ['Hoy'] : ['Hoy', 'Semana', 'Mes', 'Año'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final op = opciones[i];
          final selected = _rangoRapido == op;
          return Material(
            color: selected ? Colors.transparent : p.surface,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: isVendedor ? null : () => _aplicarRangoRapido(op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: _C.gradBrand)
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected ? Colors.transparent : p.borderStrong,
                  ),
                  boxShadow: selected ? p.glow(_C.primary, o: 0.28) : null,
                ),
                child: Text(
                  op,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? Colors.white : p.textMid,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //  SUCURSAL FILTER
  // ============================================================
  Widget _sucursalFilter(BuildContext context, AppProvider provider, _P p) {
    if (provider.sucursales.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .16 : .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront_rounded,
                size: 15, color: _C.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _sucursalSeleccionada,
                isDense: true,
                isExpanded: true,
                dropdownColor: p.surface,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
                onChanged: (v) => setState(() {
                  _sucursalSeleccionada = v;
                  _visibleCount = 20;
                }),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas las sucursales'),
                  ),
                  ...provider.sucursales.map((s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.nombre),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  KPI STRIP
  // ============================================================
  Widget _kpiStrip(
    _P p,
    int totalVentas,
    double montoTotal,
    double gananciaTotal,
    double ticketProm,
    bool isManager,
  ) {
    final tiles = <Widget>[
      _kpiTile(
        p: p,
        icon: Icons.receipt_long_rounded,
        label: 'Operaciones',
        value: '$totalVentas',
        color: _C.primary,
      ),
      _kpiTile(
        p: p,
        icon: Icons.attach_money_rounded,
        label: 'Monto total',
        value: '\$${_fmt(montoTotal)}',
        color: _C.success,
      ),
      if (isManager)
        _kpiTile(
          p: p,
          icon: Icons.savings_rounded,
          label: 'Ganancia',
          value: '\$${_fmt(gananciaTotal)}',
          color: _C.cyan,
        ),
      if (isManager)
        _kpiTile(
          p: p,
          icon: Icons.trending_up_rounded,
          label: 'Ticket prom.',
          value: '\$${_fmt(ticketProm)}',
          color: _C.purple,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _kpiTile({
    required _P p,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
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
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: p.textHigh,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FECHA HEADER
  // ============================================================
  String _fechaKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Widget _fechaHeader(
      BuildContext context, String key, List<Venta> ventas, _P p) {
    final fecha = DateTime.parse(key);
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaAyer = DateTime(ayer.year, ayer.month, ayer.day);
    final fechaEste = DateTime(fecha.year, fecha.month, fecha.day);

    String titulo;
    if (fechaEste == fechaHoy) {
      titulo = 'Hoy';
    } else if (fechaEste == fechaAyer) {
      titulo = 'Ayer';
    } else {
      titulo = DateFormat('EEEE, d MMMM', 'es').format(fecha);
    }
    titulo = titulo[0].toUpperCase() + titulo.substring(1);

    double monto = 0;
    for (final v in ventas) {
      monto += v.total;
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _C.gradBrand),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            color: p.textHigh,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _C.primary.withOpacity(p.dark ? .16 : .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${ventas.length}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _C.primary,
            ),
          ),
        ),
        const Spacer(),
        Text(
          '\$${_fmt(monto)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _C.success,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  VENTA CARD
  // ============================================================
  Widget _ventaCard(
    BuildContext context,
    Venta v,
    AppProvider provider,
    _P p,
    bool isAdmin,
  ) {
    final cliente = v.clienteId != null
        ? provider.clientes.firstWhere(
            (c) => c.id == v.clienteId,
            orElse: () => Cliente(id: '', nombre: 'Cliente eliminado'),
          )
        : null;
    final sucursal = v.sucursalId != null
        ? provider.sucursales.firstWhere(
            (s) => s.id == v.sucursalId,
            orElse: () =>
                Sucursal(id: '', nombre: 'Sin sucursal', direccion: ''),
          )
        : null;
    final emailVendedor = provider.getUsuarioEmail(v.usuarioId);

    final ganancia = v.total - v.costoTotal;
    final cancelada = v.estado == 'cancelled' || v.costoTotal <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              _mostrarOpcionesVenta(context, v, provider, p),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cancelada
                    ? _C.danger.withOpacity(.35)
                    : p.border,
              ),
              boxShadow: p.shadowSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cancelada
                          ? [
                              _C.danger.withOpacity(.22),
                              _C.danger.withOpacity(.06),
                            ]
                          : [
                              _C.success.withOpacity(.22),
                              _C.cyan.withOpacity(.06),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: (cancelada ? _C.danger : _C.success)
                          .withOpacity(.24),
                    ),
                  ),
                  child: Text(
                    _fmtCant(v.cantidad),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: cancelada ? _C.danger : _C.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              v.productoNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: p.textHigh,
                              ),
                            ),
                          ),
                          if (cancelada) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.danger.withOpacity(.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CANCELADA',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                  color: _C.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _miniTag(p, Icons.access_time_rounded,
                              DateFormat('HH:mm').format(v.fecha)),
                          _miniTag(p, Icons.payments_rounded, v.metodoPago),
                          if (cliente != null && cliente.nombre.isNotEmpty)
                            _miniTag(p, Icons.person_rounded,
                                cliente.nombre),
                          if (isAdmin && sucursal != null)
                            _miniTag(p, Icons.storefront_rounded,
                                sucursal.nombre),
                          _miniTag(p, Icons.person_outline_rounded,
                              emailVendedor),
                        ],
                      ),
                      if (v.totalUSD != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.orange.withOpacity(.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '\$${v.totalUSD!.toStringAsFixed(2)} USD',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _C.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '× ${v.tasaCambio?.toStringAsFixed(0) ?? '—'}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_fmt(v.total)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.3,
                        color: cancelada ? p.textMuted : _C.success,
                        decoration:
                            cancelada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (!cancelada && ganancia != 0)
                      Text(
                        '+\$${_fmt(ganancia)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _C.cyan,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: p.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTag(_P p, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: p.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  CARGAR MÁS
  // ============================================================
  Widget _cargarMasButton(_P p, int total) {
    return Center(
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() => _visibleCount += _incrementCount),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _C.primary.withOpacity(.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.expand_more_rounded,
                    size: 18, color: _C.primary),
                const SizedBox(width: 8),
                Text(
                  'Cargar más ($_visibleCount de $total)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _C.primary,
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
  //  EMPTY STATE
  // ============================================================
  Widget _emptyState(_P p, bool isVendedor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.primary.withOpacity(.16),
                    _C.cyan.withOpacity(.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVendedor ? Icons.today_rounded : Icons.history_rounded,
                size: 42,
                color: _C.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isVendedor
                  ? 'No tienes ventas hoy'
                  : 'Sin ventas en este período',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isVendedor
                  ? 'Cuando registres una venta aparecerá aquí.'
                  : 'Prueba a cambiar los filtros o el rango de fechas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  BOTTOM SHEET · Detalle
  // ============================================================
  void _mostrarOpcionesVenta(
      BuildContext context, Venta venta, AppProvider provider, _P p) {
    final producto = provider.getProductoById(venta.productoId);
    final cliente = venta.clienteId != null
        ? provider.clientes.firstWhere(
            (c) => c.id == venta.clienteId,
            orElse: () => Cliente(id: '', nombre: 'Cliente eliminado'),
          )
        : null;
    final emailVendedor = provider.getUsuarioEmail(venta.usuarioId);
    final ganancia = venta.total - venta.costoTotal;
    final cancelada = venta.estado == 'cancelled' || venta.costoTotal <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cancelada
                              ? [_C.danger.withOpacity(.22), _C.danger.withOpacity(.06)]
                              : [_C.success.withOpacity(.22), _C.cyan.withOpacity(.06)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (cancelada ? _C.danger : _C.success)
                              .withOpacity(.24),
                        ),
                      ),
                      child: Icon(
                        cancelada
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded,
                        color: cancelada ? _C.danger : _C.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cancelada ? 'Venta cancelada' : 'Venta completada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: cancelada ? _C.danger : _C.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venta.productoNombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
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

                const SizedBox(height: 20),

                // Total destacado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cancelada
                          ? [_C.danger.withOpacity(.12), _C.danger.withOpacity(.04)]
                          : _C.gradBrand,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: cancelada
                        ? null
                        : p.glow(_C.primary, o: 0.32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DE LA VENTA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: cancelada
                              ? p.textMuted
                              : Colors.white.withOpacity(.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${_fmt(venta.total)}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: cancelada ? p.textHigh : Colors.white,
                          ),
                        ),
                      ),
                      if (venta.totalUSD != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '\$${venta.totalUSD!.toStringAsFixed(2)} USD × ${venta.tasaCambio?.toStringAsFixed(0) ?? '—'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: cancelada
                                ? p.textMuted
                                : Colors.white.withOpacity(.90),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Detalle grid
                _seccionTitulo('Detalle de la operación', p),
                const SizedBox(height: 10),
                _detalleRow(Icons.shopping_bag_rounded, 'Producto',
                    producto?.nombre ?? venta.productoNombre, p),
                _detalleRow(Icons.numbers_rounded, 'Cantidad',
                    _fmtCant(venta.cantidad), p),
                _detalleRow(Icons.attach_money_rounded, 'Precio unitario',
                    '\$${_fmt(venta.precioUnitario)}', p),
                _detalleRow(Icons.payments_rounded, 'Método',
                    venta.metodoPago, p),
                if (producto != null)
                  _detalleRow(Icons.warehouse_rounded, 'Unidad',
                      producto.unidadMedida, p),

                const SizedBox(height: 16),
                _seccionTitulo('Información adicional', p),
                const SizedBox(height: 10),
                _detalleRow(Icons.event_rounded, 'Fecha',
                    DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha), p),
                if (cliente != null && cliente.nombre.isNotEmpty)
                  _detalleRow(Icons.person_rounded, 'Cliente',
                      cliente.nombre, p),
                if (venta.usuarioId != null)
                  _detalleRow(Icons.badge_rounded, 'Vendedor',
                      emailVendedor, p),
                if (venta.sucursalId != null)
                  _detalleRow(
                      Icons.storefront_rounded,
                      'Sucursal',
                      provider.getSucursalNombre(venta.sucursalId!),
                      p),
                if (venta.nota != null && venta.nota!.isNotEmpty)
                  _detalleRow(Icons.notes_rounded, 'Nota', venta.nota!, p),

                const SizedBox(height: 16),

                // Margen
                if (!cancelada)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (ganancia > 0 ? _C.success : _C.danger)
                          .withOpacity(p.dark ? .10 : .06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (ganancia > 0 ? _C.success : _C.danger)
                            .withOpacity(.24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ganancia > 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 18,
                          color: ganancia > 0 ? _C.success : _C.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Margen de esta venta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.textMid,
                            ),
                          ),
                        ),
                        Text(
                          '\$${_fmt(ganancia)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color:
                                ganancia > 0 ? _C.success : _C.danger,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Acciones
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.receipt_long_rounded,
                        label: 'Facturar',
                        color: _C.primary,
                        p: p,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/facturacion',
                              arguments: venta);
                        },
                      ),
                    ),
                    if (!cancelada) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.cancel_rounded,
                          label: 'Cancelar',
                          color: _C.danger,
                          p: p,
                          onTap: () {
                            Navigator.pop(ctx);
                            _cancelarVentaDesdeDialogo(
                                context, venta, provider);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _seccionTitulo(String text, _P p) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _C.gradBrand),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _detalleRow(IconData icon, String label, String value, _P p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .14 : .08),
              borderRadius: BorderRadius.circular(9),
              border:
                  Border.all(color: _C.primary.withOpacity(.16)),
            ),
            child: Icon(icon, size: 15, color: _C.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required _P p,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(p.dark ? .16 : .10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
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
  //  CANCELAR VENTA
  // ============================================================
  Future<void> _cancelarVentaDesdeDialogo(
      BuildContext context, Venta venta, AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final confirm = await showDialog<bool>(
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
              child: const Icon(Icons.cancel_rounded,
                  color: _C.danger, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancelar venta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de cancelar la venta de ${venta.productoNombre} por \$${_fmt(venta.total)}?',
          style: TextStyle(color: p.textMid, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Sí, cancelar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await provider.eliminarVenta(venta.id);
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Venta cancelada correctamente', esExito: true);
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Error al cancelar: ${mensajeAmigable(e)}',
              esExito: false);
        }
      }
    }
  }

  // ============================================================
  //  DIÁLOGO DE FILTROS
  // ============================================================
  void _mostrarDialogoFiltros(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDark);
    final isVendedor = provider.rol == 'vendedor';
    final isAdmin = _isAdmin(provider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .16 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: _C.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              isVendedor ? 'Filtros (solo hoy)' : 'Filtros',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Método de pago
                    DropdownButtonFormField<String>(
                      value: _filtroMetodo,
                      dropdownColor: p.surface,
                      decoration: InputDecoration(
                        labelText: 'Método de pago',
                        labelStyle: TextStyle(
                            fontSize: 12.5, color: p.textMuted),
                        filled: true,
                        fillColor: p.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.textHigh,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(
                            value: 'Efectivo CUP',
                            child: Text('Efectivo CUP')),
                        DropdownMenuItem(
                            value: 'Efectivo MLC',
                            child: Text('Efectivo MLC')),
                        DropdownMenuItem(
                            value: 'Transferencia',
                            child: Text('Transferencia')),
                        DropdownMenuItem(
                            value: 'Tarjeta', child: Text('Tarjeta')),
                      ],
                      onChanged: (value) =>
                          setLocal(() => _filtroMetodo = value!),
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _sucursalSeleccionada,
                        dropdownColor: p.surface,
                        decoration: InputDecoration(
                          labelText: 'Sucursal',
                          labelStyle: TextStyle(
                              fontSize: 12.5, color: p.textMuted),
                          filled: true,
                          fillColor: p.surface2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: p.textHigh,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('Todas')),
                          ...provider.sucursales.map((s) =>
                              DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(s.nombre),
                              )),
                        ],
                        onChanged: (value) =>
                            setLocal(() => _sucursalSeleccionada = value),
                      ),
                    ],

                    if (!isVendedor) ...[
                      const SizedBox(height: 12),
                      _dateFieldDialog(
                        p,
                        'Desde',
                        _fechaInicio,
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaInicio,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setLocal(() => _fechaInicio = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _dateFieldDialog(
                        p,
                        'Hasta',
                        _fechaFin,
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaFin,
                            firstDate: _fechaInicio,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setLocal(() => _fechaFin = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Mostrar canceladas',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.textHigh,
                            ),
                          ),
                          value: _mostrarCanceladas,
                          activeColor: _C.primary,
                          onChanged: (value) =>
                              setLocal(() => _mostrarCanceladas = value),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _C.info.withOpacity(.10),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: _C.info.withOpacity(.24)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: _C.info, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Solo se muestran ventas del día actual.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.textMid,
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
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroBusqueda = '';
                _searchCtrl.clear();
                _filtroMetodo = 'Todos';
                if (isAdmin) _sucursalSeleccionada = null;
                if (!isVendedor) {
                  _fechaInicio =
                      DateTime.now().subtract(const Duration(days: 30));
                  _fechaFin = DateTime.now();
                  _mostrarCanceladas = false;
                  _rangoRapido = 'Mes';
                }
                _visibleCount = 20;
              });
              Navigator.pop(context);
            },
            child: Text('Limpiar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _visibleCount = 20);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Aplicar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _dateFieldDialog(
      _P p, String label, DateTime value, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: _C.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$label: ${DateFormat('dd/MM/yyyy').format(value)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  EXPORTAR
  // ============================================================
  Future<void> _exportarResumen(
      BuildContext context, AppProvider provider) async {
    final b = StringBuffer();
    b.writeln('═══════════════════════════════');
    b.writeln('HISTORIAL DE VENTAS');
    b.writeln('═══════════════════════════════');
    b.writeln(
        'Período: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}');
    b.writeln('Empresa: ${provider.nombreEmpresa ?? ''}');
    b.writeln('');

    var ventas = provider.ventasPermitidas.toList();
    if (_filtroMetodo != 'Todos') {
      ventas = ventas.where((v) => v.metodoPago == _filtroMetodo).toList();
    }
    if (_isAdmin(provider) && _sucursalSeleccionada != null) {
      ventas =
          ventas.where((v) => v.sucursalId == _sucursalSeleccionada).toList();
    }
    ventas = ventas
        .where((v) =>
            v.fecha.isAfter(_fechaInicio) && v.fecha.isBefore(_fechaFin))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    double total = 0;
    for (final v in ventas) {
      total += v.total;
    }

    b.writeln('Total operaciones: ${ventas.length}');
    b.writeln('Monto total: \$${_fmt(total)}');
    b.writeln('');
    b.writeln('─── Detalle ───');

    for (final v in ventas.take(100)) {
      b.writeln(
          '${DateFormat('dd/MM HH:mm').format(v.fecha)} · ${v.productoNombre} × ${_fmtCant(v.cantidad)} = \$${_fmt(v.total)} (${v.metodoPago})');
    }

    if (ventas.length > 100) {
      b.writeln('... y ${ventas.length - 100} más');
    }

    await Share.share(b.toString());
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  String _fmt(double n) => NumberFormat('#,##0.00').format(n);

  String _fmtCant(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}