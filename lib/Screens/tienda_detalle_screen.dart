// ============================================================
//  tienda_detalle_screen.dart
//  Detalle de tienda · Rediseño premium
//  · Hero con cover + avatar solapado
//  · Stats inline
//  · Acciones rápidas (llamar, WhatsApp, mapa)
//  · Catálogo con filtros de categoría
//  · Reseñas con histograma premium
// ============================================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import 'mapa_tiendas_screen.dart';
import 'mi_tienda_screen.dart'
    show keyTiendaDeEmpresa, kNetworkStoresKey, kNetworkRev;

class TiendaDetalleScreen extends StatefulWidget {
  final String empresaId;
  final ProductoPublicado? productoDestacado;

  const TiendaDetalleScreen({
    Key? key,
    required this.empresaId,
    this.productoDestacado,
  }) : super(key: key);

  @override
  State<TiendaDetalleScreen> createState() => _TiendaDetalleScreenState();
}

class _TiendaDetalleScreenState extends State<TiendaDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  TiendaPublica? _tienda;
  List<ResenaPublica> _resenas = [];
  bool _cargando = true;
  String _q = '';
  String? _catSel;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final box = provider.catalogosBox;
    TiendaPublica? t;

    if (widget.empresaId == provider.empresaId) {
      final raw = box.get(keyTiendaDeEmpresa(widget.empresaId));
      if (raw is Map) {
        final temp =
            TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
        if (temp.empresaId == widget.empresaId) t = temp;
      }
    }
    if (t == null) {
      final raw = (box.get(kNetworkStoresKey) as List?) ?? [];
      for (final e in raw) {
        final x =
            TiendaPublica.fromJson(Map<String, dynamic>.from(e));
        if (x.empresaId == widget.empresaId) {
          t = x;
          break;
        }
      }
    }

    final revRaw = (box.get(kNetworkRev) as List?) ?? [];
    final revs = revRaw
        .map((e) =>
            ResenaPublica.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.targetId == widget.empresaId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (!mounted) return;
    setState(() {
      _tienda = t;
      _resenas = revs;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    if (_cargando) {
      return Scaffold(
        backgroundColor: p.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_tienda == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_rounded,
                  size: 60, color: p.textMuted),
              const SizedBox(height: 14),
              Text('Tienda no encontrada',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.textHigh,
                  )),
            ],
          ),
        ),
      );
    }

    final t = _tienda!;
    final catalogo = _filtrarCatalogo(t);

    return Scaffold(
      backgroundColor: p.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _hero(t, p),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                indicatorColor: _C.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: _C.primary,
                unselectedLabelColor: p.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_rounded,
                            size: 15),
                        const SizedBox(width: 6),
                        Text('Catálogo (${t.totalProductos})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.reviews_rounded, size: 15),
                        const SizedBox(width: 6),
                        Text('Reseñas (${_resenas.length})'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Info'),
                      ],
                    ),
                  ),
                ],
              ),
              p.surface,
              p.border,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _tabCatalogo(catalogo, p, isDesktop),
            _tabResenas(p),
            _tabInfo(t, p, isDesktop),
          ],
        ),
      ),
    );
  }

  List<ProductoPublicado> _filtrarCatalogo(TiendaPublica t) {
    var lista = t.catalogo;
    if (_catSel != null) {
      lista = lista
          .where((x) =>
              x.categoria.toLowerCase() == _catSel!.toLowerCase())
          .toList();
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      lista = lista
          .where((x) =>
              x.nombre.toLowerCase().contains(q) ||
              x.categoria.toLowerCase().contains(q))
          .toList();
    }
    return lista;
  }

  // ══════════════════════════════════════════════════════════
  //  HERO (con avatar solapado)
  // ══════════════════════════════════════════════════════════
  Widget _hero(TiendaPublica t, _P p) {
    final cat = CategoriasPublicas.nombreTienda(t.categoriaId);
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.black.withOpacity(.35),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover con gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: _C.gradBrand,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Patrón decorativo
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.08),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                ),
              ),
            ),
            // Gradiente negro abajo para contraste
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(.55),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Contenido
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.28),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: _C.gradBrand,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t.nombre.isNotEmpty
                                  ? t.nombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.nombre,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black38,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (t.verificado) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded,
                                        size: 20,
                                        color: Colors.white),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (t.rating > 0)
                                    _heroChip(
                                      Icons.star_rounded,
                                      '${t.rating.toStringAsFixed(1)} · ${t.totalResenas}',
                                    ),
                                  _heroChip(
                                      Icons.category_rounded, cat),
                                  if (t.tieneUbicacion)
                                    _heroChip(
                                        Icons.location_on_rounded,
                                        'En mapa'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Acciones rápidas
                    Row(
                      children: [
                        if (t.telefono != null &&
                            t.telefono!.isNotEmpty)
                          Expanded(
                            child: _quickAction(
                              icon: Icons.phone_rounded,
                              label: 'Llamar',
                              color: _C.info,
                              onTap: () => _llamar(t.telefono!),
                            ),
                          ),
                        if (t.whatsapp != null &&
                            t.whatsapp!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickAction(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                              color: _C.success,
                              onTap: () => _whatsapp(t.whatsapp!),
                            ),
                          ),
                        ],
                        if (t.tieneUbicacion) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickAction(
                              icon: Icons.directions_rounded,
                              label: 'Ir',
                              color: _C.purple,
                              onTap: () => _abrirComoLlegar(t),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(.95),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB CATÁLOGO
  // ══════════════════════════════════════════════════════════
  Widget _tabCatalogo(List<ProductoPublicado> catalogo, _P p,
      bool isDesktop) {
    if (_tienda!.catalogo.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(p.dark ? .14 : .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 36, color: _C.primary),
              ),
              const SizedBox(height: 16),
              Text('Catálogo vacío',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  )),
              const SizedBox(height: 6),
              Text('Esta tienda aún no ha publicado productos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted)),
            ],
          ),
        ),
      );
    }

    final cats = <String>{};
    for (final prod in _tienda!.catalogo) {
      if (prod.categoria.isNotEmpty) cats.add(prod.categoria);
    }
    final catList = cats.toList()..sort();

    return ListView(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
      children: [
        // Search
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: p.border, width: 1.2),
            boxShadow: p.shadowSm,
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _q = v),
            style:
                TextStyle(fontSize: 13.5, color: p.textHigh),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Buscar en esta tienda…',
              hintStyle:
                  TextStyle(fontSize: 13, color: p.textMuted),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: p.textMuted),
              suffixIcon: _q.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 17, color: p.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _q = '');
                      })
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Chips de categorías
        if (catList.isNotEmpty)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _catChip(p, 'Todo', _catSel == null,
                    () => setState(() => _catSel = null)),
                ...catList.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _catChip(p, c, _catSel == c,
                          () => setState(() => _catSel = c)),
                    )),
              ],
            ),
          ),
        const SizedBox(height: 16),

        if (catalogo.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 44, color: p.textMuted),
                const SizedBox(height: 12),
                Text('Sin coincidencias',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 4),
                Text('Prueba con otra búsqueda o categoría.',
                    style: TextStyle(
                        fontSize: 12.5, color: p.textMuted)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: catalogo.length,
            itemBuilder: (_, i) => _ProductCard(
              producto: catalogo[i],
              p: p,
              destacado:
                  widget.productoDestacado?.id == catalogo[i].id,
              onTap: () => _verProducto(catalogo[i], p),
            ),
          ),
      ],
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

  void _verProducto(ProductoPublicado prod, _P p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
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
            const SizedBox(height: 20),
            if (prod.imagenUrl != null &&
                prod.imagenUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.4,
                  child: CachedNetworkImage(
                    imageUrl: prod.imagenUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: p.surface2),
                    errorWidget: (_, __, ___) => Container(
                        color: p.surface2,
                        child: Icon(Icons.inventory_2_rounded,
                            color: p.textMuted)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(prod.nombre,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.success.withOpacity(.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_rounded,
                          size: 12, color: _C.success),
                      const SizedBox(width: 4),
                      Text(
                        prod.disponible ? 'Disponible' : 'Agotado',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: prod.disponible
                              ? _C.success
                              : _C.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prod.categoria,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _C.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${prod.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: _C.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ${prod.unidad}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            if (prod.descripcion != null &&
                prod.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(prod.descripcion!,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: p.textMid)),
              ),
            ],
            if (prod.unidadesVendidas > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _C.warning.withOpacity(.10),
                    _C.warning.withOpacity(.04),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _C.warning.withOpacity(.24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 18, color: _C.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡${prod.unidadesVendidas} unidades vendidas!',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _C.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Entendido',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB RESEÑAS
  // ══════════════════════════════════════════════════════════
  Widget _tabResenas(_P p) {
    if (_resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _C.warning.withOpacity(p.dark ? .14 : .08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.reviews_outlined,
                    size: 36, color: _C.warning),
              ),
              const SizedBox(height: 16),
              Text('Sin reseñas todavía',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  )),
              const SizedBox(height: 6),
              Text('Sé el primero en dejar tu opinión.',
                  style: TextStyle(
                      fontSize: 12.5, color: p.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _resenas.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) return _resumenResenas(p);
        return _resenaCard(_resenas[i - 1], p);
      },
    );
  }

  Widget _resumenResenas(_P p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _tienda!.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  color: p.textHigh,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _tienda!.rating.round();
                  return Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: _C.warning,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_tienda!.totalResenas} reseñas',
                style:
                    TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int e = 5; e >= 1; e--)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text('$e',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.textMuted)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded,
                            size: 11, color: _C.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _proporcion(e),
                              minHeight: 6,
                              backgroundColor: p.surface2,
                              valueColor:
                                  const AlwaysStoppedAnimation(
                                      _C.warning),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${(_proporcion(e) * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _proporcion(int estrellas) {
    if (_resenas.isEmpty) return 0;
    final c =
        _resenas.where((r) => r.rating.round() == estrellas).length;
    return c / _resenas.length;
  }

  Widget _resenaCard(ResenaPublica r, _P p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _C.primary.withOpacity(.14),
                child: Text(
                  r.autorNombre.isNotEmpty
                      ? r.autorNombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _C.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.autorNombre,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        )),
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < r.rating.round();
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 13,
                          color: _C.warning,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fechaCorta(r.fecha),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (r.comentario != null && r.comentario!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.comentario!,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: p.textMid)),
          ],
        ],
      ),
    );
  }

  String _fechaCorta(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';
    return '${(diff.inDays / 30).floor()}m';
  }

  // ══════════════════════════════════════════════════════════
  //  TAB INFO
  // ══════════════════════════════════════════════════════════
  Widget _tabInfo(TiendaPublica t, _P p, bool isDesktop) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 14, 16, isDesktop ? 24 : 14, 40),
      children: [
        if (t.descripcion.isNotEmpty) ...[
          _infoCard(
            p,
            title: 'Sobre la tienda',
            icon: Icons.info_rounded,
            color: _C.primary,
            child: Text(t.descripcion,
                style: TextStyle(
                    fontSize: 13, height: 1.55, color: p.textMid)),
          ),
          const SizedBox(height: 14),
        ],
        if (t.tieneUbicacion) ...[
          _infoCard(
            p,
            title: 'Ubicación',
            icon: Icons.location_on_rounded,
            color: _C.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.direccion != null &&
                    t.direccion!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.place_rounded,
                          size: 15, color: p.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.direccion!,
                            style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: p.textMid)),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MapaTiendasScreen(tiendaEnfocada: t),
                          ),
                        ),
                        icon: const Icon(Icons.map_rounded,
                            size: 16),
                        label: const Text('Ver en mapa'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _abrirComoLlegar(t),
                        icon: const Icon(Icons.directions_rounded,
                            size: 16),
                        label: const Text('Cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _infoCard(
          p,
          title: 'Contacto',
          icon: Icons.contact_phone_rounded,
          color: _C.cyan,
          child: Column(
            children: [
              if (t.telefono != null &&
                  t.telefono!.isNotEmpty)
                _infoRow(
                  p,
                  icon: Icons.phone_rounded,
                  label: 'Teléfono',
                  value: t.telefono!,
                  color: _C.info,
                  onTap: () => _llamar(t.telefono!),
                ),
              if (t.whatsapp != null &&
                  t.whatsapp!.isNotEmpty)
                _infoRow(
                  p,
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  value: t.whatsapp!,
                  color: _C.success,
                  onTap: () => _whatsapp(t.whatsapp!),
                ),
              if (t.email != null && t.email!.isNotEmpty)
                _infoRow(
                  p,
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: t.email!,
                  color: _C.warning,
                  onTap: () => _email(t.email!),
                ),
              if (t.horario != null && t.horario!.isNotEmpty)
                _infoRow(
                  p,
                  icon: Icons.schedule_rounded,
                  label: 'Horario',
                  value: t.horario!,
                  color: _C.purple,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    _P p, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
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
                  gradient: LinearGradient(colors: [
                    color,
                    color.withOpacity(.72),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                    letterSpacing: -0.2,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    _P p, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(p.dark ? .18 : .10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 10),
                Text('$label: ',
                    style: TextStyle(
                        fontSize: 12.5, color: p.textMuted)),
                Expanded(
                  child: Text(value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color:
                            onTap != null ? _C.primary : p.textHigh,
                      )),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: _C.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirComoLlegar(TiendaPublica t) async {
    if (!t.tieneUbicacion) return;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${t.latitud},${t.longitud}&travelmode=driving';
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _llamar(String tel) async {
    final clean = tel.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await launchUrl(Uri.parse('tel:$clean'));
    } catch (_) {}
  }

  Future<void> _whatsapp(String wa) async {
    final clean = wa.replaceAll(RegExp(r'\D'), '');
    try {
      await launchUrl(Uri.parse('https://wa.me/$clean'),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _email(String email) async {
    try {
      await launchUrl(Uri.parse('mailto:$email'));
    } catch (_) {}
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bg;
  final Color border;
  _TabBarDelegate(this.tabBar, this.bg, this.border);

  @override
  double get minExtent => tabBar.preferredSize.height + 4;
  @override
  double get maxExtent => tabBar.preferredSize.height + 4;

  @override
  Widget build(
          BuildContext context, double s, bool overlaps) =>
      Container(
        color: bg,
        child: Column(
          children: [
            Expanded(child: tabBar),
            Container(height: 1, color: border),
          ],
        ),
      );

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) =>
      tabBar != old.tabBar || bg != old.bg || border != old.border;
}

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const gold = Color(0xFFEAB308);
  static const purple = Color(0xFF8B5CF6);
  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2 => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
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

class _ProductCard extends StatelessWidget {
  final ProductoPublicado producto;
  final _P p;
  final VoidCallback onTap;
  final bool destacado;
  const _ProductCard({
    required this.producto,
    required this.p,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: destacado
                  ? _C.primary.withOpacity(.55)
                  : p.border,
              width: destacado ? 1.6 : 1.2,
            ),
            boxShadow: p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 58,
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
                        child: producto.imagenUrl != null &&
                                producto.imagenUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: producto.imagenUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _ph(),
                                errorWidget: (_, __, ___) => _ph(),
                              )
                            : _ph(),
                      ),
                    ),
                    if (producto.destacado)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: _C.gradBrand),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: _C.primary.withOpacity(.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 9, color: Colors.white),
                              SizedBox(width: 3),
                              Text('TOP',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    if (!producto.disponible)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.55),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'AGOTADO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _C.danger,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 42,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: p.textHigh,
                            )),
                      ),
                      const SizedBox(height: 2),
                      Text(producto.categoria,
                          style: TextStyle(
                              fontSize: 9.5, color: p.textMuted)),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                                '\$${producto.precio.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  color: _C.primary,
                                )),
                          ),
                          const SizedBox(width: 3),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 2),
                            child: Text('/${producto.unidad}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: p.textMuted)),
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

  Widget _ph() => Center(
        child: Icon(Icons.inventory_2_rounded,
            size: 28, color: Colors.grey.shade400),
      );
}