// ============================================================
//  productos_publicados_screen.dart  ·  NEXORA BUSINESS
//  Gestión de productos visibles en la tienda pública
//  Claves namespaced por empresa
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import '../widgets/cached_product_image.dart';
import 'mi_tienda_screen.dart'
    show keyTiendaDeEmpresa, kNetworkStoresKey;
import 'servicio_cancelado_screen.dart';

// ════════════════════════════════════════════════════════════
//  PALETA
// ════════════════════════════════════════════════════════════
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

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
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
  List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: dark ? Colors.black.withOpacity(.30)
          : const Color(0xFF0A1A33).withOpacity(.05),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
  ];
}

class ProductosPublicadosScreen extends StatefulWidget {
  const ProductosPublicadosScreen({Key? key}) : super(key: key);

  @override
  State<ProductosPublicadosScreen> createState() =>
      _ProductosPublicadosScreenState();
}

class _ProductosPublicadosScreenState
    extends State<ProductosPublicadosScreen> {
  TiendaPublica? _tienda;
  bool _cargando = true;
  String _busqueda = '';
  final _searchCtrl = TextEditingController();
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    TiendaPublica? t;
    final raw = provider.catalogosBox.get(keyTiendaDeEmpresa(empresaId));
    if (raw is Map) {
      final temp = TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
      if (temp.empresaId == empresaId) t = temp;
    }

    if (!mounted) return;
    setState(() {
      _tienda = t;
      _cargando = false;
    });
  }

  // ══════════════════════════════════════════════════════════
  //  DESPUBLICAR — reconstruye catálogo y sincroniza red
  // ══════════════════════════════════════════════════════════
  Future<void> _despublicar(String productoId) async {
    if (_tienda == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return;

    // 1) Quitar de productosPublicados
    final lista = List<String>.from(_tienda!.productosPublicados)
      ..remove(productoId);

    // 2) Reconstruir catálogo sin ese producto
    final catalogoActualizado = _tienda!.catalogo
        .where((p) => p.id != productoId)
        .toList();

    final nueva = _tienda!.copyWith(
      productosPublicados: lista,
      catalogo: catalogoActualizado,
      updatedAt: DateTime.now(),
    );

    // 3) Local namespaced
    await provider.catalogosBox.put(
        keyTiendaDeEmpresa(empresaId), nueva.toJson());

    // 4) Upsert en Red local
    final netRaw =
        (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
    final netList =
        netRaw.map((e) => Map<String, dynamic>.from(e)).toList();
    final idx = netList.indexWhere((e) => e['empresaId'] == empresaId);
    if (idx >= 0) {
      netList[idx] = nueva.toJson();
    } else {
      netList.add(nueva.toJson());
    }
    await provider.catalogosBox.put(kNetworkStoresKey, netList);

    // 5) Supabase (para que otros dispositivos lo vean)
    if (provider.isOnline) {
      try {
        await provider.publicarTiendaEnRed(
          nombre: nueva.nombre,
          slug: nueva.slug,
          descripcion: nueva.descripcion,
          telefono: nueva.telefono,
          whatsapp: nueva.whatsapp,
          email: nueva.email,
          direccion: nueva.direccion,
          horario: nueva.horario,
          categoriaId: nueva.categoriaId,
          latitud: nueva.latitud,
          longitud: nueva.longitud,
          catalogo: nueva.catalogo.map((p) => p.toJson()).toList(),
          activa: nueva.activa,
        );
      } catch (e) {
        print('⚠️ Error sincronizando despublicación: $e');
      }
    }

    if (!mounted) return;
    setState(() => _tienda = nueva);
    mostrarSnackBar(mensaje: 'Producto despublicado', esExito: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    if (_cargando) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_tienda == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _C.primary.withOpacity(.16),
                      _C.cyan.withOpacity(.06),
                    ]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 38, color: _C.primary),
                ),
                const SizedBox(height: 16),
                Text('Primero configura tu tienda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                          context, '/mi-tienda')
                      .then((_) => _cargar()),
                  icon: const Icon(Icons.settings_rounded, size: 16),
                  label: const Text('Ir a Mi tienda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Productos publicados actuales (activos y con inventario en la empresa)
    final publicados = provider.productos
        .where((prod) =>
            _tienda!.productosPublicados.contains(prod.id))
        .toList();

    var filtrados = publicados.where((prod) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return prod.nombre.toLowerCase().contains(q) ||
          (prod.sku ?? '').toLowerCase().contains(q);
    }).toList();

    if (_filtro == 'Con stock') {
      filtrados = filtrados.where((prod) => prod.stock > 0).toList();
    } else if (_filtro == 'Sin stock') {
      filtrados = filtrados.where((prod) => prod.stock <= 0).toList();
    }

    final sinStock = publicados.where((prod) => prod.stock <= 0).length;
    final conStock = publicados.length - sinStock;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          RefreshIndicator(
            onRefresh: _cargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kpiStrip(publicados.length, conStock, sinStock, p),
                      const SizedBox(height: 16),
                      _searchBar(p),
                      const SizedBox(height: 12),
                      _filtros(p),
                      const SizedBox(height: 16),
                      if (filtrados.isEmpty)
                        _emptyState(p)
                      else
                        _grid(filtrados, provider, p),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'publicados_fab',
        onPressed: () => Navigator.pushNamed(
                context, '/publicar-producto')
            .then((_) => _cargar()),
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
        label: const Text(
          'Publicar más',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _background(_P p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -180, right: -160,
              child: _orb(420, _C.primary.withOpacity(p.dark ? .12 : .07)),
            ),
            Positioned(
              bottom: -220, left: -140,
              child: _orb(440, _C.cyan.withOpacity(p.dark ? .10 : .06)),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(_P p) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.inventory_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Publicados',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  )),
              Text('Productos en tu tienda',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiStrip(int total, int conStock, int sinStock, _P p) {
    return Row(
      children: [
        Expanded(
          child: _kpiTile(p,
              label: 'Total', value: '$total',
              color: _C.primary, icon: Icons.inventory_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiTile(p,
              label: 'Con stock', value: '$conStock',
              color: _C.success, icon: Icons.check_circle_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiTile(p,
              label: 'Sin stock', value: '$sinStock',
              color: _C.danger, icon: Icons.block_rounded),
        ),
      ],
    );
  }

  Widget _kpiTile(_P p,
      {required String label,
      required String value,
      required Color color,
      required IconData icon}) {
    return Container(
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
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(11),
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
                Text(value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: p.textHigh,
                    )),
                Text(label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        onChanged: (v) => setState(() => _busqueda = v),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.textHigh,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar producto publicado…',
          hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: p.textMuted),
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

  Widget _filtros(_P p) {
    final opciones = ['Todos', 'Con stock', 'Sin stock'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final op = opciones[i];
          final selected = _filtro == op;
          return Material(
            color: selected ? Colors.transparent : p.surface,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => setState(() => _filtro = op),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: _C.gradBrand)
                      : null,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected ? Colors.transparent : p.border,
                  ),
                ),
                child: Text(op,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: selected ? Colors.white : p.textMid,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grid(List<Producto> productos, AppProvider provider, _P p) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: productos.length,
      itemBuilder: (_, i) => _productoCard(productos[i], p),
    );
  }

  Widget _productoCard(Producto prod, _P p) {
    final sinStock = prod.stock <= 0;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sinStock ? _C.danger.withOpacity(.35) : p.border,
        ),
        boxShadow: p.shadowSm,
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
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Container(
                    color: p.surface2,
                    width: double.infinity,
                    height: double.infinity,
                    child: CachedProductImage(
                      url: prod.imageUrl,
                      productName: prod.nombre,
                      width: double.infinity,
                      height: double.infinity,
                      radius: 0,
                      fit: BoxFit.cover,
                      agotado: sinStock,
                      accent: _C.primary,
                      dangerAccent: _C.danger,
                    ),
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: sinStock
                            ? [_C.danger, const Color(0xFFEC4899)]
                            : _C.gradBrand,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (sinStock ? _C.danger : _C.primary)
                              .withOpacity(.32),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sinStock
                              ? Icons.block_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sinStock ? 'SIN STOCK' : 'PUBLICADO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Material(
                    color: Colors.black.withOpacity(.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _confirmarDespublicar(prod),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(prod.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          color: p.textHigh,
                          letterSpacing: -0.1,
                        )),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            '\$${prod.precioVenta.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: _C.success,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (sinStock ? _C.danger : _C.success)
                              .withOpacity(.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_fmt(prod.stock)} ${prod.unidadMedida}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: sinStock ? _C.danger : _C.success,
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
    );
  }

  Future<void> _confirmarDespublicar(Producto prod) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Despublicar producto'),
        content: Text(
            '¿Quieres quitar "${prod.nombre}" de tu tienda pública?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _C.danger),
            child: const Text('Despublicar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _despublicar(prod.id);
    }
  }

  Widget _emptyState(_P p) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.primary.withOpacity(.16),
                _C.cyan.withOpacity(.06),
              ]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_rounded,
                size: 38, color: _C.primary),
          ),
          const SizedBox(height: 16),
          Text('Sin productos publicados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              )),
          const SizedBox(height: 6),
          Text(
            'Publica productos desde tu inventario para mostrarlos aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}