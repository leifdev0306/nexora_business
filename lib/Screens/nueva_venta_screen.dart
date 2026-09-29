// ============================================================
//  nueva_venta_screen.dart  ·  NEXORA BUSINESS
//  Punto de venta premium · CON IMÁGENES cacheadas
//  · Tarjetas rediseñadas (imagen 55% / info 45%)
//  · Grid desktop compacto: 5/6/7 columnas
//  · Paleta azul eléctrico + cyan
//  · Atajos: Ctrl+K (buscar), F12 / Ctrl+Enter (cobrar), Esc
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nexora_business/responsive_helper.dart';
import 'package:nexora_business/screens/servicio_cancelado_screen.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../widgets/cached_product_image.dart';

// ============================================================
//  Acentos compartidos
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const primaryDk = Color(0xFF4A8BFF);
  static const cyan      = Color(0xFF06B6D4);
  static const cyanDk    = Color(0xFF22D3EE);
  static const success   = Color(0xFF10B981);
  static const danger    = Color(0xFFEF4444);
  static const warning   = Color(0xFFF59E0B);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const pink      = Color(0xFFEC4899);
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
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
}

// ============================================================
//  MODELO ITEM
// ============================================================
class ItemVenta {
  final Key key;
  String? productoId;
  double cantidad;
  double precio;
  bool esMayorista;
  late TextEditingController cantidadController;

  ItemVenta({
    required this.key,
    this.productoId,
    this.cantidad = 1.0,
    this.precio = 0,
    this.esMayorista = false,
  }) {
    cantidadController = TextEditingController(text: cantidad.toString());
  }
}

// ============================================================
//  PANTALLA
// ============================================================
class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({Key? key}) : super(key: key);

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  // ─── Configuración
  String _metodoPago = 'Efectivo CUP';
  final _notaCtrl = TextEditingController();
  String? _clienteId;
  String? _sucursalIdSeleccionada;

  // ─── Carrito
  List<ItemVenta> _items = [];

  // ─── Búsqueda / categorías (desktop)
  final _desktopSearchFocus = FocusNode();
  final _desktopKeyboardFocus = FocusNode();
  String _desktopSearch = '';
  String? _categoriaSeleccionada;

  // ─── Nota visible (desktop)
  bool _mostrarNotaDesktop = false;

  // ─── Transferencia
  final _nombreCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _numeroTransferenciaCtrl = TextEditingController();
  DateTime _fechaHoraTransferencia = DateTime.now();
  bool _transferenciaExpandido = true;

  // ─── Estado
  bool _isSaving = false;

  // ─── Scroll / timers
  final _scrollController = ScrollController();
  final _catalogScrollController = ScrollController();
  Timer? _repeticionTimer;

  bool get _necesitaTransferencia =>
      _metodoPago == 'Transfermóvil' || _metodoPago == 'EnZona';

  @override
  void initState() {
    super.initState();
    _agregarItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.esAdminGlobal && provider.sucursales.isNotEmpty) {
        setState(
            () => _sucursalIdSeleccionada = provider.sucursales.first.id);
      }
      if (mounted) _desktopKeyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _catalogScrollController.dispose();
    _notaCtrl.dispose();
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    _telefonoCtrl.dispose();
    _numeroTransferenciaCtrl.dispose();
    _desktopSearchFocus.dispose();
    _desktopKeyboardFocus.dispose();
    _repeticionTimer?.cancel();
    for (final item in _items) {
      item.cantidadController.dispose();
    }
    super.dispose();
  }

  // ============================================================
  //  LÓGICA DE CARRITO
  // ============================================================
  void _agregarItem() {
    setState(() {
      _items.add(ItemVenta(key: UniqueKey(), cantidad: 1, precio: 0));
    });
  }

  void _eliminarItem(ItemVenta item) {
    if (_items.length <= 1) {
      mostrarSnackBar(
        mensaje: 'Debe haber al menos un producto en la venta',
        esExito: false,
      );
      return;
    }
    setState(() {
      item.cantidadController.dispose();
      _items.remove(item);
    });
  }

  double get _totalGeneral {
    double total = 0;
    for (final item in _items) {
      if (item.cantidad > 0 && item.precio > 0) {
        total += item.cantidad * item.precio;
      }
    }
    return total;
  }

  int get _productosEnCarrito =>
      _items.where((i) => i.productoId != null).length;

  List<Producto> _getProductosDisponibles(AppProvider provider) {
    if (provider.esAdminGlobal && _sucursalIdSeleccionada != null) {
      return provider.productos
          .where((p) => p.sucursalId == _sucursalIdSeleccionada)
          .toList();
    }
    return provider.productosPorSucursal;
  }

  Future<void> _seleccionarProducto(
      ItemVenta item, BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.empresaActiva) {
      mostrarSnackBar(mensaje: 'Servicio cancelado', esExito: false);
      return;
    }

    final productosDisponibles =
        _getProductosDisponibles(provider).where((p) => p.stock > 0).toList();

    final ventasPorProducto = <String, int>{};
    for (final venta in provider.ventas) {
      ventasPorProducto[venta.productoId] =
          (ventasPorProducto[venta.productoId] ?? 0) +
              venta.cantidad.toInt();
    }
    final sortedIds = ventasPorProducto.keys.toList()
      ..sort((a, b) => (ventasPorProducto[b] ?? 0)
          .compareTo(ventasPorProducto[a] ?? 0));
    final top1 = sortedIds.isNotEmpty ? sortedIds.first : null;
    final top5 = sortedIds.take(5).toList();

    final idsSeleccionados = _items
        .where((i) => i != item && i.productoId != null)
        .map((i) => i.productoId!)
        .toList();

    final selected = await showSearch<Producto?>(
      context: context,
      delegate: _ProductoSearchDelegate(
        productosDisponibles,
        idsSeleccionados,
        top1: top1,
        top5: top5,
        provider: provider,
      ),
    );

    if (selected == null) return;

    if (idsSeleccionados.contains(selected.id)) {
      mostrarSnackBar(
        mensaje: 'El producto "${selected.nombre}" ya está agregado.',
        esExito: false,
      );
      return;
    }

    final precio = provider.getPrecioProducto(selected, _metodoPago, false);

    setState(() {
      item.productoId = selected.id;
      item.precio = precio;
      item.cantidad = 1.0;
      item.cantidadController.text = '1';
      item.esMayorista = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _agregarProductoDirecto(Producto producto) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!provider.empresaActiva) {
      mostrarSnackBar(mensaje: 'Servicio cancelado', esExito: false);
      return;
    }
    if (producto.stock <= 0) {
      mostrarSnackBar(
        mensaje: '"${producto.nombre}" está agotado',
        esExito: false,
      );
      return;
    }

    final existente =
        _items.where((i) => i.productoId == producto.id).toList();
    if (existente.isNotEmpty) {
      final item = existente.first;
      final step = _getStepForUnit(producto.unidadMedida);
      final nueva = (item.cantidad + step).clamp(0.0, producto.stock);
      if (nueva > item.cantidad) {
        setState(() {
          item.cantidad = nueva;
          item.cantidadController.text =
              nueva.toStringAsFixed(step % 1 == 0 ? 0 : 1);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        mostrarSnackBar(
          mensaje: 'Stock máximo para "${producto.nombre}"',
          esExito: false,
        );
      }
      return;
    }

    final precio = provider.getPrecioProducto(producto, _metodoPago, false);

    setState(() {
      if (_items.length == 1 && _items.first.productoId == null) {
        final item = _items.first;
        item.productoId = producto.id;
        item.precio = precio;
        item.cantidad = 1;
        item.cantidadController.text = '1';
        item.esMayorista = false;
      } else {
        _items.add(ItemVenta(
          key: UniqueKey(),
          productoId: producto.id,
          cantidad: 1,
          precio: precio,
        ));
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _actualizarPrecios() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      for (final item in _items) {
        if (item.productoId != null) {
          final producto = provider.getProductoById(item.productoId!);
          if (producto != null) {
            item.precio = provider.getPrecioProducto(
              producto,
              _metodoPago,
              item.esMayorista,
            );
          }
        }
      }
    });
  }

  void _actualizarPrecioItem(ItemVenta item) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (item.productoId == null) return;
    final producto = provider.getProductoById(item.productoId!);
    if (producto == null) return;
    setState(() {
      item.precio = provider.getPrecioProducto(
          producto, _metodoPago, item.esMayorista);
    });
  }

  double _getStepForUnit(String unidad) {
    final decimales = ['kg', 'g', 'lb', 'L', 'mL', 'm', 'cm'];
    return decimales.contains(unidad) ? 0.5 : 1.0;
  }

  void _incrementarCantidad(ItemVenta item, Producto producto) {
    final step = _getStepForUnit(producto.unidadMedida);
    setState(() {
      item.cantidad =
          (item.cantidad + step).clamp(0.0, producto.stock);
      item.cantidadController.text =
          item.cantidad.toStringAsFixed(step % 1 == 0 ? 0 : 1);
    });
  }

  void _decrementarCantidad(ItemVenta item, Producto producto) {
    final step = _getStepForUnit(producto.unidadMedida);
    setState(() {
      item.cantidad =
          (item.cantidad - step).clamp(0.0, producto.stock);
      item.cantidadController.text =
          item.cantidad.toStringAsFixed(step % 1 == 0 ? 0 : 1);
    });
  }

  void _startRepetir({
    required bool incrementar,
    required ItemVenta item,
    required Producto producto,
  }) {
    _repeticionTimer?.cancel();
    _repeticionTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (_) {
        if (incrementar) {
          _incrementarCantidad(item, producto);
        } else {
          _decrementarCantidad(item, producto);
        }
      },
    );
  }

  void _stopRepetir() {
    _repeticionTimer?.cancel();
    _repeticionTimer = null;
  }

  Future<void> _agregarProductoRapido(BuildContext context) async {
    ItemVenta item;
    if (_items.isEmpty || _items.last.productoId == null) {
      if (_items.isEmpty) _agregarItem();
      item = _items.last;
    } else {
      _agregarItem();
      item = _items.last;
    }
    await _seleccionarProducto(item, context);
  }

  // ============================================================
  //  PRODUCTOS / CATEGORÍAS DESKTOP
  // ============================================================
  List<Producto> _productosDesktop(AppProvider provider) {
    List<Producto> base;
    if (provider.esAdminGlobal && _sucursalIdSeleccionada != null) {
      base = provider.productos
          .where((p) => p.sucursalId == _sucursalIdSeleccionada)
          .toList();
    } else {
      base = provider.productosPorSucursal;
    }

    var productos = base.toList();
    final q = _desktopSearch.trim().toLowerCase();
    if (q.isNotEmpty) {
      productos = productos.where((p) {
        final n = p.nombre.toLowerCase();
        final c =
            provider.getNombreCategoria(p.categoriaId).toLowerCase();
        final sku = (p.sku ?? '').toLowerCase();
        return n.contains(q) || c.contains(q) || sku.contains(q);
      }).toList();
    }
    if (_categoriaSeleccionada != null) {
      productos = productos
          .where((p) => p.categoriaId == _categoriaSeleccionada)
          .toList();
    }

    final ventasPorProd = <String, int>{};
    for (final v in provider.ventas) {
      ventasPorProd[v.productoId] =
          (ventasPorProd[v.productoId] ?? 0) + v.cantidad.toInt();
    }
    productos.sort((a, b) {
      final va = ventasPorProd[a.id] ?? 0;
      final vb = ventasPorProd[b.id] ?? 0;
      if (va != vb) return vb.compareTo(va);
      return a.nombre.compareTo(b.nombre);
    });
    return productos;
  }

  List<String> _categoriasDesktop(AppProvider provider) {
    List<Producto> base;
    if (provider.esAdminGlobal && _sucursalIdSeleccionada != null) {
      base = provider.productos
          .where((p) => p.sucursalId == _sucursalIdSeleccionada)
          .toList();
    } else {
      base = provider.productosPorSucursal;
    }
    final cats = <String>{};
    for (final p in base) {
      if (p.categoriaId != null && p.categoriaId!.isNotEmpty) {
        cats.add(p.categoriaId!);
      }
    }
    return cats.toList();
  }

  void _limpiarVenta() {
    for (final item in _items) {
      item.cantidadController.dispose();
    }
    setState(() {
      _items = [ItemVenta(key: UniqueKey(), cantidad: 1, precio: 0)];
      _clienteId = null;
      _notaCtrl.clear();
      _mostrarNotaDesktop = false;
      _nombreCtrl.clear();
      _ciCtrl.clear();
      _telefonoCtrl.clear();
      _numeroTransferenciaCtrl.clear();
      _fechaHoraTransferencia = DateTime.now();
    });
  }

  void _manejarTecladoDesktop(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    final isCtrl = event.isControlPressed || event.isMetaPressed;

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      _desktopSearchFocus.requestFocus();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.f12 ||
        (isCtrl && event.logicalKey == LogicalKeyboardKey.enter)) {
      _registrarVenta();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _desktopSearch = '');
      _desktopSearchFocus.unfocus();
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: p.bg,
          body: Stack(
            children: [
              Positioned(
                top: -180,
                right: -160,
                child: IgnorePointer(
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _C.primary.withOpacity(p.dark ? .13 : .06),
                          _C.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: isDesktop
                    ? _buildDesktop(context, provider, p)
                    : _buildMobile(context, provider, p),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  //  DESKTOP
  // ============================================================
  Widget _buildDesktop(
      BuildContext context, AppProvider provider, _P p) {
    return RawKeyboardListener(
      focusNode: _desktopKeyboardFocus,
      onKey: _manejarTecladoDesktop,
      child: Column(
        children: [
          _desktopHeader(context, provider, p),
          _desktopConfigBar(context, provider, p),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _desktopCatalog(context, provider, p),
                ),
                Container(width: 1, color: p.border),
                SizedBox(
                  width: MediaQuery.of(context).size.width >= 1700
                      ? 500
                      : (MediaQuery.of(context).size.width >= 1400
                          ? 450
                          : 400),
                  child: _desktopCart(context, provider, p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER DESKTOP
  Widget _desktopHeader(
      BuildContext context, AppProvider provider, _P p) {
    final nombreCliente = _clienteId != null
        ? provider.clientes.firstWhere((c) => c.id == _clienteId).nombre
        : 'Consumidor final';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: p.textMid),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _C.gradBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: p.glow(_C.primary, o: 0.28),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva venta',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                  color: p.textHigh,
                ),
              ),
              Text(
                'Punto de venta · Nexora Business',
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: _clienteId != null
                ? _C.primary.withOpacity(p.dark ? .16 : .10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _mostrarClienteDesktop(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _clienteId != null
                        ? _C.primary.withOpacity(.35)
                        : p.borderStrong,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _clienteId != null
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 16,
                      color: _clienteId != null ? _C.primary : p.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _clienteId != null
                          ? nombreCliente
                          : 'Consumidor final',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            _clienteId != null ? _C.primary : p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Nota',
            onPressed: () => setState(
                () => _mostrarNotaDesktop = !_mostrarNotaDesktop),
            icon: Icon(
              _mostrarNotaDesktop
                  ? Icons.notes_rounded
                  : Icons.notes_outlined,
              size: 20,
              color: _mostrarNotaDesktop ? _C.primary : p.textMuted,
            ),
          ),
          IconButton(
            tooltip: 'Limpiar venta',
            onPressed: _limpiarVenta,
            icon: Icon(Icons.refresh_rounded, size: 20, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── CONFIG BAR DESKTOP
  Widget _desktopConfigBar(
      BuildContext context, AppProvider provider, _P p) {
    final esAdmin = provider.esAdminGlobal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          _configChip(
            icon: Icons.payments_rounded,
            label: _metodoPago,
            onTap: () => _mostrarMetodoPagoDesktop(context),
            p: p,
          ),
          const SizedBox(width: 10),
          if (esAdmin) _sucursalDropdown(context, provider, p),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .16 : .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded,
                    size: 14, color: _C.primary),
                const SizedBox(width: 6),
                Text(
                  '$_productosEnCarrito',
                  style: const TextStyle(
                    color: _C.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _configChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required _P p,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _C.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sucursalDropdown(
      BuildContext context, AppProvider provider, _P p) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.borderStrong),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sucursalIdSeleccionada,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: p.textMuted),
          dropdownColor: p.surface,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: p.textHigh,
          ),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _sucursalIdSeleccionada = v;
              _desktopSearch = '';
              _categoriaSeleccionada = null;
            });
          },
          items: provider.sucursales.map((s) {
            return DropdownMenuItem<String>(
              value: s.id,
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 14, color: _C.primary),
                  const SizedBox(width: 6),
                  Text(s.nombre),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── CATALOG DESKTOP
  Widget _desktopCatalog(
      BuildContext context, AppProvider provider, _P p) {
    final productos = _productosDesktop(provider);
    final categorias = _categoriasDesktop(provider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: p.borderStrong),
                  ),
                  child: TextField(
                    focusNode: _desktopSearchFocus,
                    onChanged: (v) =>
                        setState(() => _desktopSearch = v),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: p.textHigh,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 19, color: p.textMuted),
                      hintText: 'Buscar producto (Ctrl+K)…',
                      hintStyle: TextStyle(
                          fontSize: 13, color: p.textMuted),
                      suffixIcon: _desktopSearch.isNotEmpty
                          ? IconButton(
                              onPressed: () =>
                                  setState(() => _desktopSearch = ''),
                              icon: Icon(Icons.close_rounded,
                                  size: 17, color: p.textMuted),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(p.dark ? .16 : .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded,
                        size: 16, color: _C.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${productos.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _C.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip(
                  label: 'Todos',
                  selected: _categoriaSeleccionada == null,
                  onTap: () =>
                      setState(() => _categoriaSeleccionada = null),
                  p: p,
                ),
                ...categorias.map(
                  (id) => _categoryChip(
                    label: provider.getNombreCategoria(id),
                    selected: _categoriaSeleccionada == id,
                    onTap: () =>
                        setState(() => _categoriaSeleccionada = id),
                    p: p,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: productos.isEmpty
                ? _emptyCatalog(p)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Tarjetas compactas:
                      //   7 cols ≥ 1700px
                      //   6 cols ≥ 1450px
                      //   5 cols ≥ 1150px
                      //   4 cols ≥  880px
                      //   3 cols ≥  620px
                      //   2 cols <  620px
                      final cols = constraints.maxWidth >= 1700
                          ? 7
                          : (constraints.maxWidth >= 1450
                              ? 6
                              : (constraints.maxWidth >= 1150
                                  ? 5
                                  : (constraints.maxWidth >= 880
                                      ? 4
                                      : (constraints.maxWidth >= 620
                                          ? 3
                                          : 2))));
                      return GridView.builder(
                        controller: _catalogScrollController,
                        padding: const EdgeInsets.only(bottom: 10),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (_, i) => _productCardDesktop(
                          context,
                          productos[i],
                          provider,
                          p,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required _P p,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.transparent : p.surface,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
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
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : p.textMid,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── PRODUCT CARD DESKTOP (compacta)
  Widget _productCardDesktop(
    BuildContext context,
    Producto producto,
    AppProvider provider,
    _P p,
  ) {
    final agotado = producto.stock <= 0;
    final stockBajo = producto.stock > 0 && producto.stock < 5;
    final yaEnCarrito = _items.any((i) => i.productoId == producto.id);
    final ventas = provider.ventas
        .where((v) => v.productoId == producto.id)
        .fold<double>(0, (s, v) => s + v.cantidad);
    final esTop = ventas > 10;

    Color badgeColor;
    String badgeText;
    if (yaEnCarrito) {
      badgeColor = _C.success;
      badgeText = 'EN CARRITO';
    } else if (agotado) {
      badgeColor = _C.danger;
      badgeText = 'AGOTADO';
    } else if (stockBajo) {
      badgeColor = _C.warning;
      badgeText = 'STOCK BAJO';
    } else if (esTop) {
      badgeColor = _C.gold;
      badgeText = '★ TOP';
    } else {
      badgeColor = _C.success;
      badgeText = 'DISPONIBLE';
    }

    final precio = provider.getPrecioProducto(producto, _metodoPago, false);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: agotado ? null : () => _agregarProductoDirecto(producto),
        splashColor: _C.primary.withOpacity(.10),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: yaEnCarrito
                  ? _C.primary.withOpacity(.55)
                  : p.border,
              width: yaEnCarrito ? 1.6 : 1.2,
            ),
            boxShadow: yaEnCarrito
                ? p.glow(_C.primary, o: 0.20)
                : p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 55,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(13),
                        topRight: Radius.circular(13),
                      ),
                      child: Container(
                        color: p.surface2,
                        width: double.infinity,
                        height: double.infinity,
                        child: CachedProductImage(
                          url: producto.imageUrl,
                          productName: producto.nombre,
                          width: double.infinity,
                          height: double.infinity,
                          radius: 0,
                          fit: BoxFit.cover,
                          agotado: agotado,
                          accent: _C.primary,
                          dangerAccent: _C.danger,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (yaEnCarrito)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _C.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _C.success.withOpacity(.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 11),
                        ),
                      ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${_fmt(producto.stock)} ${producto.unidadMedida}',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: agotado ? p.textMuted : p.textHigh,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${precio.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.4,
                                color:
                                    agotado ? p.textMuted : _C.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '/${producto.unidadMedida}',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCatalog(_P p) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .12 : .08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 32, color: _C.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin resultados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: p.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba con otro nombre o categoría.',
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── CART DESKTOP
  Widget _desktopCart(
      BuildContext context, AppProvider provider, _P p) {
    return Container(
      color: p.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Text(
                  'Carrito',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(p.dark ? .16 : .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_productosEnCarrito',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _C.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (_productosEnCarrito > 0)
                  TextButton(
                    onPressed: _limpiarVenta,
                    style: TextButton.styleFrom(
                      foregroundColor: _C.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Vaciar',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),

          if (_necesitaTransferencia) _transferFormDesktop(p),

          if (_mostrarNotaDesktop)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _notaCtrl,
                maxLines: 2,
                style: TextStyle(fontSize: 12.5, color: p.textHigh),
                decoration: InputDecoration(
                  hintText: 'Nota de la venta…',
                  hintStyle: TextStyle(fontSize: 12.5, color: p.textMuted),
                  prefixIcon: const Icon(Icons.notes_rounded,
                      size: 17, color: _C.primary),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _mostrarNotaDesktop = false),
                    icon: Icon(Icons.close_rounded,
                        size: 17, color: p.textMuted),
                  ),
                  filled: true,
                  fillColor: p.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          Expanded(
            child: _productosEnCarrito == 0
                ? _emptyCartDesktop(p)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final producto = item.productoId != null
                          ? provider.getProductoById(item.productoId!)
                          : null;
                      if (producto == null) {
                        return const SizedBox.shrink();
                      }
                      return _cartItemDesktop(item, producto, p);
                    },
                  ),
          ),

          _cartFooterDesktop(context, p),
        ],
      ),
    );
  }

  Widget _transferFormDesktop(_P p) {
    final completo = _nombreCtrl.text.trim().isNotEmpty &&
        _ciCtrl.text.trim().isNotEmpty &&
        _telefonoCtrl.text.trim().isNotEmpty &&
        _numeroTransferenciaCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: (completo ? _C.success : _C.warning)
              .withOpacity(p.dark ? .12 : .07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (completo ? _C.success : _C.warning).withOpacity(.30),
          ),
        ),
        child: Theme(
          data: Theme.of(_dummyContext()).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: _transferenciaExpandido,
            onExpansionChanged: (v) =>
                setState(() => _transferenciaExpandido = v),
            tilePadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Icon(
              completo
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: completo ? _C.success : _C.warning,
              size: 20,
            ),
            title: Text(
              completo
                  ? 'Datos de transferencia completos'
                  : 'Datos de transferencia',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _miniField(
                        _nombreCtrl, 'Nombre completo',
                        Icons.person_rounded, p),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniField(_ciCtrl, 'Carnet',
                        Icons.badge_rounded, p),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _miniField(
                      _telefonoCtrl,
                      'Teléfono',
                      Icons.phone_rounded,
                      p,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniField(
                      _numeroTransferenciaCtrl,
                      'N° Transferencia',
                      Icons.receipt_rounded,
                      p,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      DateFormat('dd/MM/yyyy')
                          .format(_fechaHoraTransferencia),
                      Icons.calendar_today_rounded,
                      p,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaHoraTransferencia,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _fechaHoraTransferencia = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              _fechaHoraTransferencia.hour,
                              _fechaHoraTransferencia.minute,
                            );
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateField(
                      DateFormat('HH:mm')
                          .format(_fechaHoraTransferencia),
                      Icons.access_time_rounded,
                      p,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              _fechaHoraTransferencia),
                        );
                        if (picked != null) {
                          setState(() {
                            _fechaHoraTransferencia = DateTime(
                              _fechaHoraTransferencia.year,
                              _fechaHoraTransferencia.month,
                              _fechaHoraTransferencia.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
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

  BuildContext _dummyContext() => navigatorKey.currentContext!;

  Widget _miniField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    _P p, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11.5, color: p.textMuted),
        prefixIcon: Icon(icon, size: 16, color: _C.primary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateField(
    String value,
    IconData icon,
    _P p, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: _C.primary),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCartDesktop(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .12 : .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 28, color: _C.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'Carrito vacío',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca un producto del catálogo para agregarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CART ITEM DESKTOP
  Widget _cartItemDesktop(ItemVenta item, Producto producto, _P p) {
    final step = _getStepForUnit(producto.unidadMedida);
    final subtotal = item.cantidad * item.precio;
    final stockInsuficiente = item.cantidad > producto.stock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: stockInsuficiente
              ? _C.danger.withOpacity(.45)
              : p.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CachedProductImage(
                url: producto.imageUrl,
                productName: producto.nombre,
                width: 44,
                height: 44,
                radius: 10,
                agotado: producto.stock <= 0,
                accent: _C.primary,
                dangerAccent: _C.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
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
                      '\$${item.precio.toStringAsFixed(2)} / ${producto.unidadMedida}',
                      style: TextStyle(
                          fontSize: 10.5, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _C.primary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: () => _eliminarItem(item),
                icon: const Icon(Icons.close_rounded, color: _C.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: Checkbox(
                  value: item.esMayorista,
                  onChanged: (v) {
                    setState(() {
                      item.esMayorista = v ?? false;
                      _actualizarPrecioItem(item);
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: _C.warning,
                  side: BorderSide(color: p.borderStrong, width: 1.4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Mayorista',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: item.esMayorista ? _C.warning : p.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove_rounded,
                      enabled: item.cantidad > 0,
                      onTap: () {
                        if (item.cantidad > 0) {
                          _decrementarCantidad(item, producto);
                        }
                      },
                      onLongPress: () {
                        if (item.cantidad > 0) {
                          _startRepetir(
                            incrementar: false,
                            item: item,
                            producto: producto,
                          );
                        }
                      },
                      onLongPressUp: _stopRepetir,
                    ),
                    SizedBox(
                      width: 44,
                      child: TextFormField(
                        controller: item.cantidadController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: stockInsuficiente
                              ? _C.danger
                              : p.textHigh,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        onChanged: (v) {
                          final n = double.tryParse(v);
                          if (n != null) {
                            setState(() {
                              item.cantidad =
                                  n.clamp(0.0, producto.stock);
                            });
                          }
                        },
                        onEditingComplete: () {
                          final v = double.tryParse(
                              item.cantidadController.text);
                          item.cantidad =
                              (v ?? 1).clamp(0.0, producto.stock);
                          item.cantidadController.text = item.cantidad
                              .toStringAsFixed(step % 1 == 0 ? 0 : 1);
                          setState(() {});
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add_rounded,
                      enabled: item.cantidad < producto.stock,
                      onTap: () {
                        if (item.cantidad < producto.stock) {
                          _incrementarCantidad(item, producto);
                        }
                      },
                      onLongPress: () {
                        if (item.cantidad < producto.stock) {
                          _startRepetir(
                            incrementar: true,
                            item: item,
                            producto: producto,
                          );
                        }
                      },
                      onLongPressUp: _stopRepetir,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockInsuficiente
                      ? _C.danger.withOpacity(.10)
                      : p.surface,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${_fmt(producto.stock)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: stockInsuficiente ? _C.danger : p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (stockInsuficiente)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: _C.danger, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Stock insuficiente',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _C.danger,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      onLongPressUp: onLongPressUp,
      child: SizedBox(
        width: 30,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _C.primary : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _cartFooterDesktop(BuildContext context, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Productos',
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
              const Spacer(),
              Text(
                '$_productosEnCarrito',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
              ),
              const Spacer(),
              Text(
                '\$${_totalGeneral.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _C.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _registrarVenta,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 19),
              label: Text(
                _isSaving ? '' : 'COBRAR',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaving ? Colors.grey : _C.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'F12 o Ctrl+Enter para cobrar  ·  Ctrl+K buscar',
            style: TextStyle(fontSize: 9.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  MÓVIL
  // ============================================================
  Widget _buildMobile(
      BuildContext context, AppProvider provider, _P p) {
    return Scaffold(
      backgroundColor: p.bg,
      appBar: _mobileAppBar(context, provider, p),
      body: Column(
        children: [
          _mobileConfigBar(context, provider, p),
          if (_necesitaTransferencia) _mobileTransferBanner(context, p),
          Expanded(
            child: _items.isEmpty
                ? _mobileEmptyCart(p)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _items.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _items.length) {
                        return _mobileAddButton(context, p);
                      }
                      final item = _items[i];
                      final producto = item.productoId != null
                          ? provider.getProductoById(item.productoId!)
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _cartItemMobile(
                            context, item, producto, p),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _mobileCheckout(context, p),
    );
  }

  PreferredSizeWidget _mobileAppBar(
    BuildContext context,
    AppProvider provider,
    _P p,
  ) {
    final nombreCliente = _clienteId != null
        ? provider.clientes
            .firstWhere((c) => c.id == _clienteId)
            .nombre
        : 'Consumidor final';

    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_rounded, color: p.textHigh),
      ),
      title: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: _C.primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Nueva venta',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .16 : .10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_productosEnCarrito',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: nombreCliente,
          icon: Icon(
            _clienteId != null
                ? Icons.person_rounded
                : Icons.person_outline_rounded,
            color: _clienteId != null ? _C.primary : p.textMuted,
          ),
          onPressed: () => _mostrarClienteMobile(context, provider),
        ),
        IconButton(
          tooltip: 'Nota',
          icon: Icon(
            _notaCtrl.text.trim().isEmpty
                ? Icons.notes_outlined
                : Icons.notes_rounded,
            color: _notaCtrl.text.trim().isEmpty
                ? p.textMuted
                : _C.primary,
          ),
          onPressed: () => _mostrarNotaMobile(context),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: p.textMuted),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          color: p.surface,
          onSelected: (v) {
            if (v == 'clear') _limpiarVenta();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Limpiar venta'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileConfigBar(
      BuildContext context, AppProvider provider, _P p) {
    final esAdmin = provider.esAdminGlobal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: p.surface,
      child: Row(
        children: [
          _configChip(
            icon: Icons.payments_rounded,
            label: _metodoPago,
            onTap: () => _mostrarMetodoPagoMobile(context),
            p: p,
          ),
          const SizedBox(width: 8),
          if (esAdmin)
            Expanded(child: _sucursalDropdown(context, provider, p)),
          if (!esAdmin) const Spacer(),
        ],
      ),
    );
  }

  Widget _mobileTransferBanner(BuildContext context, _P p) {
    final completo = _nombreCtrl.text.trim().isNotEmpty &&
        _ciCtrl.text.trim().isNotEmpty &&
        _telefonoCtrl.text.trim().isNotEmpty &&
        _numeroTransferenciaCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editarTransferenciaMobile(context, p),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (completo ? _C.success : _C.warning)
                  .withOpacity(p.dark ? .14 : .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (completo ? _C.success : _C.warning).withOpacity(.30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  completo
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: completo ? _C.success : _C.warning,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    completo
                        ? 'Datos de transferencia completos'
                        : 'Completa los datos de transferencia',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _mobileEmptyCart(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .12 : .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 36, color: _C.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Carrito vacío',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca "Agregar producto" para empezar la venta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileAddButton(BuildContext context, _P p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _agregarProductoRapido(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .10 : .05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _C.primary.withOpacity(.30),
                width: 1.3,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradBrand),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Agregar producto',
                  style: TextStyle(
                    color: _C.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── CART ITEM MOBILE
  Widget _cartItemMobile(
    BuildContext context,
    ItemVenta item,
    Producto? producto,
    _P p,
  ) {
    final hasProduct = producto != null;
    final step =
        hasProduct ? _getStepForUnit(producto.unidadMedida) : 1.0;
    final subtotal = item.cantidad * item.precio;
    final stockInsuficiente =
        hasProduct && item.cantidad > producto.stock;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stockInsuficiente
              ? _C.danger.withOpacity(.55)
              : p.border,
          width: stockInsuficiente ? 1.4 : 1.2,
        ),
        boxShadow: p.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _seleccionarProducto(item, context),
                  child: hasProduct
                      ? CachedProductImage(
                          url: producto.imageUrl,
                          productName: producto.nombre,
                          width: 56,
                          height: 56,
                          radius: 13,
                          agotado: producto.stock <= 0,
                          accent: _C.primary,
                          dangerAccent: _C.danger,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: _C.primary.withOpacity(.25),
                              width: 1.3,
                            ),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: _C.primary, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _seleccionarProducto(item, context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasProduct
                              ? producto.nombre
                              : 'Seleccionar producto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: hasProduct
                                ? p.textHigh
                                : p.textMuted,
                          ),
                        ),
                        if (hasProduct) ...[
                          const SizedBox(height: 2),
                          Text(
                            '\$${item.precio.toStringAsFixed(2)} / ${producto.unidadMedida}',
                            style: TextStyle(
                                fontSize: 11, color: p.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _C.primary,
                    letterSpacing: -.3,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => _eliminarItem(item),
                  icon:
                      const Icon(Icons.close_rounded, color: _C.danger),
                ),
              ],
            ),

            if (hasProduct) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: item.esMayorista,
                      onChanged: (v) {
                        setState(() {
                          item.esMayorista = v ?? false;
                          _actualizarPrecioItem(item);
                        });
                      },
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      activeColor: _C.warning,
                      side: BorderSide(
                          color: p.borderStrong, width: 1.4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mayorista',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: item.esMayorista
                          ? _C.warning
                          : p.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockInsuficiente
                          ? _C.danger.withOpacity(.10)
                          : p.surface2,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 11,
                          color: stockInsuficiente
                              ? _C.danger
                              : p.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(producto.stock)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: stockInsuficiente
                                ? _C.danger
                                : p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        _qtyBtn(
                          icon: Icons.remove_rounded,
                          enabled: item.cantidad > 0,
                          onTap: () {
                            if (item.cantidad > 0) {
                              _decrementarCantidad(item, producto);
                            }
                          },
                          onLongPress: () {
                            if (item.cantidad > 0) {
                              _startRepetir(
                                incrementar: false,
                                item: item,
                                producto: producto,
                              );
                            }
                          },
                          onLongPressUp: _stopRepetir,
                        ),
                        SizedBox(
                          width: 50,
                          child: TextFormField(
                            controller: item.cantidadController,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: stockInsuficiente
                                  ? _C.danger
                                  : p.textHigh,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (v) {
                              final n = double.tryParse(v);
                              if (n != null) {
                                setState(() {
                                  item.cantidad =
                                      n.clamp(0.0, producto.stock);
                                });
                              }
                            },
                            onEditingComplete: () {
                              final v = double.tryParse(
                                  item.cantidadController.text);
                              item.cantidad =
                                  (v ?? 1).clamp(0.0, producto.stock);
                              item.cantidadController.text =
                                  item.cantidad.toStringAsFixed(
                                      step % 1 == 0 ? 0 : 1);
                              setState(() {});
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        _qtyBtn(
                          icon: Icons.add_rounded,
                          enabled: item.cantidad < producto.stock,
                          onTap: () {
                            if (item.cantidad < producto.stock) {
                              _incrementarCantidad(item, producto);
                            }
                          },
                          onLongPress: () {
                            if (item.cantidad < producto.stock) {
                              _startRepetir(
                                incrementar: true,
                                item: item,
                                producto: producto,
                              );
                            }
                          },
                          onLongPressUp: _stopRepetir,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (stockInsuficiente)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: _C.danger, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Stock insuficiente. Disp: ${_fmt(producto.stock)} ${producto.unidadMedida}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _C.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mobileCheckout(BuildContext context, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(p.dark ? .35 : .08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: p.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_totalGeneral.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                      color: _C.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _registrarVenta,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSaving ? '' : 'COBRAR',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving ? Colors.grey : _C.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DIÁLOGOS
  // ============================================================
  void _mostrarClienteDesktop(
      BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .16 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.person_rounded,
                  color: _C.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Seleccionar cliente',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: DropdownButtonFormField<String?>(
            value: _clienteId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Cliente',
              labelStyle: TextStyle(fontSize: 12.5, color: p.textMuted),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: _C.primary),
              filled: true,
              fillColor: p.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Consumidor final'),
              ),
              ...provider.clientes.map(
                (c) => DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.nombre),
                ),
              ),
            ],
            onChanged: (v) {
              setState(() => _clienteId = v);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  void _mostrarClienteMobile(
      BuildContext context, AppProvider provider) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccionar cliente',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_off_rounded,
                  color: _C.primary),
              title: Text(
                'Consumidor final',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: p.textHigh,
                ),
              ),
              onTap: () {
                setState(() => _clienteId = null);
                Navigator.pop(context);
              },
            ),
            ...provider.clientes.map((c) {
              final selected = _clienteId == c.id;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.person_rounded,
                  color: selected ? _C.primary : p.textMuted,
                ),
                title: Text(
                  c.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                ),
                onTap: () {
                  setState(() => _clienteId = c.id);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _mostrarNotaMobile(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nota de la venta',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notaCtrl,
              maxLines: 4,
              autofocus: true,
              style: TextStyle(fontSize: 13.5, color: p.textHigh),
              decoration: InputDecoration(
                hintText: 'Escribe una nota…',
                hintStyle: TextStyle(fontSize: 13, color: p.textMuted),
                filled: true,
                fillColor: p.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: _C.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMetodoPagoDesktop(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final opciones = [
      'Efectivo CUP',
      'Efectivo MLC',
      'Transfermóvil',
      'EnZona'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .16 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: _C.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Método de pago',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: opciones.map((o) {
              final selected = _metodoPago == o;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected
                      ? _C.primary.withOpacity(p.dark ? .16 : .10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () {
                      setState(() => _metodoPago = o);
                      _actualizarPrecios();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected
                              ? _C.primary.withOpacity(.40)
                              : p.border,
                          width: selected ? 1.5 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected ? _C.primary : p.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            o,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textHigh,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _mostrarMetodoPagoMobile(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final opciones = [
      'Efectivo CUP',
      'Efectivo MLC',
      'Transfermóvil',
      'EnZona'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Método de pago',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 14),
            ...opciones.map((o) {
              final selected = _metodoPago == o;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected
                      ? _C.primary.withOpacity(p.dark ? .16 : .10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _metodoPago = o);
                      _actualizarPrecios();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? _C.primary.withOpacity(.40)
                              : p.border,
                          width: selected ? 1.5 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected ? _C.primary : p.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            o,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.textHigh,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _editarTransferenciaMobile(
      BuildContext context, _P p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          color: _C.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Datos de transferencia',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: p.textHigh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _mobileInput(_nombreCtrl, 'Nombre completo',
                      Icons.person_rounded, p, setLocal),
                  const SizedBox(height: 10),
                  _mobileInput(_ciCtrl, 'Carnet de identidad',
                      Icons.badge_rounded, p, setLocal),
                  const SizedBox(height: 10),
                  _mobileInput(_telefonoCtrl, 'Teléfono',
                      Icons.phone_rounded, p, setLocal,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  _mobileInput(_numeroTransferenciaCtrl, 'N° Transferencia',
                      Icons.receipt_rounded, p, setLocal),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dateField(
                          DateFormat('dd/MM/yyyy')
                              .format(_fechaHoraTransferencia),
                          Icons.calendar_today_rounded,
                          p,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: _fechaHoraTransferencia,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaHoraTransferencia = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  _fechaHoraTransferencia.hour,
                                  _fechaHoraTransferencia.minute,
                                );
                              });
                              setLocal(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateField(
                          DateFormat('HH:mm')
                              .format(_fechaHoraTransferencia),
                          Icons.access_time_rounded,
                          p,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(
                                  _fechaHoraTransferencia),
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaHoraTransferencia = DateTime(
                                  _fechaHoraTransferencia.year,
                                  _fechaHoraTransferencia.month,
                                  _fechaHoraTransferencia.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                              setLocal(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: _C.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Listo',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mobileInput(
    TextEditingController ctrl,
    String label,
    IconData icon,
    _P p,
    StateSetter setLocal, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setLocal(() {}),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: p.textMuted),
        prefixIcon: Icon(icon, color: _C.primary, size: 20),
        filled: true,
        fillColor: p.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  //  REGISTRO DE VENTA
  // ============================================================
  Future<void> _registrarVenta() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      for (final item in _items) {
        if (item.productoId == null ||
            item.cantidad <= 0 ||
            item.precio <= 0) {
          mostrarSnackBar(
            mensaje: 'Todos los productos deben estar completos',
            esExito: false,
          );
          setState(() => _isSaving = false);
          return;
        }
      }
      if (_totalGeneral <= 0) {
        mostrarSnackBar(
          mensaje: 'El total debe ser mayor que 0',
          esExito: false,
        );
        setState(() => _isSaving = false);
        return;
      }
      if (_necesitaTransferencia) {
        if (_nombreCtrl.text.trim().isEmpty ||
            _ciCtrl.text.trim().isEmpty ||
            _telefonoCtrl.text.trim().isEmpty ||
            _numeroTransferenciaCtrl.text.trim().isEmpty) {
          mostrarSnackBar(
            mensaje: 'Completa los datos de la transferencia',
            esExito: false,
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      if (!provider.empresaActiva) {
        mostrarSnackBar(mensaje: 'Servicio cancelado', esExito: false);
        setState(() => _isSaving = false);
        return;
      }

      for (final item in _items) {
        final prod = provider.getProductoById(item.productoId!);
        if (prod == null) {
          mostrarSnackBar(
              mensaje: 'Producto no encontrado', esExito: false);
          setState(() => _isSaving = false);
          return;
        }
        if (prod.stock < item.cantidad) {
          mostrarSnackBar(
            mensaje:
                'Stock insuficiente para "${prod.nombre}". Disponible: ${prod.stock}',
            esExito: false,
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      final now = DateTime.now();
      final groupId = Uuid().v4();
      final esUSD = _metodoPago == 'Efectivo USD';
      final moneda = esUSD ? 'USD' : 'CUP';
      final tasa = provider.tasaCambioUSD;

      for (final item in _items) {
        final producto = provider.getProductoById(item.productoId!);
        if (producto == null) continue;
        final total = item.cantidad * item.precio;

        final venta = Venta(
          id: '',
          productoId: producto.id,
          productoNombre: producto.nombre,
          cantidad: item.cantidad,
          precioUnitario: item.precio,
          total: total,
          metodoPago: _metodoPago,
          fecha: now,
          nota: _notaCtrl.text.trim().isEmpty
              ? 'Venta múltiple'
              : _notaCtrl.text.trim(),
          clienteId: _clienteId,
          costoUnitario: 0,
          costoTotal: 0,
          saleGroupId: groupId,
          usuarioId: provider.usuarioId,
          sucursalId: provider.esAdminGlobal
              ? _sucursalIdSeleccionada
              : provider.sucursalIdUsuario,
          tipoCliente: item.esMayorista ? 'mayorista' : 'minorista',
          moneda: moneda,
          tasaCambio: tasa,
          totalUSD: esUSD ? total / tasa : null,
        );

        await provider.agregarVenta(venta);

        if (_necesitaTransferencia) {
          final t = Transferencia(
            id: '',
            ventaId: venta.id,
            nombreCompleto: _nombreCtrl.text.trim(),
            carnetIdentidad: _ciCtrl.text.trim(),
            numeroTelefono: _telefonoCtrl.text.trim(),
            numeroTransferencia: _numeroTransferenciaCtrl.text.trim(),
            fechaHora: _fechaHoraTransferencia,
            monto: venta.total,
            empresaId: provider.empresaId,
            updatedAt: DateTime.now(),
          );
          await provider.guardarTransferencia(t);
        }
      }

      mostrarSnackBar(
          mensaje: 'Venta registrada exitosamente', esExito: true);
      _limpiarVenta();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      mostrarSnackBar(
        mensaje: 'Error al registrar venta: ${e.toString()}',
        esExito: false,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}

// ============================================================
//  SEARCH DELEGATE (CON IMÁGENES cacheadas)
// ============================================================
class _ProductoSearchDelegate extends SearchDelegate<Producto?> {
  final List<Producto> productos;
  final List<String> idsExcluidos;
  final String? top1;
  final List<String> top5;
  final AppProvider provider;

  _ProductoSearchDelegate(
    this.productos,
    this.idsExcluidos, {
    this.top1,
    required this.top5,
    required this.provider,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: Icon(
            Icons.clear_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFEEF4FC)
                : const Color(0xFF0A1A33),
          ),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFEEF4FC)
              : const Color(0xFF0A1A33),
        ),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    final results = productos
        .where((prod) =>
            !idsExcluidos.contains(prod.id) &&
            prod.nombre.toLowerCase().contains(query.toLowerCase()))
        .toList();

    results.sort((a, b) {
      final aTop = top5.contains(a.id);
      final bTop = top5.contains(b.id);
      if (aTop && !bTop) return -1;
      if (!aTop && bTop) return 1;
      return a.nombre.compareTo(b.nombre);
    });

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(p.dark ? .12 : .08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded,
                    size: 32, color: _C.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'Sin resultados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prueba con otro nombre.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final prod = results[i];
        final agotado = prod.stock <= 0;
        final stockBajo = prod.stock > 0 && prod.stock < 5;
        final esTop = top1 != null && prod.id == top1;
        final popular = !esTop && top5.contains(prod.id);

        Color badgeColor = _C.success;
        String badgeText = 'DISPONIBLE';
        if (agotado) {
          badgeColor = _C.danger;
          badgeText = 'AGOTADO';
        } else if (stockBajo) {
          badgeColor = _C.warning;
          badgeText = 'STOCK BAJO';
        } else if (esTop) {
          badgeColor = _C.gold;
          badgeText = '★ MÁS VENDIDO';
        } else if (popular) {
          badgeColor = _C.orange;
          badgeText = 'POPULAR';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: agotado ? null : () => close(context, prod),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    CachedProductImage(
                      url: prod.imageUrl,
                      productName: prod.nombre,
                      width: 56,
                      height: 56,
                      radius: 12,
                      agotado: agotado,
                      accent: _C.primary,
                      dangerAccent: _C.danger,
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
                                  prod.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: p.textHigh,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(.14),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_fmt(prod.stock)} ${prod.unidadMedida}  ·  \$${prod.precioVenta.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: p.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}