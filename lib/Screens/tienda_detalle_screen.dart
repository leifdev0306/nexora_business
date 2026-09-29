// ============================================================
//  tienda_detalle_screen.dart
//  Detalle de tienda · Catálogo · Reseñas · Info
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

    // 1) Si es MI tienda → leer del key namespaced
    if (widget.empresaId == provider.empresaId) {
      final raw = box.get(keyTiendaDeEmpresa(widget.empresaId));
      if (raw is Map) {
        final temp =
            TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
        if (temp.empresaId == widget.empresaId) t = temp;
      }
    }

    // 2) Si no → buscar en la red
    if (t == null) {
      final raw =
          (box.get(kNetworkStoresKey) as List?) ?? [];
      for (final e in raw) {
        final x = TiendaPublica.fromJson(Map<String, dynamic>.from(e));
        if (x.empresaId == widget.empresaId) {
          t = x;
          break;
        }
      }
    }

    final revRaw = (box.get(kNetworkRev) as List?) ?? [];
    final revs = revRaw
        .map((e) => ResenaPublica.fromJson(Map<String, dynamic>.from(e)))
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
              Icon(Icons.storefront_rounded, size: 60, color: p.textMuted),
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
                labelColor: _C.primary,
                unselectedLabelColor: p.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13),
                tabs: const [
                  Tab(text: 'Catálogo'),
                  Tab(text: 'Reseñas'),
                  Tab(text: 'Info'),
                ],
              ),
              p.surface,
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
    if (_q.isEmpty) return t.catalogo;
    final q = _q.toLowerCase();
    return t.catalogo
        .where((x) =>
            x.nombre.toLowerCase().contains(q) ||
            x.categoria.toLowerCase().contains(q))
        .toList();
  }

  Widget _hero(TiendaPublica t, _P p) {
    final cat = CategoriasPublicas.nombreTienda(t.categoriaId);
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _C.gradBrand,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(.32)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.nombre.isNotEmpty
                              ? t.nombre.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5, height: 1.15,
                                )),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8, runSpacing: 4,
                              children: [
                                if (t.rating > 0)
                                  _chipHero(Icons.star_rounded,
                                      '${t.rating.toStringAsFixed(1)} · ${t.totalResenas}'),
                                _chipHero(Icons.category_rounded, cat),
                                if (t.tieneUbicacion)
                                  _chipHero(Icons.location_on_rounded,
                                      'En mapa'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (t.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(t.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.92),
                          fontSize: 12.5, height: 1.4,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipHero(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.28)),
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

  // ──────────────────────────────────────────────────────────
  //  TAB CATÁLOGO
  // ──────────────────────────────────────────────────────────
  Widget _tabCatalogo(List<ProductoPublicado> catalogo, _P p,
      bool isDesktop) {
    if (_tienda!.catalogo.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: p.textMuted),
              const SizedBox(height: 14),
              Text('Catálogo vacío',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: p.border),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _q = v),
            style: TextStyle(fontSize: 13.5, color: p.textHigh),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Buscar en esta tienda…',
              hintStyle: TextStyle(fontSize: 13, color: p.textMuted),
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
        const SizedBox(height: 14),
        if (catalogo.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 40, color: p.textMuted),
                const SizedBox(height: 10),
                Text('Sin coincidencias',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh,
                    )),
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

  void _verProducto(ProductoPublicado prod, _P p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (prod.imagenUrl != null &&
                prod.imagenUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 14),
            Text(prod.nombre,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                )),
            const SizedBox(height: 4),
            Text('\$${prod.precio.toStringAsFixed(2)} / ${prod.unidad}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _C.primary,
                )),
            if (prod.descripcion != null &&
                prod.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(prod.descripcion!,
                  style: TextStyle(
                      fontSize: 13, height: 1.4, color: p.textMid)),
            ],
            if (prod.unidadesVendidas > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.warning.withOpacity(.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                            Icons.local_fire_department_rounded,
                            size: 14, color: _C.warning),
                        const SizedBox(width: 5),
                        Text('${prod.unidadesVendidas} vendidos',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _C.warning,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Entendido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  TAB RESEÑAS
  // ──────────────────────────────────────────────────────────
  Widget _tabResenas(_P p) {
    if (_resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.reviews_outlined, size: 60, color: p.textMuted),
              const SizedBox(height: 14),
              Text('Sin reseñas todavía',
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(_tienda!.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: p.textHigh,
                  )),
              Row(
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
              Text('${_tienda!.totalResenas} reseñas',
                  style: TextStyle(fontSize: 11, color: p.textMuted)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int e = 5; e >= 1; e--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('$e',
                            style: TextStyle(
                                fontSize: 10, color: p.textMuted)),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded,
                            size: 10, color: _C.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _proporcion(e),
                              minHeight: 5,
                              backgroundColor: p.surface2,
                              valueColor: const AlwaysStoppedAnimation(
                                  _C.warning),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${(_proporcion(e) * 100).round()}%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted)),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _C.primary.withOpacity(.14),
                child: Text(
                  r.autorNombre.isNotEmpty
                      ? r.autorNombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _C.primary,
                    fontWeight: FontWeight.w900,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        )),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < r.rating.round();
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 12,
                          color: _C.warning,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(_fechaCorta(r.fecha),
                  style:
                      TextStyle(fontSize: 10.5, color: p.textMuted)),
            ],
          ),
          if (r.comentario != null && r.comentario!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.comentario!,
                style: TextStyle(
                    fontSize: 12.5, height: 1.4, color: p.textMid)),
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

  // ──────────────────────────────────────────────────────────
  //  TAB INFO
  // ──────────────────────────────────────────────────────────
  Widget _tabInfo(TiendaPublica t, _P p, bool isDesktop) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
      children: [
        if (t.tieneUbicacion) ...[
          _card(p, 'Ubicación', Icons.location_on_rounded, _C.info, () {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.direccion != null && t.direccion!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.place_rounded,
                          size: 15, color: p.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(t.direccion!,
                            style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: p.textMid)),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
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
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Ver en mapa'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
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
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 14),
        ],
        _card(p, 'Contacto', Icons.contact_mail_rounded, _C.cyan, () {
          return Column(
            children: [
              if (t.telefono != null && t.telefono!.isNotEmpty)
                _infoRow(p, Icons.phone_rounded, 'Teléfono', t.telefono!,
                    onTap: () => _llamar(t.telefono!)),
              if (t.whatsapp != null && t.whatsapp!.isNotEmpty)
                _infoRow(p, Icons.chat_rounded, 'WhatsApp', t.whatsapp!,
                    onTap: () => _whatsapp(t.whatsapp!)),
              if (t.email != null && t.email!.isNotEmpty)
                _infoRow(p, Icons.email_rounded, 'Email', t.email!,
                    onTap: () => _email(t.email!)),
              if (t.horario != null && t.horario!.isNotEmpty)
                _infoRow(p, Icons.schedule_rounded, 'Horario',
                    t.horario!),
            ],
          );
        }),
      ],
    );
  }

  Widget _card(_P p, String title, IconData icon, Color color,
      Widget Function() buildChild) {
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
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(.22),
                    color.withOpacity(.06),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                    letterSpacing: -0.2,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          buildChild(),
        ],
      ),
    );
  }

  Widget _infoRow(_P p, IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: p.textMuted),
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
  _TabBarDelegate(this.tabBar, this.bg);

  @override
  double get minExtent => tabBar.preferredSize.height + 4;
  @override
  double get maxExtent => tabBar.preferredSize.height + 4;

  @override
  Widget build(
          BuildContext context, double s, bool overlaps) =>
      Container(color: bg, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) =>
      tabBar != old.tabBar || bg != old.bg;
}

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const gold = Color(0xFFCA8A04);
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
      color: dark ? Colors.black.withOpacity(.30)
          : const Color(0xFF0A1A33).withOpacity(.05),
      blurRadius: 16, offset: const Offset(0, 4),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
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
                        topLeft: Radius.circular(13),
                        topRight: Radius.circular(13),
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
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: _C.gradBrand),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('★ TOP',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              )),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 42,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: p.textHigh,
                            )),
                      ),
                      const SizedBox(height: 2),
                      Text(producto.categoria,
                          style: TextStyle(
                              fontSize: 9.5, color: p.textMuted)),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                            padding: const EdgeInsets.only(bottom: 2),
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