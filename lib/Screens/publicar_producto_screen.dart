// ============================================================
//  publicar_producto_screen.dart  ·  NEXORA BUSINESS
//  Selección y publicación de productos a la tienda pública
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
      final temp = TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
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

  // ══════════════════════════════════════════════════════════
  //  PUBLICAR
  // ══════════════════════════════════════════════════════════
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

      // Reconstruir catálogo completo con todos los IDs publicados
      final catalogo = _buildCatalogo(provider, lista);

      final nueva = _tienda!.copyWith(
        productosPublicados: lista,
        catalogo: catalogo,
        updatedAt: DateTime.now(),
      );

      // Local namespaced
      await provider.catalogosBox.put(
          keyTiendaDeEmpresa(empresaId), nueva.toJson());

      // Red local
      final netRaw =
          (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
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

      // Supabase (para que otros dispositivos lo vean)
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
          print('⚠️ Error publicando en Supabase: $e');
        }
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

  /// Construye el catálogo público desde el inventario real
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

    final filtrados = disponibles.where((prod) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      return prod.nombre.toLowerCase().contains(q) ||
          (prod.sku ?? '').toLowerCase().contains(q) ||
          provider
              .getNombreCategoria(prod.categoriaId)
              .toLowerCase()
              .contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 10),
                child: Column(
                  children: [
                    _infoCard(disponibles.length, p),
                    const SizedBox(height: 12),
                    _searchBar(p),
                    const SizedBox(height: 10),
                    _contadorSeleccion(p),
                  ],
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? _emptyState(disponibles.isEmpty, p)
                    : GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 24 : 14, 4,
                            isDesktop ? 24 : 14, 100),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) => _productoSelectable(
                            filtrados[i], provider, p),
                      ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar:
          _seleccionados.isEmpty ? null : _bottomBar(p),
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
            child: const Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Publicar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  )),
              Text('Añade productos a tu tienda',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withOpacity(p.dark ? .12 : .06),
            _C.cyan.withOpacity(p.dark ? .06 : .03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withOpacity(.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toca los productos que quieras publicar',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 2),
                Text(
                  '$disponibles producto${disponibles == 1 ? '' : 's'} disponible${disponibles == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
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
          hintText: 'Buscar producto…',
          hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: p.textMuted),
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

  Widget _contadorSeleccion(_P p) {
    if (_seleccionados.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 16, color: _C.success),
        const SizedBox(width: 6),
        Text(
          '${_seleccionados.length} seleccionado${_seleccionados.length == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: p.textMid,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _seleccionados.clear()),
          style: TextButton.styleFrom(
            foregroundColor: _C.danger,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
          child: const Text('Limpiar',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800)),
        ),
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
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _C.primary.withOpacity(.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
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
                        top: 8, right: 8,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: _C.gradBrand),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(.42),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    if (sinStock)
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
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
                          Text('${_fmt(prod.stock)} ${prod.unidadMedida}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: p.textMuted,
                              )),
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

  Widget _bottomBar(_P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
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
                  Text('SELECCIONADOS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: p.textMuted,
                      )),
                  const SizedBox(height: 2),
                  Text('${_seleccionados.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: p.textHigh,
                      )),
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(_guardando ? 'Publicando…' : 'Publicar',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _C.primary.withOpacity(.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22),
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
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.primary.withOpacity(.16),
                  _C.cyan.withOpacity(.06),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 38, color: _C.primary),
            ),
            const SizedBox(height: 16),
            Text(
              noDisponibles
                  ? 'Todo tu inventario está publicado'
                  : 'Sin resultados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noDisponibles
                  ? 'Todos los productos de tu inventario ya están visibles en tu tienda.'
                  : 'Prueba con otra búsqueda.',
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