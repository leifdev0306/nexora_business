// ============================================================
//  servicio_detalle_screen.dart  ·  NEXORA BUSINESS
//  Vista completa de un servicio público
//  SIN DATOS SIMULADOS
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../responsive_helper.dart';
import '../models/tienda_publica.dart';
import 'mapa_tiendas_screen.dart';
import 'mi_tienda_screen.dart' show kNetworkSvcsKey, kNetworkRev;

class ServicioDetalleScreen extends StatefulWidget {
  final String servicioId;
  const ServicioDetalleScreen({Key? key, required this.servicioId})
      : super(key: key);

  @override
  State<ServicioDetalleScreen> createState() => _ServicioDetalleScreenState();
}

class _ServicioDetalleScreenState extends State<ServicioDetalleScreen> {
  ServicioPublico? _s;
  List<ResenaPublica> _resenas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final box = provider.catalogosBox;

    ServicioPublico? s;

    // 1) Buscar en la red pública
    final netRaw = (box.get(kNetworkSvcsKey) as List?) ?? [];
    for (final e in netRaw) {
      final x = ServicioPublico.fromJson(Map<String, dynamic>.from(e));
      if (x.id == widget.servicioId) {
        s = x;
        break;
      }
    }

    // 2) Buscar en mis servicios (por si es propio)
    if (s == null) {
      final empresaId = provider.empresaId ?? '';
      if (empresaId.isNotEmpty) {
        final myRaw = (box.get('my_services_$empresaId') as List?) ?? [];
        for (final e in myRaw) {
          final x = ServicioPublico.fromJson(Map<String, dynamic>.from(e));
          if (x.id == widget.servicioId) {
            s = x;
            break;
          }
        }
      }
    }

    // 3) Reseñas del servicio
    final revRaw = (box.get(kNetworkRev) as List?) ?? [];
    final revs = revRaw
        .map((e) => ResenaPublica.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.targetId == widget.servicioId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (!mounted) return;
    setState(() {
      _s = s;
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
    if (_s == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handyman_rounded, size: 60, color: p.textMuted),
              const SizedBox(height: 14),
              Text(
                'Servicio no encontrado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = _s!;
    final cat = CategoriasPublicas.nombreServicio(s.categoriaId);

    return Scaffold(
      backgroundColor: p.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: p.surface,
            foregroundColor: p.textHigh,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.info.withOpacity(.85),
                      _C.purple.withOpacity(.75),
                    ],
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(.32)),
                          ),
                          child: Icon(_icono(s.categoriaId),
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _chipHero(Icons.business_rounded, s.nombreEmpresa),
                            _chipHero(Icons.category_rounded, cat),
                            if (s.destacado)
                              _chipHero(Icons.star_rounded, 'Destacado'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 14,
                16,
                isDesktop ? 24 : 14,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _precioCard(s, p),
                  const SizedBox(height: 14),

                  _card(
                    p,
                    'Descripción',
                    Icons.notes_rounded,
                    _C.primary,
                    () => Text(
                      s.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: p.textMid,
                      ),
                    ),
                  ),

                  if (s.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _card(
                      p,
                      'Características',
                      Icons.local_offer_rounded,
                      _C.warning,
                      () {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: s.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _C.primary.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              _C.primary.withOpacity(.24)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: _C.primary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          t,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: _C.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],

                  if (s.horario != null && s.horario!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _card(
                      p,
                      'Horario',
                      Icons.schedule_rounded,
                      _C.success,
                      () => Text(
                        s.horario!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.textHigh,
                        ),
                      ),
                    ),
                  ],

                  if (s.tieneUbicacion) ...[
                    const SizedBox(height: 14),
                    _card(
                      p,
                      'Ubicación',
                      Icons.location_on_rounded,
                      _C.info,
                      () {
                        return Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final punto = TiendaPublica(
                                  empresaId: s.empresaId,
                                  nombre: s.nombreEmpresa.isNotEmpty
                                      ? s.nombreEmpresa
                                      : s.nombre,
                                  slug: TiendaPublica.generarSlug(
                                      s.nombreEmpresa),
                                  descripcion: s.descripcion,
                                  telefono: s.telefono,
                                  whatsapp: s.whatsapp,
                                  horario: s.horario,
                                  latitud: s.latitud,
                                  longitud: s.longitud,
                                  activa: true,
                                  updatedAt: DateTime.now(),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MapaTiendasScreen(
                                      tiendaEnfocada: punto,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const Text('Ver en mapa'),
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size(double.infinity, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _abrirComoLlegar(s),
                              icon: const Icon(Icons.directions_rounded,
                                  size: 16),
                              label: const Text('Cómo llegar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.success,
                                foregroundColor: Colors.white,
                                minimumSize:
                                    const Size(double.infinity, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 14),
                  _card(
                    p,
                    'Contactar',
                    Icons.contact_mail_rounded,
                    _C.cyan,
                    () {
                      final tieneTel =
                          s.telefono != null && s.telefono!.isNotEmpty;
                      final tieneWa =
                          s.whatsapp != null && s.whatsapp!.isNotEmpty;
                      if (!tieneTel && !tieneWa) {
                        return Text(
                          'Sin datos de contacto disponibles.',
                          style: TextStyle(fontSize: 12.5, color: p.textMuted),
                        );
                      }
                      return Row(
                        children: [
                          if (tieneTel)
                            Expanded(
                              child: _contactoBtn(
                                icon: Icons.call_rounded,
                                label: 'Llamar',
                                color: _C.success,
                                onTap: () => _llamar(s.telefono!),
                              ),
                            ),
                          if (tieneTel && tieneWa) const SizedBox(width: 8),
                          if (tieneWa)
                            Expanded(
                              child: _contactoBtn(
                                icon: Icons.chat_rounded,
                                label: 'WhatsApp',
                                color: const Color(0xFF25D366),
                                onTap: () => _whatsapp(s.whatsapp!),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  if (_resenas.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _card(
                      p,
                      'Reseñas (${_resenas.length})',
                      Icons.reviews_rounded,
                      _C.gold,
                      () {
                        return Column(
                          children: _resenas
                              .take(5)
                              .map((r) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _resenaMini(r, p),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _precioCard(ServicioPublico s, _P p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _C.gradBrand),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.attach_money_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.precioTexto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (s.vistas > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '${s.vistas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    _P p,
    String title,
    IconData icon,
    Color color,
    Widget Function() buildChild,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildChild(),
        ],
      ),
    );
  }

  Widget _contactoBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resenaMini(ResenaPublica r, _P p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: _C.primary.withOpacity(.14),
          child: Text(
            r.autorNombre.isNotEmpty
                ? r.autorNombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 11,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.autorNombre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < r.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 12,
                        color: _C.warning,
                      ),
                    ),
                  ),
                ],
              ),
              if (r.comentario != null && r.comentario!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  r.comentario!,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: p.textMid,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
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

  Future<void> _abrirComoLlegar(ServicioPublico s) async {
    if (!s.tieneUbicacion) return;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${s.latitud},${s.longitud}&travelmode=driving';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
      await launchUrl(
        Uri.parse('https://wa.me/$clean'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}

// ============================================================
//  Paleta
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const danger    = Color(0xFFEF4444);
  static const warning   = Color(0xFFF59E0B);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const gold      = Color(0xFFCA8A04);
  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface =>
      dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
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