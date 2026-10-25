// ============================================================
//  login_screen.dart  ·  NEXORA BUSINESS
//  · Logo real (assets/logo.png) en lugar del icono de cohete
//  · Paleta Azul Eléctrico #1A5CFF + Cyan #06B6D4
//  · ✅ Errores traducidos a mensajes amigables
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, Supabase;
import 'package:nexora_business/responsive_helper.dart';
import '../main.dart';

// ============================================================
//  Acentos compartidos
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const primaryDk = Color(0xFF4A8BFF);
  static const cyan      = Color(0xFF06B6D4);
  static const cyanDk    = Color(0xFF22D3EE);
  static const success   = Color(0xFF10B981);
  static const danger    = Color(0xFFEF4444);
  static const warning   = Color(0xFFF59E0B);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

// ============================================================
//  Paleta theme-aware
// ============================================================
class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg            => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface       => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2      => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh      => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid       => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted     => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border        => dark ? const Color(0x294A8BFF) : const Color(0x1F1A5CFF);
  Color get borderStrong  => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);
}

// ============================================================
//  SCREEN
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreEmpresaCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _aceptaTerminos = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreEmpresaCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  //  ✅ TRADUCCIÓN DE ERRORES
  //  Nunca exponemos detalles técnicos al usuario. Solo se
  //  registran en el log de desarrollo para diagnóstico.
  // ══════════════════════════════════════════════════════════
  String _humanError(Object? e) {
    if (e == null) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }

    // Log solo para desarrolladores
    debugPrint('🔴 [Login] Error: $e');

    // ── 1) AuthException (Supabase Auth)
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      final code = (e.statusCode ?? '').toString().toLowerCase();
      final combined = '$msg $code';

      if (combined.contains('email not confirmed') ||
          combined.contains('email_not_confirmed')) {
        return 'Debes confirmar tu correo antes de entrar. Revisa tu bandeja.';
      }
      if (combined.contains('invalid login') ||
          combined.contains('invalid_grant') ||
          combined.contains('invalid_credentials')) {
        return 'Correo o contraseña incorrectos. Intenta de nuevo.';
      }
      if (combined.contains('user already') ||
          combined.contains('already registered') ||
          combined.contains('email_exists')) {
        return 'Este correo ya está registrado. Inicia sesión.';
      }
      if (combined.contains('weak_password') ||
          combined.contains('password should be') ||
          combined.contains('password is too short')) {
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      }
      if (combined.contains('rate_limit') ||
          combined.contains('too many') ||
          combined.contains('over_email_send')) {
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      }
      if (combined.contains('user_not_found') ||
          combined.contains('no user found')) {
        return 'No existe una cuenta con este correo.';
      }
      if (combined.contains('session_expired') ||
          combined.contains('jwt') ||
          combined.contains('token')) {
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      }
      if (combined.contains('network') ||
          combined.contains('timeout') ||
          combined.contains('connection')) {
        return 'Sin conexión al servidor. Revisa tu internet.';
      }
      return 'No pudimos validar tus datos. Revisa e intenta de nuevo.';
    }

    // ── 2) PostgrestException (Base de datos)
    if (e is PostgrestException) {
      final code = (e.code ?? '').toLowerCase();
      final msg = e.message.toLowerCase();
      final combined = '$code $msg';

      if (combined.contains('permission denied') ||
          combined.contains('row-level security') ||
          combined.contains('rls') ||
          code == '42501') {
        return 'No tienes permisos para esta acción. Contacta al administrador.';
      }
      if (combined.contains('duplicate key') ||
          combined.contains('already exists') ||
          code == '23505') {
        return 'Este registro ya existe.';
      }
      if (combined.contains('foreign key') || code == '23503') {
        return 'No se puede completar: hay datos relacionados.';
      }
      if (combined.contains('not-null') || code == '23502') {
        return 'Faltan datos obligatorios.';
      }
      if (combined.contains('invalid input syntax') ||
          code == '22p02') {
        return 'Algunos datos tienen un formato inválido.';
      }
      return 'No pudimos completar la operación. Intenta de nuevo.';
    }

    // ── 3) Errores de red / IO
    final raw = e.toString();
    final low = raw.toLowerCase();

    if (low.contains('socketexception') ||
        low.contains('failed host lookup') ||
        low.contains('network is unreachable') ||
        low.contains('no address associated')) {
      return 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
    }
    if (low.contains('timeout') || low.contains('timed out')) {
      return 'El servidor tardó demasiado. Intenta de nuevo en un momento.';
    }
    if (low.contains('connection refused') ||
        low.contains('connection reset') ||
        low.contains('connection closed') ||
        low.contains('clientexception') ||
        low.contains('connection terminated')) {
      return 'La conexión se interrumpió. Intenta de nuevo.';
    }

    // ── 4) Reglas de negocio de la app
    if (low.contains('ya pertenece a una empresa') ||
        low.contains('already belong')) {
      return 'Este usuario ya está asociado a una empresa. Inicia sesión.';
    }
    if (low.contains('no hay empresa') ||
        low.contains('sin empresa') ||
        low.contains('empresa no asociada')) {
      return 'No hay una empresa asociada a tu cuenta.';
    }
    if (low.contains('usuario no autenticado') ||
        low.contains('no autenticado') ||
        low.contains('not authenticated')) {
      return 'Inicia sesión para continuar.';
    }
    if (low.contains('servicio cancelado') ||
        low.contains('cuenta cancelada') ||
        low.contains('empresa inactiva')) {
      return 'Tu cuenta está suspendida. Contacta a soporte.';
    }
    if (low.contains('permission denied') ||
        low.contains('no autorizado')) {
      return 'No tienes permisos para esta acción.';
    }
    if (low.contains('duplicate key') || low.contains('already exists')) {
      return 'Este registro ya existe.';
    }

    // ── 5) Fallback: si el mensaje es corto y legible, se muestra
    final cleaned = raw.replaceFirst('Exception: ', '').trim();
    if (cleaned.isNotEmpty &&
        cleaned.length < 160 &&
        !_looksTechnical(cleaned)) {
      return cleaned;
    }

    return 'Ocurrió un error inesperado. Intenta de nuevo en un momento.';
  }

  bool _looksTechnical(String s) {
    final low = s.toLowerCase();
    return low.contains('exception') ||
        low.contains('stack trace') ||
        low.contains('#0 ') ||
        low.contains('postgrest') ||
        low.contains('sqlstate') ||
        low.contains('socket') ||
        low.contains('clientexception') ||
        RegExp(r'^[a-z_]+_[a-z_]+\(.*\)$').hasMatch(low);
  }

  // ══════════════════════════════════════════════════════════
  //  ACCIONES
  // ══════════════════════════════════════════════════════════
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      mostrarSnackBar(
        mensaje: _humanError(e),
        esExito: false,
        duracion: const Duration(seconds: 8),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_nombreEmpresaCtrl.text.trim().isEmpty) {
      mostrarSnackBar(
          mensaje: 'Ingresa el nombre de tu empresa', esExito: false);
      return;
    }
    if (!_aceptaTerminos) {
      mostrarSnackBar(
          mensaje: 'Debes aceptar los términos y condiciones',
          esExito: false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.register(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nombreEmpresaCtrl.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      mostrarSnackBar(
        mensaje: _humanError(e),
        esExito: false,
        duracion: const Duration(seconds: 8),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _nombreEmpresaCtrl.clear();
      _aceptaTerminos = false;
    });
  }

  Future<void> _recuperarPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      mostrarSnackBar(
          mensaje: 'Escribe tu correo para recuperar la contraseña',
          esExito: false);
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      mostrarSnackBar(
          mensaje: 'Te enviamos un correo para restablecer tu contraseña',
          esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: _humanError(e),
          esExito: false,
          duracion: const Duration(seconds: 8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    final p = _P(isDark);

    return Scaffold(
      backgroundColor: p.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isDesktop
            ? _buildDesktop(context, p)
            : _buildMobile(context, p),
      ),
    );
  }

  // ============================================================
  //  LOGO
  // ============================================================
  Widget _logo({double size = 84, double radius = 24, bool withShadow = true}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
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
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  MOBILE
  // ============================================================
  Widget _buildMobile(BuildContext context, _P p) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
        child: Column(
          children: [
            _brandHeader(p),
            const SizedBox(height: 26),
            _formCard(p, compact: true),
            const SizedBox(height: 18),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DESKTOP
  // ============================================================
  Widget _buildDesktop(BuildContext context, _P p) {
    return Row(
      children: [
        Expanded(flex: 6, child: _desktopHero()),
        Expanded(
          flex: 5,
          child: Container(
            color: p.bg,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _brandHeaderCompact(p),
                      const SizedBox(height: 28),
                      _formCard(p, compact: false),
                      const SizedBox(height: 22),
                      _footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primary, Color(0xFF2966FF), _C.cyan],
          stops: [0, 0.55, 1],
        ),
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -120,
              child: _orb(360, Colors.white.withOpacity(.08)),
            ),
            Positioned(
              bottom: -160,
              left: -100,
              child: _orb(400, Colors.white.withOpacity(.06)),
            ),
            Positioned(
              top: 180,
              left: -80,
              child: _orb(220, Colors.white.withOpacity(.10)),
            ),
            CustomPaint(
              size: Size.infinite,
              painter: _WavesPainter(
                color: Colors.white.withOpacity(.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 60, 56, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _logo(size: 52, radius: 15, withShadow: false),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nexora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                            ),
                          ),
                          Text(
                            'BUSINESS SUITE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Gestiona tu negocio,\ndonde quiera que estés.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ventas, inventario, sucursales, reportes y tienda en línea.\n'
                    'Todo en una plataforma diseñada para crecer contigo.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 44),
                  const _HeroFeature(
                    icon: Icons.point_of_sale_rounded,
                    title: 'Ventas en tiempo real',
                    subtitle: 'Modo cierre diario o venta directa',
                  ),
                  const _HeroFeature(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventario multi-sucursal',
                    subtitle: 'Stock FIFO con trazabilidad por lote',
                  ),
                  const _HeroFeature(
                    icon: Icons.insights_rounded,
                    title: 'Analítica inteligente',
                    subtitle: 'Decisiones basadas en datos reales',
                  ),
                  const _HeroFeature(
                    icon: Icons.storefront_rounded,
                    title: 'Tienda en línea incluida',
                    subtitle: 'Muestra tu catálogo al mundo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // ============================================================
  //  BRAND HEADERS
  // ============================================================
  Widget _brandHeader(_P p) {
    return Column(
      children: [
        _logo(size: 84, radius: 24),
        const SizedBox(height: 18),
        Text(
          'Nexora Business',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
            color: p.textHigh,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isRegisterMode
              ? 'Crea tu empresa en menos de un minuto'
              : 'Bienvenido de vuelta',
          style: TextStyle(
            fontSize: 13.5,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _brandHeaderCompact(_P p) {
    return Column(
      children: [
        _logo(size: 62, radius: 18),
        const SizedBox(height: 16),
        Text(
          'Nexora Business',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
            color: p.textHigh,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isRegisterMode ? 'Registra tu empresa' : 'Inicia sesión en tu cuenta',
          style: TextStyle(
            fontSize: 12.5,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  FORM CARD
  // ============================================================
  Widget _formCard(_P p, {required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 28,
        vertical: compact ? 24 : 28,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.dark
                ? Colors.black.withOpacity(.35)
                : _C.primary.withOpacity(.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isRegisterMode
                  ? 'Registra tu empresa y empieza gratis por 3 días.'
                  : 'Ingresa tus credenciales para continuar.',
              style: TextStyle(
                fontSize: 12.5,
                color: p.textMuted,
              ),
            ),
            const SizedBox(height: 22),

            _field(
              controller: _emailCtrl,
              label: 'Correo electrónico',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              p: p,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Ingresa tu correo';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value)) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            _field(
              controller: _passCtrl,
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              p: p,
              obscure: _obscurePass,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: p.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Ingresa tu contraseña';
                if (v!.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),

            if (!_isRegisterMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recuperarPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: _C.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            if (_isRegisterMode) ...[
              const SizedBox(height: 14),
              _field(
                controller: _nombreEmpresaCtrl,
                label: 'Nombre de la empresa',
                icon: Icons.storefront_rounded,
                p: p,
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Ingresa el nombre de tu empresa'
                    : null,
              ),
              const SizedBox(height: 14),
              _termsCheckbox(p),
            ],

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isRegisterMode ? _register : _login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _C.primary.withOpacity(.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isRegisterMode ? 'Crear mi cuenta' : 'Entrar',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isRegisterMode
                        ? '¿Ya tienes cuenta?'
                        : '¿Aún no tienes cuenta?',
                    style: TextStyle(
                      fontSize: 13,
                      color: p.textMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    style: TextButton.styleFrom(
                      foregroundColor: _C.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isRegisterMode ? 'Inicia sesión' : 'Regístrate gratis',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required _P p,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(
        color: p.textHigh,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: p.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: p.textMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.danger, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _C.danger,
        ),
      ),
      validator: validator,
    );
  }

  Widget _termsCheckbox(_P p) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _aceptaTerminos = !_aceptaTerminos),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _aceptaTerminos ? _C.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _aceptaTerminos ? _C.primary : p.borderStrong,
                    width: 1.6,
                  ),
                ),
                child: _aceptaTerminos
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: p.textMuted,
                    ),
                    children: const [
                      TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'términos y condiciones',
                        style: TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' y la '),
                      TextSpan(
                        text: 'política de privacidad',
                        style: TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return const Text(
      '© 2026 Leifdev · Nexora Business',
      style: TextStyle(
        fontSize: 11,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

// ============================================================
//  HERO FEATURE ROW
// ============================================================
class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  ONDAS DECORATIVAS
// ============================================================
class _WavesPainter extends CustomPainter {
  final Color color;
  _WavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int wave = 0; wave < 3; wave++) {
      final path = Path();
      final startY = size.height * (0.35 + wave * 0.22);
      final amplitude = 18.0 + wave * 8;
      final frequency = 2.2 + wave * 0.3;

      path.moveTo(0, startY);
      for (double x = 0; x <= size.width; x += 6) {
        final y = startY +
            (amplitude *
                (x / size.width * frequency * 3.14159 * 2).remainder(6.28) -
                amplitude / 2);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.color != color;
}