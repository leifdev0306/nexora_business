// ============================================================
//  tiendas_screen.dart  ·  NEXORA BUSINESS
//  Red Nexora: cercanas + recomendadas + todas
//  · Sincroniza desde Supabase al abrir
// ============================================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import 'mapa_tiendas_screen.dart';
import 'mi_tienda_screen.dart'
    show keyTiendaDeEmpresa, kNetworkStoresKey, kNetworkSvcsKey;
import 'servicio_detalle_screen.dart';
import 'servicio_cancelado_screen.dart';
import 'tienda_detalle_screen.dart';

const String kNetworkStores = kNetworkStoresKey;
const String kNetworkSvcs   = kNetworkSvcsKey;

class TiendasScreen extends StatefulWidget {
  const TiendasScreen({Key? key}) : super(key: key);

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchProdCtrl = TextEditingController();
  final _searchSvcCtrl  = TextEditingController();

  String _qProd = '';
  String? _catProd;
  String _qSvc = '';
  String? _catSvc;

  Position? _miPosicion;
  bool _cargandoUbicacion = false;
  bool _sincronizando = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _sincronizarYRefrescar();
      _obtenerUbicacion();
    });
  }

  /// ▼ FIX: baja tiendas/servicios de Supabase antes de mostrar
  Future<void> _sincronizarYRefrescar() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      await provider.sincronizarRedNexora();
    } catch (_) {}
    if (mounted) setState(() => _sincronizando = false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchProdCtrl.dispose();
    _searchSvcCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return;
      }
      setState(() => _cargandoUbicacion = true);
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() => _miPosicion = pos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  double? _distancia(TiendaPublica t) {
    if (_miPosicion == null || !t.tieneUbicacion) return null;
    return Geolocator.distanceBetween(
      _miPosicion!.latitude,
      _miPosicion!.longitude,
      t.latitud!,
      t.longitud!,
    );
  }

  String _fmtDist(double? m) {
    if (m == null) return '';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    if (m < 10000) return '${(m / 1000).toStringAsFixed(2)} km';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  List<TiendaPublica> _todas(AppProvider provider) {
    final raw = (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
    final empresaIdActual = provider.empresaId ?? '';
    return raw
        .map((e) => TiendaPublica.fromJson(Map<String, dynamic>.from(e)))
        .where((t) =>
            t.activa &&
            t.empresaId.isNotEmpty &&
            t.empresaId != empresaIdActual)
        .toList();
  }

  TiendaPublica? _miTienda(AppProvider provider) {
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return null;
    final raw = provider.catalogosBox.get(keyTiendaDeEmpresa(empresaId));
    if (raw is! Map) return null;
    final t = TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
    if (t.empresaId != empresaId || !t.activa) return null;
    return t;
  }

  List<ServicioPublico> _servicios(AppProvider provider) {
    final raw = (provider.catalogosBox.get(kNetworkSvcsKey) as List?) ?? [];
    final empresaIdActual = provider.empresaId ?? '';
    return raw
        .map((e) => ServicioPublico.fromJson(Map<String, dynamic>.from(e)))
        .where((s) =>
            s.activo &&
            s.empresaId.isNotEmpty &&
            s.empresaId != empresaIdActual)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, p),
      body: Column(
        children: [
          _heroBanner(p),
          _tabBar(p),
          Expanded(
            child: _sincronizando
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _tabTiendas(provider, p, isDesktop),
                      _tabServicios(provider, p, isDesktop),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, _P p) {
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
              gradient: const LinearGradient(colors: _C.gradNetwork),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.network.withOpacity(.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.travel_explore_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text('Red Nexora',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.network.withOpacity(.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _C.network.withOpacity(.30)),
                    ),
                    child: const Text('COMUNIDAD',
                        style: TextStyle(
                          fontSize: 7.5, fontWeight: FontWeight.w900,
                          letterSpacing: 0.8, color: _C.network,
                        )),
                  ),
                ],
              ),
              Text('Descubre otros negocios',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  )),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refrescar',
          onPressed: () async {
            setState(() => _sincronizando = true);
            await _sincronizarYRefrescar();
          },
          icon: Icon(Icons.refresh_rounded, color: p.textHigh),
        ),
        IconButton(
          tooltip: 'Mapa',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapaTiendasScreen()),
          ),
          icon: Icon(Icons.map_rounded, color: p.textHigh),
        ),
      ],
    );
  }

  Widget _heroBanner(_P p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.network.withOpacity(p.dark ? .16 : .08),
            _C.cyan.withOpacity(p.dark ? .08 : .03),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _C.network.withOpacity(p.dark ? .28 : .16),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _C.gradNetwork,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.network.withOpacity(.32),
                  blurRadius: 10, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.public_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explora la comunidad',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: p.textHigh, letterSpacing: -0.2,
                    )),
                const SizedBox(height: 3),
                Text(
                  'Negocios reales con sus productos y servicios.',
                  style: TextStyle(
                    fontSize: 11, height: 1.35,
                    color: p.textMuted, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: _C.myBusiness.withOpacity(.14),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pushNamed(context, '/mi-tienda'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _C.myBusiness.withOpacity(.32)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded,
                        size: 13, color: _C.myBusiness),
                    SizedBox(width: 5),
                    Text('Mi negocio',
                        style: TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w900,
                          color: _C.myBusiness,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar(_P p) {
    return Container(
      color: p.surface,
      child: TabBar(
        controller: _tabs,
        indicatorColor: _C.network,
        indicatorWeight: 3,
        labelColor: _C.network,
        unselectedLabelColor: p.textMuted,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 13.5),
        tabs: const [
          Tab(text: 'Tiendas', height: 46),
          Tab(text: 'Servicios', height: 46),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB TIENDAS
  // ══════════════════════════════════════════════════════════
  Widget _tabTiendas(AppProvider provider, _P p, bool isDesktop) {
    final miTienda = _miTienda(provider);
    final todas = _todas(provider);

    var filtradas = todas;
    if (_qProd.trim().isNotEmpty) {
      final q = _qProd.toLowerCase();
      filtradas = todas
          .where((t) =>
              t.nombre.toLowerCase().contains(q) ||
              t.descripcion.toLowerCase().contains(q))
          .toList();
    }
    if (_catProd != null && _catProd!.isNotEmpty) {
      filtradas =
          filtradas.where((t) => t.categoriaId == _catProd).toList();
    }

    final cercanas = <_TiendaConDist>[];
    if (_miPosicion != null) {
      for (final t in todas) {
        final d = _distancia(t);
        if (d != null && d <= 10000) {
          cercanas.add(_TiendaConDist(t, d));
        }
      }
      cercanas.sort((a, b) => a.distancia.compareTo(b.distancia));
    }

    final recomendadas = todas.toList()
      ..sort((a, b) {
        final sa = a.rating * (a.visitas + 1);
        final sb = b.rating * (b.visitas + 1);
        return sb.compareTo(sa);
      });
    final topRecomendadas = recomendadas.take(6).toList();

    final topVendidos = todas.expand((t) {
      return t.catalogo.map((prod) =>
          _ProductoDestacado(producto: prod, tienda: t));
    }).toList()
      ..sort((a, b) =>
          b.producto.unidadesVendidas
              .compareTo(a.producto.unidadesVendidas));
    final top15 = topVendidos.take(15).toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _sincronizando = true);
        await _sincronizarYRefrescar();
        await _obtenerUbicacion();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
        children: [
          _searchBar(
            p, _searchProdCtrl, _qProd,
            hint: 'Buscar negocios o productos…',
            onChanged: (v) => setState(() => _qProd = v),
          ),
          const SizedBox(height: 16),

          // MI TIENDA
          if (miTienda != null) ...[
            _headerRow(p, 'Mi negocio', 1, _C.myBusiness,
                icon: Icons.storefront_rounded),
            const SizedBox(height: 10),
            _TiendaCard(
              tienda: miTienda,
              p: p,
              accent: _C.myBusiness,
              esPropia: true,
              distancia: _distancia(miTienda),
              distanciaFormateada: _fmtDist(_distancia(miTienda)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TiendaDetalleScreen(
                    empresaId: miTienda.empresaId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // CERCA DE TI
          if (cercanas.isNotEmpty) ...[
            _headerRow(
              p, 'Cerca de ti', cercanas.length, _C.success,
              icon: Icons.near_me_rounded,
              subtitle: _cargandoUbicacion
                  ? 'Calculando distancia…'
                  : 'Ordenadas por cercanía',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cercanas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, i) => _TiendaCercanaCard(
                  item: cercanas[i], p: p,
                  distanciaFormateada:
                      _fmtDist(cercanas[i].distancia),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiendaDetalleScreen(
                        empresaId: cercanas[i].tienda.empresaId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // RECOMENDADAS
          if (topRecomendadas.isNotEmpty && _qProd.isEmpty) ...[
            _headerRow(
              p, 'Recomendadas', topRecomendadas.length, _C.gold,
              icon: Icons.star_rounded,
              subtitle: 'Mejor valoradas por la comunidad',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topRecomendadas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (_, i) => _TiendaRecomendadaCard(
                  tienda: topRecomendadas[i], p: p,
                  distancia: _distancia(topRecomendadas[i]),
                  distanciaFormateada:
                      _fmtDist(_distancia(topRecomendadas[i])),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiendaDetalleScreen(
                        empresaId: topRecomendadas[i].empresaId,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // MÁS VENDIDOS
          if (top15.isNotEmpty && _qProd.isEmpty) ...[
            _CarruselMasVendidos(
              items: top15, p: p,
              onTap: (item) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TiendaDetalleScreen(
                    empresaId: item.tienda.empresaId,
                    productoDestacado: item.producto,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],

          _chipsCategorias(
            p, CategoriasPublicas.tienda, _catProd,
            (id) => setState(() => _catProd = id),
          ),
          const SizedBox(height: 18),

          _headerRow(
            p, 'Todas las tiendas', filtradas.length, _C.network,
            icon: Icons.apps_rounded,
          ),
          const SizedBox(height: 12),

          if (filtradas.isEmpty)
            _empty(p,
                icon: Icons.public_off_rounded,
                title: 'Aún no hay negocios en la red',
                sub: 'Cuando otros negocios se unan a Nexora, aparecerán aquí.')
          else
            _gridTiendas(filtradas, p, isDesktop),
        ],
      ),
    );
  }

  Widget _gridTiendas(
      List<TiendaPublica> tiendas, _P p, bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isDesktop ? 2.15 : 3.2,
      ),
      itemCount: tiendas.length,
      itemBuilder: (_, i) => _TiendaCard(
        tienda: tiendas[i], p: p,
        distancia: _distancia(tiendas[i]),
        distanciaFormateada: _fmtDist(_distancia(tiendas[i])),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TiendaDetalleScreen(
              empresaId: tiendas[i].empresaId,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB SERVICIOS
  // ══════════════════════════════════════════════════════════
  Widget _tabServicios(AppProvider provider, _P p, bool isDesktop) {
    var servicios = _servicios(provider);

    if (_qSvc.trim().isNotEmpty) {
      final q = _qSvc.toLowerCase();
      servicios = servicios
          .where((s) =>
              s.nombre.toLowerCase().contains(q) ||
              s.descripcion.toLowerCase().contains(q) ||
              s.nombreEmpresa.toLowerCase().contains(q) ||
              s.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    if (_catSvc != null && _catSvc!.isNotEmpty) {
      servicios =
          servicios.where((s) => s.categoriaId == _catSvc).toList();
    }

    final conDist = <_ServicioConDist>[];
    final sinDist = <ServicioPublico>[];
    if (_miPosicion != null) {
      for (final s in servicios) {
        if (!s.tieneUbicacion) {
          sinDist.add(s);
          continue;
        }
        final d = Geolocator.distanceBetween(
          _miPosicion!.latitude, _miPosicion!.longitude,
          s.latitud!, s.longitud!,
        );
        conDist.add(_ServicioConDist(s, d));
      }
      conDist.sort((a, b) => a.distancia.compareTo(b.distancia));
    } else {
      sinDist.addAll(servicios);
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _sincronizando = true);
        await _sincronizarYRefrescar();
        await _obtenerUbicacion();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
        children: [
          _searchBar(
            p, _searchSvcCtrl, _qSvc,
            hint: 'Buscar servicios…',
            onChanged: (v) => setState(() => _qSvc = v),
          ),
          const SizedBox(height: 16),
          _chipsCategorias(
            p, CategoriasPublicas.servicio, _catSvc,
            (id) => setState(() => _catSvc = id),
          ),
          const SizedBox(height: 18),

          if (conDist.isNotEmpty) ...[
            _headerRow(p, 'Servicios cerca de ti', conDist.length,
                _C.success, icon: Icons.near_me_rounded),
            const SizedBox(height: 12),
            ...conDist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServicioCard(
                    servicio: item.servicio, p: p,
                    distanciaFormateada: _fmtDist(item.distancia),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServicioDetalleScreen(
                            servicioId: item.servicio.id),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 14),
          ],

          if (sinDist.isNotEmpty) ...[
            _headerRow(
              p,
              conDist.isEmpty
                  ? 'Servicios disponibles'
                  : 'Otros servicios',
              sinDist.length, _C.network,
              icon: Icons.handyman_rounded,
            ),
            const SizedBox(height: 12),
            ...sinDist.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServicioCard(
                    servicio: s, p: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServicioDetalleScreen(servicioId: s.id),
                      ),
                    ),
                  ),
                )),
          ],

          if (conDist.isEmpty && sinDist.isEmpty)
            _empty(p,
                icon: Icons.handyman_rounded,
                title: 'Aún no hay servicios en la red',
                sub: 'Cuando otros negocios ofrezcan servicios, los verás aquí.'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS UI
  // ══════════════════════════════════════════════════════════
  Widget _searchBar(_P p, TextEditingController ctrl, String value,
      {required String hint, required ValueChanged<String> onChanged}) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: p.textHigh),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: p.textMuted),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: p.textMuted),
                  onPressed: () {
                    ctrl.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _chipsCategorias(_P p, Map<String, String> cats,
      String? selected, ValueChanged<String?> onSelect) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _chip(p, 'Todas', selected == null, () => onSelect(null)),
          const SizedBox(width: 8),
          ...cats.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(p, e.value, selected == e.key,
                    () => onSelect(e.key)),
              )),
        ],
      ),
    );
  }

  Widget _chip(_P p, String label, bool selected, VoidCallback onTap) {
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
                ? const LinearGradient(colors: _C.gradNetwork)
                : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _C.network.withOpacity(.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : p.textMid,
              )),
        ),
      ),
    );
  }

  Widget _headerRow(_P p, String title, int count, Color color,
      {IconData? icon, String? subtitle}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    letterSpacing: -0.3, color: p.textHigh,
                  )),
              if (subtitle != null)
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11, color: p.textMuted,
                      fontWeight: FontWeight.w500,
                    )),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(p.dark ? .18 : .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: color)),
        ),
      ],
    );
  }

  Widget _empty(_P p,
      {required IconData icon,
      required String title,
      required String sub}) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.network.withOpacity(.16),
                _C.cyan.withOpacity(.06),
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: _C.network),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900,
                  color: p.textHigh)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HELPERS
// ════════════════════════════════════════════════════════════
class _TiendaConDist {
  final TiendaPublica tienda;
  final double distancia;
  _TiendaConDist(this.tienda, this.distancia);
}

class _ServicioConDist {
  final ServicioPublico servicio;
  final double distancia;
  _ServicioConDist(this.servicio, this.distancia);
}

class _ProductoDestacado {
  final ProductoPublicado producto;
  final TiendaPublica tienda;
  const _ProductoDestacado(
      {required this.producto, required this.tienda});
}

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
  static const gold      = Color(0xFFCA8A04);

  static const network   = Color(0xFF06B6D4);
  static const gradNetwork = [Color(0xFF06B6D4), Color(0xFF14B8A6)];
  static const myBusiness = Color(0xFF8B5CF6);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradWarm  = [Color(0xFFF59E0B), Color(0xFFF97316)];
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

// ════════════════════════════════════════════════════════════
//  TIENDA CARD
// ════════════════════════════════════════════════════════════
class _TiendaCard extends StatelessWidget {
  final TiendaPublica tienda;
  final _P p;
  final VoidCallback onTap;
  final Color? accent;
  final bool esPropia;
  final double? distancia;
  final String distanciaFormateada;

  const _TiendaCard({
    required this.tienda, required this.p, required this.onTap,
    this.accent, this.esPropia = false, this.distancia,
    this.distanciaFormateada = '',
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoriasPublicas.nombreTienda(tienda.categoriaId);
    final c = accent ?? _C.network;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c, c.withOpacity(.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: c.withOpacity(.32),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  tienda.nombre.isNotEmpty
                      ? tienda.nombre.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(tienda.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: p.textHigh,
                              )),
                        ),
                        if (esPropia)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.withOpacity(.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('MÍA',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: c,
                                )),
                          ),
                        if (tienda.verificado && !esPropia) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded,
                              size: 15, color: c),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_rounded,
                            size: 11, color: p.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(cat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: p.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            size: 11, color: _C.warning),
                        const SizedBox(width: 3),
                        Text(
                          tienda.rating > 0
                              ? tienda.rating.toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: p.textHigh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 11, color: p.textMuted),
                        const SizedBox(width: 3),
                        Text('${tienda.totalProductos}',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted)),
                        if (tienda.tieneUbicacion &&
                            distanciaFormateada.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.near_me_rounded,
                              size: 11, color: _C.success),
                          const SizedBox(width: 3),
                          Text(distanciaFormateada,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: _C.success)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CERCA DE TI · CARD
// ════════════════════════════════════════════════════════════
class _TiendaCercanaCard extends StatelessWidget {
  final _TiendaConDist item;
  final _P p;
  final String distanciaFormateada;
  final VoidCallback onTap;

  const _TiendaCercanaCard({
    required this.item, required this.p,
    required this.distanciaFormateada, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.tienda;
    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _C.success.withOpacity(.30), width: 1.2),
              boxShadow: p.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.gradNetwork),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t.nombre.isNotEmpty
                            ? t.nombre.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _C.success.withOpacity(.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _C.success.withOpacity(.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 10, color: _C.success),
                          const SizedBox(width: 3),
                          Text(distanciaFormateada,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _C.success,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(t.nombre,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w900,
                      height: 1.2, color: p.textHigh,
                    )),
                const SizedBox(height: 4),
                Text(CategoriasPublicas.nombreTienda(t.categoriaId),
                    style: TextStyle(fontSize: 11, color: p.textMuted)),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: _C.warning),
                    const SizedBox(width: 3),
                    Text(
                      t.rating > 0
                          ? t.rating.toStringAsFixed(1) : '—',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.inventory_2_rounded,
                        size: 11, color: p.textMuted),
                    const SizedBox(width: 3),
                    Text('${t.totalProductos}',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  RECOMENDADA · CARD
// ════════════════════════════════════════════════════════════
class _TiendaRecomendadaCard extends StatelessWidget {
  final TiendaPublica tienda;
  final _P p;
  final double? distancia;
  final String distanciaFormateada;
  final VoidCallback onTap;

  const _TiendaRecomendadaCard({
    required this.tienda, required this.p,
    required this.distancia,
    required this.distanciaFormateada, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _C.gold.withOpacity(.30), width: 1.2),
              boxShadow: p.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.gradWarm),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tienda.nombre.isNotEmpty
                            ? tienda.nombre.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.gradWarm),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text('TOP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(tienda.nombre,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w900,
                      height: 1.2, color: p.textHigh,
                    )),
                const SizedBox(height: 4),
                Text(CategoriasPublicas.nombreTienda(tienda.categoriaId),
                    style: TextStyle(fontSize: 11, color: p.textMuted)),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: _C.warning),
                    const SizedBox(width: 3),
                    Text(tienda.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        )),
                    const Spacer(),
                    if (distanciaFormateada.isNotEmpty) ...[
                      const Icon(Icons.near_me_rounded,
                          size: 11, color: _C.success),
                      const SizedBox(width: 3),
                      Text(distanciaFormateada,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _C.success)),
                    ] else ...[
                      Icon(Icons.visibility_rounded,
                          size: 11, color: p.textMuted),
                      const SizedBox(width: 3),
                      Text('${tienda.visitas}',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: p.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARRUSEL
// ════════════════════════════════════════════════════════════
class _CarruselMasVendidos extends StatelessWidget {
  final List<_ProductoDestacado> items;
  final void Function(_ProductoDestacado) onTap;
  final _P p;
  const _CarruselMasVendidos({
    required this.items, required this.onTap, required this.p,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradWarm),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lo más vendido',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        letterSpacing: -0.3, color: p.textHigh,
                      )),
                  Text('Top ventas de la red',
                      style: TextStyle(
                        fontSize: 11, color: p.textMuted,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _card(context, items[i], i + 1),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, _ProductoDestacado item, int rank) {
    final prod = item.producto;
    final t = item.tienda;
    return SizedBox(
      width: 150,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
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
                          topLeft: Radius.circular(13),
                          topRight: Radius.circular(13),
                        ),
                        child: Container(
                          color: p.surface2,
                          width: double.infinity,
                          height: double.infinity,
                          child: prod.imagenUrl != null &&
                                  prod.imagenUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: prod.imagenUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _ph(),
                                  errorWidget: (_, __, ___) => _ph(),
                                )
                              : _ph(),
                        ),
                      ),
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: _C.gradWarm),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text('$rank',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.w900,
                              )),
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
                          child: Text(prod.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                height: 1.15, color: p.textHigh,
                              )),
                        ),
                        const SizedBox(height: 2),
                        Text(t.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5, color: p.textMuted)),
                        const SizedBox(height: 3),
                        Text('\$${prod.precio.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900,
                              letterSpacing: -0.4, color: _C.primary,
                            )),
                      ],
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

  Widget _ph() => Center(
        child: Icon(Icons.inventory_2_rounded,
            size: 28, color: Colors.grey.shade400),
      );
}

// ════════════════════════════════════════════════════════════
//  SERVICIO · CARD
// ════════════════════════════════════════════════════════════
class _ServicioCard extends StatelessWidget {
  final ServicioPublico servicio;
  final _P p;
  final VoidCallback onTap;
  final String distanciaFormateada;

  const _ServicioCard({
    required this.servicio, required this.p,
    required this.onTap, this.distanciaFormateada = '',
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoriasPublicas.nombreServicio(servicio.categoriaId);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _C.network.withOpacity(.22),
                    _C.network.withOpacity(.06),
                  ]),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: _C.network.withOpacity(.28)),
                ),
                child: Icon(_icono(servicio.categoriaId),
                    color: _C.network, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(servicio.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900,
                          color: p.textHigh,
                        )),
                    const SizedBox(height: 3),
                    Text('${servicio.nombreEmpresa} · $cat',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted)),
                    const SizedBox(height: 5),
                    Text(servicio.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, height: 1.35,
                            color: p.textMid)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        _tag(servicio.precioTexto, _C.success),
                        if (distanciaFormateada.isNotEmpty)
                          _tag(distanciaFormateada, _C.info),
                        ...servicio.tags.take(1)
                            .map((t) => _tag(t, _C.network)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(.24)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: color)),
      );

  IconData _icono(String cat) {
    switch (cat) {
      case 'reparacion':    return Icons.build_rounded;
      case 'fabricacion':   return Icons.precision_manufacturing_rounded;
      case 'estetica':      return Icons.spa_rounded;
      case 'barberia':      return Icons.content_cut_rounded;
      case 'limpieza':      return Icons.cleaning_services_rounded;
      case 'transporte':    return Icons.local_shipping_rounded;
      case 'diseno':        return Icons.design_services_rounded;
      case 'informatica':   return Icons.computer_rounded;
      case 'educacion':     return Icons.school_rounded;
      case 'fotografia':    return Icons.photo_camera_rounded;
      case 'mantenimiento': return Icons.engineering_rounded;
      case 'construccion':  return Icons.construction_rounded;
      case 'eventos':       return Icons.event_rounded;
      default:              return Icons.handyman_rounded;
    }
  }
}