// ============================================================
//  fiscal_screen.dart · NEXORA BUSINESS
//  Estado de resultados y exportación ONAT
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const teal = Color(0xFF14B8A6);
  static const orange = Color(0xFFF97316);
  static const deepOrange = Color(0xFFEA580C);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradWarn = [Color(0xFFF59E0B), Color(0xFFF97316)];
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

class FiscalScreen extends StatefulWidget {
  const FiscalScreen({Key? key}) : super(key: key);

  @override
  State<FiscalScreen> createState() => _FiscalScreenState();
}

class _FiscalScreenState extends State<FiscalScreen> {
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    // ✅ Fix roles
    final esAdmin = provider.rol == 'dueno';
    final esGerente = provider.rol == 'gerente';

    if (!esAdmin && !esGerente) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          title: const Text('Módulo Fiscal'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 64, color: p.textMuted),
              const SizedBox(height: 16),
              Text(
                'No tienes permisos para esta sección',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final inicioMes = DateTime(_anioSeleccionado, _mesSeleccionado, 1);
    final finMes = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 1);

    final totalVentas = provider.getTotalVentas(inicioMes, finMes);
    final costoVentas = provider.getCostoVentas(inicioMes, finMes);
    final gananciaBruta = totalVentas - costoVentas;
    final totalGastos = provider.getTotalGastos(inicioMes, finMes);
    final totalMermas = provider.getTotalMermas(inicioMes, finMes);
    final gananciaNeta = gananciaBruta - totalGastos - totalMermas;

    final taxaVentas = provider.taxaVentas;
    final taxaUtilidades = provider.taxaUtilidades;
    final impuestoVentas = totalVentas * (taxaVentas / 100);
    final impuestoUtilidades =
        gananciaNeta > 0 ? gananciaNeta * (taxaUtilidades / 100) : 0;
    final totalImpuestos = impuestoVentas + impuestoUtilidades;
    final resultadoFinal = gananciaNeta - totalImpuestos;

    final ventasMes = provider.getVentasPorPeriodo(inicioMes, finMes);
    final gastosMes = provider.getGastosPorPeriodo(inicioMes, finMes);
    final mermasMes = provider.mermas
        .where((m) =>
            !m.cancelado &&
            m.fecha.isAfter(inicioMes) &&
            m.fecha.isBefore(finMes))
        .toList();

    final numVentas = ventasMes.length;
    final ticketPromedio = numVentas > 0 ? totalVentas / numVentas : 0;
    final margenBruto =
        totalVentas > 0 ? (gananciaBruta / totalVentas) * 100 : 0;
    final margenNeto =
        totalVentas > 0 ? (gananciaNeta / totalVentas) * 100 : 0;

    final nombreMes = DateFormat('MMMM yyyy', 'es').format(inicioMes);
    final nombreMesCap =
        nombreMes[0].toUpperCase() + nombreMes.substring(1);

    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, provider, inicioMes, finMes),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(14),
          children: [
            _selectorMesAnio(meses, p),
            const SizedBox(height: 14),
            _warningBanner(p),
            const SizedBox(height: 14),
            _resumenEjecutivo(nombreMesCap, totalVentas, gananciaNeta,
                totalImpuestos, resultadoFinal, p, isDesktop),
            const SizedBox(height: 14),
            _estadoResultados(
              totalVentas,
              costoVentas,
              gananciaBruta,
              totalGastos,
              totalMermas,
              gananciaNeta,
              impuestoVentas,
              impuestoUtilidades.toDouble(),
              totalImpuestos,
              resultadoFinal,
              taxaVentas,
              taxaUtilidades,
              p,
            ),
            if (ventasMes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _tablaVentas(ventasMes, provider, p),
            ],
            if (gastosMes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _tablaGastos(gastosMes, p),
            ],
            if (mermasMes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _tablaMermas(mermasMes, provider, p),
            ],
            const SizedBox(height: 14),
            _estadisticas(
              totalVentas,
              gananciaNeta,
              resultadoFinal,
              numVentas,
              ticketPromedio.toDouble(),
              margenBruto.toDouble(),
              margenNeto.toDouble(),
              gastosMes.length,
              mermasMes.length,
              p,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(
    _P p,
    AppProvider provider,
    DateTime inicio,
    DateTime fin,
  ) {
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
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.request_quote_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Módulo Fiscal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Estado de resultados',
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
          tooltip: 'Exportar ONAT',
          icon: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.upload_file_rounded, color: p.textMid),
          onPressed: _cargando
              ? null
              : () => _exportarONAT(context, provider, inicio, fin),
        ),
      ],
    );
  }

  Widget _selectorMesAnio(List<String> meses, _P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: p.textMid),
            onPressed: () => setState(() {
              if (_mesSeleccionado == 1) {
                _mesSeleccionado = 12;
                _anioSeleccionado--;
              } else {
                _mesSeleccionado--;
              }
            }),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  meses[_mesSeleccionado - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: p.textHigh,
                  ),
                ),
                Text(
                  '$_anioSeleccionado',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: p.textMid),
            onPressed: () => setState(() {
              if (_mesSeleccionado == 12) {
                _mesSeleccionado = 1;
                _anioSeleccionado++;
              } else {
                _mesSeleccionado++;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _warningBanner(_P p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.warning.withOpacity(.32)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _C.warning.withOpacity(.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: _C.warning, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los cálculos son orientativos. Consulta con un contador o la ONAT para valores oficiales.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.textMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenEjecutivo(
    String nombreMesCap,
    double ventas,
    double ganancia,
    double impuestos,
    double resultado,
    _P p,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withOpacity(.10),
            _C.cyan.withOpacity(.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.primary.withOpacity(.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.summarize_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombreMesCap,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: p.textHigh,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryCard('Ventas', ventas, _C.success, p),
              _summaryCard('Ganancia', ganancia, _C.info, p),
              _summaryCard('Impuestos', impuestos, _C.purple, p),
              _summaryCard(
                  'Resultado', resultado,
                  resultado >= 0 ? _C.teal : _C.danger, p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface.withOpacity(.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _fmtMoney(value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: p.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoResultados(
    double ventas,
    double costo,
    double gananciaBruta,
    double gastos,
    double mermas,
    double gananciaNeta,
    double impuestoVentas,
    double impuestoUtilidades,
    double totalImpuestos,
    double resultadoFinal,
    double taxaVentas,
    double taxaUtilidades,
    _P p,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
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
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                'Estado de Resultados',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('Ventas', ventas, _C.success, p,
              icon: Icons.trending_up_rounded),
          _divider(p),
          _row('Costo de Ventas (FIFO)', -costo, _C.danger, p,
              icon: Icons.trending_down_rounded),
          _row('Ganancia Bruta', gananciaBruta, _C.orange, p,
              bold: true, icon: Icons.savings_rounded),
          _divider(p),
          _row('Gastos Operativos', -gastos, _C.pink, p,
              icon: Icons.receipt_long_rounded),
          _row('Mermas', -mermas, _C.deepOrange, p,
              icon: Icons.warning_amber_rounded),
          _row('Ganancia Neta', gananciaNeta, _C.info, p,
              bold: true, icon: Icons.account_balance_rounded),
          _divider(p),
          _row(
              'Impuesto Ventas (${taxaVentas.toStringAsFixed(0)}%)',
              -impuestoVentas,
              _C.purple,
              p,
              icon: Icons.percent_rounded),
          _row(
              'Impuesto Utilidades (${taxaUtilidades.toStringAsFixed(0)}%)',
              -impuestoUtilidades,
              _C.purple,
              p,
              icon: Icons.percent_rounded),
          _row('Total Impuestos', -totalImpuestos, _C.pink, p,
              bold: true, icon: Icons.calculate_rounded),
          _divider(p),
          _row(
            'Resultado Final',
            resultadoFinal,
            resultadoFinal >= 0 ? _C.teal : _C.danger,
            p,
            bold: true,
            big: true,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _divider(_P p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: p.border, height: 1),
      );

  Widget _row(
    String label,
    double value,
    Color color,
    _P p, {
    bool bold = false,
    bool big = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: big ? 14.5 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: p.textHigh,
              ),
            ),
          ),
          Text(
            _fmtMoney(value),
            style: TextStyle(
              fontSize: big ? 16 : 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  TABLAS
  // ============================================================
  Widget _tablaVentas(List<Venta> ventas, AppProvider provider, _P p) {
    return _tablaSection(
      title: 'Ventas del mes',
      count: ventas.length,
      icon: Icons.shopping_cart_rounded,
      color: _C.success,
      p: p,
      child: Column(
        children: ventas.take(20).map((v) {
          final cliente = v.clienteId != null
              ? provider.clientes.firstWhere(
                  (c) => c.id == v.clienteId,
                  orElse: () => Cliente(id: '', nombre: '')).nombre
              : null;
          return _tablaRow(
            p,
            left: v.productoNombre,
            sub: '${DateFormat('dd/MM HH:mm').format(v.fecha)} · ${v.cantidad} u · ${v.metodoPago}',
            right: '\$${v.total.toStringAsFixed(2)}',
            rightColor: _C.success,
          );
        }).toList(),
      ),
    );
  }

  Widget _tablaGastos(List<Gasto> gastos, _P p) {
    return _tablaSection(
      title: 'Gastos del mes',
      count: gastos.length,
      icon: Icons.receipt_long_rounded,
      color: _C.danger,
      p: p,
      child: Column(
        children: gastos.take(20).map((g) {
          return _tablaRow(
            p,
            left: g.concepto,
            sub:
                '${g.categoria} · ${DateFormat('dd/MM').format(g.fecha)}',
            right: '-\$${g.monto.toStringAsFixed(2)}',
            rightColor: _C.danger,
          );
        }).toList(),
      ),
    );
  }

  Widget _tablaMermas(List<Merma> mermas, AppProvider provider, _P p) {
    return _tablaSection(
      title: 'Mermas del mes',
      count: mermas.length,
      icon: Icons.warning_amber_rounded,
      color: _C.orange,
      p: p,
      child: Column(
        children: mermas.take(20).map((m) {
          final prod = provider.getProductoById(m.productoId);
          return _tablaRow(
            p,
            left: prod?.nombre ?? 'Producto eliminado',
            sub:
                '${m.cantidad} u · ${_traducirMotivo(m.motivo)} · ${DateFormat('dd/MM').format(m.fecha)}',
            right: '-\$${m.costoTotal.toStringAsFixed(2)}',
            rightColor: _C.deepOrange,
          );
        }).toList(),
      ),
    );
  }

  Widget _tablaSection({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required _P p,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
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
                  gradient: LinearGradient(colors: [
                    color.withOpacity(.20),
                    color.withOpacity(.05),
                  ]),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withOpacity(.28)),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _tablaRow(
    _P p, {
    required String left,
    required String sub,
    required String right,
    required Color rightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadisticas(
    double totalVentas,
    double gananciaNeta,
    double resultadoFinal,
    int numVentas,
    double ticketPromedio,
    double margenBruto,
    double margenNeto,
    int numGastos,
    int numMermas,
    _P p,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
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
                ),
                child: const Icon(Icons.insights_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen Estadístico',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statMini('Ventas', '$numVentas', _C.primary, p),
              _statMini('Ticket prom.',
                  _fmtMoney(ticketPromedio), _C.purple, p),
              _statMini('Margen bruto',
                  '${margenBruto.toStringAsFixed(1)}%', _C.orange, p),
              _statMini('Margen neto',
                  '${margenNeto.toStringAsFixed(1)}%', _C.pink, p),
              _statMini('Gastos', '$numGastos', _C.danger, p),
              _statMini('Mermas', '$numMermas', _C.deepOrange, p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  String _fmtMoney(double n) {
    if (n.abs() >= 1000000) return '\$${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '\$${NumberFormat('#,###').format(n)}';
    return '\$${NumberFormat('#,##0.00').format(n)}';
  }

  Future<void> _exportarONAT(
    BuildContext context,
    AppProvider provider,
    DateTime inicio,
    DateTime fin,
  ) async {
    // ✅ Fix: solo 'dueno'
    if (provider.rol != 'dueno') {
      mostrarSnackBar(
          mensaje: 'Solo el dueño puede exportar', esExito: false);
      return;
    }
    setState(() => _cargando = true);
    try {
      final ventas = provider.getVentasPorPeriodo(inicio, fin);
      if (ventas.isEmpty) {
        mostrarSnackBar(
            mensaje: 'No hay ventas en el período', esExito: false);
        setState(() => _cargando = false);
        return;
      }
      String csv =
          'Fecha,Producto,Cantidad,PrecioUnitario,Total,MetodoPago,Cliente,Moneda,TotalUSD\n';
      for (var v in ventas) {
        final cliente = v.clienteId != null
            ? provider.clientes.firstWhere(
                (c) => c.id == v.clienteId,
                orElse: () => Cliente(id: '', nombre: '')).nombre
            : 'Consumidor Final';
        csv +=
            '${DateFormat('yyyy-MM-dd').format(v.fecha)},${v.productoNombre},${v.cantidad},${v.precioUnitario},${v.total},${v.metodoPago},$cliente,${v.moneda ?? 'CUP'},${v.totalUSD?.toStringAsFixed(2) ?? ''}\n';
      }
      final bytes = Uint8List.fromList(csv.codeUnits);
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/libro_ventas_onat_${DateFormat('yyyyMM').format(inicio)}.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Libro de Ventas ONAT',
      );
      mostrarSnackBar(
          mensaje: 'Exportado correctamente', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}