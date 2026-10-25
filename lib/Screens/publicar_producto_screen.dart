// ============================================================
//  publicar_producto_screen.dart  ·  NEXORA BUSINESS
//  Publicación premium con selección masiva
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

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
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
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class PublicarProductoScreen extends StatefulWidget {
  const PublicarProductoScreen({Key? key}) : super(key: key);

  @override
  State<PublicarProductoScreen> createState() =>
      _PublicarProductoScreenState();
}

class _PublicarProductoScreenState
    extends State<PublicarProductoScreen> {
  final Set<String> _seleccionados = <String>{};
  TiendaPublica? _tienda;
  bool _cargando = true;
  bool _guardando = false;
  String _busqueda = '';
  String? _catSel;
  final _searchCtrl = TextEditingController();

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

    final key = keyTiendaDeEmpresa(empresaId);
    TiendaPublica? t;
    final raw = provider.catalogosBox.get(key);
    if (raw is Map) {
      final temp =
          TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
      if (temp.empresaId == empresaId) t = temp;
    } else {
      t = TiendaPublica.porDefecto(
        empresaId: empresaId,
        nombreEmpresa: provider.nombreEmpresa ?? 'Mi Empresa',
      );
      await provider.catalogosBox.put(key, t.toJson());
    }

    if (!mounted) return;
    setState(() {
      _tienda = t;
      _cargando = false;
    });
  }

  Future<void> _publicar() async {
    if (_tienda == null || _seleccionados.isEmpty) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return;

    setState(() => _guardando = true);
    try {
      final lista = List<String>.from(_tienda!.productosPublicados);
      for (final id in _seleccionados) {
        if (!lista.contains(id)) lista.add(id);
      }

      final catalogo = _buildCatalogo(provider, lista);

      final nueva = _tienda!.copyWith(
        productosPublicados: lista,
        catalogo: catalogo,
        updatedAt: DateTime.now(),
      );

      await provider.catalogosBox.put(
          keyTiendaDeEmpresa(empresaId), nueva.toJson());

      final netRaw =
          (provider.catalogosBox.get(kNetworkStoresKey) as List?) ??
              [];
      final netList =
          netRaw.map((e) => Map<String, dynamic>.from(e)).toList();
      final idx =
          netList.indexWhere((e) => e['empresaId'] == empresaId);
      if (idx >= 0) {
        netList[idx] = nueva.toJson();
      } else {
        netList.add(nueva.toJson());
      }
      await provider.catalogosBox.put(kNetworkStoresKey, netList);

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
            catalogo:
                nueva.catalogo.map((p) => p.toJson()).toList(),
            activa: nueva.activa,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      mostrarSnackBar(
        mensaje:
            '${_seleccionados.length} producto${_seleccionados.length == 1 ? '' : 's'} publicado${_seleccionados.length == 1 ? '' : 's'}',
        esExito: true,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      mostrarSnackBar(
        mensaje: 'Error: ${mensajeAmigable(e)}',
        esExito: false,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  List<ProductoPublicado> _buildCatalogo(
      AppProvider provider, List<String> ids) {
    final result = <ProductoPublicado>[];
    for (final id in ids) {
      final prod = provider.getProductoById(id);
      if (prod == null || !prod.activo) continue;
      final vendidas = provider.ventas
          .where((v) => v.productoId == id)
          .fold<double>(0, (s, v) => s + v.cantidad)
          .toInt();
      result.add(ProductoPublicado(
        id: prod.id,
        nombre: prod.nombre,
        descripcion: prod.descripcion,
        precio: prod.precioVenta,
        imagenUrl: prod.imageUrl,
        categoria: provider.getNombreCategoria(prod.categoriaId),
        unidad: prod.unidadMedida,
        unidadesVendidas: vendidas,
        destacado: vendidas > 10,
        disponible: prod.stock > 0,
      ));
    }
    return result;
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

    final yaPublicados = _tienda!.productosPublicados.toSet();
    final disponibles = provider.productos
        .where((prod) => !yaPublicados.contains(prod.id))
        .toList();

    final cats = <String>{};
    for (final prod in disponibles) {
      final c = provider.getNombreCategoria(prod.categoriaId);
      if (c.isNotEmpty && c != 'Sin categoría') cats.add(c);
    }
    final catList = cats.toList()..sort();

    var filtrados = disponibles.where((prod) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return prod.nombre.toLowerCase().contains(q) ||
          (prod.sku ?? '').toLowerCase().contains(q) ||
          provider
              .getNombreCategoria(prod.categoriaId)
              .toLowerCase()
              .contains(q);
    }).toList();

    if (_catSel != null) {
      filtrados = filtrados
          .where((prod) =>
              provider.getNombreCategoria(prod.categoriaId) ==
              _catSel)
          .toList();
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 20 : 14, 14, isDesktop ? 20 : 14, 0),
            child: Column(
              children: [
                _infoCard(disponibles.length, p),
                const SizedBox(height: 12),
                _searchBar(p),
                const SizedBox(height: 12),
                if (catList.isNotEmpty)
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _catChip(p, 'Todas', _catSel == null,
                            () => setState(() => _catSel = null)),
                        ...catList.map((c) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 8),
                              child: _catChip(p, c, _catSel == c,
                                  () => setState(() => _catSel = c)),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (disponibles.isNotEmpty)
                  _seleccionMasivaRow(filtrados, p),
              ],
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? _emptyState(disponibles.isEmpty, p)
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 20 : 14,
                        12,
                        isDesktop ? 20 : 14,
                        _seleccionados.isEmpty ? 20 : 100),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => _productoSelectable(
                        filtrados[i], provider, p),
                  ),
          ),
        ],
      ),
      bottomNavigationBar:
          _seleccionados.isEmpty ? null : _bottomBar(p, provider),
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
            width: 36,
            height: 36,
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
            child: const Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Publicar productos',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  )),
              Text('Añade a tu tienda pública',
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

  Widget _infoCard(int disponibles, _P p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withOpacity(p.dark ? .22 : .12),
            _C.cyan.withOpacity(p.dark ? .10 : .05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _C.primary.withOpacity(p.dark ? .35 : .24)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.42),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona los productos a publicar',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  disponibles == 0
                      ? 'Todo tu inventario ya está publicado'
                      : '$disponibles producto${disponibles == 1 ? '' : 's'} disponible${disponibles == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11.5,
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
  }

  Widget _searchBar(_P p) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border, width: 1.2),
        boxShadow: p.shadowSm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _busqueda = v),
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: p.textHigh),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar producto…',
          hintStyle:
              TextStyle(fontSize: 13.5, color: p.textMuted),
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

  Widget _catChip(
      _P p, String label, bool selected, VoidCallback onTap) {
    return Material(
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
                color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _C.primary.withOpacity(.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(label,
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
  }

  Widget _seleccionMasivaRow(
      List<Producto> visibles, _P p) {
    final todosVisiblesSeleccionados = visibles.isNotEmpty &&
        visibles.every((prod) => _seleccionados.contains(prod.id));

    return Row(
      children: [
        if (_seleccionados.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.success.withOpacity(p.dark ? .18 : .10),
              borderRadius: BorderRadius.circular(9),
              border:
                  Border.all(color: _C.success.withOpacity(.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: _C.success),
                const SizedBox(width: 5),
                Text(
                  '${_seleccionados.length} seleccionado${_seleccionados.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _C.success,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () =>
                setState(() => _seleccionados.clear()),
            icon: const Icon(Icons.close_rounded, size: 15),
            label: const Text('Limpiar'),
            style: TextButton.styleFrom(
              foregroundColor: _C.danger,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ] else ...[
          Text(
            '${visibles.length} visible${visibles.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (todosVisiblesSeleccionados) {
                  for (final prod in visibles) {
                    _seleccionados.remove(prod.id);
                  }
                } else {
                  for (final prod in visibles) {
                    _seleccionados.add(prod.id);
                  }
                }
              });
            },
            icon: Icon(
              todosVisiblesSeleccionados
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 15,
            ),
            label: Text(todosVisiblesSeleccionados
                ? 'Deseleccionar todos'
                : 'Seleccionar todos'),
            style: TextButton.styleFrom(
              foregroundColor: _C.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }

  Widget _productoSelectable(
      Producto prod, AppProvider provider, _P p) {
    final selected = _seleccionados.contains(prod.id);
    final sinStock = prod.stock <= 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            if (selected) {
              _seleccionados.remove(prod.id);
            } else {
              _seleccionados.add(prod.id);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _C.primary : p.border,
              width: selected ? 2 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _C.primary.withOpacity(.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
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
                    if (selected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: _C.gradBrand),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    if (sinStock)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              _C.danger,
                              Color(0xFFEC4899),
                            ]),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text('SIN STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              )),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 45,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                              color: sinStock
                                  ? _C.danger.withOpacity(.10)
                                  : _C.success.withOpacity(.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_fmt(prod.stock)} ${prod.unidadMedida}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: sinStock
                                    ? _C.danger
                                    : _C.success,
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

  Widget _bottomBar(_P p, AppProvider provider) {
    double totalEstimado = 0;
    for (final id in _seleccionados) {
      final prod = provider.getProductoById(id);
      if (prod != null) {
        totalEstimado += prod.precioVenta * (prod.stock > 0 ? 1 : 0);
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 22,
            offset: const Offset(0, -6),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${_seleccionados.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _C.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('productos',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.textMuted,
                          )),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '≈ \$${totalEstimado.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: p.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _publicar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded,
                        size: 18),
                label: Text(
                  _guardando ? 'Publicando…' : 'Publicar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _C.primary.withOpacity(.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool noDisponibles, _P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.primary.withOpacity(.20),
                  _C.cyan.withOpacity(.06),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 42, color: _C.primary),
            ),
            const SizedBox(height: 18),
            Text(
              noDisponibles
                  ? 'Todo tu inventario está publicado'
                  : 'Sin resultados',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noDisponibles
                  ? 'Todos los productos de tu inventario ya están visibles en tu tienda.'
                  : 'Prueba con otra búsqueda o categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }
}