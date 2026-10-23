// ============================================================
//  compras_screen.dart  ·  NEXORA BUSINESS
//  Historial de compras (reabastecimientos)
//  · KPIs: total invertido, unidades, cantidad, promedio
//  · Filtros: período, producto, proveedor, búsqueda
//  · Vistas: lista plana / agrupado por producto
//  · Detalle por compra + exportar + eliminar del historial
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../responsive_helper.dart';
import 'servicio_cancelado_screen.dart';

// ============================================================
//  Acentos compartidos
// ============================================================
class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan    = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);
  static const purple  = Color(0xFF8B5CF6);
  static const pink    = Color(0xFFEC4899);
  static const indigo  = Color(0xFF6366F1);
  static const teal    = Color(0xFF14B8A6);

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm    = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const gradDanger  = [Color(0xFFEF4444), Color(0xFFEC4899)];
  static const gradCompras = [Color(0xFF8B5CF6), Color(0xFF6366F1)];
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
  Color get borderStrong=> dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
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
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({Key? key}) : super(key: key);

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  int _periodoIdx = 3; // 0=Hoy, 1=Semana, 2=Mes, 3=Todo
  String _search = '';
  String? _productoFiltroId;
  String? _proveedorFiltroId;
  bool _agruparPorProducto = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  (DateTime, DateTime) get _rangoPeriodo {
    final hoy = DateTime.now();
    switch (_periodoIdx) {
      case 0: // Hoy
        return (
          DateTime(hoy.year, hoy.month, hoy.day),
          DateTime(hoy.year, hoy.month, hoy.day + 1),
        );
      case 1: // Semana
        final inicio = hoy.subtract(Duration(days: (hoy.weekday - 1) % 7));
        final inicioDia = DateTime(inicio.year, inicio.month, inicio.day);
        return (inicioDia, inicioDia.add(const Duration(days: 7)));
      case 2: // Mes
        return (
          DateTime(hoy.year, hoy.month, 1),
          DateTime(hoy.year, hoy.month + 1, 1),
        );
      default: // Todo
        return (DateTime(2000), DateTime(2100));
    }
  }

  String get _periodoLabel {
    switch (_periodoIdx) {
      case 0:
        return 'Hoy';
      case 1:
        return 'Esta semana';
      case 2:
        return 'Este mes';
      default:
        return 'Todo';
    }
  }

  List<Compra> _comprasFiltradas(AppProvider provider) {
    final (inicio, fin) = _rangoPeriodo;
    var lista = provider.comprasPorPeriodo(inicio, fin);

    if (_productoFiltroId != null) {
      lista = lista
          .where((c) => c.productoId == _productoFiltroId)
          .toList();
    }
    if (_proveedorFiltroId != null) {
      lista = lista
          .where((c) => c.proveedorId == _proveedorFiltroId)
          .toList();
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((c) {
        final prod = c.productoNombre.toLowerCase();
        final prov = (c.proveedorNombre ?? '').toLowerCase();
        final nota = (c.nota ?? '').toLowerCase();
        return prod.contains(q) || prov.contains(q) || nota.contains(q);
      }).toList();
    }
    return lista;
  }

  List<Map<String, dynamic>> _agrupadoPorProducto(List<Compra> compras) {
    final grupos = <String, Map<String, dynamic>>{};
    for (final c in compras) {
      final key = c.productoId;
      grupos.putIfAbsent(
        key,
        () => {
          'productoId': c.productoId,
          'productoNombre': c.productoNombre,
          'totalCantidad': 0.0,
          'totalMonto': 0.0,
          'comprasCount': 0,
          'ultimaFecha': c.fecha,
          'compras': <Compra>[],
        },
      );
      final g = grupos[key]!;
      g['totalCantidad'] = (g['totalCantidad'] as double) + c.cantidad;
      g['totalMonto'] = (g['totalMonto'] as double) + c.total;
      g['comprasCount'] = (g['comprasCount'] as int) + 1;
      if (c.fecha.isAfter(g['ultimaFecha'] as DateTime)) {
        g['ultimaFecha'] = c.fecha;
      }
      (g['compras'] as List<Compra>).add(c);
    }
    final lista = grupos.values.toList();
    lista.sort(
        (a, b) => (b['totalMonto'] as double).compareTo(a['totalMonto'] as double));
    return lista;
  }

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return NumberFormat('#,###.##').format(n);
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  String _fmtCompact(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  // ============================================================
  //  EXPORTAR
  // ============================================================
  Future<void> _exportar(List<Compra> compras) async {
    if (compras.isEmpty) {
      mostrarSnackBar(
        mensaje: 'No hay compras para exportar',
        esExito: false,
      );
      return;
    }

    final b = StringBuffer();
    b.writeln('=== HISTORIAL DE COMPRAS · $APP_NAME ===');
    b.writeln('Período: $_periodoLabel');
    if (_productoFiltroId != null || _proveedorFiltroId != null) {
      b.writeln('(filtros aplicados)');
    }
    b.writeln('');

    final total = compras.fold<double>(0, (s, c) => s + c.total);
    final unidades = compras.fold<double>(0, (s, c) => s + c.cantidad);
    b.writeln('Total invertido: \$${_fmt(total)}');
    b.writeln('Unidades compradas: ${_fmt(unidades)}');
    b.writeln('N° compras: ${compras.length}');
    b.writeln('---');
    b.writeln('');

    for (final c in compras) {
      b.writeln(
          '${DateFormat('dd/MM/yyyy HH:mm').format(c.fecha)} · ${c.productoNombre}');
      b.writeln(
          '  ${_fmt(c.cantidad)} × \$${c.precioUnitario.toStringAsFixed(2)} = \$${_fmt(c.total)}');
      if (c.proveedorNombre != null && c.proveedorNombre!.isNotEmpty) {
        b.writeln('  Proveedor: ${c.proveedorNombre}');
      }
      if (c.nota != null && c.nota!.isNotEmpty) {
        b.writeln('  Nota: ${c.nota}');
      }
    }

    try {
      await Share.share(b.toString(), subject: 'Compras · $_periodoLabel');
    } catch (e) {
      mostrarSnackBar(
        mensaje: 'No se pudo compartir: ${mensajeAmigable(e)}',
        esExito: false,
      );
    }
  }

  // ============================================================
  //  ELIMINAR
  // ============================================================
  Future<void> _confirmarEliminar(
      BuildContext context, AppProvider provider, Compra compra, _P p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(p.dark ? .18 : .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _C.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar del historial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a eliminar esta compra del historial local:',
              style: TextStyle(fontSize: 13.5, color: p.textMid),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    compra.productoNombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: p.textHigh,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(compra.cantidad)} × \$${compra.precioUnitario.toStringAsFixed(2)} = \$${_fmt(compra.total)}',
                    style: TextStyle(fontSize: 11.5, color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(p.dark ? .14 : .08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.warning.withOpacity(.32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: _C.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El stock del producto NO se modifica. Solo se elimina del historial local.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: p.textMid,
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await provider.eliminarCompraDelHistorial(compra.id);
      if (mounted) {
        mostrarSnackBar(
          mensaje: 'Compra eliminada del historial',
          esExito: true,
        );
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
          mensaje: 'No se pudo eliminar: ${mensajeAmigable(e)}',
          esExito: false,
        );
      }
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.empresaActiva) {
          return ServicioCanceladoScreen(onLogout: () => provider.logout());
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final p = _P(isDark);

        final compras = _comprasFiltradas(provider);
        final totalInvertido =
            compras.fold<double>(0, (s, c) => s + c.total);
        final totalUnidades =
            compras.fold<double>(0, (s, c) => s + c.cantidad);
        final promedio = compras.isEmpty
            ? 0.0
            : totalInvertido / compras.length;

        return Scaffold(
          backgroundColor: p.bg,
          body: Stack(
            children: [
              // Fondo decorativo
              Positioned(
                top: -180,
                right: -140,
                child: IgnorePointer(
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _C.purple.withOpacity(isDark ? .12 : .06),
                          _C.purple.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context, provider, p, compras),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildKpis(p, totalInvertido, totalUnidades,
                                compras.length, promedio),
                            const SizedBox(height: 14),
                            _buildFilterBar(context, provider, p),
                            const SizedBox(height: 14),
                            if (compras.isEmpty)
                              _buildEmptyState(context, p)
                            else if (_agruparPorProducto)
                              _buildGroupedView(context, provider, p, compras)
                            else
                              _buildListView(context, provider, p, compras),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //  TOP BAR
  // ============================================================
  Widget _buildTopBar(
    BuildContext context,
    AppProvider provider,
    _P p,
    List<Compra> compras,
  ) {
    final isDesktop = ResponsiveHelper.isDesktop();

    return Container(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 12, 12, isDesktop ? 20 : 10, 8),
      child: Row(
        children: [
          if (!isDesktop)
            Material(
              color: p.surface,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: p.borderStrong),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 20, color: p.textHigh),
                ),
              ),
            ),
          if (isDesktop)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(Icons.arrow_back_rounded, color: p.textMid),
            ),
          SizedBox(width: isDesktop ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(colors: _C.gradCompras),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _C.purple.withOpacity(.32),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shopping_cart_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historial de compras',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4,
                              color: p.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _periodoLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Compartir',
            onPressed: () => _exportar(compras),
            icon: Icon(Icons.share_rounded, color: p.textMid),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  KPIs
  // ============================================================
  Widget _buildKpis(
    _P p,
    double totalInvertido,
    double totalUnidades,
    int cantidadCompras,
    double promedio,
  ) {
    final isDesktop = ResponsiveHelper.isDesktop();

    final items = <Map<String, dynamic>>[
      {
        'label': 'Total invertido',
        'value': '\$${_fmt(totalInvertido)}',
        'icon': Icons.account_balance_wallet_rounded,
        'color': _C.purple,
      },
      {
        'label': 'Unidades',
        'value': _fmt(totalUnidades),
        'icon': Icons.inventory_2_rounded,
        'color': _C.indigo,
      },
      {
        'label': 'Compras',
        'value': '$cantidadCompras',
        'icon': Icons.shopping_cart_rounded,
        'color': _C.cyan,
      },
      {
        'label': 'Promedio',
        'value': '\$${_fmt(promedio)}',
        'icon': Icons.trending_up_rounded,
        'color': _C.success,
      },
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _kpiCard(items[i], p)),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    // Móvil: grid 2x2
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _kpiCard(items[0], p)),
            const SizedBox(width: 10),
            Expanded(child: _kpiCard(items[1], p)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _kpiCard(items[2], p)),
            const SizedBox(width: 10),
            Expanded(child: _kpiCard(items[3], p)),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(Map<String, dynamic> item, _P p) {
    final color = item['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(.22), color.withOpacity(.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(item['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
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

  // ============================================================
  //  FILTROS
  // ============================================================
  Widget _buildFilterBar(
      BuildContext context, AppProvider provider, _P p) {
    final isDesktop = ResponsiveHelper.isDesktop();

    // Productos y proveedores que tienen compras (para los dropdowns)
    final productosConCompras = <String, String>{};
    final proveedoresConCompras = <String, String>{};
    for (final c in provider.compras) {
      productosConCompras[c.productoId] = c.productoNombre;
      if (c.proveedorId != null &&
          c.proveedorNombre != null &&
          c.proveedorNombre!.isNotEmpty) {
        proveedoresConCompras[c.proveedorId!] = c.proveedorNombre!;
      }
    }

    final periodChips = <Widget>[
      _periodChip(label: 'Hoy', selected: _periodoIdx == 0, p: p, onTap: () {
        setState(() => _periodoIdx = 0);
      }),
      _periodChip(label: 'Semana', selected: _periodoIdx == 1, p: p, onTap: () {
        setState(() => _periodoIdx = 1);
      }),
      _periodChip(label: 'Mes', selected: _periodoIdx == 2, p: p, onTap: () {
        setState(() => _periodoIdx = 2);
      }),
      _periodChip(label: 'Todo', selected: _periodoIdx == 3, p: p, onTap: () {
        setState(() => _periodoIdx = 3);
      }),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Búsqueda
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(fontSize: 13.5, color: p.textHigh),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: p.textMuted),
                hintText: 'Buscar por producto, proveedor o nota…',
                hintStyle:
                    TextStyle(fontSize: 13, color: p.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                        icon: Icon(Icons.close_rounded,
                            size: 16, color: p.textMuted),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Períodos + toggle agrupar
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: periodChips),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle agrupar
              Material(
                color: _agruparPorProducto
                    ? _C.purple.withOpacity(p.dark ? .20 : .12)
                    : p.surface2,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(
                      () => _agruparPorProducto = !_agruparPorProducto),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _agruparPorProducto
                            ? _C.purple.withOpacity(.45)
                            : p.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _agruparPorProducto
                              ? Icons.view_agenda_rounded
                              : Icons.view_list_rounded,
                          size: 14,
                          color: _agruparPorProducto
                              ? _C.purple
                              : p.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _agruparPorProducto ? 'Agrupado' : 'Lista',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _agruparPorProducto
                                ? _C.purple
                                : p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Filtros avanzados
          if (productosConCompras.isNotEmpty ||
              proveedoresConCompras.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (isDesktop)
              Row(
                children: [
                  if (productosConCompras.isNotEmpty)
                    Expanded(
                      child: _productoDropdown(p, productosConCompras),
                    ),
                  if (productosConCompras.isNotEmpty &&
                      proveedoresConCompras.isNotEmpty)
                    const SizedBox(width: 10),
                  if (proveedoresConCompras.isNotEmpty)
                    Expanded(
                      child: _proveedorDropdown(p, proveedoresConCompras),
                    ),
                ],
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (productosConCompras.isNotEmpty)
                      SizedBox(
                        width: 200,
                        child: _productoDropdown(p, productosConCompras),
                      ),
                    if (productosConCompras.isNotEmpty &&
                        proveedoresConCompras.isNotEmpty)
                      const SizedBox(width: 8),
                    if (proveedoresConCompras.isNotEmpty)
                      SizedBox(
                        width: 200,
                        child: _proveedorDropdown(p, proveedoresConCompras),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _periodChip({
    required String label,
    required bool selected,
    required _P p,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.transparent : p.surface2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: _C.gradCompras)
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.transparent : p.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _C.purple.withOpacity(.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? Colors.white : p.textMid,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productoDropdown(_P p, Map<String, String> productos) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _productoFiltroId,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: p.textMuted),
          dropdownColor: p.surface,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.textHigh,
          ),
          hint: Text(
            'Todos los productos',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
          onChanged: (v) => setState(() => _productoFiltroId = v),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos los productos'),
            ),
            ...productos.entries.map(
              (e) => DropdownMenuItem<String?>(
                value: e.key,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proveedorDropdown(_P p, Map<String, String> proveedores) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _proveedorFiltroId,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: p.textMuted),
          dropdownColor: p.surface,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.textHigh,
          ),
          hint: Text(
            'Todos los proveedores',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
          onChanged: (v) => setState(() => _proveedorFiltroId = v),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos los proveedores'),
            ),
            ...proveedores.entries.map(
              (e) => DropdownMenuItem<String?>(
                value: e.key,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  LISTA PLANA
  // ============================================================
  Widget _buildListView(
    BuildContext context,
    AppProvider provider,
    _P p,
    List<Compra> compras,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seccionHeader('Registros', compras.length, p),
        const SizedBox(height: 10),
        for (final c in compras) ...[
          _compraTile(context, provider, p, c),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _compraTile(
    BuildContext context,
    AppProvider provider,
    _P p,
    Compra compra,
  ) {
    final prod = provider.getProductoById(compra.productoId);
    final imageUrl = prod?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetailSheet(context, provider, p, compra),
          onLongPress: () => _confirmarEliminar(context, provider, compra, p),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen o icono
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _initialBox(compra.productoNombre),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _initialBox(compra.productoNombre);
                          },
                        )
                      : _initialBox(compra.productoNombre),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compra.productoNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 10, color: p.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              DateFormat('dd/MM/yyyy · HH:mm')
                                  .format(compra.fecha),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (compra.proveedorNombre != null &&
                          compra.proveedorNombre!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.business_rounded,
                                size: 10, color: p.textMuted),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                compra.proveedorNombre!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (compra.nota != null &&
                          compra.nota!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.notes_rounded,
                                size: 10, color: p.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                compra.nota!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: p.textMuted,
                                ),
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
                      '\$${_fmt(compra.total)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                        color: _C.purple,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmt(compra.cantidad)} × \$${compra.precioUnitario.toStringAsFixed(2)}',
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
          ),
        ),
      ),
    );
  }

  Widget _initialBox(String nombre) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _C.gradCompras,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  //  VISTA AGRUPADA POR PRODUCTO
  // ============================================================
  Widget _buildGroupedView(
    BuildContext context,
    AppProvider provider,
    _P p,
    List<Compra> compras,
  ) {
    final grupos = _agrupadoPorProducto(compras);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seccionHeader('${grupos.length} productos', compras.length, p),
        const SizedBox(height: 10),
        for (final g in grupos) ...[
          _grupoTile(context, provider, p, g),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _grupoTile(
    BuildContext context,
    AppProvider provider,
    _P p,
    Map<String, dynamic> grupo,
  ) {
    final prod = provider.getProductoById(grupo['productoId'] as String);
    final imageUrl = prod?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Filtrar lista plana por este producto y volver a lista
            setState(() {
              _productoFiltroId = grupo['productoId'] as String;
              _agruparPorProducto = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _initialBox(grupo['productoNombre'] as String),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _initialBox(
                                grupo['productoNombre'] as String);
                          },
                        )
                      : _initialBox(grupo['productoNombre'] as String),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo['productoNombre'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _C.purple.withOpacity(
                                  p.dark ? .16 : .10),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${grupo['comprasCount']} compra${(grupo['comprasCount'] as int) == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _C.purple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_fmt(grupo['totalCantidad'] as double)} uds',
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Últ. ${DateFormat('dd/MM/yyyy').format(grupo['ultimaFecha'] as DateTime)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_fmt(grupo['totalMonto'] as double)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.3,
                        color: _C.purple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'total',
                      style: TextStyle(
                        fontSize: 10,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  HEADER DE SECCIÓN
  // ============================================================
  Widget _seccionHeader(String titulo, int count, _P p) {
    return Row(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
            color: p.textHigh,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _C.purple.withOpacity(p.dark ? .16 : .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: _C.purple,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(BuildContext context, _P p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.purple.withOpacity(.16),
                    _C.indigo.withOpacity(.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 42,
                color: _C.purple,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _search.isNotEmpty ||
                      _productoFiltroId != null ||
                      _proveedorFiltroId != null
                  ? 'Sin resultados'
                  : 'Aún no hay compras',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _search.isNotEmpty ||
                        _productoFiltroId != null ||
                        _proveedorFiltroId != null
                    ? 'Prueba con otro filtro o cambia el período.'
                    : 'Cuando reabastezcas productos, aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DETALLE
  // ============================================================
  void _showDetailSheet(
    BuildContext context,
    AppProvider provider,
    _P p,
    Compra compra,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(colors: _C.gradCompras),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalle de compra',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: p.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            compra.productoNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _detailRow(Icons.shopping_bag_rounded,
                        'Producto', compra.productoNombre, p),
                    _detailRow(Icons.calendar_today_rounded, 'Fecha',
                        DateFormat('dd/MM/yyyy · HH:mm').format(compra.fecha), p),
                    _detailRow(Icons.numbers_rounded, 'Cantidad',
                        '${_fmt(compra.cantidad)} unidades', p),
                    _detailRow(Icons.attach_money_rounded,
                        'Precio unitario',
                        '\$${compra.precioUnitario.toStringAsFixed(2)}', p),
                    _detailRow(
                        Icons.payments_rounded,
                        'Total',
                        '\$${_fmt(compra.total)}',
                        p,
                        valueColor: _C.purple,
                        bold: true),
                    if (compra.proveedorNombre != null &&
                        compra.proveedorNombre!.isNotEmpty)
                      _detailRow(Icons.business_rounded, 'Proveedor',
                          compra.proveedorNombre!, p),
                    if (compra.nota != null && compra.nota!.isNotEmpty)
                      _detailRow(
                          Icons.notes_rounded, 'Nota', compra.nota!, p),
                    _detailRow(
                        Icons.person_outline_rounded,
                        'Registrado por',
                        provider.getUsuarioEmail(compra.usuarioId),
                        p),
                    if (compra.sucursalId != null)
                      _detailRow(
                          Icons.storefront_rounded,
                          'Sucursal',
                          provider.getSucursalNombre(compra.sucursalId!),
                          p),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmarEliminar(context, provider, compra, p);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18),
                      label: const Text('Eliminar del historial'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.danger,
                        side: BorderSide(
                            color: _C.danger.withOpacity(.40)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    _P p, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.purple.withOpacity(p.dark ? .14 : .08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.purple.withOpacity(.16)),
            ),
            child: Icon(icon, size: 15, color: _C.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: bold ? 15 : 13.5,
                    fontWeight:
                        bold ? FontWeight.w900 : FontWeight.w700,
                    color: valueColor ?? p.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}