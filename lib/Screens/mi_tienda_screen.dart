// ============================================================
//  mi_tienda_screen.dart  ·  NEXORA BUSINESS
//  Gestión completa de la tienda pública + servicios
//  · Sync automático a Supabase (Red Nexora)
//  · Catálogo construido desde inventario real
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import 'mapa_tiendas_screen.dart';
import 'servicio_cancelado_screen.dart';

// ════════════════════════════════════════════════════════════
//  CLAVES
// ════════════════════════════════════════════════════════════
const String kNetworkStoresKey = 'network_stores';
const String kNetworkSvcsKey   = 'network_services';
const String kNetworkRev       = 'network_reviews';

String keyTiendaDeEmpresa(String id) => 'tiendaPublica_$id';
String keyMisServiciosDeEmpresa(String id) => 'my_services_$id';

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
  static const gold      = Color(0xFFCA8A04);

  static const gradBrand  = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradPurple = [Color(0xFF8B5CF6), Color(0xFF6366F1)];
  static const gradSuccess= [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm   = [Color(0xFFF59E0B), Color(0xFFF97316)];
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
//  SCREEN
// ════════════════════════════════════════════════════════════
class MiTiendaScreen extends StatefulWidget {
  const MiTiendaScreen({Key? key}) : super(key: key);

  @override
  State<MiTiendaScreen> createState() => _MiTiendaScreenState();
}

class _MiTiendaScreenState extends State<MiTiendaScreen> {
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _telefonoCtrl    = TextEditingController();
  final _whatsappCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _direccionCtrl   = TextEditingController();
  final _horarioCtrl     = TextEditingController();

  TiendaPublica? _tienda;
  bool _cargando = true;
  bool _guardando = false;
  bool _editando = false;
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _horarioCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  //  CARGA
  // ============================================================
  Future<void> _cargar() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final tiendaKey = keyTiendaDeEmpresa(empresaId);

    // Limpieza de clave legacy
    if (provider.catalogosBox.get('tiendaPublicaConfig') != null) {
      await provider.catalogosBox.delete('tiendaPublicaConfig');
    }

    TiendaPublica? t;
    final raw = provider.catalogosBox.get(tiendaKey);
    if (raw is Map) {
      final temp = TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
      if (temp.empresaId == empresaId) t = temp;
    }

    if (t == null) {
      t = TiendaPublica.porDefecto(
        empresaId: empresaId,
        nombreEmpresa: provider.nombreEmpresa ?? 'Mi Empresa',
      );
    }

    final idsValidos = provider.productos.map((p) => p.id).toSet();
    final limpios = t.productosPublicados
        .where((id) => idsValidos.contains(id))
        .toList();

    final catalogo = _buildCatalogo(provider, limpios);

    t = t.copyWith(
      productosPublicados: limpios,
      catalogo: catalogo,
    );

    await _persistirYRed(provider, t);

    if (!mounted) return;
    setState(() {
      _tienda = t;
      _cargando = false;
      _sincronizarControllers(t!);
    });
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

  // ============================================================
  //  PERSISTIR local + SUPABASE
  // ============================================================
  Future<void> _persistirYRed(
      AppProvider provider, TiendaPublica t) async {
    // 1) Local namespaced
    await provider.catalogosBox.put(
        keyTiendaDeEmpresa(t.empresaId), t.toJson());

    // 2) Local "red" para lectura rápida en este dispositivo
    final raw =
        (provider.catalogosBox.get(kNetworkStoresKey) as List?) ?? [];
    final list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    final idx = list.indexWhere((e) => e['empresaId'] == t.empresaId);
    final json = t.toJson();
    if (idx >= 0) {
      list[idx] = json;
    } else {
      list.add(json);
    }
    await provider.catalogosBox.put(kNetworkStoresKey, list);

    // 3) SUPABASE — sube para que otros dispositivos lo vean
    if (provider.isOnline) {
      try {
        await provider.publicarTiendaEnRed(
          nombre: t.nombre,
          slug: t.slug,
          descripcion: t.descripcion,
          telefono: t.telefono,
          whatsapp: t.whatsapp,
          email: t.email,
          direccion: t.direccion,
          horario: t.horario,
          categoriaId: t.categoriaId,
          latitud: t.latitud,
          longitud: t.longitud,
          catalogo: t.catalogo.map((p) => p.toJson()).toList(),
          activa: t.activa,
        );
        print('✅ Tienda publicada en Supabase');
      } catch (e) {
        print('⚠️ Error publicando tienda en Supabase: $e');
      }
    }
  }

  void _sincronizarControllers(TiendaPublica t) {
    _nombreCtrl.text = t.nombre;
    _descripcionCtrl.text = t.descripcion;
    _telefonoCtrl.text = t.telefono ?? '';
    _whatsappCtrl.text = t.whatsapp ?? '';
    _emailCtrl.text = t.email ?? '';
    _direccionCtrl.text = t.direccion ?? '';
    _horarioCtrl.text = t.horario ?? '';
  }

  // ============================================================
  //  GUARDAR
  // ============================================================
  Future<void> _guardar() async {
    if (_tienda == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    setState(() => _guardando = true);
    try {
      final limpios = _tienda!.productosPublicados;
      final catalogo = _buildCatalogo(provider, limpios);

      final nueva = _tienda!.copyWith(
        nombre: _nombreCtrl.text.trim().isEmpty
            ? _tienda!.nombre
            : _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        slug: TiendaPublica.generarSlug(
          _nombreCtrl.text.trim().isEmpty
              ? _tienda!.nombre
              : _nombreCtrl.text.trim(),
        ),
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null : _telefonoCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim().isEmpty
            ? null : _whatsappCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty
            ? null : _emailCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null : _direccionCtrl.text.trim(),
        horario: _horarioCtrl.text.trim().isEmpty
            ? null : _horarioCtrl.text.trim(),
        catalogo: catalogo,
        updatedAt: DateTime.now(),
      );

      await _persistirYRed(provider, nueva);

      if (!mounted) return;
      setState(() {
        _tienda = nueva;
        _editando = false;
      });
      mostrarSnackBar(mensaje: 'Tienda actualizada', esExito: true);
    } catch (e) {
      if (!mounted) return;
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _toggleActiva() async {
    if (_tienda == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nueva = _tienda!.copyWith(
      activa: !_tienda!.activa,
      updatedAt: DateTime.now(),
    );
    await _persistirYRed(provider, nueva);
    if (!mounted) return;
    setState(() => _tienda = nueva);
    mostrarSnackBar(
      mensaje: nueva.activa ? 'Tienda activada' : 'Tienda desactivada',
      esExito: true,
    );
  }

  Future<void> _compartir() async {
    if (_tienda == null) return;
    final mensaje = '🛍️ ¡Visita mi tienda en línea!\n\n'
        '${_tienda!.nombre}\n'
        '${_tienda!.descripcion}\n\n'
        '${_tienda!.urlPublica}';
    await Share.share(mensaje);
  }

  // ============================================================
  //  UBICACIÓN
  // ============================================================
  Future<void> _usarMiUbicacion() async {
    if (_tienda == null) return;
    setState(() => _obteniendoUbicacion = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        mostrarSnackBar(
            mensaje: 'Activa el GPS de tu dispositivo', esExito: false);
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        mostrarSnackBar(
            mensaje: 'Permiso de ubicación denegado', esExito: false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _guardarCoordenadas(pos.latitude, pos.longitude);
      mostrarSnackBar(
          mensaje: 'Ubicación actualizada desde el GPS', esExito: true);
    } catch (_) {
      mostrarSnackBar(
          mensaje: 'No se pudo obtener la ubicación', esExito: false);
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  Future<void> _abrirSelectorEnMapa() async {
    if (_tienda == null) return;
    final resultado = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _SelectorUbicacionScreen(
          inicial: _tienda!.tieneUbicacion
              ? LatLng(_tienda!.latitud!, _tienda!.longitud!)
              : const LatLng(23.1136, -82.3666),
          direccionSugerida: _direccionCtrl.text.trim(),
        ),
      ),
    );
    if (resultado != null) {
      await _guardarCoordenadas(resultado.latitude, resultado.longitude);
      mostrarSnackBar(
          mensaje: 'Ubicación actualizada', esExito: true);
    }
  }

  Future<void> _guardarCoordenadas(double lat, double lng) async {
    if (_tienda == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nueva = _tienda!.copyWith(
      latitud: lat, longitud: lng, updatedAt: DateTime.now(),
    );
    await _persistirYRed(provider, nueva);
    if (!mounted) return;
    setState(() => _tienda = nueva);
  }

  Future<void> _limpiarUbicacion() async {
    if (_tienda == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nueva = _tienda!.copyWith(
      limpiarUbicacion: true, updatedAt: DateTime.now(),
    );
    await _persistirYRed(provider, nueva);
    if (!mounted) return;
    setState(() => _tienda = nueva);
    mostrarSnackBar(mensaje: 'Ubicación eliminada', esExito: true);
  }

  Future<void> _verEnMapa() async {
    if (_tienda == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaTiendasScreen(tiendaEnfocada: _tienda),
      ),
    );
  }

  Future<void> _abrirComoLlegar() async {
    if (_tienda == null || !_tienda!.tieneUbicacion) return;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${_tienda!.latitud},${_tienda!.longitud}&travelmode=driving';
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ============================================================
  //  MIS SERVICIOS
  // ============================================================
  List<ServicioPublico> _misServicios(AppProvider provider) {
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return [];
    final raw = (provider.catalogosBox
            .get(keyMisServiciosDeEmpresa(empresaId)) as List?) ??
        [];
    return raw
        .map((e) => ServicioPublico.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _persistirServicio(
      AppProvider provider, ServicioPublico s) async {
    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return;
    final myKey = keyMisServiciosDeEmpresa(empresaId);

    // 1) Local
    final raw = (provider.catalogosBox.get(myKey) as List?) ?? [];
    final list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    final idx = list.indexWhere((e) => e['id'] == s.id);
    if (idx >= 0) {
      list[idx] = s.toJson();
    } else {
      list.add(s.toJson());
    }
    await provider.catalogosBox.put(myKey, list);

    // 2) Red local
    final netRaw =
        (provider.catalogosBox.get(kNetworkSvcsKey) as List?) ?? [];
    final netList =
        netRaw.map((e) => Map<String, dynamic>.from(e)).toList();
    final netIdx = netList.indexWhere((e) => e['id'] == s.id);
    if (netIdx >= 0) {
      netList[netIdx] = s.toJson();
    } else {
      netList.add(s.toJson());
    }
    await provider.catalogosBox.put(kNetworkSvcsKey, netList);

    // 3) Supabase
    if (provider.isOnline) {
      try {
        await provider.publicarServicioEnRed(
          id: s.id,
          categoriaId: s.categoriaId,
          nombre: s.nombre,
          descripcion: s.descripcion,
          precioDesde: s.precioDesde,
          precioNota: s.precioNota,
          telefono: s.telefono,
          whatsapp: s.whatsapp,
          horario: s.horario,
          tags: s.tags,
          latitud: s.latitud,
          longitud: s.longitud,
          activo: s.activo,
        );
        print('✅ Servicio publicado en Supabase');
      } catch (e) {
        print('⚠️ Error publicando servicio: $e');
      }
    }
  }

  Future<void> _eliminarServicio(
      AppProvider provider, ServicioPublico s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Seguro que quieres eliminar "${s.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _C.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final empresaId = provider.empresaId ?? '';
    if (empresaId.isEmpty) return;
    final myKey = keyMisServiciosDeEmpresa(empresaId);

    final raw = (provider.catalogosBox.get(myKey) as List?) ?? [];
    await provider.catalogosBox.put(
      myKey,
      raw
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'] != s.id)
          .toList(),
    );

    final netRaw =
        (provider.catalogosBox.get(kNetworkSvcsKey) as List?) ?? [];
    await provider.catalogosBox.put(
      kNetworkSvcsKey,
      netRaw
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['id'] != s.id)
          .toList(),
    );

    if (provider.isOnline) {
      await provider.eliminarServicioDeRed(s.id);
    }

    if (!mounted) return;
    setState(() {});
    mostrarSnackBar(mensaje: 'Servicio eliminado', esExito: true);
  }

  Future<void> _editarServicio(
      AppProvider provider, _P p, ServicioPublico? original) async {
    final nombreCtrl = TextEditingController(text: original?.nombre ?? '');
    final descCtrl   = TextEditingController(text: original?.descripcion ?? '');
    final precioCtrl = TextEditingController(
        text: original?.precioDesde?.toStringAsFixed(0) ?? '');
    final notaCtrl   = TextEditingController(text: original?.precioNota ?? '');
    final tagsCtrl   = TextEditingController(
        text: (original?.tags ?? []).join(', '));
    final telCtrl = TextEditingController(
        text: original?.telefono ?? _telefonoCtrl.text);
    final waCtrl = TextEditingController(
        text: original?.whatsapp ?? _whatsappCtrl.text);
    final horCtrl = TextEditingController(text: original?.horario ?? '');

    String cat = original?.categoriaId ?? 'reparacion';
    bool activo = original?.activo ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.gradPurple),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.handyman_rounded,
                          color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      original == null
                          ? 'Publicar nuevo servicio'
                          : 'Editar servicio',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle:
                        TextStyle(fontSize: 12.5, color: p.textMuted),
                    filled: true,
                    fillColor: p.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: CategoriasPublicas.servicio.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: TextStyle(
                                    fontSize: 13, color: p.textHigh)),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => cat = v ?? cat),
                ),
                const SizedBox(height: 12),
                _fieldMini(nombreCtrl, 'Nombre del servicio',
                    Icons.title_rounded, p),
                const SizedBox(height: 10),
                _fieldMini(descCtrl, 'Descripción',
                    Icons.notes_rounded, p, maxLines: 3),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _fieldMini(precioCtrl, 'Precio (opcional)',
                          Icons.attach_money_rounded, p,
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _fieldMini(notaCtrl, 'Nota de precio',
                          Icons.info_outline_rounded, p),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _fieldMini(tagsCtrl, 'Etiquetas (separadas por coma)',
                    Icons.local_offer_rounded, p),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _fieldMini(telCtrl, 'Teléfono',
                          Icons.phone_rounded, p,
                          keyboardType: TextInputType.phone),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _fieldMini(waCtrl, 'WhatsApp',
                          Icons.chat_rounded, p,
                          keyboardType: TextInputType.phone),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _fieldMini(horCtrl, 'Horario',
                    Icons.schedule_rounded, p),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Servicio activo',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh)),
                  value: activo,
                  activeColor: _C.purple,
                  onChanged: (v) => setLocal(() => activo = v),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      mostrarSnackBar(
                          mensaje: 'Completa nombre y descripción',
                          esExito: false);
                      return;
                    }
                    final empresaId = provider.empresaId ?? '';
                    final nuevo = ServicioPublico(
                      id: original?.id ??
                          'svc-${DateTime.now().millisecondsSinceEpoch}',
                      empresaId: empresaId,
                      nombreEmpresa: _nombreCtrl.text.trim().isEmpty
                          ? (provider.nombreEmpresa ?? 'Mi Empresa')
                          : _nombreCtrl.text.trim(),
                      categoriaId: cat,
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descCtrl.text.trim(),
                      precioDesde:
                          double.tryParse(precioCtrl.text.trim()),
                      precioNota: notaCtrl.text.trim().isEmpty
                          ? null : notaCtrl.text.trim(),
                      telefono: telCtrl.text.trim().isEmpty
                          ? null : telCtrl.text.trim(),
                      whatsapp: waCtrl.text.trim().isEmpty
                          ? null : waCtrl.text.trim(),
                      horario: horCtrl.text.trim().isEmpty
                          ? null : horCtrl.text.trim(),
                      tags: tagsCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      activo: activo,
                      latitud: _tienda?.latitud,
                      longitud: _tienda?.longitud,
                      createdAt: original?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await _persistirServicio(provider, nuevo);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    setState(() {});
                    mostrarSnackBar(
                        mensaje: original == null
                            ? 'Servicio publicado'
                            : 'Servicio actualizado',
                        esExito: true);
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(original == null
                      ? 'Publicar servicio'
                      : 'Guardar cambios'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nombreCtrl.dispose();
    descCtrl.dispose();
    precioCtrl.dispose();
    notaCtrl.dispose();
    tagsCtrl.dispose();
    telCtrl.dispose();
    waCtrl.dispose();
    horCtrl.dispose();
  }

  Widget _fieldMini(
    TextEditingController ctrl,
    String label,
    IconData icon,
    _P p, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textHigh),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12.5, color: p.textMuted),
        prefixIcon: Icon(icon, size: 16, color: _C.purple),
        filled: true,
        fillColor: p.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
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

    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_tienda == null)
            _emptyError(p)
          else
            RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroCard(provider, p),
                        const SizedBox(height: 16),
                        _statsRow(provider, p, isDesktop),
                        const SizedBox(height: 16),
                        _accionesRapidas(context, provider, p, isDesktop),
                        const SizedBox(height: 22),
                        _seccionMisServicios(context, provider, p),
                        const SizedBox(height: 22),
                        _seccionUbicacion(p, isDesktop),
                        const SizedBox(height: 22),
                        _seccionInfo(provider, p, isDesktop),
                        const SizedBox(height: 22),
                        _seccionContacto(p, isDesktop),
                        const SizedBox(height: 30),
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

  Widget _background(_P p) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -180, right: -160,
                child: _orb(420,
                    _C.primary.withOpacity(p.dark ? .12 : .07)),
              ),
              Positioned(
                bottom: -220, left: -140,
                child: _orb(440,
                    _C.cyan.withOpacity(p.dark ? .10 : .06)),
              ),
            ],
          ),
        ),
      );

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
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Mi tienda',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  )),
              Text('Tu negocio en línea',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  )),
            ],
          ),
        ],
      ),
      actions: [
        if (_tienda != null && !_editando)
          IconButton(
            tooltip: 'Editar',
            onPressed: () => setState(() => _editando = true),
            icon: Icon(Icons.edit_rounded, color: p.textHigh),
          ),
        if (_tienda != null)
          IconButton(
            tooltip: 'Compartir',
            onPressed: _compartir,
            icon: Icon(Icons.share_rounded, color: p.textHigh),
          ),
      ],
    );
  }

  Widget _emptyError(_P p) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 60, color: _C.primary),
              const SizedBox(height: 14),
              Text('No se pudo cargar la tienda',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  )),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: _cargar,
                  child: const Text('Reintentar')),
            ],
          ),
        ),
      );

  Widget _heroCard(AppProvider provider, _P p) {
    final t = _tienda!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _C.gradBrand,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.42),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(.32)),
                ),
                child: const Icon(Icons.store_mall_directory_rounded,
                    color: Colors.white, size: 28),
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
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.15,
                        )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: t.activa
                                ? Colors.white
                                : Colors.white.withOpacity(.5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.activa
                              ? 'TIENDA ACTIVA'
                              : 'TIENDA DESACTIVADA',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.92),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: t.activa,
                onChanged: (_) => _toggleActiva(),
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(.35),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(.25),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(.24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.urlPublica,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.95),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                Material(
                  color: Colors.white.withOpacity(.20),
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: t.urlPublica));
                      mostrarSnackBar(
                          mensaje: 'Enlace copiado', esExito: true);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.copy_rounded,
                          color: Colors.white, size: 15),
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

  Widget _statsRow(AppProvider provider, _P p, bool isDesktop) {
    final t = _tienda!;
    final publicados = t.catalogo.length;
    final conStock = t.catalogo.where((x) => x.disponible).length;
    final misServicios = _misServicios(provider).length;

    final tiles = [
      _statTile(p,
          icon: Icons.inventory_2_rounded,
          label: 'Productos', value: '$publicados',
          color: _C.primary),
      _statTile(p,
          icon: Icons.check_circle_rounded,
          label: 'Con stock', value: '$conStock',
          color: _C.success),
      _statTile(p,
          icon: Icons.handyman_rounded,
          label: 'Servicios', value: '$misServicios',
          color: _C.purple),
      _statTile(p,
          icon: Icons.location_on_rounded,
          label: 'Ubicación',
          value: t.tieneUbicacion ? 'OK' : '—',
          color: _C.info),
    ];

    if (isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            Expanded(child: tiles[i]),
            if (i != tiles.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i != tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _statTile(_P p,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: p.textHigh,
                )),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _accionesRapidas(BuildContext context, AppProvider provider,
      _P p, bool isDesktop) {
    final t = _tienda!;
    final acciones = [
      _accionTile(context, p,
          icon: Icons.add_photo_alternate_rounded,
          label: 'Publicar', sub: 'Añadir producto',
          color: _C.primary,
          onTap: () => Navigator.pushNamed(
                  context, '/publicar-producto')
              .then((_) => _cargar())),
      _accionTile(context, p,
          icon: Icons.inventory_rounded,
          label: 'Productos',
          sub: '${t.catalogo.length} en tienda',
          color: _C.purple,
          onTap: () => Navigator.pushNamed(
                  context, '/productos-publicados')
              .then((_) => _cargar())),
      _accionTile(context, p,
          icon: Icons.map_rounded,
          label: 'Ver en mapa',
          sub: t.tieneUbicacion ? 'Ubicación lista' : 'Sin coordenadas',
          color: _C.info,
          onTap: _verEnMapa),
      _accionTile(context, p,
          icon: Icons.share_rounded,
          label: 'Compartir', sub: 'Enviar enlace',
          color: _C.pink,
          onTap: _compartir),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isDesktop ? 1.8 : 1.75,
      children: acciones,
    );
  }

  Widget _accionTile(BuildContext context, _P p,
      {required IconData icon,
      required String label,
      required String sub,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(.22),
                    color.withOpacity(.06),
                  ]),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  )),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: p.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionMisServicios(
      BuildContext context, AppProvider provider, _P p) {
    final mis = _misServicios(provider);

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
                  gradient: const LinearGradient(colors: _C.gradPurple),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Mis servicios publicados',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: p.textHigh,
                      letterSpacing: -0.2,
                    )),
              ),
              if (mis.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.purple.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${mis.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _C.purple,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (mis.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _C.warning, size: 26),
                  const SizedBox(height: 8),
                  Text('¿Ofreces servicios?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    'Publica tus servicios para que otros negocios '
                    'te encuentren en la Red Nexora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: mis
                  .map((s) =>
                      _servicioMiniCard(context, provider, s, p))
                  .toList(),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _editarServicio(provider, p, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Publicar nuevo servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
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

  Widget _servicioMiniCard(
      BuildContext context,
      AppProvider provider,
      ServicioPublico s,
      _P p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _C.purple.withOpacity(.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.purple.withOpacity(.24)),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: _C.purple, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nombre,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(CategoriasPublicas.nombreServicio(
                            s.categoriaId),
                        style: TextStyle(
                            fontSize: 10.5, color: p.textMuted)),
                    const SizedBox(width: 8),
                    Text(s.precioTexto,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _C.success,
                        )),
                  ],
                ),
              ],
            ),
          ),
          if (!s.activo)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('OCULTO',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: _C.danger,
                  )),
            ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: () => _editarServicio(provider, p, s),
            icon: const Icon(Icons.edit_rounded, color: _C.primary),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: () => _eliminarServicio(provider, s),
            icon: const Icon(Icons.delete_outline_rounded,
                color: _C.danger),
          ),
        ],
      ),
    );
  }

  Widget _seccionUbicacion(_P p, bool isDesktop) {
    final t = _tienda!;
    final tiene = t.tieneUbicacion;

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
                    _C.info.withOpacity(.22),
                    _C.info.withOpacity(.06),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.info.withOpacity(.24)),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: _C.info, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Ubicación en el mapa',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                    letterSpacing: -0.2,
                  )),
              const Spacer(),
              if (tiene)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.success.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('LISTA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: _C.success,
                      )),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (tiene)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            LatLng(t.latitud!, t.longitud!),
                        initialZoom: 15,
                        interactionOptions:
                            const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.nexorabusiness.app',
                        ),
                        MarkerLayer(markers: [
                          Marker(
                            point:
                                LatLng(t.latitud!, t.longitud!),
                            width: 40, height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: _C.gradBrand),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.primary.withOpacity(.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _verEnMapa,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.open_in_full_rounded,
                                    size: 14, color: _C.primary),
                                SizedBox(width: 5),
                                Text('Ampliar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _C.primary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 20),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: _C.warning, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aún no has marcado tu tienda en el mapa. '
                      'Los clientes no podrán verla ni saber cómo llegar.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: p.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (tiene) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.pin_drop_rounded,
                    size: 14, color: p.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${t.latitud!.toStringAsFixed(5)}, '
                  '${t.longitud!.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _btnAccion(
                icon: Icons.my_location_rounded,
                label: _obteniendoUbicacion
                    ? 'Obteniendo…' : 'Usar mi ubicación',
                color: _C.primary,
                onTap: _obteniendoUbicacion ? null : _usarMiUbicacion,
                cargando: _obteniendoUbicacion,
              ),
              _btnAccion(
                icon: Icons.edit_location_alt_rounded,
                label: tiene ? 'Ajustar en mapa' : 'Marcar en mapa',
                color: _C.info,
                onTap: _abrirSelectorEnMapa,
              ),
              if (tiene)
                _btnAccion(
                  icon: Icons.directions_rounded,
                  label: 'Cómo llegar',
                  color: _C.success,
                  onTap: _abrirComoLlegar,
                ),
              if (tiene)
                _btnAccion(
                  icon: Icons.delete_outline_rounded,
                  label: 'Quitar',
                  color: _C.danger,
                  onTap: _limpiarUbicacion,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnAccion({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool cargando = false,
  }) {
    return Material(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cargando)
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: color,
                  ),
                )
              else
                Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccionInfo(AppProvider provider, _P p, bool isDesktop) {
    return _card(
      p,
      title: 'Información general',
      icon: Icons.info_rounded,
      color: _C.primary,
      child: Column(
        children: [
          _campo(p,
              label: 'Nombre de la tienda',
              icon: Icons.storefront_rounded,
              controller: _nombreCtrl,
              readOnly: !_editando),
          const SizedBox(height: 12),
          _campo(p,
              label: 'Descripción',
              icon: Icons.notes_rounded,
              controller: _descripcionCtrl,
              readOnly: !_editando,
              maxLines: 3),
        ],
      ),
      accion: _editando ? _botonesGuardar(p) : null,
    );
  }

  Widget _botonesGuardar(_P p) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                _editando = false;
                if (_tienda != null) {
                  _sincronizarControllers(_tienda!);
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: p.textMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 15, height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_guardando ? 'Guardando…' : 'Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _seccionContacto(_P p, bool isDesktop) {
    return _card(
      p,
      title: 'Contacto',
      icon: Icons.contact_mail_rounded,
      color: _C.cyan,
      child: Column(
        children: [
          _campo(p,
              label: 'Teléfono',
              icon: Icons.phone_rounded,
              controller: _telefonoCtrl,
              readOnly: !_editando,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _campo(p,
              label: 'WhatsApp',
              icon: Icons.chat_rounded,
              controller: _whatsappCtrl,
              readOnly: !_editando,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _campo(p,
              label: 'Email',
              icon: Icons.email_rounded,
              controller: _emailCtrl,
              readOnly: !_editando,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _campo(p,
              label: 'Dirección',
              icon: Icons.location_on_rounded,
              controller: _direccionCtrl,
              readOnly: !_editando),
          const SizedBox(height: 12),
          _campo(p,
              label: 'Horario de atención',
              icon: Icons.schedule_rounded,
              controller: _horarioCtrl,
              readOnly: !_editando),
        ],
      ),
    );
  }

  Widget _card(_P p,
      {required String title,
      required IconData icon,
      required Color color,
      required Widget child,
      Widget? accion}) {
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
          const SizedBox(height: 16),
          child,
          if (accion != null) ...[
            const SizedBox(height: 16),
            accion,
          ],
        ],
      ),
    );
  }

  Widget _campo(_P p,
      {required String label,
      required IconData icon,
      required TextEditingController controller,
      bool readOnly = false,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: readOnly ? p.textMid : p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12, color: p.textMuted, fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 17, color: p.textMuted),
        filled: true,
        fillColor: readOnly ? p.surface2 : p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _C.primary, width: 1.5),
        ),
      ),
    );
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

// ════════════════════════════════════════════════════════════
//  SELECTOR DE UBICACIÓN
// ════════════════════════════════════════════════════════════
class _SelectorUbicacionScreen extends StatefulWidget {
  final LatLng inicial;
  final String direccionSugerida;

  const _SelectorUbicacionScreen({
    required this.inicial,
    required this.direccionSugerida,
  });

  @override
  State<_SelectorUbicacionScreen> createState() =>
      _SelectorUbicacionScreenState();
}

class _SelectorUbicacionScreenState
    extends State<_SelectorUbicacionScreen> {
  final _mapController = MapController();
  late LatLng _centro;
  bool _cargandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _centro = widget.inicial;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        mostrarSnackBar(mensaje: 'Permiso denegado', esExito: false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _centro = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_centro, 16);
      setState(() {});
    } catch (_) {
      mostrarSnackBar(
          mensaje: 'No se pudo obtener tu ubicación', esExito: false);
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textHigh,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Marcar ubicación',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900,
            )),
        actions: [
          IconButton(
            tooltip: 'Mi ubicación',
            onPressed: _cargandoUbicacion ? null : _usarMiUbicacion,
            icon: _cargandoUbicacion
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centro,
              initialZoom: 16,
              onTap: (_, point) {
                setState(() => _centro = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nexorabusiness.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _centro,
                  width: 60, height: 60,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: _C.gradBrand),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withOpacity(.5),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Container(width: 3, height: 10, color: _C.primary),
                    ],
                  ),
                ),
              ]),
            ],
          ),
          Positioned(
            top: 12, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 16, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 18, color: _C.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Toca el mapa para mover el marcador',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.textHigh,
                        )),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.textMid,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: p.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: p.surface,
                      ),
                      child: const Text('Cancelar',
                          style:
                              TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, _centro),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirmar ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}