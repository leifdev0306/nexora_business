// ============================================================
//  reabastecer_screen.dart  ·  NEXORA BUSINESS
//  Reabastecer producto con estilo Nexora
//  · Selector premium, tarjetas modernas, control de cantidad
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';
import 'dart:async';

// ============================================================
//  PALETA NEXORA
// ============================================================
class _N {
  static const primary = Color(0xFF5B5BFF);
  static const primaryDark = Color(0xFF3B3BE8);
  static const accent = Color(0xFFFF4D8D);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF06B6D4);

  static const bgLight = Color(0xFFF4F6FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8ECF4);

  static const bgDark = Color(0xFF0A0E1A);
  static const surfaceDark = Color(0xFF131A2A);
  static const surfaceDark2 = Color(0xFF1B2438);
  static const borderDark = Color(0xFF26314A);

  static const textLight = Color(0xFF0B1120);
  static const textSoftLight = Color(0xFF5B6780);
  static const textMuteLight = Color(0xFF8E99AE);
  static const textDark = Color(0xFFF1F4FA);
  static const textSoftDark = Color(0xFF9CA7BF);
  static const textMuteDark = Color(0xFF6A7590);
}

// ============================================================
//  SCREEN
// ============================================================
class ReabastecerScreen extends StatefulWidget {
  final String? productoId;
  const ReabastecerScreen({Key? key, this.productoId}) : super(key: key);

  @override
  State<ReabastecerScreen> createState() => _ReabastecerScreenState();
}

class _ReabastecerScreenState extends State<ReabastecerScreen> {
  String? _productoId;
  String? _proveedorId;
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _cargando = false;

  double _cantidad = 1.0;
  double _step = 1.0;
  Timer? _repeticionTimer;

  @override
  void initState() {
    super.initState();
    if (widget.productoId != null) {
      _productoId = widget.productoId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarProducto(_productoId!);
      });
    }
  }

  void _cargarProducto(String id) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final producto = provider.getProductoById(id);
    if (producto != null) {
      final ultimoPrecio = producto.lotes.isNotEmpty
          ? (producto.lotes.last['precioCompra'] as num).toDouble()
          : producto.precioCompra;
      _precioCtrl.text = ultimoPrecio.toStringAsFixed(2);
      _step = _getStepForUnit(producto.unidadMedida);
      _cantidad = 1.0;
      _cantidadCtrl.text = '1.0';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _repeticionTimer?.cancel();
    super.dispose();
  }

  List<Producto> _ordenarProductos(List<Producto> productos, AppProvider provider) {
    final ventasPorProducto = <String, double>{};
    for (var venta in provider.ventas) {
      ventasPorProducto[venta.productoId] =
          (ventasPorProducto[venta.productoId] ?? 0.0) + venta.cantidad;
    }

    productos.sort((a, b) {
      final aVentas = ventasPorProducto[a.id] ?? 0.0;
      final bVentas = ventasPorProducto[b.id] ?? 0.0;

      final aAgotado = a.stock == 0;
      final bAgotado = b.stock == 0;
      if (aAgotado && !bAgotado) return -1;
      if (!aAgotado && bAgotado) return 1;

      if (aAgotado && bAgotado) return bVentas.compareTo(aVentas);

      final aStockBajo = a.stock < 5;
      final bStockBajo = b.stock < 5;
      if (aStockBajo && !bStockBajo) return -1;
      if (!aStockBajo && bStockBajo) return 1;

      return bVentas.compareTo(aVentas);
    });

    return productos;
  }

  double _getStepForUnit(String unidad) {
    final unidadesDecimales = ['kg', 'g', 'lb', 'L', 'mL', 'm', 'cm'];
    return unidadesDecimales.contains(unidad) ? 0.5 : 1.0;
  }

  void _ajustarCantidad({required bool incrementar}) {
    final step = _step;
    if (incrementar) {
      _cantidad += step;
    } else {
      if (_cantidad - step >= 0) {
        _cantidad -= step;
      } else {
        _cantidad = 0;
      }
    }
    _cantidadCtrl.text = _cantidad.toStringAsFixed(step % 1 == 0 ? 0 : 1);
    setState(() {});
  }

  void _startRepetir({required bool incrementar}) {
    _repeticionTimer?.cancel();
    _repeticionTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      _ajustarCantidad(incrementar: incrementar);
    });
  }

  void _stopRepetir() {
    _repeticionTimer?.cancel();
    _repeticionTimer = null;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = provider.rol == 'admin' || provider.rol == 'dueno';
    final esGestor = provider.rol == 'gestor' || provider.rol == 'gerente';

    final productosBase = provider.productos.where((p) {
      if (isAdmin || esGestor) return true;
      return p.sucursalId == provider.sucursalIdUsuario;
    }).toList();

    final productosOrdenados = _ordenarProductos(productosBase, provider);

    final ventasPorProducto = <String, double>{};
    for (var venta in provider.ventas) {
      ventasPorProducto[venta.productoId] =
          (ventasPorProducto[venta.productoId] ?? 0.0) + venta.cantidad;
    }

    final productoSeleccionado = _productoId != null
        ? provider.getProductoById(_productoId!)
        : null;

    final unidad = productoSeleccionado?.unidadMedida ?? 'unidad';
    final step = _getStepForUnit(unidad);
    if (_step != step) _step = step;

    String nombreSucursal = '';
    if (productoSeleccionado != null && productoSeleccionado.sucursalId != null) {
      nombreSucursal = provider.getSucursalNombre(productoSeleccionado.sucursalId!);
    }

    return Scaffold(
      backgroundColor: isDark ? _N.bgDark : _N.bgLight,
      appBar: _buildAppBar(context, isDark),
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _N.success.withOpacity(isDark ? .10 : .05),
                      _N.success.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _productCard(
                            context,
                            productoSeleccionado,
                            provider,
                            ventasPorProducto,
                            isDark,
                            nombreSucursal,
                          ),
                          const SizedBox(height: 14),
                          _priceCard(context, isDark),
                          const SizedBox(height: 14),
                          _quantityCard(context, isDark),
                          if (isAdmin) ...[
                            const SizedBox(height: 14),
                            _providerCard(context, isDark, provider),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? _N.surfaceDark : Colors.white,
      foregroundColor: isDark ? _N.textDark : _N.textLight,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? _N.textDark : _N.textLight,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_N.success, Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _N.success.withOpacity(.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_box_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Reabastecer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                  color: isDark ? _N.textDark : _N.textLight,
                ),
              ),
              Text(
                'Añade stock al inventario',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? _N.textSoftDark : _N.textSoftLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  TARJETA DEL PRODUCTO
  // ------------------------------------------------------------
  Widget _productCard(
    BuildContext context,
    Producto? producto,
    AppProvider provider,
    Map<String, double> ventas,
    bool isDark,
    String nombreSucursal,
  ) {
    final agotado = producto?.stock == 0;
    final stockBajo = producto != null && producto.stock > 0 && producto.stock < 5;

    Color stateColor = _N.primary;
    IconData stateIcon = Icons.inventory_2_rounded;
    String stateLabel = 'Selecciona un producto';

    if (producto != null) {
      if (agotado) {
        stateColor = _N.danger;
        stateIcon = Icons.error_outline_rounded;
        stateLabel = 'AGOTADO';
      } else if (stockBajo) {
        stateColor = _N.warning;
        stateIcon = Icons.warning_amber_rounded;
        stateLabel = 'STOCK BAJO';
      } else {
        stateColor = _N.success;
        stateIcon = Icons.check_circle_rounded;
        stateLabel = 'DISPONIBLE';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: producto != null
              ? stateColor.withOpacity(.30)
              : (isDark ? _N.borderDark : _N.borderLight),
          width: producto != null ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .25 : .03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                    colors: producto != null
                        ? [
                            stateColor.withOpacity(.18),
                            stateColor.withOpacity(.05),
                          ]
                        : [
                            _N.primary.withOpacity(.18),
                            _N.primary.withOpacity(.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(stateIcon, color: stateColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto != null ? producto.nombre : 'Sin producto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                        color: producto != null
                            ? (isDark ? _N.textDark : _N.textLight)
                            : (isDark ? _N.textSoftDark : _N.textSoftLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (producto != null)
                      Text(
                        'Stock: ${producto.stock} ${producto.unidadMedida}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? _N.textSoftDark : _N.textSoftLight,
                        ),
                      )
                    else
                      Text(
                        'Toca "Buscar producto" para empezar',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? _N.textSoftDark : _N.textSoftLight,
                        ),
                      ),
                  ],
                ),
              ),
              if (producto != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                      color: stateColor,
                    ),
                  ),
                ),
            ],
          ),
          if (producto != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  Icons.category_rounded,
                  provider.getNombreCategoria(producto.categoriaId),
                  isDark,
                ),
                _chip(
                  Icons.attach_money_rounded,
                  'Venta \$${producto.precioVenta.toStringAsFixed(2)}',
                  isDark,
                ),
                _chip(
                  Icons.trending_up_rounded,
                  '${ventas[producto.id]?.toInt() ?? 0} ventas',
                  isDark,
                ),
                if (nombreSucursal.isNotEmpty)
                  _chip(
                    Icons.storefront_rounded,
                    nombreSucursal,
                    isDark,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarSelectorProductos(
                context,
                _ordenarProductos(
                  provider.productos.where((p) {
                    if (provider.rol == 'admin' ||
                        provider.rol == 'dueno' ||
                        provider.rol == 'gestor' ||
                        provider.rol == 'gerente') {
                      return true;
                    }
                    return p.sucursalId == provider.sucursalIdUsuario;
                  }).toList(),
                  provider,
                ),
                ventas,
                provider,
              ),
              icon: Icon(
                producto == null ? Icons.search_rounded : Icons.swap_horiz_rounded,
                size: 18,
              ),
              label: Text(
                producto == null ? 'Buscar producto' : 'Cambiar producto',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _N.primary,
                side: BorderSide(color: _N.primary.withOpacity(.35), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark2 : _N.bgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? _N.textSoftDark : _N.textSoftLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? _N.textSoftDark : _N.textSoftLight,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  TARJETA PRECIO
  // ------------------------------------------------------------
  Widget _priceCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _N.borderDark : _N.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .25 : .03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _N.warning.withOpacity(.18),
                      _N.warning.withOpacity(.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: _N.warning,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio de compra unitario',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                        color: isDark ? _N.textDark : _N.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Costo por unidad comprada',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? _N.textSoftDark : _N.textSoftLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _precioCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Requerido';
              final n = double.tryParse(v!);
              if (n == null || n <= 0) return 'Ingresa un precio > 0';
              return null;
            },
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? _N.textDark : _N.textLight,
            ),
            decoration: InputDecoration(
              labelText: 'Precio (CUP) *',
              labelStyle: TextStyle(
                fontSize: 12.5,
                color: isDark ? _N.textSoftDark : _N.textSoftLight,
              ),
              prefixIcon: const Icon(
                Icons.payments_rounded,
                color: _N.warning,
                size: 19,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? _N.textMuteDark : _N.textMuteLight,
              ),
              filled: true,
              fillColor: isDark ? _N.surfaceDark2 : _N.bgLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? _N.borderDark : _N.borderLight,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _N.primary, width: 1.6),
              ),
              errorStyle: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _N.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  TARJETA CANTIDAD
  // ------------------------------------------------------------
  Widget _quantityCard(BuildContext context, bool isDark) {
    final precio = double.tryParse(_precioCtrl.text) ?? 0;
    final cant = double.tryParse(_cantidadCtrl.text) ?? 0;
    final totalCosto = precio * cant;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _N.borderDark : _N.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .25 : .03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _N.info.withOpacity(.18),
                      _N.info.withOpacity(.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: _N.info,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cantidad a agregar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                        color: isDark ? _N.textDark : _N.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paso: ${_step.toStringAsFixed(_step % 1 == 0 ? 0 : 1)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? _N.textSoftDark : _N.textSoftLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove_rounded,
                enabled: _cantidad > 0,
                isDark: isDark,
                onTap: () => _ajustarCantidad(incrementar: false),
                onLongPress: () => _startRepetir(incrementar: false),
                onLongPressUp: _stopRepetir,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _cantidadCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                    color: isDark ? _N.textDark : _N.textLight,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? _N.surfaceDark2 : _N.bgLight,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? _N.borderDark : _N.borderLight,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _N.primary, width: 1.6),
                    ),
                    errorStyle: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _N.danger,
                    ),
                  ),
                  onChanged: (value) {
                    final val = double.tryParse(value);
                    if (val != null && val > 0) {
                      _cantidad = val;
                    } else {
                      _cantidad = 0;
                    }
                    setState(() {});
                  },
                  onEditingComplete: () {
                    final val = double.tryParse(_cantidadCtrl.text);
                    if (val != null && val > 0) {
                      _cantidad = val;
                    } else {
                      _cantidad = 1.0;
                      _cantidadCtrl.text = '1.0';
                    }
                    setState(() {});
                    FocusScope.of(context).unfocus();
                  },
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Requerido';
                    final n = double.tryParse(v!);
                    if (n == null || n <= 0) return 'Cantidad > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              _qtyButton(
                icon: Icons.add_rounded,
                enabled: true,
                isDark: isDark,
                onTap: () => _ajustarCantidad(incrementar: true),
                onLongPress: () => _startRepetir(incrementar: true),
                onLongPressUp: _stopRepetir,
              ),
            ],
          ),
          if (totalCosto > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          _N.success.withOpacity(.14),
                          _N.success.withOpacity(.04),
                        ]
                      : [
                          _N.success.withOpacity(.08),
                          _N.success.withOpacity(.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _N.success.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _N.success.withOpacity(.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: _N.success,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Costo total de la compra',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? _N.textSoftDark : _N.textSoftLight,
                      ),
                    ),
                  ),
                  Text(
                    '\$${totalCosto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                      color: _N.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      onLongPressUp: onLongPressUp,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? _N.primary.withOpacity(isDark ? .16 : .10)
              : (isDark ? _N.surfaceDark2 : _N.bgLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? _N.primary.withOpacity(.30)
                : (isDark ? _N.borderDark : _N.borderLight),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled
              ? _N.primary
              : (isDark ? _N.textMuteDark : _N.textMuteLight),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  TARJETA PROVEEDOR (solo admin)
  // ------------------------------------------------------------
  Widget _providerCard(BuildContext context, bool isDark, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _N.borderDark : _N.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .25 : .03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _N.primary.withOpacity(.18),
                      _N.primary.withOpacity(.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: _N.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proveedor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                        color: isDark ? _N.textDark : _N.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opcional · Se actualizará la deuda',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? _N.textSoftDark : _N.textSoftLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            value: _proveedorId,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? _N.textSoftDark : _N.textSoftLight,
            ),
            dropdownColor: isDark ? _N.surfaceDark : Colors.white,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? _N.textDark : _N.textLight,
            ),
            decoration: InputDecoration(
              labelText: 'Proveedor',
              labelStyle: TextStyle(
                fontSize: 12.5,
                color: isDark ? _N.textSoftDark : _N.textSoftLight,
              ),
              prefixIcon: const Icon(
                Icons.person_rounded,
                color: _N.primary,
                size: 19,
              ),
              filled: true,
              fillColor: isDark ? _N.surfaceDark2 : _N.bgLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? _N.borderDark : _N.borderLight,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _N.primary, width: 1.6),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Sin proveedor'),
              ),
              ...provider.proveedores.map(
                (p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text(p.nombre),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _proveedorId = value),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  BOTTOM BAR
  // ------------------------------------------------------------
  Widget _buildBottomBar(BuildContext context, bool isDark, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .35 : .08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _cargando ? null : _reabastecer,
            icon: const Icon(Icons.add_box_rounded, size: 20),
            label: const Text(
              'REABASTECER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _N.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  SELECTOR DE PRODUCTOS
  // ============================================================
  void _mostrarSelectorProductos(
    BuildContext context,
    List<Producto> productos,
    Map<String, double> ventas,
    AppProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          String filtro = '';
          return StatefulBuilder(
            builder: (context, setModalState) {
              final filtrados = productos.where((p) {
                final q = filtro.toLowerCase();
                return p.nombre.toLowerCase().contains(q) ||
                    provider.getNombreCategoria(p.categoriaId).toLowerCase().contains(q);
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? _N.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? _N.borderDark : _N.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Título
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_N.primary, _N.accent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seleccionar producto',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.3,
                                    color: isDark ? _N.textDark : _N.textLight,
                                  ),
                                ),
                                Text(
                                  '${filtrados.length} disponibles',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? _N.textSoftDark : _N.textSoftLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Búsqueda
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setModalState(() => filtro = v),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? _N.textDark : _N.textLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o categoría…',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? _N.textMuteDark : _N.textMuteLight,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: isDark ? _N.textSoftDark : _N.textSoftLight,
                          ),
                          suffixIcon: filtro.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setModalState(() => filtro = '');
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: isDark ? _N.textSoftDark : _N.textSoftLight,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? _N.surfaceDark2 : _N.bgLight,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    // Lista
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _N.primary.withOpacity(isDark ? .12 : .08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      size: 28,
                                      color: _N.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Sin resultados',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? _N.textDark : _N.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: filtrados.length,
                              itemBuilder: (context, index) {
                                final p = filtrados[index];
                                final ventasProducto = ventas[p.id] ?? 0.0;
                                final agotado = p.stock == 0;
                                final stockBajo = p.stock > 0 && p.stock < 5;
                                final nombreSucursal = p.sucursalId != null
                                    ? provider.getSucursalNombre(p.sucursalId!)
                                    : 'Sin sucursal';

                                Color stateColor;
                                String stateText;
                                if (agotado) {
                                  stateColor = _N.danger;
                                  stateText = 'AGOTADO';
                                } else if (stockBajo) {
                                  stateColor = _N.warning;
                                  stateText = 'STOCK BAJO';
                                } else {
                                  stateColor = _N.success;
                                  stateText = 'DISPONIBLE';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: _productoId == p.id
                                        ? _N.primary.withOpacity(isDark ? .14 : .08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        final ultimoPrecio = p.lotes.isNotEmpty
                                            ? (p.lotes.last['precioCompra'] as num).toDouble()
                                            : p.precioCompra;
                                        setState(() {
                                          _productoId = p.id;
                                          _precioCtrl.text =
                                              ultimoPrecio.toStringAsFixed(2);
                                          _cantidad = 1.0;
                                          _cantidadCtrl.text = '1.0';
                                          _step = _getStepForUnit(p.unidadMedida);
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _productoId == p.id
                                                ? _N.primary.withOpacity(.45)
                                                : (isDark ? _N.borderDark : _N.borderLight),
                                            width: _productoId == p.id ? 1.4 : 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: agotado
                                                      ? [
                                                          _N.danger.withOpacity(.18),
                                                          _N.danger.withOpacity(.05),
                                                        ]
                                                      : [
                                                          _N.primary.withOpacity(.18),
                                                          _N.primary.withOpacity(.05),
                                                        ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                p.nombre.isNotEmpty
                                                    ? p.nombre[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: agotado ? _N.danger : _N.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          p.nombre,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 13.5,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isDark
                                                                ? _N.textDark
                                                                : _N.textLight,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: stateColor
                                                              .withOpacity(.14),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          stateText,
                                                          style: TextStyle(
                                                            fontSize: 8.5,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            letterSpacing: .3,
                                                            color: stateColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.inventory_2_rounded,
                                                        size: 11,
                                                        color: isDark
                                                            ? _N.textSoftDark
                                                            : _N.textSoftLight,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${p.stock} ${p.unidadMedida}',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          color: isDark
                                                              ? _N.textSoftDark
                                                              : _N.textSoftLight,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Icon(
                                                        Icons.trending_up_rounded,
                                                        size: 11,
                                                        color: isDark
                                                            ? _N.textSoftDark
                                                            : _N.textSoftLight,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${ventasProducto.toInt()} ventas',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          color: isDark
                                                              ? _N.textSoftDark
                                                              : _N.textSoftLight,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '\$${p.precioVenta.toStringAsFixed(2)} · $nombreSucursal',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: _N.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                              color: isDark
                                                  ? _N.textMuteDark
                                                  : _N.textMuteLight,
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
            },
          );
        },
      ),
    );
  }

  // ============================================================
  //  REABASTECER
  // ============================================================
  Future<void> _reabastecer() async {
    if (_formKey.currentState!.validate() && _productoId != null) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final cantidad = double.parse(_cantidadCtrl.text);
      final precio = double.parse(_precioCtrl.text);

      setState(() => _cargando = true);

      try {
        await provider.reabastecerProducto(_productoId!, cantidad, precio);

        if (_proveedorId != null &&
            (provider.rol == 'admin' || provider.rol == 'dueno')) {
          final proveedor =
              provider.clientes.firstWhere((c) => c.id == _proveedorId);
          proveedor.saldoPendiente =
              (proveedor.saldoPendiente ?? 0) + (cantidad * precio);
          await provider.editarCliente(proveedor);
          mostrarSnackBar(
            mensaje: 'Reabastecimiento registrado. Deuda con proveedor actualizada.',
            esExito: true,
          );
        } else {
          mostrarSnackBar(mensaje: 'Reabastecimiento exitoso', esExito: true);
        }

        _cantidad = 1.0;
        _cantidadCtrl.text = '1.0';
        _precioCtrl.clear();
        _proveedorId = null;

        final producto = provider.getProductoById(_productoId!);
        if (producto != null) {
          final ultimoPrecio = producto.lotes.isNotEmpty
              ? (producto.lotes.last['precioCompra'] as num).toDouble()
              : producto.precioCompra;
          _precioCtrl.text = ultimoPrecio.toStringAsFixed(2);
        }

        setState(() {});
      } catch (e) {
        mostrarSnackBar(
          mensaje: 'Error al reabastecer: ${mensajeAmigable(e)}',
          esExito: false,
        );
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    } else {
      mostrarSnackBar(
        mensaje: 'Completa todos los campos correctamente',
        esExito: false,
      );
    }
  }
}