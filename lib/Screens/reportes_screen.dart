// ============================================================
//  reportes_screen.dart  ·  NEXORA BUSINESS
//  Centro de inteligencia de negocio · Industry Peak
// ============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:fl_chart/fl_chart.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

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
  static const gradGold    = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
}

class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg            => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface       => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2      => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3      => dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);
  Color get textHigh      => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid       => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted     => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border        => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong  => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

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
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  String _periodoTipo = 'Mes';
  DateTime _mesSeleccionado = DateTime.now();
  DateTime _anioSeleccionado = DateTime.now();
  DateTime? _diaSeleccionado;
  DateTime? _rangoInicio;
  DateTime? _rangoFin;
  bool _cargando = false;
  final NumberFormat _format = NumberFormat('#,##0.00');
  String? _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarPeriodo('Mes');
    });
  }

  void _aplicarPeriodo(String tipo) {
    final now = DateTime.now();
    setState(() {
      _periodoTipo = tipo;
      switch (tipo) {
        case 'Hoy':
          _fechaInicio = DateTime(now.year, now.month, now.day);
          _fechaFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Semana':
          _fechaInicio = now.subtract(Duration(days: now.weekday - 1));
          _fechaInicio = DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day);
          _fechaFin = now;
          break;
        case 'Mes':
          _fechaInicio = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, 1);
          _fechaFin = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0, 23, 59, 59);
          break;
        case 'Año':
          _fechaInicio = DateTime(_anioSeleccionado.year, 1, 1);
          _fechaFin = DateTime(_anioSeleccionado.year, 12, 31, 23, 59, 59);
          break;
        case 'Dia':
          if (_diaSeleccionado != null) {
            _fechaInicio = DateTime(_diaSeleccionado!.year, _diaSeleccionado!.month, _diaSeleccionado!.day);
            _fechaFin = DateTime(_diaSeleccionado!.year, _diaSeleccionado!.month, _diaSeleccionado!.day, 23, 59, 59);
          }
          break;
        case 'Rango':
          if (_rangoInicio != null && _rangoFin != null) {
            _fechaInicio = DateTime(_rangoInicio!.year, _rangoInicio!.month, _rangoInicio!.day);
            _fechaFin = DateTime(_rangoFin!.year, _rangoFin!.month, _rangoFin!.day, 23, 59, 59);
          }
          break;
      }
    });
  }

  Map<String, DateTime> _periodoAnterior() {
    final duracion = _fechaFin.difference(_fechaInicio);
    final inicioAnt = _fechaInicio.subtract(duracion + const Duration(seconds: 1));
    final finAnt = _fechaInicio.subtract(const Duration(seconds: 1));
    return {'inicio': inicioAnt, 'fin': finAnt};
  }

  Future<void> _seleccionarMes() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mesSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _mesSeleccionado = DateTime(picked.year, picked.month, 1);
      _aplicarPeriodo('Mes');
    }
  }

  Future<void> _seleccionarAnio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anioSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _anioSeleccionado = DateTime(picked.year, 1, 1);
      _aplicarPeriodo('Año');
    }
  }

  Future<void> _seleccionarDia() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _diaSeleccionado = picked;
      _aplicarPeriodo('Dia');
    }
  }

  Future<void> _seleccionarRango() async {
    final now = DateTime.now();
    final inicio = await showDatePicker(
      context: context,
      initialDate: _rangoInicio ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (inicio == null) return;
    final fin = await showDatePicker(
      context: context,
      initialDate: _rangoFin ?? now,
      firstDate: inicio,
      lastDate: now,
    );
    if (fin == null) return;
    _rangoInicio = inicio;
    _rangoFin = fin;
    _aplicarPeriodo('Rango');
  }

  List<Venta> _ventasPeriodo(AppProvider provider,
      {DateTime? inicio, DateTime? fin}) {
    final ini = inicio ?? _fechaInicio;
    final fn = fin ?? _fechaFin;
    return provider.ventas
        .where((v) =>
            v.fecha.isAfter(ini) &&
            v.fecha.isBefore(fn) &&
            (_sucursalSeleccionada == null ||
                v.sucursalId == _sucursalSeleccionada))
        .toList();
  }

  List<Gasto> _gastosPeriodo(AppProvider provider,
      {DateTime? inicio, DateTime? fin}) {
    final ini = inicio ?? _fechaInicio;
    final fn = fin ?? _fechaFin;
    return provider.gastos
        .where((g) =>
            g.fecha.isAfter(ini) &&
            g.fecha.isBefore(fn) &&
            (_sucursalSeleccionada == null ||
                g.sucursalId == _sucursalSeleccionada))
        .toList();
  }

  double _ventas(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      _ventasPeriodo(p, inicio: ini, fin: fin)
          .fold(0.0, (s, v) => s + v.total)
          .toDouble();

  double _costo(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      _ventasPeriodo(p, inicio: ini, fin: fin)
          .fold(0.0, (s, v) => s + v.costoTotal)
          .toDouble();

  double _gananciaBruta(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      (_ventas(p, ini: ini, fin: fin) - _costo(p, ini: ini, fin: fin)).toDouble();

  double _gastos(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      _gastosPeriodo(p, inicio: ini, fin: fin)
          .fold(0.0, (s, g) => s + g.monto)
          .toDouble();

  double _mermas(AppProvider p, {DateTime? ini, DateTime? fin}) {
    final i = ini ?? _fechaInicio;
    final f = fin ?? _fechaFin;
    return p.mermas
        .where((m) =>
            !m.cancelado &&
            m.fecha.isAfter(i) &&
            m.fecha.isBefore(f) &&
            (_sucursalSeleccionada == null ||
                m.sucursalId == _sucursalSeleccionada))
        .fold(0.0, (s, m) => s + m.costoTotal)
        .toDouble();
  }

  double _gananciaNeta(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      (_gananciaBruta(p, ini: ini, fin: fin) -
              _gastos(p, ini: ini, fin: fin) -
              _mermas(p, ini: ini, fin: fin))
          .toDouble();

  int _numVentas(AppProvider p, {DateTime? ini, DateTime? fin}) =>
      _ventasPeriodo(p, inicio: ini, fin: fin).length;

  double _ticketProm(AppProvider p, {DateTime? ini, DateTime? fin}) {
    final n = _numVentas(p, ini: ini, fin: fin);
    return n > 0 ? (_ventas(p, ini: ini, fin: fin) / n).toDouble() : 0.0;
  }

  double _margenBruto(AppProvider p, {DateTime? ini, DateTime? fin}) {
    final v = _ventas(p, ini: ini, fin: fin);
    return v > 0
        ? ((_gananciaBruta(p, ini: ini, fin: fin) / v) * 100).toDouble()
        : 0.0;
  }

  double _margenNeto(AppProvider p, {DateTime? ini, DateTime? fin}) {
    final v = _ventas(p, ini: ini, fin: fin);
    return v > 0
        ? ((_gananciaNeta(p, ini: ini, fin: fin) / v) * 100).toDouble()
        : 0.0;
  }

  double _costoPersonal(AppProvider p, {DateTime? ini, DateTime? fin}) {
    final i = ini ?? _fechaInicio;
    final f = fin ?? _fechaFin;
    return p.getCostoPersonal(i, f).toDouble();
  }

  List<Map<String, dynamic>> _topProductos(AppProvider provider) {
    final ventas = _ventasPeriodo(provider);
    final resumen = <String, Map<String, dynamic>>{};
    for (final v in ventas) {
      resumen.putIfAbsent(
        v.productoId,
        () => {
          'nombre': v.productoNombre,
          'cantidad': 0.0,
          'total': 0.0,
          'costo': 0.0,
        },
      );
      resumen[v.productoId]!['cantidad'] =
          (resumen[v.productoId]!['cantidad'] as double) + v.cantidad;
      resumen[v.productoId]!['total'] =
          (resumen[v.productoId]!['total'] as double) + v.total;
      resumen[v.productoId]!['costo'] =
          (resumen[v.productoId]!['costo'] as double) + v.costoTotal;
    }
    final list = resumen.entries
        .map((e) => {
              'id': e.key,
              'nombre': e.value['nombre'],
              'cantidad': e.value['cantidad'],
              'total': e.value['total'],
              'costo': e.value['costo'],
              'ganancia':
                  ((e.value['total'] as double) - (e.value['costo'] as double))
                      .toDouble(),
            })
        .toList();
    list.sort((a, b) =>
        (b['total'] as double).compareTo(a['total'] as double));
    return list;
  }

  List<Map<String, dynamic>> _topClientes(AppProvider provider) {
    final ventas = _ventasPeriodo(provider);
    final compras = <String, double>{};
    for (final v in ventas) {
      if (v.clienteId != null) {
        compras[v.clienteId!] = (compras[v.clienteId!] ?? 0) + v.total;
      }
    }
    final list = compras.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).map((e) {
      final cli = provider.clientes.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Cliente(id: e.key, nombre: 'Cliente'),
      );
      return {'nombre': cli.nombre, 'total': e.value};
    }).toList();
  }

  List<Map<String, dynamic>> _evolucion(AppProvider provider) {
    final datos = <Map<String, dynamic>>[];
    final dias = _fechaFin.difference(_fechaInicio).inDays.clamp(1, 31);
    final mostrar = dias > 14 ? 30 : dias;

    for (int i = mostrar - 1; i >= 0; i--) {
      final dia = DateTime(
        _fechaFin.year,
        _fechaFin.month,
        _fechaFin.day - i,
      );
      final diaSig = dia.add(const Duration(days: 1));
      final ventasDia = provider.ventas.where((v) =>
          v.fecha.isAfter(dia) &&
          v.fecha.isBefore(diaSig) &&
          (_sucursalSeleccionada == null ||
              v.sucursalId == _sucursalSeleccionada));
      final total = ventasDia.fold(0.0, (s, v) => s + v.total).toDouble();
      final costo = ventasDia.fold(0.0, (s, v) => s + v.costoTotal).toDouble();
      final gastosDia = provider.gastos.where((g) =>
          g.fecha.isAfter(dia) &&
          g.fecha.isBefore(diaSig) &&
          (_sucursalSeleccionada == null ||
              g.sucursalId == _sucursalSeleccionada));
      final gastos = gastosDia.fold(0.0, (s, g) => s + g.monto).toDouble();
      final mermasDia = provider.mermas.where((m) =>
          !m.cancelado &&
          m.fecha.isAfter(dia) &&
          m.fecha.isBefore(diaSig) &&
          (_sucursalSeleccionada == null ||
              m.sucursalId == _sucursalSeleccionada));
      final mermas = mermasDia.fold(0.0, (s, m) => s + m.costoTotal).toDouble();

      datos.add({
        'fecha': dia,
        'periodo': mostrar <= 7
            ? DateFormat('E', 'es').format(dia).substring(0, 3)
            : '${dia.day}',
        'ventas': total,
        'gananciaBruta': (total - costo).toDouble(),
        'gananciaNeta': (total - costo - gastos - mermas).toDouble(),
      });
    }
    return datos;
  }

  List<Map<String, dynamic>> _ventasPorHora(AppProvider provider) {
    final franjas = <String, double>{
      '6-9': 0.0,
      '9-12': 0.0,
      '12-15': 0.0,
      '15-18': 0.0,
      '18-21': 0.0,
      '21-24': 0.0,
    };
    for (final v in _ventasPeriodo(provider)) {
      final h = v.fecha.hour;
      String key;
      if (h < 9) {
        key = '6-9';
      } else if (h < 12) {
        key = '9-12';
      } else if (h < 15) {
        key = '12-15';
      } else if (h < 18) {
        key = '15-18';
      } else if (h < 21) {
        key = '18-21';
      } else {
        key = '21-24';
      }
      franjas[key] = (franjas[key] ?? 0.0) + v.total;
    }
    final list = franjas.entries
        .map((e) => {'franja': e.key, 'total': e.value})
        .toList();
    return list;
  }

  List<Map<String, dynamic>> _generarInsights(AppProvider provider) {
    final insights = <Map<String, dynamic>>[];

    final ventasActual = _ventas(provider);
    final ventasAnterior = _ventas(provider,
        ini: _periodoAnterior()['inicio'], fin: _periodoAnterior()['fin']);
    final margenNeto = _margenNeto(provider);
    final gastos = _gastos(provider);
    final gananciaBruta = _gananciaBruta(provider);
    final mermas = _mermas(provider);
    final costoPersonal = _costoPersonal(provider);

    if (ventasAnterior > 0) {
      final delta =
          (((ventasActual - ventasAnterior) / ventasAnterior) * 100).toDouble();
      if (delta.abs() >= 5) {
        insights.add({
          'icon': delta > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          'color': delta > 0 ? _C.success : _C.danger,
          'titulo': delta > 0
              ? 'Ventas suben ${delta.toStringAsFixed(1)}%'
              : 'Ventas bajan ${delta.abs().toStringAsFixed(1)}%',
          'detalle': delta > 0
              ? 'Excelente — superaste el período anterior.'
              : 'Revisa estrategia comercial o precios.',
        });
      }
    }

    if (margenNeto < 5) {
      insights.add({
        'icon': Icons.warning_amber_rounded,
        'color': _C.warning,
        'titulo': 'Margen neto bajo',
        'detalle':
            'Estás en ${margenNeto.toStringAsFixed(1)}%. Revisa precios y gastos.',
      });
    } else if (margenNeto > 25) {
      insights.add({
        'icon': Icons.emoji_events_rounded,
        'color': _C.success,
        'titulo': 'Margen neto excelente',
        'detalle': '${margenNeto.toStringAsFixed(1)}% — negocio muy rentable.',
      });
    }

    if (gananciaBruta > 0 && gastos / gananciaBruta > 0.6) {
      insights.add({
        'icon': Icons.receipt_long_rounded,
        'color': _C.orange,
        'titulo': 'Gastos elevados',
        'detalle':
            '${(gastos / gananciaBruta * 100).toStringAsFixed(0)}% de la ganancia bruta.',
      });
    }

    if (gananciaBruta > 0 && mermas / gananciaBruta > 0.05) {
      insights.add({
        'icon': Icons.warning_amber_rounded,
        'color': _C.danger,
        'titulo': 'Mermas altas',
        'detalle':
            '\$${_format.format(mermas)} (${(mermas / gananciaBruta * 100).toStringAsFixed(1)}% de ganancia).',
      });
    }

    if (ventasActual > 0 && costoPersonal / ventasActual > 0.25) {
      insights.add({
        'icon': Icons.people_rounded,
        'color': _C.purple,
        'titulo': 'Personal costoso',
        'detalle':
            '${(costoPersonal / ventasActual * 100).toStringAsFixed(0)}% de las ventas.',
      });
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildSafe(context);
    } catch (e, stack) {
      print('Error en ReportesScreen: $e\n$stack');
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Ocurrió un error al cargar los reportes'),
                const SizedBox(height: 8),
                Text(e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSafe(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isManager = provider.rol == 'dueno' ||
        provider.rol == 'admin' ||
        provider.rol == 'gerente' ||
        provider.rol == 'gestor';
    final isAdmin = provider.rol == 'dueno' || provider.rol == 'admin';
    final isPremium = provider.plan == 'premium';
    final isDesktop = ResponsiveHelper.isDesktop();

    final double ventas = _ventas(provider);
    final double costo = _costo(provider);
    final double gananciaBruta = _gananciaBruta(provider);
    final double gastos = _gastos(provider);
    final double mermas = _mermas(provider);
    final double gananciaNeta = _gananciaNeta(provider);
    final int numVentas = _numVentas(provider);
    final double ticket = _ticketProm(provider);
    final double margenBruto = _margenBruto(provider);
    final double margenNeto = _margenNeto(provider);
    final double costoPersonal = _costoPersonal(provider);

    final rangoAnt = _periodoAnterior();
    final double ventasAnt =
        _ventas(provider, ini: rangoAnt['inicio'], fin: rangoAnt['fin']);
    final double gananciaNetaAnt = _gananciaNeta(provider,
        ini: rangoAnt['inicio'], fin: rangoAnt['fin']);
    final int numVentasAnt = _numVentas(provider,
        ini: rangoAnt['inicio'], fin: rangoAnt['fin']);

    final double taxaVentas = provider.taxaVentas.toDouble();
    final double taxaUtilidades = provider.taxaUtilidades.toDouble();
    final double impuestoVentas =
        (ventas * (taxaVentas / 100)).toDouble();
    final double impuestoUtilidades = gananciaNeta > 0
        ? (gananciaNeta * (taxaUtilidades / 100)).toDouble()
        : 0.0;
    final double totalImpuestos =
        (impuestoVentas + impuestoUtilidades).toDouble();
    final double resultadoFinal =
        (gananciaNeta - totalImpuestos).toDouble();

    final insights = _generarInsights(provider);
    final datosGrafico = _evolucion(provider);
    final datosHora = _ventasPorHora(provider);
    final topProductos = _topProductos(provider);
    final topClientes = _topClientes(provider);

    final gastosPorCat = <String, double>{};
    for (final g in _gastosPeriodo(provider)) {
      gastosPorCat[g.categoria] =
          (gastosPorCat[g.categoria] ?? 0.0) + g.monto;
    }
    final listaGastosCat = gastosPorCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final metodos = <String, double>{};
    for (final v in _ventasPeriodo(provider)) {
      metodos[v.metodoPago] = (metodos[v.metodoPago] ?? 0.0) + v.total;
    }
    final listaMetodos = metodos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, provider, p, isAdmin, isPremium),
      body: Stack(
        children: [
          _background(p),
          RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 14,
                14,
                isDesktop ? 24 : 14,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin) _sucursalFilter(context, provider, p),
                  _periodSelector(context, p),
                  const SizedBox(height: 14),
                  _periodInfo(context, p),
                  const SizedBox(height: 16),
                  _kpiHero(context, p, ventas, gananciaNeta, resultadoFinal,
                      numVentas),
                  const SizedBox(height: 16),
                  _kpiComparative(context, p, ventas, ventasAnt, gananciaNeta,
                      gananciaNetaAnt, numVentas, numVentasAnt),
                  if (insights.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _insightsPanel(context, p, insights),
                  ],
                  const SizedBox(height: 16),
                  _chartEvolution(context, p, datosGrafico),
                  const SizedBox(height: 16),
                  _chartHourHeatmap(context, p, datosHora),
                  const SizedBox(height: 16),
                  _estadoResultados(context, p, ventas, costo, gananciaBruta,
                      gastos, mermas, gananciaNeta, costoPersonal,
                      impuestoVentas, impuestoUtilidades, totalImpuestos,
                      resultadoFinal, taxaVentas, taxaUtilidades),
                  const SizedBox(height: 16),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              if (listaMetodos.isNotEmpty)
                                _cardMetodos(context, p, listaMetodos, ventas),
                              const SizedBox(height: 16),
                              if (topProductos.isNotEmpty)
                                _cardTopProductos(
                                    context, p, topProductos, isAdmin),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              if (listaGastosCat.isNotEmpty)
                                _cardGastosCat(
                                    context, p, listaGastosCat, gastos),
                              const SizedBox(height: 16),
                              if (topClientes.isNotEmpty)
                                _cardTopClientes(context, p, topClientes),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    if (listaMetodos.isNotEmpty)
                      _cardMetodos(context, p, listaMetodos, ventas),
                    const SizedBox(height: 16),
                    if (listaGastosCat.isNotEmpty)
                      _cardGastosCat(context, p, listaGastosCat, gastos),
                    const SizedBox(height: 16),
                    if (topProductos.isNotEmpty)
                      _cardTopProductos(context, p, topProductos, isAdmin),
                    const SizedBox(height: 16),
                    if (topClientes.isNotEmpty)
                      _cardTopClientes(context, p, topClientes),
                  ],
                  if (isManager) ...[
                    const SizedBox(height: 16),
                    _cardMetas(context, provider, p),
                    const SizedBox(height: 16),
                    _cardVendedores(context, provider, p),
                  ],
                  const SizedBox(height: 16),
                  _cardGastosRecientes(context, p, _gastosPeriodo(provider)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  PreferredSizeWidget _appBar(
    BuildContext context,
    AppProvider provider,
    _P p,
    bool isAdmin,
    bool isPremium,
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
            child: const Icon(Icons.insights_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Reportes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Centro de inteligencia',
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
        if (isAdmin && isPremium)
          PopupMenuButton<String>(
            icon: Icon(Icons.file_download_outlined, color: p.textHigh),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            color: p.surface,
            onSelected: (value) {
              if (value == 'pdf') _exportarPDF(context, provider);
              if (value == 'excel') _exportarExcel(context, provider);
              if (value == 'csv') _exportarCSV(context, provider);
              if (value == 'onat') _generarLibroONAT(context, provider);
            },
            itemBuilder: (_) => [
              _menuItem('pdf', Icons.picture_as_pdf_rounded,
                  'Exportar PDF profesional', p),
              _menuItem('excel', Icons.table_chart_rounded, 'Exportar Excel', p),
              _menuItem('csv', Icons.description_rounded, 'Exportar CSV', p),
              const PopupMenuDivider(),
              _menuItem('onat', Icons.account_balance_rounded,
                  'Libro ONAT (Ingresos/Gastos)', p),
            ],
          ),
        IconButton(
          tooltip: 'Compartir reporte',
          onPressed: () => _imprimirReporte(context, provider),
          icon: Icon(Icons.share_outlined, color: p.textHigh),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, _P p) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.primary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: p.textHigh, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sucursalFilter(BuildContext context, AppProvider provider, _P p) {
    if (provider.sucursales.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .16 : .10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.storefront_rounded,
                size: 16, color: _C.primary),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
                onChanged: (v) => setState(() => _sucursalSeleccionada = v),
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

  Widget _periodSelector(BuildContext context, _P p) {
    final opciones = ['Hoy', 'Semana', 'Mes', 'Año', 'Dia', 'Rango'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: opciones.map((op) {
                final selected = _periodoTipo == op;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => _aplicarPeriodo(op),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(colors: _C.gradBrand)
                              : null,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow:
                              selected ? p.glow(_C.primary, o: 0.28) : null,
                        ),
                        child: Text(
                          op,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected ? Colors.white : p.textMid,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_periodoTipo == 'Mes' ||
              _periodoTipo == 'Año' ||
              _periodoTipo == 'Dia' ||
              _periodoTipo == 'Rango') ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: p.border),
            const SizedBox(height: 6),
            _periodoSelectorEspecifico(context, p),
          ],
        ],
      ),
    );
  }

  Widget _periodoSelectorEspecifico(BuildContext context, _P p) {
    if (_periodoTipo == 'Mes') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: p.textMid),
            onPressed: () {
              _mesSeleccionado = DateTime(
                  _mesSeleccionado.year, _mesSeleccionado.month - 1, 1);
              _aplicarPeriodo('Mes');
            },
          ),
          TextButton(
            onPressed: _seleccionarMes,
            style: TextButton.styleFrom(
              foregroundColor: _C.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              DateFormat('MMMM yyyy', 'es').format(_mesSeleccionado),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: p.textMid),
            onPressed: () {
              final next = DateTime(
                  _mesSeleccionado.year, _mesSeleccionado.month + 1, 1);
              if (next.isBefore(DateTime.now().add(const Duration(days: 31)))) {
                _mesSeleccionado = next;
                _aplicarPeriodo('Mes');
              }
            },
          ),
        ],
      );
    }
    if (_periodoTipo == 'Año') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: p.textMid),
            onPressed: () {
              _anioSeleccionado = DateTime(_anioSeleccionado.year - 1, 1, 1);
              _aplicarPeriodo('Año');
            },
          ),
          TextButton(
            onPressed: _seleccionarAnio,
            style: TextButton.styleFrom(foregroundColor: _C.primary),
            child: Text(
              '${_anioSeleccionado.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: p.textMid),
            onPressed: () {
              if (_anioSeleccionado.year < DateTime.now().year) {
                _anioSeleccionado = DateTime(_anioSeleccionado.year + 1, 1, 1);
                _aplicarPeriodo('Año');
              }
            },
          ),
        ],
      );
    }
    if (_periodoTipo == 'Dia') {
      return TextButton.icon(
        onPressed: _seleccionarDia,
        icon: const Icon(Icons.calendar_today_rounded,
            size: 15, color: _C.primary),
        label: Text(
          _diaSeleccionado != null
              ? DateFormat('EEEE d MMMM yyyy', 'es').format(_diaSeleccionado!)
              : 'Seleccionar día',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        style: TextButton.styleFrom(foregroundColor: _C.primary),
      );
    }
    if (_periodoTipo == 'Rango') {
      return TextButton.icon(
        onPressed: _seleccionarRango,
        icon: const Icon(Icons.date_range_rounded,
            size: 15, color: _C.primary),
        label: Text(
          _rangoInicio != null && _rangoFin != null
              ? '${DateFormat('dd/MM/yy').format(_rangoInicio!)} → ${DateFormat('dd/MM/yy').format(_rangoFin!)}'
              : 'Seleccionar rango',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        style: TextButton.styleFrom(foregroundColor: _C.primary),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _periodInfo(BuildContext context, _P p) {
    return Row(
      children: [
        Icon(Icons.event_rounded, size: 14, color: p.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Del ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} al ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: p.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiHero(
    BuildContext context,
    _P p,
    double ventas,
    double gananciaNeta,
    double resultadoFinal,
    int numVentas,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _C.gradBrand,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: p.glow(_C.primary, o: 0.42),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.32)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '$numVentas OPERACIONES',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.32)),
                ),
                child: Text(
                  _periodoTipo.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Ingresos totales',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${_format.format(ventas)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _heroStat('Ganancia neta',
                      '\$${_format.format(gananciaNeta)}'),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(.20),
                ),
                Expanded(
                  child: _heroStat('Resultado final',
                      '\$${_format.format(resultadoFinal)}',
                      right: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value,
      {bool center = false, bool right = false}) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(.75),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiComparative(
    BuildContext context,
    _P p,
    double ventas,
    double ventasAnt,
    double gananciaNeta,
    double gananciaNetaAnt,
    int numVentas,
    int numVentasAnt,
  ) {
    final tiles = [
      _kpiTrendTile(
        context, p,
        label: 'Ventas',
        value: '\$${_format.format(ventas)}',
        icon: Icons.trending_up_rounded,
        color: _C.success,
        actual: ventas,
        anterior: ventasAnt,
      ),
      _kpiTrendTile(
        context, p,
        label: 'Ganancia neta',
        value: '\$${_format.format(gananciaNeta)}',
        icon: Icons.savings_rounded,
        color: _C.cyan,
        actual: gananciaNeta,
        anterior: gananciaNetaAnt,
      ),
      _kpiTrendTile(
        context, p,
        label: 'Operaciones',
        value: '$numVentas',
        icon: Icons.receipt_long_rounded,
        color: _C.primary,
        actual: numVentas.toDouble(),
        anterior: numVentasAnt.toDouble(),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i != tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _kpiTrendTile(
    BuildContext context,
    _P p, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double actual,
    required double anterior,
  }) {
    double? pct;
    if (anterior > 0) {
      pct = (((actual - anterior) / anterior) * 100).toDouble();
    }

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
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              if (pct != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (pct >= 0 ? _C.success : _C.danger)
                        .withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pct >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: pct >= 0 ? _C.success : _C.danger,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${pct.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: pct >= 0 ? _C.success : _C.danger,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '—',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: p.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightsPanel(
      BuildContext context, _P p, List<Map<String, dynamic>> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
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
                child: const Icon(Icons.lightbulb_rounded,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Insights inteligentes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(p.dark ? .16 : .10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${insights.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _C.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.take(4).map((i) {
            final color = i['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(p.dark ? .10 : .06),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: color.withOpacity(.22)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                      child:
                          Icon(i['icon'] as IconData, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i['titulo'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: p.textHigh,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            i['detalle'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chartEvolution(
      BuildContext context, _P p, List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) return const SizedBox.shrink();

    double maxY = 0.0;
    for (final d in datos) {
      final double m = [
        d['ventas'] as double,
        d['gananciaBruta'] as double,
        d['gananciaNeta'] as double,
      ].reduce((a, b) => a > b ? a : b);
      if (m > maxY) maxY = m;
    }
    if (maxY <= 0.0) maxY = 1.0;

    final double maxYFinal = (maxY * 1.2).toDouble();
    final double interval = (maxYFinal / 4).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
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
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: p.glow(_C.primary, o: 0.28),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolución del período',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    Text(
                      '${datos.length} día${datos.length == 1 ? '' : 's'} en vista',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxYFinal,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: p.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: p.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (datos.length / 6).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= datos.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            (datos[i]['periodo'] as String).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: p.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => p.surface3,
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final i = s.x.toInt();
                        final label = i >= 0 && i < datos.length
                            ? DateFormat('dd MMM', 'es')
                                .format(datos[i]['fecha'] as DateTime)
                            : '';
                        return LineTooltipItem(
                          '$label\n\$${_format.format(s.y)}',
                          TextStyle(
                            color: p.textHigh,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  _linea(datos, 'ventas', _C.success),
                  _linea(datos, 'gananciaBruta', _C.orange),
                  _linea(datos, 'gananciaNeta', _C.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _legend(p, _C.success, 'Ventas'),
              _legend(p, _C.orange, 'Ganancia bruta'),
              _legend(p, _C.primary, 'Ganancia neta'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _linea(
      List<Map<String, dynamic>> datos, String key, Color color) {
    return LineChartBarData(
      spots: datos.asMap().entries
          .map((e) => FlSpot(
                e.key.toDouble(),
                (e.value[key] as double)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
              ))
          .toList(),
      isCurved: true,
      curveSmoothness: 0.28,
      color: color,
      barWidth: 2.6,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(.20),
            color.withOpacity(.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _legend(_P p, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: p.textMid,
          ),
        ),
      ],
    );
  }

  Widget _chartHourHeatmap(
      BuildContext context, _P p, List<Map<String, dynamic>> datos) {
    if (datos.isEmpty) return const SizedBox.shrink();

    double maxY = 0.0;
    double total = 0.0;
    for (final d in datos) {
      final v = (d['total'] as double).toDouble();
      if (v > maxY) maxY = v;
      total += v;
    }
    if (maxY <= 0.0) return const SizedBox.shrink();

    int bestIdx = 0;
    for (int i = 0; i < datos.length; i++) {
      if ((datos[i]['total'] as double) == maxY) bestIdx = i;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
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
                  gradient: const LinearGradient(colors: _C.gradWarm),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: p.glow(_C.warning, o: 0.28),
                ),
                child: const Icon(Icons.access_time_filled_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventas por franja horaria',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    Text(
                      'Identifica tus horas más productivas',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(datos.length, (i) {
              final d = datos[i];
              final v = (d['total'] as double).toDouble();
              final ratio = (v / maxY).clamp(0.0, 1.0).toDouble();
              final esMejor = i == bestIdx;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        v > 0 ? '\$${_fmtK(v)}' : '—',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: esMejor ? _C.warning : p.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 600 + i * 60),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: ratio),
                        builder: (_, value, __) => Container(
                          height: 100 * value + 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: esMejor
                                  ? _C.gradWarm
                                  : [
                                      _C.primary
                                          .withOpacity(.35 + 0.55 * ratio),
                                      _C.primary.withOpacity(.08),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: esMejor
                                ? p.glow(_C.warning, o: 0.35)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d['franja'] as String,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              esMejor ? FontWeight.w900 : FontWeight.w700,
                          color: esMejor ? _C.warning : p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .10 : .06),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.primary.withOpacity(.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: _C.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu hora top: ${datos[bestIdx]['franja']} con \$${_format.format(maxY)} (${(maxY / total * 100).toStringAsFixed(0)}% del total)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _estadoResultados(
    BuildContext context,
    _P p,
    double ventas,
    double costo,
    double gananciaBruta,
    double gastos,
    double mermas,
    double gananciaNeta,
    double costoPersonal,
    double impuestoVentas,
    double impuestoUtilidades,
    double totalImpuestos,
    double resultadoFinal,
    double taxaVentas,
    double taxaUtilidades,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
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
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: p.glow(_C.primary, o: 0.28),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de resultados',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    Text(
                      'Resumen contable del período',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _resultBlockLabel('INGRESOS', _C.success, p),
          _resultRow('Ventas brutas', ventas, p, positive: true, bold: true),
          const SizedBox(height: 6),

          _resultBlockLabel('COSTOS', _C.danger, p),
          _resultRow('Costo de ventas (FIFO)', -costo, p, negative: true),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.orange.withOpacity(p.dark ? .12 : .06),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.orange.withOpacity(.24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GANANCIA BRUTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: p.textHigh,
                    ),
                  ),
                ),
                Text(
                  '\$${_format.format(gananciaBruta)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _C.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _resultBlockLabel('GASTOS OPERATIVOS', _C.danger, p),
          _resultRow('Gastos', -gastos, p, negative: true),
          _resultRow('Mermas', -mermas, p, negative: true),
          _resultRow('Costo personal', -costoPersonal, p, negative: true),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .14 : .08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.primary.withOpacity(.30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GANANCIA NETA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: p.textHigh,
                    ),
                  ),
                ),
                Text(
                  '\$${_format.format(gananciaNeta)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _C.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _resultBlockLabel('IMPUESTOS', _C.purple, p),
          _resultRow('Impuesto ventas (${taxaVentas.toStringAsFixed(0)}%)',
              -impuestoVentas, p, negative: true),
          _resultRow(
              'Impuesto utilidades (${taxaUtilidades.toStringAsFixed(0)}%)',
              -impuestoUtilidades,
              p,
              negative: true),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: resultadoFinal >= 0
                    ? _C.gradSuccess
                    : _C.gradDanger,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: p.glow(
                resultadoFinal >= 0 ? _C.success : _C.danger,
                o: 0.32,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'RESULTADO FINAL',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white.withOpacity(.95),
                    ),
                  ),
                ),
                Text(
                  '\$${_format.format(resultadoFinal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBlockLabel(String label, Color color, _P p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    double value,
    _P p, {
    bool positive = false,
    bool negative = false,
    bool bold = false,
  }) {
    final color = value >= 0
        ? (positive ? _C.success : p.textHigh)
        : (negative ? _C.danger : _C.danger);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 12.5 : 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? p.textHigh : p.textMid,
              ),
            ),
          ),
          Text(
            '\$${_format.format(value.abs())}',
            style: TextStyle(
              fontSize: bold ? 13.5 : 12.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              letterSpacing: -0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMetodos(BuildContext context, _P p,
      List<MapEntry<String, double>> metodos, double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.credit_card_rounded, _C.info, 'Métodos de pago',
              'Distribución de ingresos por método', p),
          const SizedBox(height: 14),
          ...metodos.map((e) {
            final pct = total > 0 ? (e.value / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.textHigh,
                          ),
                        ),
                      ),
                      Text(
                        '\$${_format.format(e.value)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.info.withOpacity(p.dark ? .18 : .10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _C.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        Container(height: 6, color: p.border),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: pct),
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: _C.gradBrand),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardGastosCat(BuildContext context, _P p,
      List<MapEntry<String, double>> gastos, double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.receipt_long_rounded, _C.danger,
              'Gastos por categoría', 'Distribución de egresos', p),
          const SizedBox(height: 14),
          ...gastos.take(6).map((e) {
            final pct = total > 0 ? (e.value / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.textHigh,
                          ),
                        ),
                      ),
                      Text(
                        '\$${_format.format(e.value)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.danger.withOpacity(p.dark ? .18 : .10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _C.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        Container(height: 6, color: p.border),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: pct),
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: _C.gradDanger),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardTopProductos(BuildContext context, _P p,
      List<Map<String, dynamic>> productos, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.emoji_events_rounded, _C.gold, 'Productos estrella',
              'Los más vendidos por ingresos', p),
          const SizedBox(height: 14),
          ...productos.take(6).map((prod) {
            final idx = productos.indexOf(prod);
            final isTop = idx == 0;
            final color = isTop ? _C.gold : _C.primary;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isTop
                            ? _C.gradGold
                            : [
                                _C.primary.withOpacity(.18),
                                _C.primary.withOpacity(.04),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isTop ? p.glow(_C.gold, o: 0.32) : null,
                    ),
                    child: isTop
                        ? const Icon(Icons.emoji_events_rounded,
                            size: 17, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod['nombre'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: p.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_fmtNum(prod['cantidad'] as double)} u · \$${_format.format(prod['total'])}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_format.format(prod['ganancia'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _C.success,
                          ),
                        ),
                        Text(
                          'ganancia',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardTopClientes(
      BuildContext context, _P p, List<Map<String, dynamic>> clientes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.people_alt_rounded, _C.purple, 'Mejores clientes',
              'Ranking por volumen de compra', p),
          const SizedBox(height: 14),
          ...clientes.map((cli) {
            final idx = clientes.indexOf(cli);
            final isTop = idx == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isTop ? _C.gold : _C.purple).withOpacity(.22),
                          (isTop ? _C.gold : _C.purple).withOpacity(.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isTop ? _C.gold : _C.purple)
                            .withOpacity(.28),
                      ),
                    ),
                    child: Text(
                      (cli['nombre'] as String)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isTop ? _C.gold : _C.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cli['nombre'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                  ),
                  Text(
                    '\$${_format.format(cli['total'])}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: _C.success,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _cardMetas(BuildContext context, AppProvider provider, _P p) {
    final metaDiaria = (provider.meta?.metaDiaria ?? 0).toDouble();
    final metaSemanal = (provider.meta?.metaSemanal ?? 0).toDouble();
    final metaMensual = (provider.meta?.metaMensual ?? 0).toDouble();
    if (metaDiaria == 0 && metaSemanal == 0 && metaMensual == 0) {
      return const SizedBox.shrink();
    }

    final hoy = DateTime.now();
    final hoyIni = DateTime(hoy.year, hoy.month, hoy.day);
    final hoyFin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    final ventasHoy = provider.ventas
        .where((v) =>
            v.fecha.isAfter(hoyIni) &&
            v.fecha.isBefore(hoyFin) &&
            (_sucursalSeleccionada == null ||
                v.sucursalId == _sucursalSeleccionada))
        .fold(0.0, (s, v) => s + v.total)
        .toDouble();

    final semIni = provider.inicioSemana;
    final semFin = provider.finSemana;
    final ventasSem = provider.ventas
        .where((v) =>
            v.fecha.isAfter(semIni) &&
            v.fecha.isBefore(semFin) &&
            (_sucursalSeleccionada == null ||
                v.sucursalId == _sucursalSeleccionada))
        .fold(0.0, (s, v) => s + v.total)
        .toDouble();

    final mesIni = provider.inicioMes;
    final mesFin = provider.finMes;
    final ventasMes = provider.ventas
        .where((v) =>
            v.fecha.isAfter(mesIni) &&
            v.fecha.isBefore(mesFin) &&
            (_sucursalSeleccionada == null ||
                v.sucursalId == _sucursalSeleccionada))
        .fold(0.0, (s, v) => s + v.total)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.flag_rounded, _C.cyan, 'Progreso de metas',
              'Avance hacia tus objetivos', p),
          const SizedBox(height: 16),
          if (metaDiaria > 0)
            _metaBar('Diaria', ventasHoy, metaDiaria, _C.primary, p),
          if (metaSemanal > 0) ...[
            const SizedBox(height: 12),
            _metaBar('Semanal', ventasSem, metaSemanal, _C.cyan, p),
          ],
          if (metaMensual > 0) ...[
            const SizedBox(height: 12),
            _metaBar('Mensual', ventasMes, metaMensual, _C.purple, p),
          ],
        ],
      ),
    );
  }

  Widget _metaBar(
      String label, double actual, double meta, Color color, _P p) {
    final pct = (actual / meta).clamp(0.0, 1.0).toDouble();
    final alcanzada = actual >= meta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
            const SizedBox(width: 8),
            if (alcanzada)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradSuccess),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓ LOGRADA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            Text(
              '\$${_format.format(actual)} / \$${_format.format(meta)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 8, color: p.border),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: pct),
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: alcanzada
                            ? _C.gradSuccess
                            : [color, color.withOpacity(.65)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(pct * 100).toStringAsFixed(0)}% completado',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: alcanzada ? _C.success : p.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _cardVendedores(
      BuildContext context, AppProvider provider, _P p) {
    return FutureBuilder<List<EstadisticasVendedor>>(
      future: provider.getEstadisticasVendedores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final stats = snapshot.data!.take(5).toList();
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardTitle(Icons.leaderboard_rounded, _C.indigo,
                  'Rendimiento de vendedores', 'Top performers', p),
              const SizedBox(height: 14),
              ...stats.map((s) {
                final idx = stats.indexOf(s);
                final isTop = idx == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (isTop ? _C.gold : _C.indigo).withOpacity(.22),
                              (isTop ? _C.gold : _C.indigo).withOpacity(.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isTop ? _C.gold : _C.indigo)
                                .withOpacity(.28),
                          ),
                        ),
                        child: Text(
                          s.email.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isTop ? _C.gold : _C.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: p.textHigh,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.totalVentas} ventas · \$${_format.format(s.totalMonto)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${_format.format(s.totalGanancia)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: _C.success,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _cardGastosRecientes(
      BuildContext context, _P p, List<Gasto> gastos) {
    if (gastos.isEmpty) return const SizedBox.shrink();
    final recientes = gastos.reversed.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.history_rounded, _C.orange, 'Gastos recientes',
              'Últimos egresos del período', p),
          const SizedBox(height: 14),
          ...recientes.map((g) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _C.danger.withOpacity(p.dark ? .14 : .08),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: _C.danger.withOpacity(.22)),
                      ),
                      child: const Icon(Icons.money_off_rounded,
                          size: 16, color: _C.danger),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.concepto,
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
                            '${g.categoria} · ${DateFormat('dd/MM/yy').format(g.fecha)}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-\$${_format.format(g.monto)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: _C.danger,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _cardTitle(
      IconData icon, Color color, String title, String subtitle, _P p) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(.22), color.withOpacity(.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.28)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 17, color: color),
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
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtK(double n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _fmtNum(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  Future<void> _exportarPDF(BuildContext context, AppProvider provider) async {
    if (provider.rol != 'dueno' && provider.rol != 'admin') {
      mostrarSnackBar(
          mensaje: 'Solo administradores pueden exportar', esExito: false);
      return;
    }
    if (provider.plan != 'premium') {
      mostrarSnackBar(
          mensaje: 'Plan Premium requerido', esExito: false);
      return;
    }
    setState(() => _cargando = true);
    try {
      final pdf = await _construirPDF(provider);
      final bytes = await pdf.save();
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name:
                'Reporte_${DateFormat('yyyyMMdd').format(_fechaInicio)}_${DateFormat('yyyyMMdd').format(_fechaFin)}.pdf',
          ),
        ],
        text: 'Reporte profesional · ${provider.nombreEmpresa ?? ''}',
      );
      mostrarSnackBar(mensaje: 'PDF exportado', esExito: true);
    } catch (e) {
      mostrarSnackBar(mensaje: 'Error: $e', esExito: false);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<pw.Document> _construirPDF(AppProvider provider) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    final double ventas = _ventas(provider);
    final double costo = _costo(provider);
    final double gananciaBruta = _gananciaBruta(provider);
    final double gastos = _gastos(provider);
    final double mermas = _mermas(provider);
    final double gananciaNeta = _gananciaNeta(provider);
    final double costoPersonal = _costoPersonal(provider);
    final double taxaVentas = provider.taxaVentas.toDouble();
    final double taxaUtilidades = provider.taxaUtilidades.toDouble();
    final double impuestoVentas = (ventas * (taxaVentas / 100)).toDouble();
    final double impuestoUtilidades = gananciaNeta > 0
        ? (gananciaNeta * (taxaUtilidades / 100)).toDouble()
        : 0.0;
    final double totalImpuestos =
        (impuestoVentas + impuestoUtilidades).toDouble();
    final double resultadoFinal =
        (gananciaNeta - totalImpuestos).toDouble();

    final topProd = _topProductos(provider).take(10).toList();
    final topCli = _topClientes(provider);

    final gastosPorCat = <String, double>{};
    for (final g in _gastosPeriodo(provider)) {
      gastosPorCat[g.categoria] =
          (gastosPorCat[g.categoria] ?? 0.0) + g.monto;
    }
    final listaGastosCat = gastosPorCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final metodos = <String, double>{};
    for (final v in _ventasPeriodo(provider)) {
      metodos[v.metodoPago] = (metodos[v.metodoPago] ?? 0.0) + v.total;
    }
    final listaMetodos = metodos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final navy = PdfColor.fromInt(0xFF0A1A33);
    final primary = PdfColor.fromInt(0xFF1A5CFF);
    final cyan = PdfColor.fromInt(0xFF06B6D4);
    final gray = PdfColors.grey700;
    final lightGray = PdfColors.grey200;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: lightGray, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Nexora Business · ${provider.nombreEmpresa ?? ''}',
                style: pw.TextStyle(fontSize: 8, color: gray),
              ),
              pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: gray),
              ),
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primary, cyan],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 54,
                    height: 54,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(logo, fit: pw.BoxFit.cover),
                  ),
                if (logo != null) pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        provider.nombreEmpresa ?? 'Mi Empresa',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Reporte de gestión',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      DateFormat('dd/MM/yyyy').format(_fechaInicio),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'al ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(20)),
                      ),
                      child: pw.Text(
                        _periodoTipo.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          _pdfSectionTitle('RESUMEN EJECUTIVO', primary),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _pdfKpiCard('Ventas', '\$${_format.format(ventas)}', primary),
              pw.SizedBox(width: 8),
              _pdfKpiCard('Ganancia neta', '\$${_format.format(gananciaNeta)}',
                  PdfColor.fromInt(0xFF06B6D4)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _pdfKpiCard('Gastos', '\$${_format.format(gastos)}',
                  PdfColor.fromInt(0xFFEF4444)),
              pw.SizedBox(width: 8),
              _pdfKpiCard('Resultado final',
                  '\$${_format.format(resultadoFinal)}',
                  PdfColor.fromInt(0xFF10B981)),
            ],
          ),
          pw.SizedBox(height: 20),

          _pdfSectionTitle('ESTADO DE RESULTADOS', primary),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: lightGray, width: 0.5),
            ),
            child: pw.Column(
              children: [
                _pdfRow('Ingresos (Ventas)', ventas, bold: true, color: navy),
                pw.Divider(color: lightGray, height: 12),
                _pdfRow('Costo de ventas (FIFO)', -costo, color: gray),
                _pdfRow('Ganancia bruta', gananciaBruta,
                    bold: true, color: primary),
                pw.Divider(color: lightGray, height: 12),
                _pdfRow('Gastos operativos', -gastos, color: gray),
                _pdfRow('Mermas', -mermas, color: gray),
                _pdfRow('Costo de personal', -costoPersonal, color: gray),
                _pdfRow('Ganancia neta', gananciaNeta,
                    bold: true, color: primary),
                pw.Divider(color: lightGray, height: 12),
                _pdfRow(
                    'Impuesto ventas (${taxaVentas.toStringAsFixed(0)}%)',
                    -impuestoVentas,
                    color: gray),
                _pdfRow(
                    'Impuesto utilidades (${taxaUtilidades.toStringAsFixed(0)}%)',
                    -impuestoUtilidades,
                    color: gray),
                pw.Divider(color: lightGray, height: 12),
                _pdfRow('RESULTADO FINAL', resultadoFinal,
                    bold: true, color: PdfColor.fromInt(0xFF10B981)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          if (listaMetodos.isNotEmpty) ...[
            _pdfSectionTitle('MÉTODOS DE PAGO', primary),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: lightGray, width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
              },
              children: [
                _pdfTableHeader(['Método', 'Total', '%']),
                ...listaMetodos.map((m) {
                  final pct = ventas > 0 ? (m.value / ventas) * 100 : 0.0;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(m.key, align: pw.TextAlign.left),
                      _pdfTableCell('\$${_format.format(m.value)}'),
                      _pdfTableCell('${pct.toStringAsFixed(1)}%'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          if (topProd.isNotEmpty) ...[
            _pdfSectionTitle('TOP 10 PRODUCTOS', primary),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: lightGray, width: 0.5),
              columnWidths: {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                _pdfTableHeader(
                    ['#', 'Producto', 'Cant.', 'Total', 'Ganancia']),
                ...topProd.asMap().entries.map((entry) {
                  final i = entry.key;
                  final prod = entry.value;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell('${i + 1}',
                          align: pw.TextAlign.center),
                      _pdfTableCell(prod['nombre'] as String,
                          align: pw.TextAlign.left),
                      _pdfTableCell(_fmtNum(prod['cantidad'] as double)),
                      _pdfTableCell('\$${_format.format(prod['total'])}'),
                      _pdfTableCell(
                          '\$${_format.format(prod['ganancia'])}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          if (topCli.isNotEmpty) ...[
            _pdfSectionTitle('MEJORES CLIENTES', primary),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: lightGray, width: 0.5),
              columnWidths: {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(3),
              },
              children: [
                _pdfTableHeader(['#', 'Cliente', 'Total']),
                ...topCli.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cli = entry.value;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell('${i + 1}',
                          align: pw.TextAlign.center),
                      _pdfTableCell(cli['nombre'] as String,
                          align: pw.TextAlign.left),
                      _pdfTableCell('\$${_format.format(cli['total'])}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          if (listaGastosCat.isNotEmpty) ...[
            _pdfSectionTitle('GASTOS POR CATEGORÍA', primary),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: lightGray, width: 0.5),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
              },
              children: [
                _pdfTableHeader(['Categoría', 'Total', '%']),
                ...listaGastosCat.map((e) {
                  final pct = gastos > 0 ? (e.value / gastos) * 100 : 0.0;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(e.key, align: pw.TextAlign.left),
                      _pdfTableCell('\$${_format.format(e.value)}'),
                      _pdfTableCell('${pct.toStringAsFixed(1)}%'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Documento generado automáticamente',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: gray,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Fecha de emisión: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}  ·  '
                  'Sistema: Nexora Business  ·  '
                  'Este reporte tiene fines informativos y no sustituye asesoría contable profesional.',
                  style: pw.TextStyle(fontSize: 7.5, color: gray),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 0.5, color: navy),
                  pw.SizedBox(height: 4),
                  pw.Text('Firma del responsable',
                      style: pw.TextStyle(fontSize: 8, color: gray)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 0.5, color: navy),
                  pw.SizedBox(height: 4),
                  pw.Text('Sello de la empresa',
                      style: pw.TextStyle(fontSize: 8, color: gray)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return pdf;
  }

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: color, width: 3),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _pdfKpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfRow(String label, double value,
      {bool bold = false, required PdfColor color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 10 : 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            '\$${_format.format(value.abs())}',
            style: pw.TextStyle(
              fontSize: bold ? 10 : 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _pdfTableHeader(List<String> cols) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey200),
      children: cols
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  c,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _pdfTableCell(String text,
      {pw.TextAlign align = pw.TextAlign.right}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
        textAlign: align,
      ),
    );
  }

  Future<void> _generarLibroONAT(
      BuildContext context, AppProvider provider) async {
    if (provider.rol != 'dueno' && provider.rol != 'admin') {
      mostrarSnackBar(mensaje: 'Solo administradores', esExito: false);
      return;
    }
    setState(() => _cargando = true);
    try {
      final eventos =
          provider.generarLibroIngresosGastos(_fechaInicio, _fechaFin);
      if (eventos.isEmpty) {
        mostrarSnackBar(mensaje: 'Sin datos en el período', esExito: false);
        setState(() => _cargando = false);
        return;
      }

      final pdf = pw.Document();
      pw.MemoryImage? logo;
      try {
        final bytes = await rootBundle.load('assets/logo.png');
        logo = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}

      final primary = PdfColor.fromInt(0xFF1A5CFF);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          footer: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Libro de Ingresos y Gastos',
                    style:
                        pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                    style:
                        pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ],
            ),
          ),
          build: (ctx) => [
            pw.Center(
              child: pw.Column(
                children: [
                  if (logo != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'LIBRO DE INGRESOS Y GASTOS',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    provider.nombreEmpresa ?? 'Mi Empresa',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Período: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} — ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 18),
                ],
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey500, width: 0.5),
              columnWidths: {
                0: pw.FixedColumnWidth(60),
                1: pw.FlexColumnWidth(4),
                2: pw.FixedColumnWidth(72),
                3: pw.FixedColumnWidth(72),
                4: pw.FixedColumnWidth(72),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell('Fecha', align: pw.TextAlign.center),
                    _pdfTableCell('Concepto',
                        align: pw.TextAlign.center),
                    _pdfTableCell('Ingreso (\$)',
                        align: pw.TextAlign.center),
                    _pdfTableCell('Gasto (\$)',
                        align: pw.TextAlign.center),
                    _pdfTableCell('Saldo (\$)',
                        align: pw.TextAlign.center),
                  ],
                ),
                ...eventos.map((e) {
                  final fecha =
                      DateFormat('dd/MM/yyyy').format(e['fecha'] as DateTime);
                  final concepto = e['concepto'] as String;
                  final recorte = concepto.length > 45
                      ? '${concepto.substring(0, 42)}...'
                      : concepto;
                  final ingreso = e['ingreso'] as double;
                  final gasto = e['gasto'] as double;
                  final saldo = e['saldo'] as double;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(fecha, align: pw.TextAlign.center),
                      _pdfTableCell(recorte, align: pw.TextAlign.left),
                      _pdfTableCell(
                          ingreso > 0 ? _format.format(ingreso) : ''),
                      _pdfTableCell(
                          gasto > 0 ? _format.format(gasto) : ''),
                      _pdfTableCell(_format.format(saldo)),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTableCell('', align: pw.TextAlign.center),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TOTALES',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          )),
                    ),
                    _pdfTableCell(
                      _format.format(eventos.fold<double>(
                          0, (s, e) => s + (e['ingreso'] as double))),
                    ),
                    _pdfTableCell(
                      _format.format(eventos.fold<double>(
                          0, (s, e) => s + (e['gasto'] as double))),
                    ),
                    _pdfTableCell(
                      eventos.isNotEmpty
                          ? _format.format(eventos.last['saldo'] as double)
                          : '0.00',
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Container(width: 140, height: 0.5, color: PdfColors.grey700),
                  pw.SizedBox(height: 4),
                  pw.Text('Firma del Contador',
                      style: const pw.TextStyle(fontSize: 9)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 140, height: 0.5, color: PdfColors.grey700),
                  pw.SizedBox(height: 4),
                  pw.Text('Sello de la Empresa',
                      style: const pw.TextStyle(fontSize: 9)),
                ]),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name:
                'Libro_ONAT_${DateFormat('yyyyMMdd').format(_fechaInicio)}.pdf',
          ),
        ],
        text: 'Libro de Ingresos y Gastos',
      );
      mostrarSnackBar(mensaje: 'Libro ONAT generado', esExito: true);
    } catch (e) {
      mostrarSnackBar(mensaje: 'Error: $e', esExito: false);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _exportarExcel(BuildContext context, AppProvider provider) async {
    if (provider.rol != 'dueno' && provider.rol != 'admin') return;
    if (provider.plan != 'premium') return;
    setState(() => _cargando = true);
    try {
      final excelFile = excel.Excel.createExcel();

      final sheetRes = excelFile['Resumen'];
      sheetRes.appendRow(['RESUMEN FINANCIERO']);
      sheetRes.appendRow([
        'Período',
        '${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}'
      ]);
      sheetRes.appendRow([]);
      sheetRes.appendRow(['Métrica', 'Valor']);
      sheetRes.appendRow(['Ventas', _ventas(provider)]);
      sheetRes.appendRow(['Costo', _costo(provider)]);
      sheetRes.appendRow(['Ganancia bruta', _gananciaBruta(provider)]);
      sheetRes.appendRow(['Gastos', _gastos(provider)]);
      sheetRes.appendRow(['Mermas', _mermas(provider)]);
      sheetRes.appendRow(['Ganancia neta', _gananciaNeta(provider)]);

      final sheetProd = excelFile['Top productos'];
      sheetProd.appendRow(
          ['Producto', 'Cantidad', 'Total', 'Costo', 'Ganancia']);
      for (final p in _topProductos(provider)) {
        sheetProd.appendRow([
          p['nombre'],
          p['cantidad'],
          p['total'],
          p['costo'],
          p['ganancia'],
        ]);
      }

      final sheetMet = excelFile['Métodos de pago'];
      sheetMet.appendRow(['Método', 'Total']);
      final metodos = <String, double>{};
      for (final v in _ventasPeriodo(provider)) {
        metodos[v.metodoPago] = (metodos[v.metodoPago] ?? 0.0) + v.total;
      }
      metodos.forEach((k, v) => sheetMet.appendRow([k, v]));

      final sheetGastos = excelFile['Gastos'];
      sheetGastos.appendRow(['Concepto', 'Categoría', 'Monto', 'Fecha']);
      for (final g in _gastosPeriodo(provider)) {
        sheetGastos.appendRow([
          g.concepto,
          g.categoria,
          g.monto,
          DateFormat('dd/MM/yyyy').format(g.fecha),
        ]);
      }

      final bytes = excelFile.save();
      if (bytes != null) {
        await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name:
                  'Reporte_${DateFormat('yyyyMMdd').format(_fechaInicio)}.xlsx',
            ),
          ],
          text: 'Reporte Excel',
        );
        mostrarSnackBar(mensaje: 'Excel exportado', esExito: true);
      }
    } catch (e) {
      mostrarSnackBar(mensaje: 'Error: $e', esExito: false);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _exportarCSV(BuildContext context, AppProvider provider) async {
    if (provider.rol != 'dueno' && provider.rol != 'admin') return;
    if (provider.plan != 'premium') return;
    setState(() => _cargando = true);
    try {
      String csv = 'Producto,Cantidad,Total,Costo,Ganancia\n';
      for (final p in _topProductos(provider)) {
        csv +=
            '"${p['nombre']}",${p['cantidad']},${p['total']},${p['costo']},${p['ganancia']}\n';
      }
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(csv.codeUnits),
            mimeType: 'text/csv',
            name:
                'Reporte_${DateFormat('yyyyMMdd').format(_fechaInicio)}.csv',
          ),
        ],
        text: 'Reporte CSV',
      );
      mostrarSnackBar(mensaje: 'CSV exportado', esExito: true);
    } catch (e) {
      mostrarSnackBar(mensaje: 'Error: $e', esExito: false);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _imprimirReporte(
      BuildContext context, AppProvider provider) async {
    final reporte = provider.generarReporteTexto(_fechaInicio, _fechaFin);
    await Share.share(reporte);
  }
}