// ============================================================
//  about_screen.dart  ·  NEXORA BUSINESS
//  Sobre nosotros con hero, features y contacto premium
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../responsive_helper.dart';
import '../main.dart';

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const pink      = Color(0xFFEC4899);
  static const indigo    = Color(0xFF6366F1);
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

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

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
              child: const Icon(Icons.info_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sobre nosotros',
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
                    _hero(p, isDesktop),
                    const SizedBox(height: 22),
                    _description(p, isDesktop),
                    const SizedBox(height: 22),
                    _infoGrid(p, isDesktop),
                    const SizedBox(height: 22),
                    _contactCard(p),
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

  Widget _hero(_P p, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
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
            width: isDesktop ? 84 : 68,
            height: isDesktop ? 84 : 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDesktop ? 22 : 18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isDesktop ? 22 : 18),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withOpacity(.20),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 22 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nexora Business',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BUSINESS SUITE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.80),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.28)),
                  ),
                  child: Text(
                    'v$APP_VERSION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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

  Widget _description(_P p, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.primary.withOpacity(.20),
                      _C.primary.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _C.primary.withOpacity(.24)),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 17, color: _C.primary),
              ),
              const SizedBox(width: 12),
              Text(
                '¿Qué es Nexora?',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nexora Business es una aplicación de gestión empresarial diseñada para ayudar a micro, pequeñas y medianas empresas a administrar inventario, ventas, gastos, clientes y finanzas de manera sencilla y eficiente, incluso sin conexión a internet.',
            style: TextStyle(
              fontSize: isDesktop ? 13.5 : 13,
              height: 1.65,
              color: p.textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(_P p, bool isDesktop) {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.phone_android_rounded,
        'label': 'Plataforma',
        'value': 'Flutter',
        'color': _C.primary,
      },
      {
        'icon': Icons.storage_rounded,
        'label': 'Base de datos',
        'value': 'Supabase + Hive',
        'color': _C.cyan,
      },
      {
        'icon': Icons.lock_rounded,
        'label': 'Autenticación',
        'value': 'Supabase Auth',
        'color': _C.purple,
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Reportes',
        'value': 'PDF · Excel · CSV',
        'color': _C.success,
      },
      {
        'icon': Icons.cloud_done_rounded,
        'label': 'Offline-first',
        'value': 'Sync automática',
        'color': _C.indigo,
      },
      {
        'icon': Icons.language_rounded,
        'label': 'Plataformas',
        'value': 'Android · Windows',
        'color': _C.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STACK TECNOLÓGICO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isDesktop ? 2.6 : 2.2,
          children: items.map((it) => _infoCard(it, p)).toList(),
        ),
      ],
    );
  }

  Widget _infoCard(Map<String, dynamic> it, _P p) {
    final color = it['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(.22),
                  color.withOpacity(.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(it['icon'] as IconData, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (it['label'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  it['value'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: p.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(_P p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withOpacity(p.dark ? .14 : .08),
            _C.cyan.withOpacity(p.dark ? .06 : .03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.primary.withOpacity(.24)),
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
                child: const Icon(Icons.contact_mail_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Contacto',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _contactRow(
            p,
            Icons.email_rounded,
            'Email',
            'leifdev0306@gmail.com',
            _C.primary,
          ),
          const SizedBox(height: 8),
          _contactRow(
            p,
            Icons.code_rounded,
            'GitHub',
            'github.com/leifdev0306',
            _C.cyan,
          ),
          const SizedBox(height: 8),
          _contactRow(
            p,
            Icons.business_rounded,
            'Desarrollado por',
            'Leifdev Software Developer',
            _C.purple,
          ),
        ],
      ),
    );
  }

  Widget _contactRow(_P p, IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(p.dark ? .14 : .08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withOpacity(.22)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: p.textHigh,
            ),
          ),
        ),
      ],
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