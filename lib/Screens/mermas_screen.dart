// ============================================================
//  mermas_screen.dart · NEXORA BUSINESS
//  Historial y registro de mermas con stats y agrupado por fecha
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../main.dart';
import '../responsive_helper.dart';
import 'servicio_cancelado_screen.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF97316);
  static const gold = Color(0xFFCA8A04);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradWarn = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const gradDanger = [Color(0xFFEF4444), Color(0xFFEC4899)];
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
  Color get textHigh =>
      dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid =>
      dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted =>
      dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border =>
      dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
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

class MermasScreen extends StatefulWidget {
  const MermasScreen({Key? key}) : super(key: key);

  @override
  State<MermasScreen> createState() => _MermasScreenState();
}

class _MermasScreenState extends State<MermasScreen> {
  String _filtroMotivo = 'Todos';
  String _filtroBusqueda = '';
  String? _sucursalSeleccionada;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    // ✅ Fix roles: son 'dueno' y 'gerente' (no 'admin' ni 'gestor')
    final esAdmin = provider.rol == 'dueno';
    final esGerente = provider.rol == 'gerente';

    if (!esAdmin && !esGerente) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          title: const Text('Mermas y Pérdidas'),
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
        ),
        body: const Center(
            child: Text('No tienes permisos para ver esta sección.')),
      );
    }

    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    var mermas = provider.mermas.where((m) => !m.cancelado).toList();

    if (esAdmin && _sucursalSeleccionada != null) {
      mermas = mermas
          .where((m) => m.sucursalId == _sucursalSeleccionada)
          .toList();
    }

    if (_filtroBusqueda.isNotEmpty) {
      mermas = mermas.where((m) {
        final producto = provider.getProductoById(m.productoId);
        final nombre = producto?.nombre.toLowerCase() ?? '';
        final motivo = m.motivo.toLowerCase();
        final q = _filtroBusqueda.toLowerCase();
        return nombre.contains(q) || motivo.contains(q);
      }).toList();
    }

    if (_filtroMotivo != 'Todos') {
      mermas = mermas.where((m) => m.motivo == _filtroMotivo).toList();
    }

    mermas.sort((a, b) => b.fecha.compareTo(a.fecha));

    final totalCosto =
        mermas.fold<double>(0.0, (s, m) => s + m.costoTotal);

    final agrupadas = _agruparPorFecha(mermas);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistrarMerma(context, provider, p),
        backgroundColor: _C.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          _statsRow(mermas, totalCosto, p),
          _filtrosBar(provider, p, esAdmin),
          Expanded(
            child: mermas.isEmpty
                ? _emptyState(p)
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      children: agrupadas.entries
                          .map((e) => _grupoFecha(e.key, e.value,
                              provider, p, esAdmin, esGerente, isDesktop))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  GRUPO POR FECHA
  // ============================================================
  Map<String, List<Merma>> _agruparPorFecha(List<Merma> mermas) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));

    final grupos = <String, List<Merma>>{};
    for (final m in mermas) {
      final f = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      String key;
      if (f == hoy) {
        key = 'Hoy';
      } else if (f == ayer) {
        key = 'Ayer';
      } else if (f.isAfter(inicioSemana) || f == inicioSemana) {
        key = 'Esta semana';
      } else if (f.month == hoy.month && f.year == hoy.year) {
        key = 'Este mes';
      } else {
        key = 'Anteriores';
      }
      grupos.putIfAbsent(key, () => []).add(m);
    }
    return grupos;
  }

  Widget _grupoFecha(
    String label,
    List<Merma> mermas,
    AppProvider provider,
    _P p,
    bool esAdmin,
    bool esGerente,
    bool isDesktop,
  ) {
    final total = mermas.fold<double>(0.0, (s, m) => s + m.costoTotal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${mermas.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _C.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '-\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _C.danger,
                ),
              ),
            ],
          ),
        ),
        ...mermas.map((m) => _mermaCard(
            m, provider, p, esAdmin, esGerente, isDesktop)),
        const SizedBox(height: 6),
      ],
    );
  }

  // ============================================================
  //  CARD INDIVIDUAL
  // ============================================================
  Widget _mermaCard(
    Merma m,
    AppProvider provider,
    _P p,
    bool esAdmin,
    bool esGerente,
    bool isDesktop,
  ) {
    final producto = provider.getProductoById(m.productoId);
    final color = _colorMotivo(m.motivo);
    final icon = _iconMotivo(m.motivo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(m.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _cancelarMerma(m.id, provider),
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              icon: Icons.undo_rounded,
              label: 'Cancelar',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ]),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withOpacity(.32)),
                  ),
                  child: Icon(icon, color: color, size: 20),
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
                              color: color.withOpacity(.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _traducirMotivo(m.motivo),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${m.cantidad} ${producto?.unidadMedida ?? 'u'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.textMuted,
                            ),
                          ),
                          if (esAdmin && m.sucursalId != null) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.store_rounded,
                                size: 11, color: p.textMuted),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                provider.getSucursalNombre(m.sucursalId!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(m.fecha),
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
                      '-\$${m.costoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _C.danger,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'costo',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                        letterSpacing: 0.5,
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
  //  STATS
  // ============================================================
  Widget _statsRow(List<Merma> mermas, double totalCosto, _P p) {
    // Contar por motivo
    final Map<String, int> porMotivo = {};
    for (final m in mermas) {
      porMotivo[m.motivo] = (porMotivo[m.motivo] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  label: 'Registros',
                  value: '${mermas.length}',
                  icon: Icons.warning_amber_rounded,
                  color: _C.warning,
                  p: p,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  label: 'Costo total',
                  value: '-\$${totalCosto.toStringAsFixed(2)}',
                  icon: Icons.trending_down_rounded,
                  color: _C.danger,
                  p: p,
                ),
              ),
            ],
          ),
          if (porMotivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
                boxShadow: p.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desglose por motivo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: p.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: porMotivo.entries.map((e) {
                      final color = _colorMotivo(e.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withOpacity(.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_iconMotivo(e.key),
                                size: 12, color: color),
                            const SizedBox(width: 5),
                            Text(
                              _traducirMotivo(e.key),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${e.value}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required _P p,
  }) {
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.20),
                color.withOpacity(.05),
              ]),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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
  Widget _filtrosBar(AppProvider provider, _P p, bool esAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                    boxShadow: p.shadowSm,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _filtroBusqueda = v),
                    style: TextStyle(
                      fontSize: 13,
                      color: p.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por producto o motivo…',
                      hintStyle: TextStyle(
                        color: p.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: p.textMuted),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                  boxShadow: p.shadowSm,
                ),
                child: DropdownButton<String>(
                  value: _filtroMotivo,
                  underline: const SizedBox(),
                  isDense: true,
                  dropdownColor: p.surface,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: p.textHigh,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(
                        value: 'estropeado', child: Text('Estropeado')),
                    DropdownMenuItem(
                        value: 'autoconsumo', child: Text('Autoconsumo')),
                    DropdownMenuItem(
                        value: 'perdida', child: Text('Pérdida')),
                    DropdownMenuItem(value: 'merma', child: Text('Merma')),
                  ],
                  onChanged: (v) =>
                      setState(() => _filtroMotivo = v ?? 'Todos'),
                ),
              ),
            ],
          ),
          if (esAdmin && provider.sucursales.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
                boxShadow: p.shadowSm,
              ),
              child: DropdownButton<String?>(
                value: _sucursalSeleccionada,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: p.surface,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
                hint: Text('Todas las sucursales',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5)),
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
                onChanged: (v) =>
                    setState(() => _sucursalSeleccionada = v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  //  APP BAR / EMPTY
  // ============================================================
  PreferredSizeWidget _appBar(_P p) {
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
              gradient: const LinearGradient(colors: _C.gradWarn),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.warning.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mermas y Pérdidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Historial de productos perdidos',
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

  Widget _emptyState(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.warning.withOpacity(.16),
                  _C.orange.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  size: 40, color: _C.success.withOpacity(.85)),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin mermas registradas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No se han registrado pérdidas ni mermas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: p.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  REGISTRAR MERMA (FAB)
  // ============================================================
  void _mostrarRegistrarMerma(
      BuildContext context, AppProvider provider, _P p) {
    String? productoId;
    String motivo = 'estropeado';
    final cantidadCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setSt) {
          final prodsDisponibles = provider.productos
              .where((p) => p.stock > 0)
              .toList();
          return AlertDialog(
            backgroundColor: p.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradWarn),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Registrar merma',
                  style: TextStyle(
                    color: p.textHigh,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: productoId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: p.surface2,
                      hintText: 'Selecciona…',
                    ),
                    items: prodsDisponibles
                        .map((prod) => DropdownMenuItem(
                              value: prod.id,
                              child: Text(
                                '${prod.nombre} (stock: ${prod.stock})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: p.textHigh),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setSt(() => productoId = v),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cantidad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: p.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: p.surface2,
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Motivo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'estropeado',
                      'autoconsumo',
                      'perdida',
                      'merma',
                    ].map((m) {
                      final selected = motivo == m;
                      final color = _colorMotivo(m);
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setSt(() => motivo = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(.15)
                                : p.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : p.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_iconMotivo(m),
                                  size: 13,
                                  color: selected
                                      ? color
                                      : p.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                _traducirMotivo(m),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? color
                                      : p.textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final cant = double.tryParse(cantidadCtrl.text.trim()) ?? 0;
                  if (productoId == null || cant <= 0) {
                    mostrarSnackBar(
                        mensaje: 'Completa producto y cantidad',
                        esExito: false);
                    return;
                  }
                  Navigator.pop(dctx);
                  await provider.registrarMerma(
                      productoId!, cant, motivo);
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Registrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.warning,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  //  ACCIONES
  // ============================================================
  Future<void> _cancelarMerma(String id, AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('¿Cancelar merma?',
            style: TextStyle(
                color: p.textHigh, fontWeight: FontWeight.w900)),
        content: Text(
          'El registro quedará marcado como cancelado. El stock no se restaura automáticamente.',
          style: TextStyle(color: p.textMid, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await provider.cancelarMerma(id);
      } catch (e) {
        mostrarSnackBar(
            mensaje: 'Error: ${e.toString()}', esExito: false);
      }
    }
  }

  // ============================================================
  //  HELPERS DE MOTIVO
  // ============================================================
  Color _colorMotivo(String motivo) {
    switch (motivo) {
      case 'estropeado':
        return _C.orange;
      case 'autoconsumo':
        return _C.info;
      case 'perdida':
        return _C.danger;
      case 'merma':
        return _C.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _iconMotivo(String motivo) {
    switch (motivo) {
      case 'estropeado':
        return Icons.warning_amber_rounded;
      case 'autoconsumo':
        return Icons.person_rounded;
      case 'perdida':
        return Icons.remove_shopping_cart_rounded;
      case 'merma':
        return Icons.scale_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _traducirMotivo(String motivo) {
    switch (motivo) {
      case 'estropeado':
        return 'Estropeado';
      case 'autoconsumo':
        return 'Autoconsumo';
      case 'perdida':
        return 'Pérdida';
      case 'merma':
        return 'Merma';
      default:
        return motivo;
    }
  }
}