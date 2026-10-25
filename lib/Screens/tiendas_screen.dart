// ============================================================
//  tiendas_screen.dart  ·  NEXORA BUSINESS
//  Red Nexora · Edición premium final
//  · Back button explícito
//  · Hero con orbes + stats animadas
//  · Section headers con badge de conteo
// ============================================================
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  final _searchCtrl = TextEditingController();

  String _q = '';
  String? _catProd;
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
    _searchCtrl.dispose();
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
    final raw =
        (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
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
    final raw =
        (provider.catalogosBox.get(kNetworkSvcsKey) as List?) ?? [];
    final empresaIdActual = provider.empresaId ?? '';
    return raw
        .map((e) =>
            ServicioPublico.fromJson(Map<String, dynamic>.from(e)))
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

    final tiendas = _todas(provider);
    final servicios = _servicios(provider);
    final productosRed =
        tiendas.fold<int>(0, (s, t) => s + t.totalProductos);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _heroHeader(
              context,
              p,
              tiendas.length,
              servicios.length,
              productosRed,
            ),
            _tabsBar(p),
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
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HERO con back button + orbes + stats
  // ══════════════════════════════════════════════════════════
  Widget _heroHeader(BuildContext context, _P p, int tiendas,
      int servicios, int productos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.network.withOpacity(p.dark ? .32 : .18),
              _C.primary.withOpacity(p.dark ? .20 : .10),
              _C.teal.withOpacity(p.dark ? .16 : .08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _C.network.withOpacity(p.dark ? .42 : .26),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.network.withOpacity(p.dark ? .32 : .20),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Orbes decorativas
            Positioned(
              top: -60, right: -50,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _C.network.withOpacity(p.dark ? .22 : .16),
                    _C.network.withOpacity(0),
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -80, left: -60,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _C.purple.withOpacity(p.dark ? .16 : .10),
                    _C.purple.withOpacity(0),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Fila superior: back + icon + título + mapa
                  Row(
                    children: [
                      // ✅ Back button
                      Material(
                        color: p.dark
                            ? Colors.white.withOpacity(.12)
                            : Colors.white.withOpacity(.62),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back_rounded,
                                size: 20, color: p.textHigh),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: _C.gradNetwork,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _C.network.withOpacity(.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                            Icons.travel_explore_rounded,
                            color: Colors.white, size: 24),
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
                                    'Red Nexora',
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                      color: p.textHigh,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _C.network
                                        .withOpacity(.20),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    border: Border.all(
                                        color: _C.network
                                            .withOpacity(.40)),
                                  ),
                                  child: const Text(
                                    'COMUNIDAD',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                      color: _C.network,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Descubre y conecta con otros negocios',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: p.dark
                            ? Colors.white.withOpacity(.10)
                            : Colors.white.withOpacity(.58),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MapaTiendasScreen()),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.map_rounded,
                                size: 18, color: p.textHigh),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ─── Stats
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          p,
                          icon: Icons.storefront_rounded,
                          value: '$tiendas',
                          label: 'Tiendas',
                          color: _C.network,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statTile(
                          p,
                          icon: Icons.handyman_rounded,
                          value: '$servicios',
                          label: 'Servicios',
                          color: _C.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statTile(
                          p,
                          icon: Icons.inventory_2_rounded,
                          value: '$productos',
                          label: 'Productos',
                          color: _C.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(
    _P p, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: p.dark
            ? Colors.white.withOpacity(.08)
            : Colors.white.withOpacity(.65),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: p.dark
              ? Colors.white.withOpacity(.12)
              : Colors.white.withOpacity(.72),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: p.textHigh,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
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

  Widget _tabsBar(_P p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: TabBar(
        controller: _tabs,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: _C.gradNetwork),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: _C.network.withOpacity(.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: p.textMuted,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 13.5),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13.5),
        tabs: const [
          Tab(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded, size: 16),
                SizedBox(width: 6),
                Text('Tiendas'),
              ],
            ),
          ),
          Tab(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handyman_rounded, size: 16),
                SizedBox(width: 6),
                Text('Servicios'),
              ],
            ),
          ),
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
    if (_q.trim().isNotEmpty) {
      final q = _q.toLowerCase();
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
        if (d != null && d <= 15000) {
          cercanas.add(_TiendaConDist(t, d));
        }
      }
      cercanas.sort((a, b) => a.distancia.compareTo(b.distancia));
    }

    final recomendadas = todas.toList()
      ..sort((a, b) {
        final sa =
            a.rating * (a.visitas + 1) * (a.verificado ? 2 : 1);
        final sb =
            b.rating * (b.visitas + 1) * (b.verificado ? 2 : 1);
        return sb.compareTo(sa);
      });
    final topRecomendadas = recomendadas.take(8).toList();

    final nuevas = todas.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final topNuevas = nuevas.take(6).toList();

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
            isDesktop ? 20 : 14, 14, isDesktop ? 20 : 14, 60),
        children: [
          _searchBar(p),
          const SizedBox(height: 18),

          // MI TIENDA
          if (miTienda != null) ...[
            _sectionHeader(
              p,
              icon: Icons.storefront_rounded,
              title: 'Mi negocio',
              subtitle: 'Así te ven los demás',
              color: _C.purple,
            ),
            const SizedBox(height: 12),
            _MiTiendaCard(
              tienda: miTienda,
              p: p,
              onTap: () =>
                  Navigator.pushNamed(context, '/mi-tienda'),
            ),
            const SizedBox(height: 26),
          ],

          // CERCA DE TI
          if (cercanas.isNotEmpty) ...[
            _sectionHeader(
              p,
              icon: Icons.near_me_rounded,
              title: 'Cerca de ti',
              subtitle: _cargandoUbicacion
                  ? 'Calculando distancia…'
                  : 'En un radio de 15 km',
              color: _C.success,
              count: cercanas.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cercanas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (_, i) => _TiendaCardPremium(
                  tienda: cercanas[i].tienda,
                  p: p,
                  distanciaFormateada:
                      _fmtDist(cercanas[i].distancia),
                  accent: _C.success,
                  badgeText: 'CERCA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiendaDetalleScreen(
                          empresaId: cercanas[i].tienda.empresaId),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],

          // RECOMENDADAS
          if (topRecomendadas.isNotEmpty && _q.isEmpty) ...[
            _sectionHeader(
              p,
              icon: Icons.workspace_premium_rounded,
              title: 'Recomendadas',
              subtitle: 'Mejor valoradas por la comunidad',
              color: _C.gold,
              count: topRecomendadas.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topRecomendadas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (_, i) => _TiendaCardPremium(
                  tienda: topRecomendadas[i],
                  p: p,
                  distanciaFormateada:
                      _fmtDist(_distancia(topRecomendadas[i])),
                  accent: _C.gold,
                  badgeText: i == 0 ? 'TOP #1' : 'TOP',
                  rank: i + 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiendaDetalleScreen(
                          empresaId: topRecomendadas[i].empresaId),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],

          // NUEVAS
          if (topNuevas.isNotEmpty &&
              _q.isEmpty &&
              _catProd == null) ...[
            _sectionHeader(
              p,
              icon: Icons.fiber_new_rounded,
              title: 'Nuevas en la red',
              subtitle: 'Recién llegadas a la comunidad',
              color: _C.info,
              count: topNuevas.length,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topNuevas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (_, i) => _TiendaCardPremium(
                  tienda: topNuevas[i],
                  p: p,
                  distanciaFormateada:
                      _fmtDist(_distancia(topNuevas[i])),
                  accent: _C.info,
                  badgeText: 'NUEVA',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiendaDetalleScreen(
                          empresaId: topNuevas[i].empresaId),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],

          // CATEGORÍAS
          _sectionHeader(
            p,
            icon: Icons.apps_rounded,
            title: 'Explorar categorías',
            subtitle: 'Filtra por tipo de negocio',
            color: _C.network,
          ),
          const SizedBox(height: 12),
          _chipsCategorias(p, _catProd,
              (id) => setState(() => _catProd = id)),
          const SizedBox(height: 26),

          // TODAS
          _sectionHeader(
            p,
            icon: Icons.public_rounded,
            title:
                _q.isEmpty && _catProd == null ? 'Todas las tiendas' : 'Resultados',
            subtitle: '${filtradas.length} encontradas',
            color: _C.primary,
            count: filtradas.length,
          ),
          const SizedBox(height: 12),

          if (filtradas.isEmpty)
            _empty(
              p,
              icon: Icons.storefront_rounded,
              title: 'Sin tiendas',
              sub: 'Prueba con otra búsqueda o categoría.',
            )
          else
            _gridTodas(filtradas, p, isDesktop),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB SERVICIOS
  // ══════════════════════════════════════════════════════════
  Widget _tabServicios(AppProvider provider, _P p, bool isDesktop) {
    var servicios = _servicios(provider);

    if (_q.trim().isNotEmpty) {
      final q = _q.toLowerCase();
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
          _miPosicion!.latitude,
          _miPosicion!.longitude,
          s.latitud!,
          s.longitud!,
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
            isDesktop ? 20 : 14, 14, isDesktop ? 20 : 14, 60),
        children: [
          _searchBar(p),
          const SizedBox(height: 18),
          _chipsCategoriasServicio(p, _catSvc,
              (id) => setState(() => _catSvc = id)),
          const SizedBox(height: 26),

          if (conDist.isNotEmpty) ...[
            _sectionHeader(
              p,
              icon: Icons.near_me_rounded,
              title: 'Cerca de ti',
              subtitle: 'Servicios a tu alrededor',
              color: _C.success,
              count: conDist.length,
            ),
            const SizedBox(height: 12),
            ...conDist.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServicioCardPremium(
                    servicio: item.servicio,
                    p: p,
                    distanciaFormateada: _fmtDist(item.distancia),
                    accent: _C.success,
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
            _sectionHeader(
              p,
              icon: Icons.handyman_rounded,
              title: conDist.isEmpty
                  ? 'Servicios disponibles'
                  : 'Otros servicios',
              subtitle: 'En la Red Nexora',
              color: _C.purple,
              count: sinDist.length,
            ),
            const SizedBox(height: 12),
            ...sinDist.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServicioCardPremium(
                    servicio: s,
                    p: p,
                    accent: _C.purple,
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
            _empty(
              p,
              icon: Icons.handyman_rounded,
              title: 'Sin servicios',
              sub: 'Aún no hay servicios en la red. Vuelve pronto.',
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════
  Widget _searchBar(_P p) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border, width: 1.2),
        boxShadow: p.shadowSm,
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _q = v),
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: p.textHigh),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar en la red Nexora…',
          hintStyle:
              TextStyle(fontSize: 13.5, color: p.textMuted),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: p.textMuted),
          suffixIcon: _q.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: p.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _q = '');
                  })
              : null,
        ),
      ),
    );
  }

  Widget _sectionHeader(
    _P p, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    int? count,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(.72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: p.textHigh,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: p.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(p.dark ? .18 : .10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chipsCategorias(
      _P p, String? selected, ValueChanged<String?> onSelect) {
    final cats = CategoriasPublicas.tienda;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _chip(p, 'Todas', Icons.apps_rounded, selected == null,
              () => onSelect(null), _C.network),
          const SizedBox(width: 8),
          ...cats.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  p,
                  e.value,
                  _iconoCategoriaTienda(e.key),
                  selected == e.key,
                  () => onSelect(e.key),
                  _C.network,
                ),
              )),
        ],
      ),
    );
  }

  Widget _chipsCategoriasServicio(
      _P p, String? selected, ValueChanged<String?> onSelect) {
    final cats = CategoriasPublicas.servicio;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _chip(p, 'Todos', Icons.apps_rounded, selected == null,
              () => onSelect(null), _C.purple),
          const SizedBox(width: 8),
          ...cats.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  p,
                  e.value,
                  _iconoCategoriaServicio(e.key),
                  selected == e.key,
                  () => onSelect(e.key),
                  _C.purple,
                ),
              )),
        ],
      ),
    );
  }

  Widget _chip(_P p, String label, IconData icon, bool selected,
      VoidCallback onTap, Color accent) {
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
                ? LinearGradient(
                    colors: [accent, accent.withOpacity(.75)])
                : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: selected ? Colors.transparent : p.border),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : p.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: selected ? Colors.white : p.textMid,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridTodas(
      List<TiendaPublica> tiendas, _P p, bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isDesktop ? 2.6 : 3.4,
      ),
      itemCount: tiendas.length,
      itemBuilder: (_, i) => _TiendaCardList(
        tienda: tiendas[i],
        p: p,
        distanciaFormateada: _fmtDist(_distancia(tiendas[i])),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TiendaDetalleScreen(empresaId: tiendas[i].empresaId),
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.network.withOpacity(.22),
                _C.primary.withOpacity(.06),
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: _C.network),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted)),
        ],
      ),
    );
  }

  IconData _iconoCategoriaTienda(String cat) {
    switch (cat) {
      case 'abarrotes':
        return Icons.local_grocery_store_rounded;
      case 'ropa':
        return Icons.checkroom_rounded;
      case 'tecnologia':
        return Icons.devices_rounded;
      case 'hogar':
        return Icons.chair_rounded;
      case 'belleza':
        return Icons.spa_rounded;
      case 'comida':
        return Icons.restaurant_rounded;
      case 'servicios':
        return Icons.handyman_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  IconData _iconoCategoriaServicio(String cat) {
    switch (cat) {
      case 'reparacion':
        return Icons.build_rounded;
      case 'fabricacion':
        return Icons.precision_manufacturing_rounded;
      case 'estetica':
        return Icons.spa_rounded;
      case 'barberia':
        return Icons.content_cut_rounded;
      case 'limpieza':
        return Icons.cleaning_services_rounded;
      case 'transporte':
        return Icons.local_shipping_rounded;
      case 'diseno':
        return Icons.design_services_rounded;
      case 'informatica':
        return Icons.computer_rounded;
      case 'educacion':
        return Icons.school_rounded;
      case 'fotografia':
        return Icons.photo_camera_rounded;
      case 'mantenimiento':
        return Icons.engineering_rounded;
      case 'construccion':
        return Icons.construction_rounded;
      case 'eventos':
        return Icons.event_rounded;
      default:
        return Icons.handyman_rounded;
    }
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

// ════════════════════════════════════════════════════════════
//  PALETA
// ════════════════════════════════════════════════════════════
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const teal      = Color(0xFF14B8A6);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);
  static const gold      = Color(0xFFEAB308);
  static const purple    = Color(0xFF8B5CF6);

  static const network   = Color(0xFF06B6D4);
  static const gradNetwork = [Color(0xFF06B6D4), Color(0xFF14B8A6)];
  static const myBusiness = Color(0xFF8B5CF6);
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

// ════════════════════════════════════════════════════════════
//  CARD PREMIUM (carruseles)
// ════════════════════════════════════════════════════════════
class _TiendaCardPremium extends StatelessWidget {
  final TiendaPublica tienda;
  final _P p;
  final String distanciaFormateada;
  final VoidCallback onTap;
  final Color accent;
  final String badgeText;
  final int? rank;

  const _TiendaCardPremium({
    required this.tienda,
    required this.p,
    required this.onTap,
    this.distanciaFormateada = '',
    this.accent = _C.network,
    this.badgeText = '',
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoriasPublicas.nombreTienda(tienda.categoriaId);
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: p.dark
                      ? Colors.black.withOpacity(.35)
                      : const Color(0xFF0A1A33).withOpacity(.08),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 42,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              accent.withOpacity(.65),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(19),
                            topRight: Radius.circular(19),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            tienda.nombre.isNotEmpty
                                ? tienda.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ),
                      if (badgeText.isNotEmpty)
                        Positioned(
                          top: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      if (tienda.verificado)
                        Positioned(
                          top: 10, right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.verified_rounded,
                                size: 14, color: accent),
                          ),
                        ),
                      if (distanciaFormateada.isNotEmpty)
                        Positioned(
                          bottom: 10, left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(distanciaFormateada,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 58,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (rank != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(.14),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                tienda.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: p.textHigh,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 13, color: _C.gold),
                            const SizedBox(width: 3),
                            Text(
                              tienda.rating > 0
                                  ? tienda.rating.toStringAsFixed(1)
                                  : '—',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: p.textHigh,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.inventory_2_rounded,
                                size: 12, color: p.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${tienda.totalProductos}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted,
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
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CARD LIST
// ════════════════════════════════════════════════════════════
class _TiendaCardList extends StatelessWidget {
  final TiendaPublica tienda;
  final _P p;
  final String distanciaFormateada;
  final VoidCallback onTap;

  const _TiendaCardList({
    required this.tienda,
    required this.p,
    required this.onTap,
    this.distanciaFormateada = '',
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoriasPublicas.nombreTienda(tienda.categoriaId);
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
                  gradient: const LinearGradient(
                    colors: _C.gradNetwork,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.network.withOpacity(.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  tienda.nombre.isNotEmpty
                      ? tienda.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
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
                          child: Text(
                            tienda.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: p.textHigh,
                            ),
                          ),
                        ),
                        if (tienda.verificado) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: _C.network),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category_rounded,
                            size: 12, color: p.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            cat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded,
                            size: 12, color: _C.gold),
                        const SizedBox(width: 3),
                        Text(
                          tienda.rating > 0
                              ? tienda.rating.toStringAsFixed(1)
                              : '—',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: p.textHigh,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 12, color: p.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '${tienda.totalProductos} productos',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.textMuted,
                          ),
                        ),
                        if (distanciaFormateada.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.near_me_rounded,
                              size: 12, color: _C.success),
                          const SizedBox(width: 3),
                          Text(
                            distanciaFormateada,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: _C.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.network.withOpacity(p.dark ? .14 : .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: _C.network),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MI TIENDA CARD
// ════════════════════════════════════════════════════════════
class _MiTiendaCard extends StatelessWidget {
  final TiendaPublica tienda;
  final _P p;
  final VoidCallback onTap;

  const _MiTiendaCard({
    required this.tienda,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _C.purple.withOpacity(p.dark ? .22 : .10),
                _C.purple.withOpacity(p.dark ? .10 : .04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _C.purple.withOpacity(p.dark ? .35 : .22),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.purple, _C.network],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(.42),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tienda.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: p.textHigh,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.purple.withOpacity(.18),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'MÍA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _C.purple,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tienda.totalProductos} productos publicados · ${tienda.visitas} visitas',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SERVICIO CARD PREMIUM
// ════════════════════════════════════════════════════════════
class _ServicioCardPremium extends StatelessWidget {
  final ServicioPublico servicio;
  final _P p;
  final VoidCallback onTap;
  final String distanciaFormateada;
  final Color accent;

  const _ServicioCardPremium({
    required this.servicio,
    required this.p,
    required this.onTap,
    this.distanciaFormateada = '',
    this.accent = _C.purple,
  });

  @override
  Widget build(BuildContext context) {
    final cat = CategoriasPublicas.nombreServicio(servicio.categoriaId);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(.70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(_icono(servicio.categoriaId),
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded,
                            size: 11, color: p.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            servicio.nombreEmpresa,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.circle,
                            size: 3, color: p.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      servicio.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: p.textMid,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(p, servicio.precioTexto, _C.success,
                            Icons.sell_rounded),
                        if (distanciaFormateada.isNotEmpty)
                          _tag(p, distanciaFormateada, _C.info,
                              Icons.near_me_rounded),
                        ...servicio.tags.take(1).map((t) => _tag(
                            p, t, accent, Icons.local_offer_rounded)),
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

  Widget _tag(_P p, String label, Color color, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(p.dark ? .16 : .08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }

  IconData _icono(String cat) {
    switch (cat) {
      case 'reparacion':
        return Icons.build_rounded;
      case 'fabricacion':
        return Icons.precision_manufacturing_rounded;
      case 'estetica':
        return Icons.spa_rounded;
      case 'barberia':
        return Icons.content_cut_rounded;
      case 'limpieza':
        return Icons.cleaning_services_rounded;
      case 'transporte':
        return Icons.local_shipping_rounded;
      case 'diseno':
        return Icons.design_services_rounded;
      case 'informatica':
        return Icons.computer_rounded;
      case 'educacion':
        return Icons.school_rounded;
      case 'fotografia':
        return Icons.photo_camera_rounded;
      case 'mantenimiento':
        return Icons.engineering_rounded;
      case 'construccion':
        return Icons.construction_rounded;
      case 'eventos':
        return Icons.event_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }
}