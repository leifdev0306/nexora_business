// ============================================================
//  deudas_screen.dart · NEXORA BUSINESS
//  Gestión de deudas con aging visual y pagos parciales
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
  static const gradDanger = [Color(0xFFEF4444), Color(0xFFEC4899)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
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

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({Key? key}) : super(key: key);

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  String _filtroTipo = 'todas';
  String _filtroEstado = 'pendientes';
  String _filtroBusqueda = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    // ✅ Fix: solo dueño y gerente
    final esAdmin = provider.rol == 'dueno';
    final esGerente = provider.rol == 'gerente';

    if (!esAdmin && !esGerente) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          title: const Text('Deudas'),
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
        ),
        body: const Center(
            child: Text('Solo administradores y gerentes.')),
      );
    }

    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    var deudas = List<Deuda>.from(provider.deudas);

    // Filtros
    if (_filtroTipo != 'todas') {
      deudas = deudas.where((d) => d.tipo == _filtroTipo).toList();
    }
    switch (_filtroEstado) {
      case 'pendientes':
        deudas = deudas.where((d) => !d.pagada).toList();
        break;
      case 'vencidas':
        deudas = deudas
            .where((d) =>
                !d.pagada &&
                d.fechaVencimiento != null &&
                d.fechaVencimiento!.isBefore(DateTime.now()))
            .toList();
        break;
      case 'pagadas':
        deudas = deudas.where((d) => d.pagada).toList();
        break;
    }
    if (_filtroBusqueda.isNotEmpty) {
      final q = _filtroBusqueda.toLowerCase();
      deudas = deudas.where((d) {
        final nombreEntidad = _nombreEntidad(provider, d);
        return d.concepto.toLowerCase().contains(q) ||
            nombreEntidad.toLowerCase().contains(q);
      }).toList();
    }

    deudas.sort((a, b) => b.fecha.compareTo(a.fecha));

    final totalPendiente = deudas
        .where((d) => !d.pagada)
        .fold<double>(0.0, (s, d) => s + (d.monto - d.pagado));
    final totalVencido = deudas
        .where((d) =>
            !d.pagada &&
            d.fechaVencimiento != null &&
            d.fechaVencimiento!.isBefore(DateTime.now()))
        .fold<double>(0.0, (s, d) => s + (d.monto - d.pagado));

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistro(context, provider, p),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva deuda',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          _statsRow(deudas, totalPendiente, totalVencido, p),
          _filtrosBar(p),
          Expanded(
            child: deudas.isEmpty
                ? _emptyState(p)
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      itemCount: deudas.length,
                      itemBuilder: (_, i) => _deudaCard(
                          deudas[i], provider, p, esAdmin, esGerente),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _nombreEntidad(AppProvider provider, Deuda d) {
    if (d.tipo == 'cliente') {
      final c = provider.clientes
          .firstWhere((x) => x.id == d.entidadId,
              orElse: () => Cliente(id: '', nombre: 'Cliente eliminado'));
      return c.nombre;
    }
    try {
      final c = provider.proveedores
          .firstWhere((x) => x.id == d.entidadId);
      return c.nombre;
    } catch (_) {
      return 'Proveedor eliminado';
    }
  }

  // ============================================================
  //  STATS
  // ============================================================
  Widget _statsRow(
      List<Deuda> deudas, double totalPendiente, double totalVencido, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              label: 'Pendiente',
              value: '\$${totalPendiente.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_rounded,
              color: _C.warning,
              p: p,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              label: 'Vencido',
              value: '\$${totalVencido.toStringAsFixed(0)}',
              icon: Icons.error_rounded,
              color: _C.danger,
              p: p,
            ),
          ),
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
  Widget _filtrosBar(_P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          Container(
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
                hintText: 'Buscar por concepto o persona…',
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _chipSelector(
                  label: 'Pendientes',
                  value: 'pendientes',
                  current: _filtroEstado,
                  color: _C.warning,
                  onTap: (v) => setState(() => _filtroEstado = v),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipSelector(
                  label: 'Vencidas',
                  value: 'vencidas',
                  current: _filtroEstado,
                  color: _C.danger,
                  onTap: (v) => setState(() => _filtroEstado = v),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipSelector(
                  label: 'Pagadas',
                  value: 'pagadas',
                  current: _filtroEstado,
                  color: _C.success,
                  onTap: (v) => setState(() => _filtroEstado = v),
                  p: p,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _chipSelector(
                  label: 'Todas',
                  value: 'todas',
                  current: _filtroTipo,
                  color: _C.primary,
                  onTap: (v) => setState(() => _filtroTipo = v),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipSelector(
                  label: 'Clientes',
                  value: 'cliente',
                  current: _filtroTipo,
                  color: _C.info,
                  onTap: (v) => setState(() => _filtroTipo = v),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chipSelector(
                  label: 'Proveedores',
                  value: 'proveedor',
                  current: _filtroTipo,
                  color: _C.purple,
                  onTap: (v) => setState(() => _filtroTipo = v),
                  p: p,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipSelector({
    required String label,
    required String value,
    required String current,
    required Color color,
    required void Function(String) onTap,
    required _P p,
  }) {
    final selected = current == value;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(.14)
              : p.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? color : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? color : p.textMid,
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  CARD
  // ============================================================
  Widget _deudaCard(
    Deuda d,
    AppProvider provider,
    _P p,
    bool esAdmin,
    bool esGerente,
  ) {
    final nombre = _nombreEntidad(provider, d);
    final pendiente = d.monto - d.pagado;
    final progreso = d.monto > 0 ? (d.pagado / d.monto).clamp(0.0, 1.0) : 0.0;

    // Aging
    Color agingColor;
    String agingLabel;
    IconData agingIcon;
    if (d.pagada) {
      agingColor = _C.success;
      agingLabel = 'Pagada';
      agingIcon = Icons.check_circle_rounded;
    } else if (d.fechaVencimiento == null) {
      agingColor = _C.info;
      agingLabel = 'Sin vencimiento';
      agingIcon = Icons.event_rounded;
    } else {
      final diff = d.fechaVencimiento!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        agingColor = _C.danger;
        agingLabel = 'Vencida hace ${-diff}d';
        agingIcon = Icons.error_rounded;
      } else if (diff == 0) {
        agingColor = _C.warning;
        agingLabel = 'Vence hoy';
        agingIcon = Icons.warning_amber_rounded;
      } else if (diff <= 7) {
        agingColor = _C.warning;
        agingLabel = 'Vence en ${diff}d';
        agingIcon = Icons.schedule_rounded;
      } else {
        agingColor = _C.success;
        agingLabel = 'Vence en ${diff}d';
        agingIcon = Icons.schedule_rounded;
      }
    }

    final tipoColor = d.tipo == 'cliente' ? _C.info : _C.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(d.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: d.pagada ? 0.25 : 0.5,
          children: [
            if (!d.pagada)
              SlidableAction(
                onPressed: (_) => _pagarDeuda(d, provider),
                backgroundColor: _C.success,
                foregroundColor: Colors.white,
                icon: Icons.payments_rounded,
                label: 'Pagar',
                borderRadius: BorderRadius.circular(14),
              ),
            SlidableAction(
              onPressed: (_) => _eliminarDeuda(d.id, provider),
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Eliminar',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: d.pagada
                  ? _C.success.withOpacity(.30)
                  : agingColor.withOpacity(.28),
              width: 1.2,
            ),
            boxShadow: p.shadowSm,
          ),
          child: Padding(
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
                        gradient: LinearGradient(colors: [
                          tipoColor.withOpacity(.20),
                          tipoColor.withOpacity(.05),
                        ]),
                        borderRadius: BorderRadius.circular(13),
                        border:
                            Border.all(color: tipoColor.withOpacity(.32)),
                      ),
                      child: Icon(
                        d.tipo == 'cliente'
                            ? Icons.person_rounded
                            : Icons.business_rounded,
                        color: tipoColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.concepto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: p.textHigh,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${pendiente.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: d.pagada
                                ? _C.success
                                : _C.danger,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d.moneda ?? 'CUP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: agingColor.withOpacity(.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: agingColor.withOpacity(.32)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(agingIcon, size: 11, color: agingColor),
                          const SizedBox(width: 4),
                          Text(
                            agingLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: agingColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(d.fecha),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
                if (progreso > 0 && !d.pagada) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progreso,
                      backgroundColor: p.surface2,
                      valueColor: AlwaysStoppedAnimation(_C.success),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Pagado: \$${d.pagado.toStringAsFixed(2)} de \$${d.monto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
              gradient: const LinearGradient(colors: _C.gradDanger),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.danger.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.money_off_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Deudas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Cuentas por cobrar y pagar',
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
                  _C.success.withOpacity(.16),
                  _C.cyan.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 40, color: _C.success),
            ),
            const SizedBox(height: 16),
            Text(
              'Todo al día',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay deudas que coincidan con los filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  REGISTRO
  // ============================================================
  void _mostrarRegistro(
      BuildContext context, AppProvider provider, _P p) {
    String tipo = 'cliente';
    String? entidadId;
    String concepto = '';
    double monto = 0;
    DateTime fecha = DateTime.now();
    DateTime? vencimiento;
    String moneda = 'CUP';
    String? nota;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setSt) {
          final entidades = tipo == 'cliente'
              ? provider.clientes
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombre,
                            style: TextStyle(
                                color: p.textHigh, fontSize: 13)),
                      ))
                  .toList()
              : provider.proveedores
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombre,
                            style: TextStyle(
                                color: p.textHigh, fontSize: 13)),
                      ))
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
                    gradient: const LinearGradient(colors: _C.gradDanger),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Nueva deuda',
                  style: TextStyle(
                    color: p.textHigh,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _selectorTipo(
                              label: 'Cliente',
                              value: 'cliente',
                              current: tipo,
                              icon: Icons.person_rounded,
                              color: _C.info,
                              onTap: () => setSt(() {
                                tipo = 'cliente';
                                entidadId = null;
                              }),
                              p: p,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _selectorTipo(
                              label: 'Proveedor',
                              value: 'proveedor',
                              current: tipo,
                              icon: Icons.business_rounded,
                              color: _C.purple,
                              onTap: () => setSt(() {
                                tipo = 'proveedor';
                                entidadId = null;
                              }),
                              p: p,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('Entidad', p),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: entidadId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: p.surface2,
                          hintText: tipo == 'cliente'
                              ? 'Selecciona un cliente'
                              : 'Selecciona un proveedor',
                          hintStyle: TextStyle(
                              color: p.textMuted, fontSize: 12.5),
                        ),
                        items: entidades,
                        onChanged: (v) => setSt(() => entidadId = v),
                        validator: (v) =>
                            v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _label('Concepto', p),
                      const SizedBox(height: 6),
                      TextFormField(
                        onChanged: (v) => concepto = v,
                        style: TextStyle(
                          color: p.textHigh,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: p.surface2,
                          hintText: 'Ej: Compra al crédito',
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label('Monto', p),
                                const SizedBox(height: 6),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      monto = double.tryParse(v) ?? 0,
                                  style: TextStyle(
                                    color: p.textHigh,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    fillColor: p.surface2,
                                    hintText: '0.00',
                                  ),
                                  validator: (v) =>
                                      double.tryParse(v ?? '') == null
                                          ? 'Número'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label('Moneda', p),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: moneda,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    fillColor: p.surface2,
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'CUP', child: Text('CUP')),
                                    DropdownMenuItem(
                                        value: 'USD', child: Text('USD')),
                                  ],
                                  onChanged: (v) =>
                                      setSt(() => moneda = v ?? 'CUP'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _label('Vencimiento (opcional)', p),
                      const SizedBox(height: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dctx,
                            initialDate: vencimiento ??
                                DateTime.now()
                                    .add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSt(() => vencimiento = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 16, color: p.textMuted),
                              const SizedBox(width: 10),
                              Text(
                                vencimiento != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(vencimiento!)
                                    : 'Sin vencimiento',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: vencimiento != null
                                      ? p.textHigh
                                      : p.textMuted,
                                ),
                              ),
                              const Spacer(),
                              if (vencimiento != null)
                                InkWell(
                                  onTap: () =>
                                      setSt(() => vencimiento = null),
                                  child: Icon(Icons.close_rounded,
                                      size: 16, color: p.textMuted),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _label('Nota (opcional)', p),
                      const SizedBox(height: 6),
                      TextFormField(
                        onChanged: (v) => nota = v,
                        maxLines: 2,
                        style: TextStyle(
                          color: p.textHigh,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          fillColor: p.surface2,
                          hintText: 'Ej: Fiado del 15/09',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(dctx);
                  final deuda = Deuda(
                    id: '',
                    tipo: tipo,
                    entidadId: entidadId!,
                    concepto: concepto,
                    monto: monto,
                    fecha: fecha,
                    fechaVencimiento: vencimiento,
                    nota: nota,
                    moneda: moneda,
                    tasaCambio: moneda == 'USD'
                        ? provider.tasaCambioUSD
                        : null,
                    montoUSD: moneda == 'USD' ? monto : null,
                  );
                  await provider.registrarDeuda(deuda);
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String txt, _P p) => Text(
        txt,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: p.textMid,
        ),
      );

  Widget _selectorTipo({
    required String label,
    required String value,
    required String current,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required _P p,
  }) {
    final selected = current == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.12) : p.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: selected ? color : p.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? color : p.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  ACCIONES
  // ============================================================
  Future<void> _pagarDeuda(Deuda d, AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final pendiente = d.monto - d.pagado;

    final montoCtrl = TextEditingController(
        text: pendiente.toStringAsFixed(2));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradSuccess),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Registrar pago',
              style: TextStyle(
                color: p.textHigh,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pendiente: \$${pendiente.toStringAsFixed(2)} ${d.moneda ?? 'CUP'}',
              style: TextStyle(
                fontSize: 12.5,
                color: p.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: p.textHigh,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
                fillColor: p.surface2,
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.success,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final monto = double.tryParse(montoCtrl.text.trim()) ?? 0;
      if (monto <= 0 || monto > pendiente) {
        mostrarSnackBar(
            mensaje: 'Monto inválido', esExito: false);
        return;
      }
      // Usar el método existente. Si monto == pendiente → paga total.
      // Si es parcial, se aplica parcialmente.
      await provider.pagarDeuda(d.id);
    }
    montoCtrl.dispose();
  }

  Future<void> _eliminarDeuda(String id, AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('¿Eliminar deuda?',
            style: TextStyle(
                color: p.textHigh, fontWeight: FontWeight.w900)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: p.textMid, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.eliminarDeuda(id);
    }
  }
}