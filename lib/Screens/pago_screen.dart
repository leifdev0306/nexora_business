// ============================================================
//  pago_screen.dart · NEXORA BUSINESS
//  Pago premium con ciclo rodante de 30 días
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const gold = Color(0xFFCA8A04);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradPremium = [
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarn = [Color(0xFFF59E0B), Color(0xFFF97316)];
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
  Color get borderStrong =>
      dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);
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

class PagoScreen extends StatefulWidget {
  const PagoScreen({Key? key}) : super(key: key);

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noTransaccionCtrl = TextEditingController();
  String _planSeleccionado = 'normal';
  int _diasSeleccionados = 30;
  bool _enviando = false;

  // Datos de pago (con fallback si no se cargan del servidor)
  String _numeroTarjeta = '9227 9598 7522 7600';
  String _telefonoConfirmacion = '59721408';
  String _nombreReceptor = 'Titular';
  String? _banco;
  String? _instrucciones;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.obtenerUltimaSolicitudPago();
      await _cargarDatosPago();
    });
  }

  Future<void> _cargarDatosPago() async {
    try {
      final data = await Supabase.instance.client
          .from('platform_payment_settings')
          .select('*')
          .eq('id', true)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _nombreReceptor = data['recipient_name'] ?? _nombreReceptor;
          _numeroTarjeta = _formatCard(
              data['card_number'] as String? ?? _numeroTarjeta);
          _telefonoConfirmacion =
              data['phone_number'] as String? ?? _telefonoConfirmacion;
          _banco = data['bank_name'] as String?;
          _instrucciones = data['instructions'] as String?;
        });
      }
    } catch (_) {
      // Silencioso: mantenemos el fallback
    }
  }

  String _formatCard(String raw) {
    final clean = raw.replaceAll(' ', '');
    if (clean.length != 16) return raw;
    return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)} ${clean.substring(12)}';
  }

  @override
  void dispose() {
    _noTransaccionCtrl.dispose();
    super.dispose();
  }

  double _costoBase(AppProvider provider, String plan, int dias) {
    int numSucursales = provider.sucursales.length;
    if (numSucursales == 0) numSucursales = 1;
    final double mensual =
        (plan == 'normal') ? COSTO_PLAN_BASE : COSTO_PLAN_PREMIUM;
    final double extraMensual = (numSucursales - 1) * COSTO_POR_SUCURSAL;
    final double totalMensual = mensual + extraMensual;
    return totalMensual * (dias / 30.0);
  }

  double _costoConDescuento(AppProvider provider, String plan, int dias) {
    final base = _costoBase(provider, plan, dias);
    final bono = provider.bonoActivo;
    if (bono != null) return base * (1 - bono.porcentajeDescuento / 100);
    return base;
  }

  double _descuentoAplicado(AppProvider provider, String plan, int dias) {
    final base = _costoBase(provider, plan, dias);
    final bono = provider.bonoActivo;
    if (bono != null) return base * (bono.porcentajeDescuento / 100);
    return 0;
  }

  // ────────────────────────────────────────────────────────
  //  Calcular nueva fecha de vencimiento (rolling)
  // ────────────────────────────────────────────────────────
  DateTime _calcularNuevoVencimiento(AppProvider provider, int dias) {
    final now = DateTime.now();
    final settings = provider.settingsBox;
    DateTime base = now;
    if (settings != null) {
      final vencStr = settings.get('fechaVencimiento') as String?;
      if (vencStr != null) {
        final venc = DateTime.tryParse(vencStr);
        if (venc != null && venc.isAfter(now)) {
          base = venc;
        }
      }
    }
    return base.add(Duration(days: dias));
  }

  bool _mostrarFormulario(
      SolicitudPago? ultimaSolicitud, AppProvider provider) {
    if (ultimaSolicitud == null) return true;
    if (ultimaSolicitud.estado == 'rejected') return true;
    if (ultimaSolicitud.estado == 'approved') {
      return !provider.isPagoVigente();
    }
    // 'pending' u otros estados → no mostrar
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final ultimaSolicitud = provider.ultimaSolicitudPago;
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    final bono = provider.bonoActivo;

    int numSucursales = provider.sucursales.length;
    if (numSucursales == 0) numSucursales = 1;

    final cNormalBase = _costoBase(provider, 'normal', _diasSeleccionados);
    final cPremiumBase = _costoBase(provider, 'premium', _diasSeleccionados);
    final cNormalFinal =
        _costoConDescuento(provider, 'normal', _diasSeleccionados);
    final cPremiumFinal =
        _costoConDescuento(provider, 'premium', _diasSeleccionados);
    final dNormal =
        _descuentoAplicado(provider, 'normal', _diasSeleccionados);
    final dPremium =
        _descuentoAplicado(provider, 'premium', _diasSeleccionados);

    final bool mostrarForm = _mostrarFormulario(ultimaSolicitud, provider);
    final nuevoVencimiento =
        _calcularNuevoVencimiento(provider, _diasSeleccionados);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusCard(provider, p),
                    const SizedBox(height: 16),
                    if (bono != null) ...[
                      _bonoBanner(p, bono),
                      const SizedBox(height: 16),
                    ],
                    if (ultimaSolicitud != null &&
                        ultimaSolicitud.estado == 'pending')
                      _estadoCard(
                          context, ultimaSolicitud, p, provider, false)
                    else
                      isDesktop
                          ? _desktopLayout(
                              context,
                              provider,
                              p,
                              mostrarForm,
                              numSucursales,
                              cNormalBase,
                              cPremiumBase,
                              cNormalFinal,
                              cPremiumFinal,
                              dNormal,
                              dPremium,
                              nuevoVencimiento,
                            )
                          : _mobileLayout(
                              context,
                              provider,
                              p,
                              mostrarForm,
                              numSucursales,
                              cNormalBase,
                              cPremiumBase,
                              cNormalFinal,
                              cPremiumFinal,
                              dNormal,
                              dPremium,
                              nuevoVencimiento,
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

  // ============================================================
  //  STATUS CARD — muestra trial / active / vencido
  // ============================================================
  Widget _statusCard(AppProvider provider, _P p) {
    final settings = provider.settingsBox;
    final now = DateTime.now();

    // Determinar estado real
    String estado = 'trial';
    DateTime? fechaRef;
    int diasRestantes = 0;
    Color color = _C.info;
    IconData icon = Icons.card_giftcard_rounded;
    String titulo = 'Período de prueba';
    String subtitulo = '';

    if (provider.fechaRegistro != null) {
      final finTrial = provider.fechaRegistro!.add(const Duration(days: 3));
      if (now.isBefore(finTrial)) {
        diasRestantes = finTrial.difference(now).inDays + 1;
        fechaRef = finTrial;
        estado = 'trial';
        color = _C.info;
        icon = Icons.card_giftcard_rounded;
        titulo = 'Período de prueba';
        subtitulo = 'Termina el ${DateFormat('dd/MM/yyyy').format(finTrial)}';
      }
    }

    if (settings != null) {
      final vencStr = settings.get('fechaVencimiento') as String?;
      if (vencStr != null) {
        final venc = DateTime.tryParse(vencStr);
        if (venc != null) {
          if (venc.isAfter(now)) {
            diasRestantes = venc.difference(now).inDays + 1;
            fechaRef = venc;
            estado = 'active';
            color = _C.success;
            icon = Icons.verified_rounded;
            titulo = 'Suscripción activa';
            subtitulo = 'Vence el ${DateFormat('dd/MM/yyyy').format(venc)}';
          } else {
            final diff = now.difference(venc).inDays;
            diasRestantes = -diff;
            fechaRef = venc;
            estado = 'expired';
            color = _C.danger;
            icon = Icons.error_rounded;
            titulo = 'Suscripción vencida';
            subtitulo = 'Venció el ${DateFormat('dd/MM/yyyy').format(venc)}';
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(p.dark ? .18 : .10),
            color.withOpacity(p.dark ? .06 : .03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.35), width: 1.3),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color,
                color.withOpacity(.75),
              ]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (diasRestantes > 0 && estado == 'active')
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  color,
                  color.withOpacity(.75),
                ]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$diasRestantes',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Text(
                    'días',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else if (diasRestantes < 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${diasRestantes.abs()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Text(
                    'días vencida',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //  FONDO / APP BAR
  // ============================================================
  Widget _background(_P p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -200,
              right: -160,
              child: _orb(460, _C.primary.withOpacity(p.dark ? .12 : .07)),
            ),
            Positioned(
              bottom: -240,
              left: -140,
              child: _orb(440, _C.cyan.withOpacity(p.dark ? .10 : .06)),
            ),
          ],
        ),
      ),
    );
  }

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
            child: const Icon(Icons.credit_card_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Realizar pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Activa tu suscripción',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  LAYOUTS
  // ============================================================
  Widget _desktopLayout(
    BuildContext context,
    AppProvider provider,
    _P p,
    bool mostrarForm,
    int numSucursales,
    double cNormalBase,
    double cPremiumBase,
    double cNormalFinal,
    double cPremiumFinal,
    double dNormal,
    double dPremium,
    DateTime nuevoVencimiento,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _instruccionesCard(p, true),
              const SizedBox(height: 20),
              _planesTitulo(p, numSucursales),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _planCard(
                      context: context,
                      p: p,
                      nombre: 'Normal',
                      subtitulo: '2 vendedores',
                      precioBase: cNormalBase,
                      precioFinal: cNormalFinal,
                      descuento: dNormal,
                      color: _C.primary,
                      seleccionado: _planSeleccionado == 'normal',
                      onTap: () =>
                          setState(() => _planSeleccionado = 'normal'),
                      esPremium: false,
                      isDesktop: true,
                      beneficios: const [
                        'Inventario completo',
                        'Ventas con clientes',
                        'Gestión de gastos',
                        'Metas de ventas',
                        'Sincronización offline',
                        'Hasta 2 vendedores',
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _planCard(
                      context: context,
                      p: p,
                      nombre: 'Premium',
                      subtitulo: '5 vendedores',
                      precioBase: cPremiumBase,
                      precioFinal: cPremiumFinal,
                      descuento: dPremium,
                      color: _C.warning,
                      seleccionado: _planSeleccionado == 'premium',
                      onTap: () =>
                          setState(() => _planSeleccionado = 'premium'),
                      esPremium: true,
                      isDesktop: true,
                      beneficios: const [
                        'Panel avanzado con KPIs',
                        'Exportación PDF, Excel, CSV',
                        'Ocultar costos a vendedores',
                        'Gestión de proveedores',
                        'Notificaciones de stock',
                        'Ranking de productos',
                        'Hasta 5 vendedores',
                        'Soporte prioritario',
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 1,
          child: mostrarForm
              ? _formularioCard(
                  context, provider, p,
                  cNormalFinal, cPremiumFinal,
                  dNormal, dPremium, nuevoVencimiento, true)
              : _successCard(provider, p),
        ),
      ],
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    AppProvider provider,
    _P p,
    bool mostrarForm,
    int numSucursales,
    double cNormalBase,
    double cPremiumBase,
    double cNormalFinal,
    double cPremiumFinal,
    double dNormal,
    double dPremium,
    DateTime nuevoVencimiento,
  ) {
    return Column(
      children: [
        _instruccionesCard(p, false),
        const SizedBox(height: 20),
        _planesTitulo(p, numSucursales),
        const SizedBox(height: 12),
        _planCard(
          context: context,
          p: p,
          nombre: 'Normal',
          subtitulo: '2 vendedores',
          precioBase: cNormalBase,
          precioFinal: cNormalFinal,
          descuento: dNormal,
          color: _C.primary,
          seleccionado: _planSeleccionado == 'normal',
          onTap: () => setState(() => _planSeleccionado = 'normal'),
          esPremium: false,
          isDesktop: false,
          beneficios: const [
            'Inventario completo',
            'Ventas con clientes',
            'Gestión de gastos',
            'Metas de ventas',
            'Sincronización offline',
            'Hasta 2 vendedores',
          ],
        ),
        const SizedBox(height: 12),
        _planCard(
          context: context,
          p: p,
          nombre: 'Premium',
          subtitulo: '5 vendedores',
          precioBase: cPremiumBase,
          precioFinal: cPremiumFinal,
          descuento: dPremium,
          color: _C.warning,
          seleccionado: _planSeleccionado == 'premium',
          onTap: () => setState(() => _planSeleccionado = 'premium'),
          esPremium: true,
          isDesktop: false,
          beneficios: const [
            'Panel avanzado con KPIs',
            'Exportación PDF, Excel, CSV',
            'Ocultar costos a vendedores',
            'Gestión de proveedores',
            'Notificaciones de stock',
            'Ranking de productos',
            'Hasta 5 vendedores',
            'Soporte prioritario',
          ],
        ),
        const SizedBox(height: 16),
        mostrarForm
            ? _formularioCard(
                context, provider, p,
                cNormalFinal, cPremiumFinal,
                dNormal, dPremium, nuevoVencimiento, false)
            : _successCard(provider, p),
      ],
    );
  }

  // ============================================================
  //  BONO / INSTRUCCIONES / QR / PLANES
  // ============================================================
  Widget _bonoBanner(_P p, Bono bono) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _C.gradSuccess),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.success.withOpacity(.42),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.32)),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'BONO ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${bono.porcentajeDescuento.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Descuento aplicado a tu próximo pago',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Válido hasta ${DateFormat('dd/MM/yyyy').format(bono.fechaFin)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.80),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instruccionesCard(_P p, bool isDesktop) {
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withOpacity(.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                'Instrucciones de pago',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tarjetaBlock(p, isDesktop)),
                const SizedBox(width: 12),
                _qrBlock(p),
              ],
            )
          else
            _tarjetaBlock(p, isDesktop),
          const SizedBox(height: 14),
          _telefonoRow(p),
          if (_banco != null) ...[
            const SizedBox(height: 8),
            _bancoRow(p),
          ],
          const SizedBox(height: 14),
          _tipBox(p),
        ],
      ),
    );
  }

  Widget _tarjetaBlock(_P p, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.primary.withOpacity(.24)),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: _C.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _nombreReceptor.isEmpty
                      ? 'Tarjeta Metropolitana'
                      : _nombreReceptor,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => _copiar(_numeroTarjeta.replaceAll(' ', ''),
                      'Número de tarjeta copiado'),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        size: 15, color: _C.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _numeroTarjeta,
              style: TextStyle(
                fontSize: isDesktop ? 22 : 19,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 1.4,
                color: p.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrBlock(_P p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.cyan.withOpacity(.20),
                      _C.cyan.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.cyan.withOpacity(.24)),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: _C.cyan, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                'Escanea el QR',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/qr.jpg',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 6),
                      Text(
                        'QR no disponible',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea desde tu app bancaria',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _telefonoRow(_P p) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _C.success.withOpacity(p.dark ? .14 : .08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.success.withOpacity(.24)),
          ),
          child: const Icon(Icons.phone_rounded,
              size: 15, color: _C.success),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Teléfono de confirmación',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ),
        Material(
          color: _C.success.withOpacity(p.dark ? .16 : .10),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () =>
                _copiar(_telefonoConfirmacion, 'Teléfono copiado'),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _telefonoConfirmacion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _C.success,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded,
                      size: 13, color: _C.success),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bancoRow(_P p) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _C.info.withOpacity(p.dark ? .14 : .08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.info.withOpacity(.24)),
          ),
          child: const Icon(Icons.account_balance_rounded,
              size: 15, color: _C.info),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _banco!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: p.textMid,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tipBox(_P p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(p.dark ? .10 : .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.warning.withOpacity(.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.warning.withOpacity(.22),
                  _C.warning.withOpacity(.06),
                ],
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _C.warning.withOpacity(.28)),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                size: 15, color: _C.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _instrucciones ??
                  'Envía el número de transacción para activar tu plan. Los días se suman automáticamente si tu suscripción sigue activa.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planesTitulo(_P p, int numSucursales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Planes disponibles',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: p.textHigh,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: p.textMuted),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _diasSeleccionados,
                    isDense: true,
                    underline: const SizedBox(),
                    dropdownColor: p.surface,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh,
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 días')),
                      DropdownMenuItem(value: 90, child: Text('90 días')),
                      DropdownMenuItem(value: 180, child: Text('180 días')),
                    ],
                    onChanged: (v) => setState(() {
                      _diasSeleccionados = v ?? 30;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sucursales: $numSucursales · Adicional \$${COSTO_POR_SUCURSAL.toStringAsFixed(0)} CUP/mes',
          style: TextStyle(fontSize: 11.5, color: p.textMuted),
        ),
      ],
    );
  }

  Widget _planCard({
    required BuildContext context,
    required _P p,
    required String nombre,
    required String subtitulo,
    required double precioBase,
    required double precioFinal,
    required double descuento,
    required Color color,
    required bool seleccionado,
    required VoidCallback onTap,
    required bool esPremium,
    required bool isDesktop,
    required List<String> beneficios,
  }) {
    final tieneDescuento = descuento > 0;
    final gradientColors = esPremium ? _C.gradPremium : _C.gradBrand;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: EdgeInsets.all(isDesktop ? 18 : 16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: seleccionado ? color.withOpacity(.55) : p.border,
              width: seleccionado ? 1.8 : 1.2,
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: color.withOpacity(.24),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : p.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      esPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.verified_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: p.textHigh,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (esPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _C.gradPremium),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (tieneDescuento) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${precioFinal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: _C.success,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CUP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '\$${precioBase.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.lineThrough,
                          color: p.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.success.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ahorras \$${descuento.toStringAsFixed(0)} CUP',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _C.success,
                    ),
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${precioBase.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: p.textHigh,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CUP / $_diasSeleccionados d',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: beneficios
                      .map((b) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 3),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.textMid,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: seleccionado
                      ? LinearGradient(colors: gradientColors)
                      : null,
                  color: seleccionado ? null : p.surface2,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: seleccionado ? Colors.transparent : p.border,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        seleccionado
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 15,
                        color:
                            seleccionado ? Colors.white : p.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        seleccionado ? 'SELECCIONADO' : 'Elegir plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                          color:
                              seleccionado ? Colors.white : p.textMid,
                        ),
                      ),
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

  // ============================================================
  //  FORMULARIO
  // ============================================================
  Widget _formularioCard(
    BuildContext context,
    AppProvider provider,
    _P p,
    double cNormalFinal,
    double cPremiumFinal,
    double dNormal,
    double dPremium,
    DateTime nuevoVencimiento,
    bool isDesktop,
  ) {
    final costoFinal =
        _planSeleccionado == 'normal' ? cNormalFinal : cPremiumFinal;
    final descuento =
        _planSeleccionado == 'normal' ? dNormal : dPremium;
    final planNombre =
        _planSeleccionado == 'normal' ? 'Normal' : 'Premium';
    final tieneDescuento = descuento > 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withOpacity(.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                'Enviar solicitud',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _input(
                  p,
                  label: 'Empresa',
                  icon: Icons.business_rounded,
                  controller: TextEditingController(
                      text: provider.nombreEmpresa ?? ''),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _input(
                  p,
                  label: 'Número de transacción',
                  icon: Icons.receipt_rounded,
                  controller: _noTransaccionCtrl,
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _resumenPago(p, planNombre, costoFinal, descuento,
                    tieneDescuento, nuevoVencimiento),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarSolicitud,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 19),
                    label: Text(
                      _enviando ? 'Enviando…' : 'Enviar solicitud',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _C.primary.withOpacity(.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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

  Widget _input(
    _P p, {
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: p.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 18, color: p.textMuted),
        filled: true,
        fillColor: p.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: _C.danger,
        ),
      ),
    );
  }

  Widget _resumenPago(
    _P p,
    String planNombre,
    double costoFinal,
    double descuento,
    bool tieneDescuento,
    DateTime nuevoVencimiento,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          _resumenRow(p,
              label: 'Plan', value: '$planNombre · $_diasSeleccionados días'),
          if (tieneDescuento) ...[
            const SizedBox(height: 8),
            _resumenRow(
              p,
              label: 'Descuento',
              value: '-\$${descuento.toStringAsFixed(2)} CUP',
              valueColor: _C.success,
            ),
          ],
          const SizedBox(height: 8),
          _resumenRow(
            p,
            label: 'Nuevo vencimiento',
            value: DateFormat('dd/MM/yyyy').format(nuevoVencimiento),
            valueColor: _C.info,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Row(
              children: [
                Text(
                  'Total a pagar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textMid,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${costoFinal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: _C.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'CUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: p.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenRow(
    _P p, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: p.textMuted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: valueColor ?? p.textHigh,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  ESTADO SOLICITUD PENDIENTE
  // ============================================================
  Widget _estadoCard(
    BuildContext context,
    SolicitudPago solicitud,
    _P p,
    AppProvider provider,
    bool isDesktop,
  ) {
    // ✅ Fix: usar estados en inglés que coinciden con la BD
    final estadoColor = solicitud.estado == 'approved'
        ? _C.success
        : solicitud.estado == 'rejected'
            ? _C.danger
            : _C.warning;

    final estadoIcon = solicitud.estado == 'approved'
        ? Icons.check_circle_rounded
        : solicitud.estado == 'rejected'
            ? Icons.cancel_rounded
            : Icons.hourglass_empty_rounded;

    final estadoLabel = solicitud.estado == 'approved'
        ? 'APROBADO'
        : solicitud.estado == 'rejected'
            ? 'RECHAZADO'
            : 'PENDIENTE';

    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    estadoColor,
                    estadoColor.withOpacity(.75),
                  ]),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(estadoIcon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                'Estado de tu solicitud',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  estadoColor.withOpacity(.20),
                  estadoColor.withOpacity(.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: estadoColor.withOpacity(.32)),
            ),
            child: Column(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  estadoLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: estadoColor,
                    fontSize: 17,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    solicitud.estado == 'pending'
                        ? 'Será revisada por el equipo de soporte en menos de 24h.'
                        : solicitud.estado == 'approved'
                            ? '¡Tu suscripción ya está activa!'
                            : 'Revisa los detalles y envía una nueva.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: p.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _estadoTile(p, 'Plan', solicitud.planSolicitado.toUpperCase()),
          _estadoTile(p, 'Monto',
              '\$${solicitud.monto.toStringAsFixed(2)} CUP'),
          _estadoTile(p, 'N° Transacción', solicitud.noTransaccion),
          _estadoTile(
            p,
            'Fecha',
            DateFormat('dd/MM/yyyy HH:mm').format(solicitud.fechaSolicitud),
          ),
          if (solicitud.fechaAprobacion != null)
            _estadoTile(
              p,
              'Revisada',
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(solicitud.fechaAprobacion!),
            ),
          if (solicitud.motivoRechazo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.danger.withOpacity(.24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: _C.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motivo: ${solicitud.motivoRechazo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  //  ÉXITO — pago vigente
  // ============================================================
  Widget _successCard(AppProvider provider, _P p) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.success.withOpacity(.10),
            _C.cyan.withOpacity(.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.success.withOpacity(.35), width: 1.3),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradSuccess),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.success.withOpacity(.42),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Todo en orden',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: p.textHigh,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu suscripción está activa y vigente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoTile(_P p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  void _copiar(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    mostrarSnackBar(mensaje: msg, esExito: true, icono: Icons.copy_rounded);
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() => _enviando = true);
    try {
      await provider.crearSolicitudPago(
        _noTransaccionCtrl.text.trim(),
        _planSeleccionado,
        dias: _diasSeleccionados,
      );
      _noTransaccionCtrl.clear();
      await provider.obtenerUltimaSolicitudPago();
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Solicitud enviada correctamente', esExito: true);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(mensaje: e.toString(), esExito: false);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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