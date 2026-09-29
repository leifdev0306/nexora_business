// ============================================================
//  servicio_cancelado_screen.dart  ·  NEXORA BUSINESS
//  Pantalla de servicio cancelado premium
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../responsive_helper.dart';

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const danger    = Color(0xFFEF4444);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg        => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface   => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get textHigh  => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid   => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border    => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);

  List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(.45) : const Color(0xFF0A1A33).withOpacity(.10),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];
}

class ServicioCanceladoScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ServicioCanceladoScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -180,
                    right: -160,
                    child: _orb(420, _C.danger.withOpacity(p.dark ? .12 : .08)),
                  ),
                  Positioned(
                    bottom: -200,
                    left: -160,
                    child: _orb(440, _C.primary.withOpacity(p.dark ? .08 : .05)),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 24,
                    vertical: isDesktop ? 40 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: p.border),
                    boxShadow: p.shadowMd,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isDesktop ? 120 : 100,
                        height: isDesktop ? 120 : 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _C.danger.withOpacity(.22),
                              _C.danger.withOpacity(.06),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.danger.withOpacity(.32)),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: isDesktop ? 56 : 48,
                          color: _C.danger,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Servicio cancelado',
                        style: TextStyle(
                          fontSize: isDesktop ? 26 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: p.textHigh,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tu servicio ha sido desactivado por el administrador.\n'
                        'Para más información, contacta con soporte:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 14.5 : 13.5,
                          color: p.textMid,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Email button
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final url = 'mailto:Leifdev0306@gmail.com';
                            try {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              } else {
                                _copyEmail(context, p);
                              }
                            } catch (_) {
                              _copyEmail(context, p);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _C.primary.withOpacity(.12),
                                  _C.cyan.withOpacity(.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: _C.primary.withOpacity(.30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: _C.gradBrand),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _C.primary.withOpacity(.32),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.email_rounded,
                                      color: Colors.white, size: 17),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contactar soporte',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: p.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'leifdev0306@gmail.com',
                                        style: TextStyle(
                                          fontSize: isDesktop ? 14 : 13,
                                          fontWeight: FontWeight.w900,
                                          color: _C.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.open_in_new_rounded,
                                    size: 16, color: _C.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout_rounded, size: 19),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '© 2026 Leifdev Software Developer',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
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

  void _copyEmail(BuildContext context, _P p) {
    Clipboard.setData(const ClipboardData(text: 'Leifdev0306@gmail.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Correo copiado al portapapeles'),
        backgroundColor: _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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