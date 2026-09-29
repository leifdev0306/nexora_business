// ============================================================
//  mapa_tiendas_screen.dart  ·  NEXORA BUSINESS
//  Mapa interactivo con tiendas cercanas, ruta y acceso
//  SIN DATOS SIMULADOS · Claves namespaced por empresa
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/tienda_publica.dart';
import 'mi_tienda_screen.dart'
    show keyTiendaDeEmpresa, kNetworkStoresKey;
import 'tienda_detalle_screen.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan    = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const danger  = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info    = Color(0xFF3B82F6);
  static const gold    = Color(0xFFCA8A04);
  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg        => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface   => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2  => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh  => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid   => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border    => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
}

const LatLng kCentroCuba = LatLng(23.1136, -82.3666);

class MapaTiendasScreen extends StatefulWidget {
  final TiendaPublica? tiendaEnfocada;

  const MapaTiendasScreen({Key? key, this.tiendaEnfocada}) : super(key: key);

  @override
  State<MapaTiendasScreen> createState() => _MapaTiendasScreenState();
}

class _MapaTiendasScreenState extends State<MapaTiendasScreen> {
  final MapController _mapController = MapController();

  Position? _miPosicion;
  bool _cargandoUbicacion = false;
  String? _errorUbicacion;

  List<_PuntoTienda> _tiendas = [];
  _PuntoTienda? _seleccionada;
  bool _mapaListo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTiendas();
      _obtenerUbicacion(silencioso: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ============================================================
  //  CARGAR TIENDAS
  // ============================================================
  void _cargarTiendas() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final lista = <_PuntoTienda>[];
    final empresaIdActual = provider.empresaId ?? '';

    // 1) Mi propia tienda (clave namespaced)
    if (empresaIdActual.isNotEmpty) {
      final miRaw = provider.catalogosBox
          .get(keyTiendaDeEmpresa(empresaIdActual));
      if (miRaw is Map) {
        final propia =
            TiendaPublica.fromJson(Map<String, dynamic>.from(miRaw));
        if (propia.tieneUbicacion &&
            propia.activa &&
            propia.empresaId == empresaIdActual) {
          lista.add(_PuntoTienda(tienda: propia, esPropia: true));
        }
      }
    }

    // 2) Tiendas de la red
    final netRaw =
        (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
    for (final e in netRaw) {
      final t = TiendaPublica.fromJson(Map<String, dynamic>.from(e));
      if (!t.tieneUbicacion) continue;
      if (!t.activa) continue;
      if (t.empresaId == empresaIdActual) continue;
      lista.add(_PuntoTienda(tienda: t, esPropia: false));
    }

    if (!mounted) return;
    setState(() => _tiendas = lista);

    // 3) Tienda enfocada por parámetro
    if (widget.tiendaEnfocada != null &&
        widget.tiendaEnfocada!.tieneUbicacion) {
      final existe = _tiendas.any((t) =>
          t.tienda.empresaId == widget.tiendaEnfocada!.empresaId);

      if (!existe) {
        setState(() {
          _tiendas.add(_PuntoTienda(
            tienda: widget.tiendaEnfocada!,
            esPropia:
                widget.tiendaEnfocada!.empresaId == empresaIdActual,
          ));
        });
      }
      _seleccionada = _tiendas.firstWhere(
        (t) => t.tienda.empresaId == widget.tiendaEnfocada!.empresaId,
        orElse: () => _tiendas.first,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_mapaListo) return;
        _mapController.move(
          LatLng(
            widget.tiendaEnfocada!.latitud!,
            widget.tiendaEnfocada!.longitud!,
          ),
          16,
        );
      });
    } else if (_tiendas.isNotEmpty) {
      _seleccionada = _tiendas.first;
    }
  }

  // ============================================================
  //  UBICACIÓN DEL USUARIO
  // ============================================================
  Future<void> _obtenerUbicacion({bool silencioso = false}) async {
    if (_cargandoUbicacion) return;
    setState(() {
      _cargandoUbicacion = true;
      _errorUbicacion = null;
    });

    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        setState(() => _errorUbicacion = 'GPS desactivado');
        if (!silencioso) {
          mostrarSnackBar(
              mensaje: 'Activa el GPS para ver tu ubicación',
              esExito: false);
        }
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        setState(() => _errorUbicacion = 'Permiso denegado');
        if (!silencioso) {
          mostrarSnackBar(
              mensaje: 'Permiso de ubicación denegado', esExito: false);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;
      setState(() => _miPosicion = pos);

      if (!silencioso && _mapaListo) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
      }
    } catch (e) {
      setState(() => _errorUbicacion = 'No disponible');
      if (!silencioso) {
        mostrarSnackBar(
            mensaje: 'No se pudo obtener la ubicación',
            esExito: false);
      }
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  // ============================================================
  //  NAVEGACIÓN EXTERNA
  // ============================================================
  Future<void> _abrirNavegacion(_PuntoTienda p) async {
    if (!p.tienda.tieneUbicacion) {
      mostrarSnackBar(
          mensaje: 'Esta tienda no tiene ubicación', esExito: false);
      return;
    }
    final lat = p.tienda.latitud!;
    final lng = p.tienda.longitud!;

    final googleUrl = 'https://www.google.com/maps/dir/?api=1'
        '&destination=$lat,$lng&travelmode=driving';
    final appleUrl = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
    final geoUri = Uri.parse(
        'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(p.tienda.nombre)})');

    try {
      final launched =
          await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    try {
      final launched = await launchUrl(
        Uri.parse(googleUrl),
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      await launchUrl(Uri.parse(appleUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      mostrarSnackBar(
          mensaje: 'No se pudo abrir la app de mapas', esExito: false);
    }
  }

  // ============================================================
  //  VER PRODUCTOS
  // ============================================================
  void _verProductos(_PuntoTienda sel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TiendaDetalleScreen(
          empresaId: sel.tienda.empresaId,
        ),
      ),
    );
  }

  // ============================================================
  //  DISTANCIA
  // ============================================================
  double? _distanciaMetros(_PuntoTienda p) {
    if (_miPosicion == null || !p.tienda.tieneUbicacion) return null;
    return Geolocator.distanceBetween(
      _miPosicion!.latitude,
      _miPosicion!.longitude,
      p.tienda.latitud!,
      p.tienda.longitud!,
    );
  }

  String _formatearDistancia(double? metros) {
    if (metros == null) return '—';
    if (metros < 1000) return '${metros.toStringAsFixed(0)} m';
    if (metros < 10000) return '${(metros / 1000).toStringAsFixed(2)} km';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    LatLng centro = kCentroCuba;
    if (_seleccionada != null && _seleccionada!.tienda.tieneUbicacion) {
      centro = LatLng(
        _seleccionada!.tienda.latitud!,
        _seleccionada!.tienda.longitud!,
      );
    } else if (_miPosicion != null) {
      centro = LatLng(_miPosicion!.latitude, _miPosicion!.longitude);
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textHigh,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.map_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mapa de tiendas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    )),
                if (_tiendas.isNotEmpty)
                  Text(
                    '${_tiendas.length} tienda${_tiendas.length == 1 ? '' : 's'} en el mapa',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: p.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mi ubicación',
            onPressed: _cargandoUbicacion
                ? null
                : () => _obtenerUbicacion(silencioso: false),
            icon: _cargandoUbicacion
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.my_location_rounded, color: p.textHigh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centro,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 18,
              onMapReady: () => _mapaListo = true,
              onTap: (_, __) => setState(() => _seleccionada = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nexorabusiness.app',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  for (final t in _tiendas)
                    if (t.tienda.tieneUbicacion)
                      Marker(
                        point: LatLng(
                            t.tienda.latitud!, t.tienda.longitud!),
                        width: 56, height: 56,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _seleccionada = t),
                          child: _marcadorTienda(t, p),
                        ),
                      ),
                  if (_miPosicion != null)
                    Marker(
                      point: LatLng(
                        _miPosicion!.latitude,
                        _miPosicion!.longitude,
                      ),
                      width: 40, height: 40,
                      child: _marcadorYo(),
                    ),
                ],
              ),
            ],
          ),
          if (_seleccionada != null)
            Positioned(
              left: 12, right: 12, bottom: 16,
              child: _cardSeleccionada(_seleccionada!, p),
            ),
          if (_errorUbicacion != null && _seleccionada == null)
            Positioned(
              left: 12, right: 12, top: 12,
              child: _avisoUbicacion(p),
            ),
          if (_tiendas.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off_rounded,
                            color: _C.warning, size: 40),
                        const SizedBox(height: 10),
                        Text('Sin tiendas en el mapa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: p.textHigh,
                            )),
                        const SizedBox(height: 6),
                        Text(
                          'Configura tu ubicación en "Mi tienda" para '
                          'que aparezcas aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _marcadorTienda(_PuntoTienda t, _P p) {
    final seleccionada =
        _seleccionada?.tienda.empresaId == t.tienda.empresaId;

    final gradient = t.esPropia
        ? const LinearGradient(colors: _C.gradBrand)
        : const LinearGradient(
            colors: [_C.info, Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final sombraColor = t.esPropia ? _C.primary : _C.info;

    return AnimatedScale(
      scale: seleccionada ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: sombraColor.withOpacity(.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              t.esPropia
                  ? Icons.storefront_rounded
                  : Icons.store_mall_directory_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            width: 3, height: 6,
            decoration: BoxDecoration(
              color: sombraColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marcadorYo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _C.success.withOpacity(.25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Container(
          width: 14, height: 14,
          decoration: const BoxDecoration(
            color: _C.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _cardSeleccionada(_PuntoTienda sel, _P p) {
    final t = sel.tienda;
    final metros = _distanciaMetros(sel);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      color: p.surface,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: _C.gradBrand),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      t.nombre.isNotEmpty
                          ? t.nombre.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(t.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: p.textHigh,
                                )),
                          ),
                          if (sel.esPropia) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.primary.withOpacity(.14),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: const Text('MI TIENDA',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: _C.primary,
                                  )),
                            ),
                          ],
                          if (t.verificado && !sel.esPropia) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                size: 14, color: _C.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (t.rating > 0) ...[
                            const Icon(Icons.star_rounded,
                                size: 12, color: _C.warning),
                            const SizedBox(width: 3),
                            Text(t.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: p.textHigh,
                                )),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.location_on_rounded,
                              size: 12, color: p.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              t.direccion?.isNotEmpty == true
                                  ? t.direccion!
                                  : 'Sin dirección',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textMuted),
                            ),
                          ),
                          if (metros != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.success.withOpacity(.14),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatearDistancia(metros),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _C.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _seleccionada = null),
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: p.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _verProductos(sel),
                    icon: const Icon(Icons.storefront_rounded,
                        size: 17),
                    label: const Text('Ver productos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirNavegacion(sel),
                    icon: const Icon(Icons.directions_rounded,
                        size: 16),
                    label: const Text('Ir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.success,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                          color: _C.success.withOpacity(.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (t.telefono?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  _accionIcono(
                    icon: Icons.call_rounded,
                    color: _C.success,
                    onTap: () async {
                      final uri = Uri.parse('tel:${t.telefono}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ],
                if (t.whatsapp?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  _accionIcono(
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final numero = t.whatsapp!
                          .replaceAll(RegExp(r'\D'), '');
                      final uri =
                          Uri.parse('https://wa.me/$numero');
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionIcono({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44, height: 44,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _avisoUbicacion(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.warning.withOpacity(.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: _C.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Activa la ubicación para ver tu posición y calcular distancias.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textHigh,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _obtenerUbicacion(silencioso: false),
            child: const Text('Activar',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  AUXILIAR
// ============================================================
class _PuntoTienda {
  final TiendaPublica tienda;
  final bool esPropia;

  _PuntoTienda({required this.tienda, required this.esPropia});

  @override
  bool operator ==(Object other) =>
      other is _PuntoTienda && other.tienda.empresaId == tienda.empresaId;

  @override
  int get hashCode => tienda.empresaId.hashCode ^ esPropia.hashCode;
}

double distanciaHaversine(LatLng a, LatLng b) {
  const radio = 6371000.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * radio * math.asin(math.sqrt(h));
}