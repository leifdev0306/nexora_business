// ============================================================
//  vista_tienda_screen.dart · NEXORA BUSINESS
//  Vista pública de la tienda (preview y cliente final)
//  Claves namespaced por empresa
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import '../widgets/cached_product_image.dart';
import 'mi_tienda_screen.dart' show keyTiendaDeEmpresa;

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg =>
      dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface =>
      dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh =>
      dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid =>
      dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted =>
      dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border =>
      dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
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

class VistaTiendaScreen extends StatefulWidget {
  final TiendaPublica? tiendaOverride;
  final bool esPreviewPropio;

  const VistaTiendaScreen({
    Key? key,
    this.tiendaOverride,
    this.esPreviewPropio = false,
  }) : super(key: key);

  @override
  State<VistaTiendaScreen> createState() => _VistaTiendaScreenState();
}

class _VistaTiendaScreenState extends State<VistaTiendaScreen> {
  TiendaPublica? _tienda;
  bool _cargando = true;
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';
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
    if (widget.tiendaOverride != null) {
      setState(() {
        _tienda = widget.tiendaOverride;
        _cargando = false;
      });
      return;
    }
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empresaId = provider.empresaId ?? '';
    TiendaPublica? t;
    if (empresaId.isNotEmpty) {
      final raw = provider.catalogosBox
          .get(keyTiendaDeEmpresa(empresaId));
      if (raw is Map) {
        final temp =
            TiendaPublica.fromJson(Map<String, dynamic>.from(raw));
        if (temp.empresaId == empresaId) t = temp;
      }
    }
    if (!mounted) return;
    setState(() {
      _tienda = t;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    if (_cargando) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p, null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_tienda == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p, null),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _C.primary.withOpacity(.16),
                      _C.cyan.withOpacity(.04),
                    ]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      size: 40, color: _C.primary),
                ),
                const SizedBox(height: 16),
                Text('Tienda no configurada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Configura tu tienda primero para poder verla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                          context, '/mi-tienda')
                      .then((_) => _cargar()),
                  icon: const Icon(Icons.settings_rounded, size: 16),
                  label: const Text('Configurar tienda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final t = _tienda!;

    if (!t.activa && !widget.esPreviewPropio) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: _appBar(p, t),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: _C.warning.withOpacity(.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_circle_rounded,
                      size: 40, color: _C.warning),
                ),
                const SizedBox(height: 16),
                Text('Tienda temporalmente cerrada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: p.textHigh,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Esta tienda no está aceptando visitas por ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Productos publicados
    final ids = t.productosPublicados.toSet();
    final productos = provider.productos
        .where((prod) => ids.contains(prod.id))
        .where((prod) => prod.activo)
        .toList();

    // Categorías disponibles
    final categoriasIds = productos
        .map((prod) => prod.categoriaId)
        .whereType<String>()
        .toSet();
    final categorias = <Categoria>[];
    for (final cid in categoriasIds) {
      final c = provider.getCategoriaById(cid);
      if (c != null) categorias.add(c);
    }

    // Filtros
    var filtrados = productos.where((prod) {
      if (_busqueda.isNotEmpty) {
        final q = _busqueda.toLowerCase();
        if (!prod.nombre.toLowerCase().contains(q) &&
            !(prod.descripcion ?? '').toLowerCase().contains(q) &&
            !(prod.sku ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_categoriaSeleccionada != 'Todas') {
        if (prod.categoriaId != _categoriaSeleccionada) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, t),
      body: Stack(
        children: [
          _background(p),
          RefreshIndicator(
            onRefresh: _cargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.zero,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.esPreviewPropio) _previewBanner(p),
                      _hero(t, p),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),
                            if (t.descripcion.isNotEmpty) ...[
                              _descripcionBox(t, p),
                              const SizedBox(height: 18),
                            ],
                            _contactoGrid(t, p, isDesktop),
                            const SizedBox(height: 22),
                            _searchBar(p),
                            const SizedBox(height: 12),
                            if (categorias.isNotEmpty) ...[
                              _categoriasRow(categorias, p),
                              const SizedBox(height: 16),
                            ],
                            _productosHeader(filtrados.length, p),
                            const SizedBox(height: 12),
                            if (filtrados.isEmpty)
                              _emptyProductos(p)
                            else
                              _grid(productos: filtrados, p: p),
                            const SizedBox(height: 30),
                            _footer(t, p),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  PreferredSizeWidget _appBar(_P p, TiendaPublica? t) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t?.nombre ?? 'Tienda',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    )),
                Text(
                  t != null && t.activa ? 'Abierta' : 'Cerrada',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: t != null && t.activa
                        ? _C.success
                        : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBanner(_P p) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: _C.warning.withOpacity(.14),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded,
              size: 16, color: _C.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estás viendo una vista previa. Así verán tu tienda los clientes.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.textMid,
              ),
            ),
          ),
        ],
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

  Widget _hero(TiendaPublica t, _P p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(.32)),
            ),
            child: Text(
              t.nombre.isNotEmpty
                  ? t.nombre.substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
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
                      t.activa ? 'ABIERTA' : 'CERRADA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.92),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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

  Widget _descripcionBox(TiendaPublica t, _P p) {
    return Container(
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
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _C.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.info_outline_rounded,
                size: 16, color: _C.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.descripcion,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textMid,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }

  Widget _contactoGrid(TiendaPublica t, _P p, bool isDesktop) {
    final items = <Map<String, dynamic>>[];
    if (t.telefono != null && t.telefono!.isNotEmpty) {
      items.add({
        'icon': Icons.phone_rounded,
        'label': 'Teléfono',
        'value': t.telefono!,
        'color': _C.success,
      });
    }
    if (t.whatsapp != null && t.whatsapp!.isNotEmpty) {
      items.add({
        'icon': Icons.chat_rounded,
        'label': 'WhatsApp',
        'value': t.whatsapp!,
        'color': _C.info,
      });
    }
    if (t.email != null && t.email!.isNotEmpty) {
      items.add({
        'icon': Icons.email_rounded,
        'label': 'Email',
        'value': t.email!,
        'color': _C.purple,
      });
    }
    if (t.direccion != null && t.direccion!.isNotEmpty) {
      items.add({
        'icon': Icons.location_on_rounded,
        'label': 'Dirección',
        'value': t.direccion!,
        'color': _C.pink,
      });
    }
    if (t.horario != null && t.horario!.isNotEmpty) {
      items.add({
        'icon': Icons.schedule_rounded,
        'label': 'Horario',
        'value': t.horario!,
        'color': _C.warning,
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final color = item['color'] as Color;
        final width = isDesktop
            ? 220.0
            : (MediaQuery.of(context).size.width - 48) / 2;
        return Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(.28)),
                ),
                child: Icon(item['icon'] as IconData,
                    color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((item['label'] as String).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6,
                          color: p.textMuted,
                        )),
                    const SizedBox(height: 2),
                    Text(item['value'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

  Widget _categoriasRow(List<Categoria> categorias, _P p) {
    final todas = ['Todas', ...categorias.map((c) => c.id)];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: todas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final id = todas[i];
          final label = id == 'Todas'
              ? 'Todas'
              : categorias.firstWhere((c) => c.id == id).nombre;
          final selected = _categoriaSeleccionada == id;
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => setState(
                  () => _categoriaSeleccionada = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: _C.gradBrand)
                      : null,
                  color: selected ? null : p.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color:
                        selected ? Colors.transparent : p.border,
                  ),
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color:
                          selected ? Colors.white : p.textMid,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productosHeader(int total, _P p) {
    return Row(
      children: [
        Text('Productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: p.textHigh,
            )),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _C.primary.withOpacity(p.dark ? .18 : .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$total',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _C.primary,
              )),
        ),
      ],
    );
  }

  Widget _grid({required List<Producto> productos, required _P p}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
                if (sinStock)
                  Positioned(
                    top: 8, left: 8,
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
                      child: const Text('AGOTADO',
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
            flex: 42,
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
                  if (prod.descripcion != null &&
                      prod.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(prod.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: p.textMuted,
                        )),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            '\$${prod.precioVenta.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: _C.success,
                            )),
                      ),
                      if (prod.stock > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.success.withOpacity(.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_fmt(prod.stock)} ${prod.unidadMedida}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _C.success,
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

  Widget _emptyProductos(_P p) {
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
            width: 70, height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.primary.withOpacity(.16),
                _C.cyan.withOpacity(.06),
              ]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_rounded,
                size: 34, color: _C.primary),
          ),
          const SizedBox(height: 14),
          Text('Sin productos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              )),
          const SizedBox(height: 4),
          Text('Esta tienda aún no tiene productos publicados.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12.5, color: p.textMuted)),
        ],
      ),
    );
  }

  Widget _footer(TiendaPublica t, _P p) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text('Powered by Nexora',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: p.textMuted,
              )),
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