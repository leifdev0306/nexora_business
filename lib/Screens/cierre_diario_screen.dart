// ============================================================
//  cierre_diario_screen.dart  ·  NEXORA BUSINESS
//  Cierre diario: captura stock inicial, introduce stock final
//  producto por producto y genera ventas por diferencia.
//  Diseño moderno consistente con el resto de la app.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm    = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const gradDanger  = [Color(0xFFEF4444), Color(0xFFEC4899)];
  static const gradGold    = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg          => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface     => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2    => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3    => dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);
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
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
}

class CierreDiarioScreen extends StatefulWidget {
  const CierreDiarioScreen({Key? key}) : super(key: key);

  @override
  State<CierreDiarioScreen> createState() => _CierreDiarioScreenState();
}

class _CierreDiarioScreenState extends State<CierreDiarioScreen> {
  final TextEditingController _stockController = TextEditingController();
  final FocusNode _stockFocus = FocusNode();

  int _currentIndex = 0;
  bool _finalizando = false;
  bool _inicializado = false;
  final Map<String, double> _stockFinal = {};

  String get _keyHoy => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get _keyBorrador => '${_keyHoy}_draft';

  @override
  void initState() {
    super.initState();
    _stockController.addListener(_onStockChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializarDatos());
  }

  @override
  void dispose() {
    _stockController.removeListener(_onStockChanged);
    _stockController.dispose();
    _stockFocus.dispose();
    super.dispose();
  }

  // ============================================================
  //  INICIALIZACIÓN
  // ============================================================
  void _inicializarDatos() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.haySnapshotHoy) {
      setState(() => _inicializado = true);
      return;
    }

    final snap = provider.snapshotHoy!;
    final productos = provider.productosParaCierre;

    Map<dynamic, dynamic> draftMap = {};
    try {
      final draft = provider.cierreDiarioBox.get(_keyBorrador);
      if (draft != null) draftMap = Map<dynamic, dynamic>.from(draft as Map);
    } catch (_) {}

    for (var p in productos) {
      if (draftMap.containsKey(p.id)) {
        _stockFinal[p.id] = (draftMap[p.id] as num).toDouble();
      } else {
        _stockFinal[p.id] = snap[p.id] ?? p.stock;
      }
    }

    _cargarTextoDelActual(productos);
    if (mounted) setState(() => _inicializado = true);
  }

  void _cargarTextoDelActual(List<Producto> productos) {
    if (productos.isEmpty || _currentIndex >= productos.length) return;
    final p = productos[_currentIndex];
    final val = _stockFinal[p.id] ?? p.stock;
    _stockController.text = _formatNum(val);
  }

  // ============================================================
  //  INPUT
  // ============================================================
  void _onStockChanged() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final productos = provider.productosParaCierre;
    if (productos.isEmpty || _currentIndex >= productos.length) return;
    final p = productos[_currentIndex];
    final val = double.tryParse(_stockController.text.replaceAll(',', '.'));
    if (val == null || val < 0) return;
    _stockFinal[p.id] = val;
    _guardarBorrador(provider);
  }

  Future<void> _guardarBorrador(AppProvider provider) async {
    try {
      final map = <String, double>{};
      _stockFinal.forEach((k, v) => map[k] = v);
      await provider.cierreDiarioBox.put(_keyBorrador, map);
    } catch (_) {}
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  // ============================================================
  //  NAVEGACIÓN
  // ============================================================
  void _irA(int index, List<Producto> productos) {
    if (index < 0 || index >= productos.length) return;
    setState(() => _currentIndex = index);
    _cargarTextoDelActual(productos);
    _stockFocus.requestFocus();
  }

  void _anterior(List<Producto> productos) => _irA(_currentIndex - 1, productos);
  void _siguiente(List<Producto> productos) => _irA(_currentIndex + 1, productos);

  // ============================================================
  //  ACCIONES
  // ============================================================
  Future<void> _iniciarDia(AppProvider provider) async {
    try {
      await provider.iniciarDiaCierre();
      if (!mounted) return;
      setState(() {
        _currentIndex = 0;
        _stockFinal.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _inicializarDatos());
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al iniciar día: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> _finalizarCierre(
      AppProvider provider, List<Producto> productos) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        int conVentas = 0;
        _stockFinal.forEach((id, finalVal) {
          final snap = provider.snapshotHoy![id] ?? 0;
          if (snap - finalVal > 0) conVentas++;
        });

        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradSuccess),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Cerrar el día',
                  style: TextStyle(
                      color: p.textHigh,
                      fontWeight: FontWeight.w900,
                      fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se van a registrar las ventas del día usando la '
                'diferencia entre el stock inicial y final.',
                style: TextStyle(color: p.textMid, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.primary.withOpacity(.24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded,
                        color: _C.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Productos con ventas: $conVentas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: _C.danger, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Esta acción no se puede deshacer.',
                    style: TextStyle(
                      color: _C.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Confirmar cierre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        );
      },
    );
    if (confirmado != true) return;

    setState(() => _finalizando = true);
    try {
      final resumen = await provider.cerrarDia(_stockFinal);
      if (!mounted) return;
      try {
        await provider.cierreDiarioBox.delete(_keyBorrador);
      } catch (_) {}
      mostrarSnackBar(
        mensaje:
            '✅ Cierre completado: ${resumen['ventasCreadas']} ventas registradas (\$${(resumen['montoTotal'] as double).toStringAsFixed(2)})',
        esExito: true,
      );
      if (mounted) setState(() {});
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al cerrar: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _finalizando = false);
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

        final p = _P(Theme.of(context).brightness == Brightness.dark);
        final isDesktop = ResponsiveHelper.isDesktop();

        if (!_inicializado) return _buildCargando(p);
        if (!provider.haySnapshotHoy) {
          return _buildBienvenida(provider, p, isDesktop);
        }
        if (provider.diaYaCerrado) {
          return _buildResumenCerrado(provider, p, isDesktop);
        }

        final productos = provider.productosParaCierre;
        if (productos.isEmpty) return _buildSinProductos(p);

        return isDesktop
            ? _buildDesktopLayout(provider, productos, p)
            : _buildMobileLayout(provider, productos, p);
      },
    );
  }

  // ============================================================
  //  CARGANDO
  // ============================================================
  Widget _buildCargando(_P p) {
    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, 'Cierre diario'),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  PreferredSizeWidget _appBar(_P p, String title, {Widget? extra}) {
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
              gradient: const LinearGradient(colors: _C.gradWarm),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.warning.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.wb_sunny_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  )),
              if (extra != null)
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 11,
                    color: p.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  child: extra,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BIENVENIDA
  // ============================================================
  Widget _buildBienvenida(AppProvider provider, _P p, bool isDesktop) {
    final productos = provider.productosFiltrados;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, 'Cierre diario',
          extra: Text(DateFormat('EEEE, d MMMM y', 'es').format(DateTime.now()))),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 620 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: _C.gradWarm,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _C.warning.withOpacity(.42),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(.32), width: 2),
                        ),
                        child: const Icon(Icons.wb_sunny_rounded,
                            size: 46, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '¡Buen día!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Antes de comenzar, captura el stock actual\n'
                        'como punto de partida para el cierre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Colors.white.withOpacity(.92),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info tiles
                _bienvenidaInfo(
                  p,
                  icon: Icons.inventory_2_rounded,
                  label: 'Productos a rastrear',
                  value: '${productos.length}',
                  color: _C.primary,
                ),
                const SizedBox(height: 10),
                _bienvenidaInfo(
                  p,
                  icon: Icons.calendar_today_rounded,
                  label: 'Fecha',
                  value: DateFormat('EEEE, d MMMM y', 'es').format(DateTime.now()),
                  color: _C.info,
                ),
                const SizedBox(height: 16),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.warning.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.warning.withOpacity(.32)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: _C.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Al final del día deberás introducir el stock '
                          'restante. Las ventas se calcularán automáticamente '
                          'por diferencia.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: p.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Botón principal
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _iniciarDia(provider),
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: const Text('Iniciar el día',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
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

  Widget _bienvenidaInfo(_P p,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(.22), color.withOpacity(.06)],
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                )),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: p.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SIN PRODUCTOS
  // ============================================================
  Widget _buildSinProductos(_P p) {
    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, 'Cierre diario'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 38, color: _C.primary),
              ),
              const SizedBox(height: 18),
              Text('No hay productos para cerrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  )),
              const SizedBox(height: 6),
              Text('Agrega productos a tu inventario primero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  LAYOUT MÓVIL
  // ============================================================
  Widget _buildMobileLayout(
      AppProvider provider, List<Producto> productos, _P p) {
    final producto = productos[_currentIndex];
    final stockInicial = provider.snapshotHoy?[producto.id] ?? producto.stock;
    final total = productos.length;
    final progress = total == 0 ? 0.0 : (_currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: true,
      appBar: _appBar(p, 'Cierre del día',
          extra: Text(DateFormat('EEEE, d MMM', 'es').format(DateTime.now()))),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso
            Container(
              color: p.surface,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Producto ${_currentIndex + 1} de $total',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: p.textHigh,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: _C.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: p.border,
                      valueColor:
                          const AlwaysStoppedAnimation(_C.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mobileProductCard(producto, stockInicial, p),
                    const SizedBox(height: 20),
                    Text(
                      'Nuevo stock restante',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Introduce cuántas unidades te quedan al final del día',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                    const SizedBox(height: 14),
                    _buildBigInput(producto, p),
                    const SizedBox(height: 14),
                    _buildQuickActions(producto, stockInicial, p),
                  ],
                ),
              ),
            ),

            // Navegación
            _buildMobileNavigationBar(provider, productos, p),
          ],
        ),
      ),
    );
  }

  Widget _mobileProductCard(
      Producto producto, double stockInicial, _P p) {
    return Container(
      width: double.infinity,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withOpacity(.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    producto.nombre.isNotEmpty
                        ? producto.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unidad: ${producto.unidadMedida}',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
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
                child: _statBadge(
                  p,
                  icon: Icons.play_circle_outline,
                  label: 'Stock inicial',
                  value: _formatNum(stockInicial),
                  color: _C.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBadge(
                  p,
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock actual',
                  value: _formatNum(producto.stock),
                  color: _C.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(_P p,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: p.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigInput(Producto producto, _P p) {
    return TextField(
      controller: _stockController,
      focusNode: _stockFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: p.textHigh,
        letterSpacing: 1,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w900,
          color: p.textMuted.withOpacity(.4),
        ),
        suffixText: producto.unidadMedida,
        suffixStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: p.textMuted,
        ),
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: p.borderStrong, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _C.primary, width: 3),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      ),
    );
  }

  Widget _buildQuickActions(
      Producto producto, double stockInicial, _P p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _quickChip(p,
            label: 'Igual al inicial',
            icon: Icons.repeat_rounded,
            onTap: () {
              _stockController.text = _formatNum(stockInicial);
            }),
        _quickChip(p,
            label: 'Mitad',
            icon: Icons.percent_rounded,
            onTap: () {
              _stockController.text =
                  _formatNum((stockInicial / 2).roundToDouble());
            }),
        _quickChip(p,
            label: 'Cero',
            icon: Icons.remove_circle_outline_rounded,
            color: _C.danger,
            onTap: () => _stockController.text = '0'),
      ],
    );
  }

  Widget _quickChip(_P p,
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      Color? color}) {
    final c = color ?? _C.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: c.withOpacity(.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigationBar(
      AppProvider provider, List<Producto> productos, _P p) {
    final esPrimero = _currentIndex == 0;
    final esUltimo = _currentIndex == productos.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: p.shadowMd,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: esPrimero ? null : () => _anterior(productos),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                  label: const Text('Anterior'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: p.borderStrong),
                    foregroundColor: p.textHigh,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: esUltimo ? null : () => _siguiente(productos),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                  label: const Text('Siguiente'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finalizando
                  ? null
                  : () => _finalizarCierre(provider, productos),
              icon: _finalizando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                _finalizando ? 'Finalizando…' : 'Finalizar cierre del día',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: _C.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  LAYOUT DESKTOP
  // ============================================================
  Widget _buildDesktopLayout(
      AppProvider provider, List<Producto> productos, _P p) {
    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, 'Cierre del día',
          extra: Text(DateFormat('EEEE, d MMMM y', 'es').format(DateTime.now()))),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDesktopSidebar(provider, productos, p),
          Expanded(
            child: _buildDesktopMainPanel(provider, productos, p),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
      AppProvider provider, List<Producto> productos, _P p) {
    final snap = provider.snapshotHoy ?? {};

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
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
                      child: const Icon(Icons.list_alt_rounded,
                          color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${productos.length} en total · ${_currentIndex + 1} de ${productos.length}',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final prod = productos[index];
                final inicial = snap[prod.id] ?? prod.stock;
                final finalVal = _stockFinal[prod.id] ?? inicial;
                final vendidos = inicial - finalVal;
                final esActual = index == _currentIndex;
                final conVenta = vendidos > 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: esActual
                        ? _C.primary.withOpacity(.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _irA(index, productos),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: conVenta
                                    ? const LinearGradient(
                                        colors: _C.gradSuccess)
                                    : null,
                                color: conVenta ? null : p.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: conVenta
                                      ? Colors.transparent
                                      : p.border,
                                ),
                              ),
                              child: Center(
                                child: conVenta
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : Text(
                                        prod.nombre.isNotEmpty
                                            ? prod.nombre[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: p.textHigh,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: esActual
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: p.textHigh,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatNum(inicial)} → ${_formatNum(finalVal)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: p.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (conVenta)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _C.success.withOpacity(.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${_formatNum(vendidos)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _C.success,
                                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMainPanel(
      AppProvider provider, List<Producto> productos, _P p) {
    final producto = productos[_currentIndex];
    final stockInicial = provider.snapshotHoy?[producto.id] ?? producto.stock;
    final finalVal = _stockFinal[producto.id] ?? stockInicial;
    final vendidos = stockInicial - finalVal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera del producto
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _C.gradBrand),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: p.glow(_C.primary, o: 0.32),
                    ),
                    child: Center(
                      child: Text(
                        producto.nombre.isNotEmpty
                            ? producto.nombre[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: p.textHigh,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unidad: ${producto.unidadMedida} · '
                          'Precio venta: \$${producto.precioVenta.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Panel de info
              Row(
                children: [
                  Expanded(
                    child: _desktopInfoTile(
                      p,
                      icon: Icons.play_circle_outline,
                      label: 'Stock inicial',
                      value: _formatNum(stockInicial),
                      color: _C.success,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _desktopInfoTile(
                      p,
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock actual en sistema',
                      value: _formatNum(producto.stock),
                      color: _C.warning,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _desktopInfoTile(
                      p,
                      icon: Icons.trending_down_rounded,
                      label: 'Vendidos (calculado)',
                      value: _formatNum(vendidos > 0 ? vendidos : 0),
                      color: vendidos > 0 ? _C.danger : p.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Input
              Text(
                'Nuevo stock restante',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Introduce cuántas unidades te quedan al final del día',
                style: TextStyle(fontSize: 13, color: p.textMuted),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: p.border),
                  boxShadow: p.shadowSm,
                ),
                child: _buildBigInput(producto, p),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(producto, stockInicial, p),

              const SizedBox(height: 36),
              // Navegación
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        _currentIndex == 0 ? null : () => _anterior(productos),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Anterior'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(150, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      foregroundColor: p.textHigh,
                      side: BorderSide(color: p.borderStrong),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _currentIndex == productos.length - 1
                        ? null
                        : () => _siguiente(productos),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Siguiente'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _finalizando
                        ? null
                        : () => _finalizarCierre(provider, productos),
                    icon: _finalizando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _finalizando
                          ? 'Finalizando…'
                          : 'Finalizar cierre del día',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(260, 52),
                      backgroundColor: _C.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopInfoTile(_P p,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: p.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  RESUMEN DE CIERRE
  // ============================================================
  Widget _buildResumenCerrado(AppProvider provider, _P p, bool isDesktop) {
    final hoy = DateTime.now();
    final ventasCierre = provider.ventas.where((v) {
      if (v.nota == null || !v.nota!.startsWith('Cierre diario')) return false;
      return v.fecha.year == hoy.year &&
          v.fecha.month == hoy.month &&
          v.fecha.day == hoy.day;
    }).toList();

    final totalMonto = ventasCierre.fold<double>(0, (s, v) => s + v.total);
    final totalCosto = ventasCierre.fold<double>(0, (s, v) => s + v.costoTotal);
    final ganancia = totalMonto - totalCosto;
    final numVentas = ventasCierre.length;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, 'Cierre del día completado'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 760 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner éxito
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: _C.gradSuccess,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _C.success.withOpacity(.42),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(.32), width: 2),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 34, color: Colors.white),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Día cerrado!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('EEEE, d MMMM y', 'es').format(hoy),
                              style: TextStyle(
                                color: Colors.white.withOpacity(.92),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // KPIs
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                          child: _resumenKpi(p, 'Ventas registradas',
                              '$numVentas', Icons.receipt_long, _C.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _resumenKpi(p, 'Monto total',
                              '\$${totalMonto.toStringAsFixed(2)}',
                              Icons.attach_money, _C.success)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _resumenKpi(p, 'Ganancia neta',
                              '\$${ganancia.toStringAsFixed(2)}',
                              Icons.trending_up, _C.warning)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _resumenKpi(p, 'Ventas registradas', '$numVentas',
                          Icons.receipt_long, _C.primary),
                      const SizedBox(height: 10),
                      _resumenKpi(p, 'Monto total',
                          '\$${totalMonto.toStringAsFixed(2)}',
                          Icons.attach_money, _C.success),
                      const SizedBox(height: 10),
                      _resumenKpi(p, 'Ganancia neta',
                          '\$${ganancia.toStringAsFixed(2)}',
                          Icons.trending_up, _C.warning),
                    ],
                  ),
                const SizedBox(height: 22),

                // Detalle
                Container(
                  padding: const EdgeInsets.all(18),
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
                              gradient: const LinearGradient(
                                  colors: _C.gradGold),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Detalle de productos vendidos',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: p.textHigh,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (ventasCierre.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No se registraron ventas hoy',
                              style: TextStyle(color: p.textMuted),
                            ),
                          ),
                        )
                      else
                        ...ventasCierre.map((v) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _C.primary.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_formatNum(v.cantidad)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: _C.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      v.productoNombre,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.textHigh,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${v.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: _C.success,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botones
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final texto = _generarResumenTexto(
                                numVentas, totalMonto, ganancia, ventasCierre);
                            Share.share(texto);
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Compartir resumen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            foregroundColor: p.textHigh,
                            side: BorderSide(color: p.borderStrong),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text('Volver al inicio'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final texto = _generarResumenTexto(
                                numVentas, totalMonto, ganancia, ventasCierre);
                            Share.share(texto);
                          },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Compartir resumen'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            foregroundColor: p.textHigh,
                            side: BorderSide(color: p.borderStrong),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text('Volver al inicio'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
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

  Widget _resumenKpi(
      _P p, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(.22), color.withOpacity(.06)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
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

  String _generarResumenTexto(int numVentas, double totalMonto, double ganancia,
      List<Venta> ventas) {
    final sb = StringBuffer();
    sb.writeln(
        '📊 CIERRE DIARIO - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Ventas registradas: $numVentas');
    sb.writeln('Monto total: \$${totalMonto.toStringAsFixed(2)}');
    sb.writeln('Ganancia neta: \$${ganancia.toStringAsFixed(2)}');
    sb.writeln('');
    sb.writeln('Detalle de productos:');
    for (var v in ventas) {
      sb.writeln(
          '• ${v.productoNombre} x${_formatNum(v.cantidad)} = \$${v.total.toStringAsFixed(2)}');
    }
    sb.writeln('');
    sb.writeln('— Generado con $APP_NAME');
    return sb.toString();
  }
}