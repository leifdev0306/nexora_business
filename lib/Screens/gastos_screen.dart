// ============================================================
//  gastos_screen.dart  ·  NEXORA BUSINESS
//  Lista de gastos con KPIs, filtros y detalle premium
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

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
  static const orange    = Color(0xFFF97316);
  static const textMuted = Color(0xFF607B9E);   // ← AGREGAR
  static const textMid   = Color(0xFF1C3352);   // ← AGREGAR

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradDanger  = [Color(0xFFEF4444), Color(0xFFEC4899)];
  static const gradWarm    = [Color(0xFFF59E0B), Color(0xFFF97316)];
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

// ============================================================
//  SCREEN
// ============================================================
class GastosScreen extends StatefulWidget {
  const GastosScreen({Key? key}) : super(key: key);

  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  String _filtroCategoria = 'Todas';
  String _busqueda = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    final gastosPeriodo = provider.gastos
        .where((g) =>
            g.fecha.isAfter(provider.inicioPeriodo) &&
            g.fecha.isBefore(provider.finPeriodo))
        .toList();

    var gastosFiltrados = gastosPeriodo;
    if (_filtroCategoria != 'Todas') {
      gastosFiltrados = gastosFiltrados
          .where((g) => g.categoria == _filtroCategoria)
          .toList();
    }
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      gastosFiltrados = gastosFiltrados
          .where((g) => g.concepto.toLowerCase().contains(q))
          .toList();
    }
    gastosFiltrados.sort((a, b) => b.fecha.compareTo(a.fecha));

    final categoriasUnicas = [
      'Todas',
      ...provider.gastos.map((g) => g.categoria).toSet()
    ];

    final double totalGastos =
        gastosFiltrados.fold(0.0, (s, g) => s + g.monto);

    // Conteo por categoría para chips
    final Map<String, int> countsPorCat = {};
    for (final g in gastosPeriodo) {
      countsPorCat[g.categoria] = (countsPorCat[g.categoria] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, provider, p),
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
                        _buscarBar(p),
                        const SizedBox(height: 12),
                        _periodoChips(p, provider),
                        const SizedBox(height: 10),
                        _categoriasChips(
                            p, categoriasUnicas, countsPorCat, gastosPeriodo.length),
                        const SizedBox(height: 14),
                        _kpiCard(p, totalGastos, gastosFiltrados.length,
                            provider.getPeriodoLabel()),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (gastosFiltrados.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(p),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 12, 4, isDesktop ? 24 : 12, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _gastoCard(context, gastosFiltrados[i], provider, p),
                        childCount: gastosFiltrados.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _fab(context, p),
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
              child: _orb(420, _C.danger.withOpacity(p.dark ? .10 : .06)),
            ),
            Positioned(
              bottom: -220,
              left: -140,
              child: _orb(440, _C.warning.withOpacity(p.dark ? .08 : .05)),
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
      BuildContext context, AppProvider provider, _P p) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.warning.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Gastos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Control de egresos',
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
        IconButton(
          tooltip: 'Nuevo gasto',
          onPressed: () => Navigator.pushNamed(context, '/nuevo-gasto'),
          icon: Icon(Icons.add_rounded, color: p.textHigh),
        ),
      ],
    );
  }

  // ============================================================
  //  BUSCAR
  // ============================================================
  Widget _buscarBar(_P p) {
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
        onChanged: (v) => setState(() => _busqueda = v),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textHigh,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por concepto…',
          hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.textMuted),
          suffixIcon: _busqueda.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: p.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _busqueda = '');
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
  Widget _periodoChips(_P p, AppProvider provider) {
    final opciones = ['Hoy', 'Semana', 'Mes'];
    return Row(
      children: List.generate(opciones.length, (i) {
        final selected = provider.periodoSeleccionado == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == opciones.length - 1 ? 0 : 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => provider.setPeriodo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: _C.gradBrand)
                        : null,
                    color: selected ? null : p.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected ? Colors.transparent : p.borderStrong,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _C.primary.withOpacity(.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    opciones[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                      color: selected ? Colors.white : p.textMid,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  //  CATEGORÍA CHIPS
  // ============================================================
  Widget _categoriasChips(_P p, List<String> categorias,
      Map<String, int> counts, int totalPeriodo) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categorias[i];
          final selected = _filtroCategoria == cat;
          final count =
              cat == 'Todas' ? totalPeriodo : (counts[cat] ?? 0);
          final color = cat == 'Todas'
              ? _C.primary
              : _colorFor(cat, p.dark);

          return Material(
            color: selected ? Colors.transparent : p.surface,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => setState(() => _filtroCategoria = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [
                          color,
                          color.withOpacity(.78),
                        ])
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (cat == 'Todas'
                            ? p.borderStrong
                            : color.withOpacity(.32)),
                  ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cat != 'Todas')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(_iconFor(cat),
                            size: 13,
                            color: selected ? Colors.white : color),
                      ),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                        color: selected ? Colors.white : p.textMid,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(.25)
                            : color.withOpacity(p.dark ? .18 : .10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  //  KPI TOTAL
  // ============================================================
  Widget _kpiCard(
      _P p, double total, int count, String periodoLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _C.gradDanger,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.danger.withOpacity(.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
            child: const Icon(Icons.money_off_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TOTAL $periodoLabel'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\$${_fmt(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
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
  //  CARD DE GASTO
  // ============================================================
  Widget _gastoCard(BuildContext context, Gasto g, AppProvider provider, _P p) {
    final color = _colorFor(g.categoria, p.dark);
    final icon = _iconFor(g.categoria);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(g.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => _eliminarGasto(context, g.id),
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Eliminar',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _mostrarDetalle(context, g, provider, p),
            child: Container(
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
                    width: 46,
                    height: 46,
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
                      border: Border.all(color: color.withOpacity(.24)),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.concepto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: p.textHigh,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _miniTag(p, icon, g.categoria),
                            _miniTag(p, Icons.access_time_rounded,
                                DateFormat('dd/MM · HH:mm').format(g.fecha)),
                            if (g.nota != null && g.nota!.isNotEmpty)
                              _miniTag(p, Icons.notes_rounded, 'Nota'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-\$${_fmt(g.monto)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: _C.danger,
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
      ),
    );
  }

  Widget _miniTag(_P p, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: p.textMuted),
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
  //  DETALLE
  // ============================================================
  void _mostrarDetalle(
      BuildContext context, Gasto g, AppProvider provider, _P p) {
    final color = _colorFor(g.categoria, p.dark);
    final icon = _iconFor(g.categoria);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(.22),
                          color.withOpacity(.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(.28)),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.categoria.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          g.concepto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: p.textHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(.14), color.withOpacity(.04)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Row(
                  children: [
                    Text(
                      'MONTO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: p.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '-\$${_fmt(g.monto)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _seccionTitulo('DETALLE', p),
              const SizedBox(height: 10),
              _detalleRow(Icons.category_rounded, 'Categoría', g.categoria, p),
              _detalleRow(Icons.event_rounded, 'Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(g.fecha), p),
              if (g.nota != null && g.nota!.isNotEmpty)
                _detalleRow(Icons.notes_rounded, 'Nota', g.nota!, p),
              const SizedBox(height: 20),
              _actionButton(
                icon: Icons.delete_rounded,
                label: 'Eliminar gasto',
                color: _C.danger,
                p: p,
                onTap: () {
                  Navigator.pop(ctx);
                  _eliminarGasto(context, g.id);
                },
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
      ),
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
          text,
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
              border: Border.all(color: _C.primary.withOpacity(.16)),
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
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  VACÍO
  // ============================================================
  Widget _emptyState(_P p) {
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
                    _C.danger.withOpacity(.16),
                    _C.warning.withOpacity(.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.money_off_rounded,
                  size: 42, color: _C.danger),
            ),
            const SizedBox(height: 18),
            Text(
              _filtroCategoria != 'Todas'
                  ? 'Sin gastos en esta categoría'
                  : 'Sin gastos registrados',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filtroCategoria != 'Todas'
                  ? 'Prueba con otra categoría o período.'
                  : 'Toca el botón + para agregar tu primer gasto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
            if (_filtroCategoria != 'Todas') ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _filtroCategoria = 'Todas'),
                child: const Text('Mostrar todas'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  FAB
  // ============================================================
  Widget _fab(BuildContext context, _P p) {
    return FloatingActionButton.extended(
      heroTag: 'gastos_fab',
      onPressed: () => Navigator.pushNamed(context, '/nuevo-gasto'),
      backgroundColor: _C.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text(
        'Nuevo gasto',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.1,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ============================================================
  //  ELIMINAR
  // ============================================================
  Future<void> _eliminarGasto(BuildContext context, String id) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.delete_rounded,
                  color: _C.danger, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Eliminar gasto',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(color: p.textMid, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: p.textMid)),
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
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.eliminarGasto(id);
        mostrarSnackBar(mensaje: 'Gasto eliminado', esExito: true);
      } catch (e) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  String _fmt(double n) => NumberFormat('#,##0.00').format(n);

  Color _colorFor(String cat, bool dark) {
    final base = {
          'Alquiler': _C.purple,
          'Luz': const Color(0xFFFBBF24),
          'Agua': _C.cyan,
          'Insumos': _C.success,
          'Transporte': _C.info,
          'Compras': _C.pink,
          'Servicios': _C.indigo,
          'Publicidad': _C.pink,
          'Impuestos': _C.danger,
          'Salarios': _C.success,
          'Nómina': _C.success,
          'Oficina': _C.cyan,
          'Mantenimiento': _C.orange,
          'Otros': _C.textMuted,
        }[cat] ??
        _C.textMuted;
    return dark ? base.withOpacity(.9) : base;
  }

  IconData _iconFor(String cat) {
    return {
          'Alquiler': Icons.home_rounded,
          'Luz': Icons.lightbulb_rounded,
          'Agua': Icons.water_drop_rounded,
          'Insumos': Icons.inventory_2_rounded,
          'Transporte': Icons.local_shipping_rounded,
          'Compras': Icons.shopping_bag_rounded,
          'Servicios': Icons.build_rounded,
          'Publicidad': Icons.campaign_rounded,
          'Impuestos': Icons.receipt_rounded,
          'Salarios': Icons.payments_rounded,
          'Nómina': Icons.payments_rounded,
          'Oficina': Icons.business_center_rounded,
          'Mantenimiento': Icons.construction_rounded,
          'Otros': Icons.more_horiz_rounded,
        }[cat] ??
        Icons.money_off_rounded;
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