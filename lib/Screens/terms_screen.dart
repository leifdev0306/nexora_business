// ============================================================
//  terms_screen.dart  ·  NEXORA BUSINESS
//  Términos con lectura premium y sección destacada
// ============================================================

import 'package:flutter/material.dart';
import '../responsive_helper.dart';
import '../main.dart';

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const purple    = Color(0xFF8B5CF6);
  static const indigo    = Color(0xFF6366F1);
  static const pink      = Color(0xFFEC4899);
  static const info      = Color(0xFF3B82F6);
  static const success   = Color(0xFF10B981);
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

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    final secciones = <Map<String, dynamic>>[
      {
        'num': '1',
        'icon': Icons.check_circle_rounded,
        'color': _C.success,
        'title': 'Aceptación de los Términos',
        'body':
            'Al utilizar la aplicación "Nexora Business" (en adelante, "la App"), usted acepta cumplir con estos Términos y Condiciones. Si no está de acuerdo, no utilice la App.',
      },
      {
        'num': '2',
        'icon': Icons.description_rounded,
        'color': _C.primary,
        'title': 'Descripción del Servicio',
        'body':
            'La App es una herramienta de gestión para micro, pequeñas y medianas empresas (MiPymes) y trabajadores por cuenta propia (TCP). Permite administrar inventario, ventas, gastos, clientes, proveedores, generar reportes contables y realizar cálculos fiscales orientativos. Además, incluye funcionalidades de alianzas comerciales, referidos, bonos y gestión de transferencias.',
      },
      {
        'num': '3',
        'icon': Icons.payments_rounded,
        'color': _C.cyan,
        'title': 'Período de prueba y planes',
        'body':
            'Al registrarse, el usuario disfruta de un período de prueba de 3 días con todas las funcionalidades Premium desbloqueadas. Al finalizar, deberá elegir uno de estos planes:\n\n'
            '•  Plan Normal: 1,000 CUP/mes — funciones básicas.\n'
            '•  Plan Premium: 2,000 CUP/mes — hasta 5 vendedores, panel avanzado, exportación, gestión de proveedores, módulo fiscal completo.\n'
            '•  Sucursal adicional: 1,000 CUP/mes.\n'
            '•  Bonos por referidos: 2 referidos que paguen otorgan un 50% de descuento en tu próximo pago.',
      },
      {
        'num': '4',
        'icon': Icons.swap_horiz_rounded,
        'color': _C.purple,
        'title': 'Cambios de plan y límite de vendedores',
        'body':
            'Si el usuario cambia de Premium a Normal y tiene más de 1 vendedor activo, deberá eliminar los excedentes. La App mostrará un aviso para facilitar el proceso. El no hacerlo puede limitar el funcionamiento correcto.',
      },
      {
        'num': '5',
        'icon': Icons.security_rounded,
        'color': _C.indigo,
        'title': 'Responsabilidades del Usuario',
        'body':
            'El usuario es responsable de mantener la confidencialidad de sus credenciales y de todas las actividades que ocurran bajo su cuenta. Debe notificar inmediatamente cualquier uso no autorizado.',
      },
      {
        'num': '6',
        'icon': Icons.copyright_rounded,
        'color': _C.pink,
        'title': 'Propiedad Intelectual',
        'body':
            'La App y todo su contenido —incluyendo código, diseño, logotipos y textos— son propiedad de Leifdev Software Developer. No se permite la reproducción o distribución sin autorización.',
      },
      {
        'num': '7',
        'icon': Icons.privacy_tip_rounded,
        'color': _C.info,
        'title': 'Privacidad de Datos',
        'body':
            'Los datos del usuario y de su empresa se almacenan de forma segura en los servidores de Supabase. La App los utiliza únicamente para proporcionar el servicio de gestión.',
      },
      {
        'num': '8',
        'icon': Icons.request_quote_rounded,
        'color': _C.warning,
        'title': 'Módulo Fiscal — Aviso legal',
        'body':
            'La App incluye un módulo fiscal que ofrece simulaciones de cálculo de impuestos (10% sobre ventas, 15% sobre utilidades), Vector Fiscal y Declaración Jurada anual estimada. Estos cálculos son orientativos y no constituyen asesoría fiscal oficial. El usuario debe verificar la información con un contador o con la ONAT. Leifdev Software Developer no se responsabiliza por errores, omisiones o decisiones tomadas basadas en estas simulaciones.',
        'highlight': true,
      },
      {
        'num': '9',
        'icon': Icons.warning_amber_rounded,
        'color': _C.danger,
        'title': 'Limitación de Responsabilidad',
        'body':
            'La App se proporciona "tal cual". Leifdev Software Developer no garantiza que esté libre de errores o que el servicio sea ininterrumpido. No se responsabiliza por daños directos o indirectos derivados del uso de la App, incluyendo errores en cálculos fiscales o pérdida de datos.',
      },
      {
        'num': '10',
        'icon': Icons.update_rounded,
        'color': _C.primary,
        'title': 'Modificaciones',
        'body':
            'Leifdev Software Developer se reserva el derecho de modificar estos términos en cualquier momento. La versión actualizada se publicará en la App y entrará en vigor inmediatamente.',
      },
      {
        'num': '11',
        'icon': Icons.contact_mail_rounded,
        'color': _C.cyan,
        'title': 'Contacto',
        'body':
            'Para cualquier consulta sobre estos términos, puede contactarnos a través del correo electrónico: Leifdev0306@gmail.com',
      },
    ];

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textHigh,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.gavel_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            const Text(
              'Términos y Condiciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -160,
                    right: -140,
                    child: _orb(400, _C.primary.withOpacity(p.dark ? .12 : .07)),
                  ),
                  Positioned(
                    bottom: -200,
                    left: -160,
                    child: _orb(420, _C.cyan.withOpacity(p.dark ? .10 : .06)),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 16, 20, isDesktop ? 40 : 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(p, isDesktop),
                    const SizedBox(height: 24),
                    ...secciones.map((s) => _section(s, p, isDesktop)),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        '© 2026 Leifdev Software Developer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(_P p, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _C.gradBrand,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.42),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
            child: const Icon(Icons.gavel_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos y Condiciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última actualización: 2 de agosto de 2026',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(Map<String, dynamic> s, _P p, bool isDesktop) {
    final color = s['color'] as Color;
    final highlight = s['highlight'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        decoration: BoxDecoration(
          color: highlight
              ? color.withOpacity(p.dark ? .12 : .06)
              : p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight
                ? color.withOpacity(.32)
                : p.border,
            width: highlight ? 1.5 : 1,
          ),
          boxShadow: p.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(.22),
                        color.withOpacity(.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(.28)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(s['icon'] as IconData, color: color, size: 19),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Art. ${s['num']}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s['title'] as String,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: p.textHigh,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                s['body'] as String,
                style: TextStyle(
                  fontSize: isDesktop ? 13.5 : 13,
                  height: 1.6,
                  color: p.textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}