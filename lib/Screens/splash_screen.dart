// ============================================================
//  splash_screen.dart  ·  NEXORA BUSINESS
//  Splash premium con logo, orbes animados y ondas
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tu_mipyme/responsive_helper.dart';
import '../main.dart';

// ============================================================
//  Acentos compartidos
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg     => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get textHigh => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid  => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
}

// ============================================================
//  SPLASH
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _orbCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutBack),
    );

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _fadeCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.usuarioId != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // Orbes animados
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: -160 + 30 * math.sin(_orbCtrl.value * math.pi * 2),
                  left: -120,
                  child: _orb(
                    480,
                    _C.primary.withOpacity(p.dark ? .20 : .16),
                  ),
                ),
                Positioned(
                  bottom: -200,
                  right: -160 + 30 * math.cos(_orbCtrl.value * math.pi * 2),
                  child: _orb(
                    520,
                    _C.cyan.withOpacity(p.dark ? .16 : .12),
                  ),
                ),
              ],
            ),
          ),
          // Ondas decorativas
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WavesPainter(
                  color: (p.dark ? Colors.white : _C.primary)
                      .withOpacity(p.dark ? .06 : .04),
                ),
              ),
            ),
          ),
          // Contenido
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: isDesktop ? 140 : 116,
                      height: isDesktop ? 140 : 116,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isDesktop ? 34 : 28),
                        boxShadow: [
                          BoxShadow(
                            color: _C.primary.withOpacity(.42),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isDesktop ? 34 : 28),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: _C.gradBrand,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.white,
                              size: isDesktop ? 60 : 52,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 28 : 22),
                    // Título
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: _C.gradBrand,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Nexora Business',
                        style: TextStyle(
                          fontSize: isDesktop ? 42 : 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BUSINESS SUITE',
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: p.textMuted,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 40 : 32),
                    // Loading
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(
                          _C.primary.withOpacity(.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando…',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 60 : 40),
                    // Versión
                    Text(
                      'v$APP_VERSION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.textMuted,
                        letterSpacing: 1,
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

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  final Color color;
  _WavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int wave = 0; wave < 3; wave++) {
      final path = Path();
      final startY = size.height * (0.30 + wave * 0.25);
      final amplitude = 20.0 + wave * 10;
      final frequency = 2.0 + wave * 0.3;

      path.moveTo(0, startY);
      for (double x = 0; x <= size.width; x += 6) {
        final y = startY +
            math.sin((x / size.width) * frequency * math.pi * 2) * amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.color != color;
}