// ============================================================
//  productos_screen.dart  ·  NEXORA BUSINESS
//  Inventario premium · Grid/List · Panel detalle izquierda
//  Sistema de etiquetas con alta presencia visual
//  Imágenes con caché persistente + offline
//  Tema: Azul Eléctrico #1A5CFF + Cyan #06B6D4
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nexora_business/screens/servicio_cancelado_screen.dart';
import 'package:nexora_business/screens/nuevo_producto_screen.dart';
import 'package:nexora_business/screens/reabastecer_screen.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../widgets/cached_product_image.dart';
import '../services/image_cache_warmer.dart';

// ============================================================
//  Acentos compartidos (theme-independent)
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const primaryDk = Color(0xFF4A8BFF);
  static const cyan      = Color(0xFF06B6D4);
  static const cyanDk    = Color(0xFF22D3EE);
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

// ============================================================
//  Paleta theme-aware
// ============================================================
class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg0          => dark ? const Color(0xFF071020) : const Color(0xFFF1F6FE);
  Color get bg1          => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface      => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2     => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3     => dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);

  Color get textHigh     => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid      => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted    => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);

  Color get border       => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(0.35)
              : const Color(0xFF0A1A33).withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ];

  List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(0.45)
              : const Color(0xFF0A1A33).withOpacity(0.09),
          blurRadius: 30,
          offset: const Offset(0, 12),
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

enum _VistaMode { grid, list }
enum _ProductTag {
  topSeller,
  popular,
  lowStock,
  outOfStock,
  newProduct,
  available,
}

// ============================================================
//  SCREEN
// ============================================================
class ProductosScreen extends StatefulWidget {
  const ProductosScreen({Key? key}) : super(key: key);

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _search = '';
  String _categoriaId = 'Todas';
  String? _sucursalFiltroId;
  bool _soloAgotados = false;
  bool _soloBajoStock = false;
  bool _ordenStockAsc = true;

  int _visible = 24;
  static const _step = 24;

  Producto? _seleccionado;
  _VistaMode _vista = _VistaMode.grid;

  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = Provider.of<AppProvider>(context, listen: false);
      final isAdmin = p.rol == 'admin' || p.rol == 'dueno';
      if (isAdmin && p.sucursales.isNotEmpty) {
        setState(() => _sucursalFiltroId = p.sucursales.first.id);
      }
      // 🔥 Pre-descarga de imágenes para uso offline
      ImageCacheWarmer.warmInBackground(
        p.productos.map((x) => x.imageUrl),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isAdmin(AppProvider p) => p.rol == 'admin' || p.rol == 'dueno';
  bool _isManager(AppProvider p) =>
      _isAdmin(p) || p.rol == 'gerente' || p.rol == 'gestor';

  void _resetPaging() {
    _visible = 24;
    _seleccionado = null;
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
        final isDesktop = ResponsiveHelper.isDesktop();
        final isManager = _isManager(provider);

        final base = _getBase(provider);

        // Ranking de ventas (para badges)
        final ventasPorProd = <String, double>{};
        for (final v in provider.ventas) {
          ventasPorProd[v.productoId] =
              (ventasPorProd[v.productoId] ?? 0.0) + v.cantidad;
        }
        final rankedIds = ventasPorProd.keys.toList()
          ..sort((a, b) =>
              (ventasPorProd[b] ?? 0).compareTo(ventasPorProd[a] ?? 0));
        final top1 = rankedIds.isNotEmpty ? rankedIds.first : null;
        final top5 = rankedIds.take(5).toList();

        // Filtrado
        var lista = base.where((prod) {
          final q = _search.toLowerCase().trim();
          if (q.isEmpty) return true;
          final n = prod.nombre.toLowerCase();
          final c = provider
              .getNombreCategoria(prod.categoriaId)
              .toLowerCase();
          final sku = (prod.sku ?? '').toLowerCase();
          final bc = (prod.barcode ?? '').toLowerCase();
          return n.contains(q) ||
              c.contains(q) ||
              sku.contains(q) ||
              bc.contains(q);
        }).toList();

        if (_categoriaId != 'Todas') {
          lista = lista
              .where((prod) => prod.categoriaId == _categoriaId)
              .toList();
        }
        if (_soloAgotados) {
          lista = lista.where((prod) => prod.stock <= 0).toList();
        }
        if (_soloBajoStock) {
          lista = lista
              .where((prod) => prod.stock > 0 && prod.stock < 5)
              .toList();
        }
        lista.sort((a, b) => _ordenStockAsc
            ? a.stock.compareTo(b.stock)
            : b.stock.compareTo(a.stock));

        // KPIs
        int total = base.length;
        double valorInventario = 0;
        double margenPotencial = 0;
        int agotados = 0;
        int bajos = 0;
        for (final prod in base) {
          valorInventario += prod.stock * prod.precioCompra;
          margenPotencial +=
              prod.stock * (prod.precioVenta - prod.precioCompra);
          if (prod.stock <= 0) {
            agotados++;
          } else if (prod.stock < 5) {
            bajos++;
          }
        }

        final mostrados = lista.take(_visible).toList();
        final hayMas = lista.length > _visible;
        final isEmpty = lista.isEmpty;

        if (isDesktop && _seleccionado == null && mostrados.isNotEmpty) {
          _seleccionado = mostrados.first;
        }
        if (isDesktop && _seleccionado != null) {
          final stillThere =
              mostrados.any((prod) => prod.id == _seleccionado!.id);
          if (!stillThere) {
            _seleccionado =
                mostrados.isNotEmpty ? mostrados.first : null;
          }
        }

        return Scaffold(
          backgroundColor: p.bg1,
          body: Stack(
            children: [
              Positioned(
                top: -200,
                right: -160,
                child: IgnorePointer(
                  child: Container(
                    width: 460,
                    height: 460,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _C.primary.withOpacity(isDark ? .14 : .08),
                          _C.primary.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -240,
                left: -140,
                child: IgnorePointer(
                  child: Container(
                    width: 440,
                    height: 440,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _C.cyan.withOpacity(isDark ? .12 : .07),
                          _C.cyan.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(context, provider, p, isManager, isDesktop),
                    if (isDesktop) _filterBar(context, provider, p),
                    Expanded(
                      child: isDesktop
                          ? _desktopBody(
                              context,
                              provider,
                              p,
                              mostrados,
                              isEmpty,
                              hayMas,
                              lista.length,
                              _seleccionado,
                              total,
                              valorInventario,
                              margenPotencial,
                              agotados,
                              bajos,
                              top1,
                              top5,
                              isManager,
                            )
                          : _mobileBody(
                              context,
                              provider,
                              p,
                              mostrados,
                              isEmpty,
                              hayMas,
                              lista.length,
                              total,
                              valorInventario,
                              margenPotencial,
                              agotados,
                              bajos,
                              top1,
                              top5,
                              isManager,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: !isDesktop && isManager
              ? _newProductFab(context)
              : null,
        );
      },
    );
  }

  List<Producto> _getBase(AppProvider provider) {
    final isAdmin = _isAdmin(provider);
    if (isAdmin && _sucursalFiltroId != null) {
      return provider.productos
          .where((prod) => prod.sucursalId == _sucursalFiltroId)
          .toList();
    }
    if (isAdmin) return provider.productos;
    return provider.productosFiltrados;
  }

  // ============================================================
  //  SISTEMA DE ETIQUETAS (tags)
  // ============================================================
  _ProductTag _tagFor(Producto p, String? top1, List<String> top5) {
    if (p.stock <= 0) return _ProductTag.outOfStock;
    if (p.stock < 5) return _ProductTag.lowStock;
    if (top1 != null && p.id == top1) return _ProductTag.topSeller;
    if (top5.contains(p.id)) return _ProductTag.popular;
    if (p.updatedAt != null &&
        DateTime.now().difference(p.updatedAt!).inDays <= 7) {
      return _ProductTag.newProduct;
    }
    return _ProductTag.available;
  }

  Widget _productTag(_ProductTag tag, {bool compact = false}) {
    late String label;
    late IconData icon;
    late List<Color> gradient;
    late Color solid;

    switch (tag) {
      case _ProductTag.topSeller:
        label = 'TOP VENDIDO';
        icon = Icons.emoji_events_rounded;
        gradient = _C.gradGold;
        solid = _C.gold;
        break;
      case _ProductTag.popular:
        label = 'MÁS VENDIDO';
        icon = Icons.local_fire_department_rounded;
        gradient = _C.gradWarm;
        solid = _C.orange;
        break;
      case _ProductTag.lowStock:
        label = 'POR AGOTARSE';
        icon = Icons.trending_down_rounded;
        gradient = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
        solid = _C.warning;
        break;
      case _ProductTag.outOfStock:
        label = 'AGOTADO';
        icon = Icons.block_rounded;
        gradient = _C.gradDanger;
        solid = _C.danger;
        break;
      case _ProductTag.newProduct:
        label = 'NUEVO';
        icon = Icons.auto_awesome_rounded;
        gradient = [_C.cyan, _C.primary];
        solid = _C.cyan;
        break;
      case _ProductTag.available:
        label = 'DISPONIBLE';
        icon = Icons.check_circle_rounded;
        gradient = _C.gradSuccess;
        solid = _C.success;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: solid.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: solid.withOpacity(0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  TOP BAR
  // ============================================================
  Widget _topBar(
    BuildContext context,
    AppProvider provider,
    _P p,
    bool isManager,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 12, 12, isDesktop ? 20 : 8, 8),
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
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_rounded, color: p.textMid),
            ),
          SizedBox(width: isDesktop ? 8 : 12),

          Expanded(
            child: _showSearch && !isDesktop
                ? _searchField(context, p)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Inventario',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4,
                              color: p.textHigh,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: _C.gradBrand),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${provider.productos.length}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isDesktop)
                        Text(
                          'Gestiona tu catálogo completo',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textMuted,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),

          if (!isDesktop)
            IconButton(
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchCtrl.clear();
                    _search = '';
                    _resetPaging();
                  }
                });
              },
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: p.textHigh,
              ),
            ),

          if (isDesktop) ...[
            SizedBox(width: 300, child: _searchField(context, p)),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.borderStrong),
              ),
              child: Row(
                children: [
                  _vistaBtn(
                    icon: Icons.grid_view_rounded,
                    selected: _vista == _VistaMode.grid,
                    p: p,
                    onTap: () =>
                        setState(() => _vista = _VistaMode.grid),
                  ),
                  _vistaBtn(
                    icon: Icons.view_list_rounded,
                    selected: _vista == _VistaMode.list,
                    p: p,
                    onTap: () =>
                        setState(() => _vista = _VistaMode.list),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          PopupMenuButton<String>(
            tooltip: 'Ordenar y filtrar',
            icon: Icon(Icons.tune_rounded, color: p.textHigh),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            color: p.surface,
            onSelected: (v) {
              setState(() {
                switch (v) {
                  case 'stock_asc':
                    _ordenStockAsc = true;
                    break;
                  case 'stock_desc':
                    _ordenStockAsc = false;
                    break;
                  case 'agotados':
                    _soloAgotados = !_soloAgotados;
                    if (_soloAgotados) _soloBajoStock = false;
                    break;
                  case 'bajos':
                    _soloBajoStock = !_soloBajoStock;
                    if (_soloBajoStock) _soloAgotados = false;
                    break;
                }
                _resetPaging();
              });
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'stock_asc',
                checked: _ordenStockAsc,
                child: const Text('Stock: menor a mayor'),
              ),
              CheckedPopupMenuItem(
                value: 'stock_desc',
                checked: !_ordenStockAsc,
                child: const Text('Stock: mayor a menor'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'agotados',
                checked: _soloAgotados,
                child: const Text('Solo agotados'),
              ),
              CheckedPopupMenuItem(
                value: 'bajos',
                checked: _soloBajoStock,
                child: const Text('Solo por agotarse'),
              ),
            ],
          ),

          if (isDesktop && isManager) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/nuevo-producto'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo producto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vistaBtn({
    required IconData icon,
    required bool selected,
    required _P p,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? _C.primary.withOpacity(p.dark ? .20 : .10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Icon(
            icon,
            size: 17,
            color: selected ? _C.primary : p.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context, _P p) {
    return TextField(
      controller: _searchCtrl,
      autofocus: _showSearch && !ResponsiveHelper.isDesktop(),
      onChanged: (v) {
        setState(() {
          _search = v;
          _resetPaging();
        });
      },
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar nombre, SKU o categoría…',
        hintStyle: TextStyle(color: p.textMuted, fontSize: 13.5),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: p.textMuted,
        ),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: p.textMuted),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _search = '';
                    _resetPaging();
                  });
                },
              )
            : null,
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.borderStrong, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.primary, width: 1.6),
        ),
      ),
    );
  }

  Widget _filterBar(
      BuildContext context, AppProvider provider, _P p) {
    final isAdmin = _isAdmin(provider);
    final cats = provider.listaCategoriasIds;

    final base = _getBase(provider);
    final counts = <String, int>{};
    for (final prod in base) {
      final id = prod.categoriaId ?? '__none__';
      counts[id] = (counts[id] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Row(
        children: [
          if (isAdmin && provider.sucursales.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.borderStrong),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sucursalFiltroId,
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: p.textMuted),
                  dropdownColor: p.surface,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _sucursalFiltroId = v;
                      _categoriaId = 'Todas';
                      _search = '';
                      _searchCtrl.clear();
                      _resetPaging();
                    });
                  },
                  items: provider.sucursales.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 15, color: _C.primary),
                          const SizedBox(width: 8),
                          Text(s.nombre),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          if (isAdmin && provider.sucursales.isNotEmpty)
            const SizedBox(width: 12),

          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final id = cats[i];
                  final selected = _categoriaId == id;
                  final label = id == 'Todas'
                      ? 'Todas'
                      : provider.getNombreCategoria(id);
                  final count = id == 'Todas'
                      ? base.length
                      : (counts[id] ?? 0);
                  return _chipFilter(
                    label: label,
                    count: count,
                    selected: selected,
                    p: p,
                    onTap: () {
                      setState(() {
                        _categoriaId = id;
                        _resetPaging();
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFilter({
    required String label,
    required int count,
    required bool selected,
    required _P p,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.transparent : p.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : p.textMid,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(.25)
                      : _C.primary.withOpacity(p.dark ? .18 : .10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : _C.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  IMAGEN (usa caché persistente)
  // ============================================================
  Widget _productImage(Producto prod, _P p,
      {double size = 40, double radius = 11}) {
    return CachedProductImage(
      url: prod.imageUrl,
      productName: prod.nombre,
      width: size,
      height: size,
      radius: radius,
      agotado: prod.stock <= 0,
      accent: _C.primary,
      dangerAccent: _C.danger,
    );
  }

  Widget _heroFallback(Producto prod, _P p) {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.primary.withOpacity(.20),
              _C.cyan.withOpacity(.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            prod.nombre.isNotEmpty
                ? prod.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _C.primary,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MOBILE BODY
  // ============================================================
  Widget _mobileBody(
    BuildContext context,
    AppProvider provider,
    _P p,
    List<Producto> mostrados,
    bool isEmpty,
    bool hayMas,
    int totalFiltrado,
    int total,
    double valorInventario,
    double margenPotencial,
    int agotados,
    int bajos,
    String? top1,
    List<String> top5,
    bool isManager,
  ) {
    return Column(
      children: [
        _mobileStats(p, total, valorInventario, margenPotencial, agotados,
            bajos, isManager),
        _mobileCategoryStrip(context, provider, p),
        Expanded(
          child: isEmpty
              ? _emptyState(p)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: mostrados.length + (hayMas ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == mostrados.length && hayMas) {
                      return _loadMoreButton(
                          context, totalFiltrado, p);
                    }
                    final prod = mostrados[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _productCardMobile(
                          context, prod, provider, p, isManager, top1, top5),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _mobileStats(
    _P p,
    int total,
    double valorInv,
    double margen,
    int agotados,
    int bajos,
    bool isManager,
  ) {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.inventory_2_rounded,
        'label': 'Productos',
        'value': '$total',
        'color': _C.primary,
      },
      {
        'icon': Icons.attach_money_rounded,
        'label': 'Costo',
        'value': '\$${_fmt(valorInv)}',
        'color': _C.warning,
      },
      if (isManager)
        {
          'icon': Icons.trending_up_rounded,
          'label': 'Margen',
          'value': '\$${_fmt(margen)}',
          'color': _C.success,
        },
      {
        'icon': Icons.trending_down_rounded,
        'label': 'Por agotarse',
        'value': '$bajos',
        'color': _C.orange,
      },
      {
        'icon': Icons.block_rounded,
        'label': 'Agotados',
        'value': '$agotados',
        'color': _C.danger,
      },
    ];

    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final color = it['color'] as Color;
          return Container(
            width: 138,
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
                  width: 36,
                  height: 36,
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
                  child: Icon(it['icon'] as IconData,
                      color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          it['value'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                            color: p.textHigh,
                          ),
                        ),
                      ),
                      Text(
                        it['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mobileCategoryStrip(
      BuildContext context, AppProvider provider, _P p) {
    final cats = provider.listaCategoriasIds;
    final base = _getBase(provider);
    final counts = <String, int>{};
    for (final prod in base) {
      final id = prod.categoriaId ?? '__none__';
      counts[id] = (counts[id] ?? 0) + 1;
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final id = cats[i];
          final selected = _categoriaId == id;
          final label =
              id == 'Todas' ? 'Todas' : provider.getNombreCategoria(id);
          final count =
              id == 'Todas' ? base.length : (counts[id] ?? 0);
          return _chipFilter(
            label: label,
            count: count,
            selected: selected,
            p: p,
            onTap: () {
              setState(() {
                _categoriaId = id;
                _resetPaging();
              });
            },
          );
        },
      ),
    );
  }

  // ============================================================
  //  DESKTOP BODY · PANEL DETALLE A LA IZQUIERDA
  // ============================================================
  Widget _desktopBody(
    BuildContext context,
    AppProvider provider,
    _P p,
    List<Producto> mostrados,
    bool isEmpty,
    bool hayMas,
    int totalFiltrado,
    Producto? seleccionado,
    int total,
    double valorInv,
    double margen,
    int agotados,
    int bajos,
    String? top1,
    List<String> top5,
    bool isManager,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _desktopKpis(total, valorInv, margen, agotados, bajos, p,
              isManager),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── IZQUIERDA: Detalle + acciones
                SizedBox(
                  width: 400,
                  child: _desktopDetailPanel(
                    context,
                    seleccionado,
                    provider,
                    p,
                    isManager,
                    top1,
                    top5,
                  ),
                ),
                const SizedBox(width: 16),
                // ─── CENTRO/DERECHA: Lista
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.border),
                      boxShadow: p.shadowSm,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 14, 20, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: _C.gradBrand),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: p.glow(_C.primary, o: 0.25),
                                ),
                                child: const Icon(
                                    Icons.inventory_2_rounded,
                                    size: 17,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Catálogo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.2,
                                  color: p.textHigh,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _C.primary
                                      .withOpacity(p.dark ? .18 : .10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$totalFiltrado',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _C.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_soloAgotados)
                                _filterTag('Solo agotados', _C.danger),
                              if (_soloBajoStock)
                                _filterTag('Por agotarse', _C.orange),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: p.border),
                        Expanded(
                          child: isEmpty
                              ? _emptyState(p)
                              : _vista == _VistaMode.grid
                                  ? _gridView(
                                      context,
                                      mostrados,
                                      provider,
                                      p,
                                      isManager,
                                      top1,
                                      top5,
                                      seleccionado,
                                      hayMas,
                                      totalFiltrado,
                                    )
                                  : _listView(
                                      context,
                                      mostrados,
                                      provider,
                                      p,
                                      isManager,
                                      top1,
                                      top5,
                                      seleccionado,
                                      hayMas,
                                      totalFiltrado,
                                    ),
                        ),
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
  }

  Widget _filterTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _gridView(
    BuildContext context,
    List<Producto> mostrados,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
    Producto? seleccionado,
    bool hayMas,
    int totalFiltrado,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.80,
      ),
      itemCount: mostrados.length + (hayMas ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == mostrados.length && hayMas) {
          return _loadMoreTile(context, totalFiltrado, p);
        }
        final prod = mostrados[i];
        final isSel = seleccionado?.id == prod.id;
        return _productGridCard(
            context, prod, provider, p, isManager, top1, top5, isSel);
      },
    );
  }

  Widget _listView(
    BuildContext context,
    List<Producto> mostrados,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
    Producto? seleccionado,
    bool hayMas,
    int totalFiltrado,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: mostrados.length + (hayMas ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == mostrados.length && hayMas) {
          return _loadMoreButton(context, totalFiltrado, p);
        }
        final prod = mostrados[i];
        final isSel = seleccionado?.id == prod.id;
        return _productRowDesktop(
          context,
          prod,
          provider,
          p,
          isManager,
          top1,
          top5,
          isSel,
          () => setState(() => _seleccionado = prod),
        );
      },
    );
  }

  // ============================================================
  //  GRID CARD (desktop)
  // ============================================================
  Widget _productGridCard(
    BuildContext context,
    Producto prod,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
    bool selected,
  ) {
    final tag = _tagFor(prod, top1, top5);
    final stockRatio = prod.stock <= 0
        ? 0.0
        : (prod.stock / 20).clamp(0.0, 1.0);

    return Material(
      color: selected
          ? _C.primary.withOpacity(p.dark ? .10 : .04)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _seleccionado = prod),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? _C.primary.withOpacity(.55)
                  : p.border,
              width: selected ? 1.6 : 1.2,
            ),
            boxShadow: selected ? p.glow(_C.primary, o: 0.20) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Container(
                        color: p.surface2,
                        child: CachedProductImage(
                          url: prod.imageUrl,
                          productName: prod.nombre,
                          width: double.infinity,
                          height: double.infinity,
                          radius: 0,
                          fit: BoxFit.cover,
                          agotado: prod.stock <= 0,
                          accent: _C.primary,
                          dangerAccent: _C.danger,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _productTag(tag, compact: true),
                    ),
                    if (prod.stock > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_fmt(prod.stock)} ${prod.unidadMedida}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.local_offer_rounded,
                              size: 10, color: p.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              provider
                                  .getNombreCategoria(prod.categoriaId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 4,
                          color: p.border,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: stockRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: prod.stock <= 0
                                      ? _C.gradDanger
                                      : prod.stock < 5
                                          ? _C.gradWarm
                                          : _C.gradSuccess,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VENTA',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .6,
                                    color: p.textMuted,
                                  ),
                                ),
                                Text(
                                  '\$${prod.precioVenta.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.5,
                                    color: _C.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isManager)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'MARGEN',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .6,
                                    color: p.textMuted,
                                  ),
                                ),
                                Text(
                                  '\$${(prod.precioVenta - prod.precioCompra).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _C.cyan,
                                  ),
                                ),
                              ],
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

  Widget _loadMoreTile(BuildContext context, int total, _P p) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _visible += _step),
        child: Container(
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _C.primary.withOpacity(.25),
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  shape: BoxShape.circle,
                  boxShadow: p.glow(_C.primary, o: 0.30),
                ),
                child: const Icon(Icons.expand_more_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                'Cargar más',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_visible de $total',
                style: TextStyle(
                  fontSize: 11,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopKpis(
    int total,
    double valorInv,
    double margen,
    int agotados,
    int bajos,
    _P p,
    bool isManager,
  ) {
    final tiles = <Widget>[
      _kpiTile('Total', '$total', Icons.inventory_2_rounded,
          _C.primary, p),
      _kpiTile('Valor inventario', '\$${_fmt(valorInv)}',
          Icons.attach_money_rounded, _C.warning, p),
      if (isManager)
        _kpiTile('Margen potencial', '\$${_fmt(margen)}',
            Icons.trending_up_rounded, _C.success, p),
      _kpiTile('Por agotarse', '$bajos',
          Icons.trending_down_rounded, _C.orange, p),
      _kpiTile('Agotados', '$agotados', Icons.block_rounded, _C.danger, p),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i != tiles.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _kpiTile(
      String title, String value, IconData icon, Color color, _P p) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(.22), color.withOpacity(.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
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
                      letterSpacing: -.5,
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
  //  LIST ROW (desktop)
  // ============================================================
  Widget _productRowDesktop(
    BuildContext context,
    Producto prod,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
    bool selected,
    VoidCallback onTap,
  ) {
    final tag = _tagFor(prod, top1, top5);
    final agotado = prod.stock <= 0;

    return Material(
      color: selected
          ? _C.primary.withOpacity(p.dark ? .14 : .08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _productImage(prod, p, size: 52, radius: 14),
              const SizedBox(width: 14),
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
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.2,
                              color: p.textHigh,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _productTag(tag, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_offer_rounded,
                            size: 11, color: p.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          provider
                              .getNombreCategoria(prod.categoriaId),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.storefront_rounded,
                            size: 11, color: p.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _sucursalNombre(provider, prod.sucursalId),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmt(prod.stock)} ${prod.unidadMedida}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: agotado
                          ? _C.danger
                          : (prod.stock < 5 ? _C.orange : p.textHigh),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${prod.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: _C.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: selected ? _C.primary : p.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  DETAIL PANEL · IZQUIERDA
  // ============================================================
  Widget _desktopDetailPanel(
    BuildContext context,
    Producto? producto,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
  ) {
    if (producto == null) {
      return Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: p.shadowSm,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.primary.withOpacity(.16),
                        _C.cyan.withOpacity(.06),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 38,
                    color: _C.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona un producto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aquí verás todos los detalles,\nprecios y acciones rápidas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tag = _tagFor(producto, top1, top5);
    final margenUnit = producto.precioVenta - producto.precioCompra;
    final margenPct = producto.precioCompra > 0
        ? (margenUnit / producto.precioCompra * 100)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: (producto.imageUrl != null &&
                        producto.imageUrl!.isNotEmpty)
                    ? () => _mostrarImagenFullscreen(
                        context, producto.imageUrl!)
                    : null,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: p.dark
                          ? [
                              _C.primary.withOpacity(.18),
                              _C.cyan.withOpacity(.04),
                            ]
                          : [
                              _C.primary.withOpacity(.08),
                              _C.cyan.withOpacity(.02),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: CachedProductImage(
                    url: producto.imageUrl,
                    productName: producto.nombre,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 19,
                    fit: BoxFit.cover,
                    agotado: producto.stock <= 0,
                    accent: _C.primary,
                    dangerAccent: _C.danger,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _productTag(tag),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black.withOpacity(.5),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NuevoProductoScreen(producto: producto),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (producto.imageUrl != null &&
                  producto.imageUrl!.isNotEmpty)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Ampliar',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                    height: 1.2,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        size: 12, color: p.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      provider.getNombreCategoria(producto.categoriaId),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _stockIndicator(producto, p),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Información', p),
                  const SizedBox(height: 10),
                  _infoTile(
                    Icons.inventory_2_rounded,
                    'Stock actual',
                    '${_fmt(producto.stock)} ${producto.unidadMedida}',
                    p,
                    valueColor: producto.stock <= 0
                        ? _C.danger
                        : (producto.stock < 5 ? _C.orange : null),
                  ),
                  _infoTile(
                    Icons.storefront_rounded,
                    'Sucursal',
                    _sucursalNombre(provider, producto.sucursalId),
                    p,
                  ),
                  if (producto.sku != null &&
                      producto.sku!.isNotEmpty)
                    _infoTile(Icons.qr_code_rounded, 'SKU',
                        producto.sku!, p),
                  if (producto.barcode != null &&
                      producto.barcode!.isNotEmpty)
                    _infoTile(Icons.qr_code_2_rounded, 'Código de barras',
                        producto.barcode!, p),

                  if (isManager) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Precios', p),
                    const SizedBox(height: 10),
                    _infoTile(
                      Icons.attach_money_rounded,
                      'Costo',
                      '\$${producto.precioCompra.toStringAsFixed(2)}',
                      p,
                    ),
                    _infoTile(
                      Icons.monetization_on_rounded,
                      'Venta efectivo',
                      '\$${producto.precioVenta.toStringAsFixed(2)}',
                      p,
                      valueColor: _C.success,
                    ),
                    _infoTile(
                      Icons.credit_card_rounded,
                      'Venta transferencia',
                      '\$${producto.precioTransferencia.toStringAsFixed(2)}',
                      p,
                      valueColor: _C.info,
                    ),
                    _infoTile(
                      Icons.shopping_bag_rounded,
                      'Mayorista efectivo',
                      '\$${producto.precioMayoristaEfectivo.toStringAsFixed(2)}',
                      p,
                    ),
                    _infoTile(
                      Icons.payment_rounded,
                      'Mayorista transferencia',
                      '\$${producto.precioMayoristaTransferencia.toStringAsFixed(2)}',
                      p,
                    ),

                    const SizedBox(height: 12),
                    _margenBlock(margenUnit, margenPct, p),
                  ],

                  if (isManager && producto.lotes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Reabastecimiento', p),
                    const SizedBox(height: 8),
                    ...producto.lotes.reversed.take(5).map((l) {
                      final cant =
                          (l['cantidad'] as num?)?.toDouble() ?? 0.0;
                      final precio =
                          (l['precioCompra'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _C.success
                                    .withOpacity(p.dark ? .14 : .08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.add_box_rounded,
                                size: 14,
                                color: _C.success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '+${_fmt(cant)} ${producto.unidadMedida}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.textHigh,
                                ),
                              ),
                            ),
                            Text(
                              '\$${precio.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          if (isManager)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Reabastecer',
                          icon: Icons.add_box_rounded,
                          color: _C.success,
                          p: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReabastecerScreen(productoId: producto.id),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'Editar',
                          icon: Icons.edit_rounded,
                          color: _C.primary,
                          p: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NuevoProductoScreen(producto: producto),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Mover',
                          icon: Icons.swap_horiz_rounded,
                          color: _C.info,
                          p: p,
                          onTap: () => _dialogMover(context, producto),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: 'Merma',
                          icon: Icons.warning_amber_rounded,
                          color: _C.warning,
                          p: p,
                          onTap: () => _dialogMerma(context, producto),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stockIndicator(Producto prod, _P p) {
    final agotado = prod.stock <= 0;
    final bajo = prod.stock > 0 && prod.stock < 5;
    final color = agotado
        ? _C.danger
        : (bajo ? _C.orange : _C.success);
    final label = agotado
        ? 'Sin existencias'
        : (bajo ? 'Por agotarse' : 'Disponible');
    final ratio = agotado ? 0.0 : (prod.stock / 30).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              agotado
                  ? Icons.block_rounded
                  : (bajo
                      ? Icons.trending_down_rounded
                      : Icons.check_circle_rounded),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '${_fmt(prod.stock)} ${prod.unidadMedida}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 6,
            color: p.border,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: agotado
                        ? _C.gradDanger
                        : (bajo ? _C.gradWarm : _C.gradSuccess),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _margenBlock(double margenUnit, double margenPct, _P p) {
    final positivo = margenUnit > 0;
    final color = positivo ? _C.success : _C.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(p.dark ? .16 : .08),
            color.withOpacity(.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.32)),
            ),
            child: Icon(Icons.trending_up_rounded,
                size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Margen unitario',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${margenUnit.toStringAsFixed(2)}  ·  ${margenPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarImagenFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.94),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(child: CachedImageViewer(url: url)),
              Positioned(
                top: 40,
                right: 20,
                child: Material(
                  color: Colors.white.withOpacity(.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, _P p) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: p.textMuted,
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value,
    _P p, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(p.dark ? .14 : .08),
              borderRadius: BorderRadius.circular(9),
              border:
                  Border.all(color: _C.primary.withOpacity(.16)),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: valueColor ?? p.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required _P p,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(p.dark ? .16 : .10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MOBILE CARD
  // ============================================================
  Widget _productCardMobile(
    BuildContext context,
    Producto prod,
    AppProvider provider,
    _P p,
    bool isManager,
    String? top1,
    List<String> top5,
  ) {
    final tag = _tagFor(prod, top1, top5);
    final stockRatio = prod.stock <= 0
        ? 0.0
        : (prod.stock / 20).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Slidable(
        key: ValueKey(prod.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.55,
          children: [
            if (isManager)
              SlidableAction(
                onPressed: (_) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReabastecerScreen(productoId: prod.id),
                  ),
                ),
                backgroundColor: _C.success,
                foregroundColor: Colors.white,
                icon: Icons.add_box_rounded,
                label: 'Reabastecer',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            if (isManager)
              SlidableAction(
                onPressed: (_) => _dialogMerma(context, prod),
                backgroundColor: _C.warning,
                foregroundColor: Colors.white,
                icon: Icons.warning_amber_rounded,
                label: 'Merma',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                _showMobileDetail(context, prod, provider, p, isManager),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _productImage(prod, p, size: 68, radius: 15),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    prod.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.2,
                                      color: p.textHigh,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _productTag(tag, compact: true),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.local_offer_rounded,
                                    size: 10, color: p.textMuted),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    provider.getNombreCategoria(
                                        prod.categoriaId),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniInfo(
                                    'Stock',
                                    '${_fmt(prod.stock)} ${prod.unidadMedida}',
                                    prod.stock <= 0
                                        ? _C.danger
                                        : (prod.stock < 5
                                            ? _C.orange
                                            : _C.success),
                                    p,
                                  ),
                                ),
                                Expanded(
                                  child: _miniInfo(
                                    'Venta',
                                    '\$${prod.precioVenta.toStringAsFixed(2)}',
                                    _C.success,
                                    p,
                                  ),
                                ),
                                if (isManager)
                                  Expanded(
                                    child: _miniInfo(
                                      'Margen',
                                      '\$${(prod.precioVenta - prod.precioCompra).toStringAsFixed(2)}',
                                      _C.cyan,
                                      p,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      color: p.border,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: stockRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: prod.stock <= 0
                                  ? _C.gradDanger
                                  : prod.stock < 5
                                      ? _C.gradWarm
                                      : _C.gradSuccess,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(
      String label, String value, Color valueColor, _P p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  MOBILE · DETALLE
  // ============================================================
  void _showMobileDetail(
    BuildContext context,
    Producto producto,
    AppProvider provider,
    _P p,
    bool isManager,
  ) {
    final margenUnit = producto.precioVenta - producto.precioCompra;
    final margenPct = producto.precioCompra > 0
        ? (margenUnit / producto.precioCompra * 100)
        : 0.0;
    final hasImg = producto.imageUrl != null &&
        producto.imageUrl!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Container(
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasImg)
                        GestureDetector(
                          onTap: () => _mostrarImagenFullscreen(
                              context, producto.imageUrl!),
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: CachedProductImage(
                              url: producto.imageUrl,
                              productName: producto.nombre,
                              width: double.infinity,
                              height: double.infinity,
                              radius: 18,
                              fit: BoxFit.cover,
                              agotado: producto.stock <= 0,
                              accent: _C.primary,
                              dangerAccent: _C.danger,
                            ),
                          ),
                        ),
                      if (hasImg) const SizedBox(height: 16),

                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                          height: 1.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.local_offer_rounded,
                              size: 12, color: p.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            provider
                                .getNombreCategoria(producto.categoriaId),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _stockIndicator(producto, p),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _priceTag(
                              'Efectivo',
                              '\$${producto.precioVenta.toStringAsFixed(2)}',
                              _C.success,
                              p,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _priceTag(
                              'Transferencia',
                              '\$${producto.precioTransferencia.toStringAsFixed(2)}',
                              _C.info,
                              p,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _sectionTitle('Información', p),
                      const SizedBox(height: 8),
                      _infoTile(
                        Icons.inventory_2_rounded,
                        'Stock actual',
                        '${_fmt(producto.stock)} ${producto.unidadMedida}',
                        p,
                        valueColor: producto.stock <= 0
                            ? _C.danger
                            : (producto.stock < 5 ? _C.orange : null),
                      ),
                      _infoTile(
                        Icons.storefront_rounded,
                        'Sucursal',
                        _sucursalNombre(provider, producto.sucursalId),
                        p,
                      ),

                      if (isManager) ...[
                        const SizedBox(height: 18),
                        _sectionTitle('Precios', p),
                        const SizedBox(height: 8),
                        _infoTile(
                          Icons.attach_money_rounded,
                          'Costo',
                          '\$${producto.precioCompra.toStringAsFixed(2)}',
                          p,
                        ),
                        _infoTile(
                          Icons.shopping_bag_rounded,
                          'Mayorista efectivo',
                          '\$${producto.precioMayoristaEfectivo.toStringAsFixed(2)}',
                          p,
                        ),
                        _infoTile(
                          Icons.payment_rounded,
                          'Mayorista transferencia',
                          '\$${producto.precioMayoristaTransferencia.toStringAsFixed(2)}',
                          p,
                        ),
                        const SizedBox(height: 12),
                        _margenBlock(margenUnit, margenPct, p),
                      ],

                      if (isManager) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('Acciones', p),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.6,
                          children: [
                            _actionButton(
                              label: 'Reabastecer',
                              icon: Icons.add_box_rounded,
                              color: _C.success,
                              p: p,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReabastecerScreen(
                                        productoId: producto.id),
                                  ),
                                );
                              },
                            ),
                            _actionButton(
                              label: 'Editar',
                              icon: Icons.edit_rounded,
                              color: _C.primary,
                              p: p,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NuevoProductoScreen(
                                        producto: producto),
                                  ),
                                );
                              },
                            ),
                            _actionButton(
                              label: 'Mover',
                              icon: Icons.swap_horiz_rounded,
                              color: _C.info,
                              p: p,
                              onTap: () {
                                Navigator.pop(context);
                                _dialogMover(context, producto);
                              },
                            ),
                            _actionButton(
                              label: 'Merma',
                              icon: Icons.warning_amber_rounded,
                              color: _C.warning,
                              p: p,
                              onTap: () {
                                Navigator.pop(context);
                                _dialogMerma(context, producto);
                              },
                            ),
                          ],
                        ),
                        if (_isAdmin(provider)) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(context, producto.id);
                              },
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17),
                              label: const Text('Eliminar producto'),
                              style: TextButton.styleFrom(
                                foregroundColor: _C.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _priceTag(String label, String value, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
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
              letterSpacing: -.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  DIÁLOGOS
  // ============================================================
  void _dialogMover(BuildContext context, Producto producto) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDark);

    if (producto.sucursalId == null) {
      mostrarSnackBar(
        mensaje: 'Producto sin sucursal origen asignada.',
        esExito: false,
      );
      return;
    }

    final destinos = provider.sucursales
        .where((s) => s.id != producto.sucursalId)
        .toList();
    if (destinos.isEmpty) {
      mostrarSnackBar(
        mensaje: 'No hay otras sucursales disponibles.',
        esExito: false,
      );
      return;
    }

    final ctrl = TextEditingController(text: '1');
    String? destinoId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.info.withOpacity(p.dark ? .18 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: _C.info, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Mover producto',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            final cantidad = double.tryParse(ctrl.text) ?? 0;
            final stockOk = cantidad > 0 && cantidad <= producto.stock;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Origen',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        _sucursalNombre(provider, producto.sucursalId),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: destinoId,
                  decoration: InputDecoration(
                    labelText: 'Sucursal destino',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      color: p.textMuted,
                    ),
                    filled: true,
                    fillColor: p.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textHigh,
                  ),
                  dropdownColor: p.surface,
                  items: destinos.map((s) {
                    return DropdownMenuItem(
                        value: s.id, child: Text(s.nombre));
                  }).toList(),
                  onChanged: (v) => setLocal(() => destinoId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => setLocal(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      color: p.textMuted,
                    ),
                    helperText:
                        'Disponible: ${_fmt(producto.stock)} ${producto.unidadMedida}',
                    helperStyle: TextStyle(
                      fontSize: 11,
                      color: p.textMuted,
                    ),
                    filled: true,
                    fillColor: p.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
                if (cantidad > 0 && !stockOk)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'La cantidad excede el stock disponible',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _C.danger,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: p.textMid),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(ctrl.text) ?? 0;
              if (destinoId == null || cantidad <= 0) {
                mostrarSnackBar(
                  mensaje: 'Completa los datos correctamente.',
                  esExito: false,
                );
                return;
              }
              if (cantidad > producto.stock) {
                mostrarSnackBar(
                  mensaje: 'Stock insuficiente.',
                  esExito: false,
                );
                return;
              }
              Navigator.pop(ctx);
              await provider.registrarMovimiento(
                producto.id,
                cantidad,
                producto.sucursalId!,
                destinoId!,
              );
              setState(() => _seleccionado = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Mover',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _dialogMerma(BuildContext context, Producto producto) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDark);
    final ctrl = TextEditingController(text: '1');
    String motivo = 'estropeado';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(p.dark ? .18 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _C.warning, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Registrar merma',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stock disponible',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        '${_fmt(producto.stock)} ${producto.unidadMedida}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _C.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textHigh,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      color: p.textMuted,
                    ),
                    filled: true,
                    fillColor: p.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: motivo,
                  decoration: InputDecoration(
                    labelText: 'Motivo',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      color: p.textMuted,
                    ),
                    filled: true,
                    fillColor: p.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.textHigh,
                  ),
                  dropdownColor: p.surface,
                  items: const [
                    DropdownMenuItem(
                        value: 'estropeado',
                        child: Text('Estropeado / dañado')),
                    DropdownMenuItem(
                        value: 'autoconsumo',
                        child: Text('Autoconsumo interno')),
                    DropdownMenuItem(
                        value: 'perdida',
                        child: Text('Pérdida / extravío')),
                    DropdownMenuItem(
                        value: 'merma', child: Text('Merma natural')),
                  ],
                  onChanged: (v) {
                    if (v != null) setLocal(() => motivo = v);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: p.textMid),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(ctrl.text) ?? 0;
              if (cantidad <= 0 || cantidad > producto.stock) {
                mostrarSnackBar(
                  mensaje: 'Cantidad inválida.',
                  esExito: false,
                );
                return;
              }
              Navigator.pop(ctx);
              await provider.registrarMerma(
                  producto.id, cantidad, motivo);
              setState(() => _seleccionado = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Registrar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = _P(isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(p.dark ? .18 : .10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _C.danger, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Eliminar producto',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar este producto? Se eliminarán también sus registros de ventas asociados.',
          style: TextStyle(
            fontSize: 13.5,
            color: p.textMid,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: p.textMid),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.eliminarProducto(id);
              setState(() => _seleccionado = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  UTILIDADES
  // ============================================================
  Widget _emptyState(_P p) {
    final esSoloAgotados = _soloAgotados;
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
                gradient: LinearGradient(
                  colors: [
                    _C.primary.withOpacity(.16),
                    _C.cyan.withOpacity(.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                esSoloAgotados
                    ? Icons.check_circle_outline_rounded
                    : Icons.inventory_2_rounded,
                size: 38,
                color: esSoloAgotados ? _C.success : _C.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              esSoloAgotados
                  ? '¡Todo en orden!'
                  : (_search.isNotEmpty
                      ? 'Sin resultados'
                      : 'No hay productos'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              esSoloAgotados
                  ? 'No tienes productos agotados.'
                  : (_search.isNotEmpty
                      ? 'Prueba con otra búsqueda.'
                      : 'Agrega tu primer producto para empezar.'),
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

  Widget _loadMoreButton(BuildContext context, int total, _P p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _visible += _step),
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          label: Text('Cargar más ($_visible de $total)'),
          style: TextButton.styleFrom(
            foregroundColor: _C.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: BorderSide(color: _C.primary.withOpacity(.25)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _newProductFab(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'inventario_fab',
      onPressed: () => Navigator.pushNamed(context, '/nuevo-producto'),
      backgroundColor: _C.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text(
        'Nuevo producto',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: .1,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  String _sucursalNombre(AppProvider provider, String? id) {
    if (id == null) return 'Sin sucursal';
    try {
      return provider.sucursales.firstWhere((s) => s.id == id).nombre;
    } catch (_) {
      return 'Sin sucursal';
    }
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}