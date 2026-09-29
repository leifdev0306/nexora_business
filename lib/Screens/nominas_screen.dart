// ============================================================
//  nominas_screen.dart  ·  NEXORA BUSINESS
//  Nóminas premium con KPIs, resumen del mes y detalle
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
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
  Color get borderStrong => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

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

class NominasScreen extends StatefulWidget {
  const NominasScreen({Key? key}) : super(key: key);

  @override
  _NominasScreenState createState() => _NominasScreenState();
}

class _NominasScreenState extends State<NominasScreen> {
  List<Map<String, dynamic>> _empleadosConDatos = [];
  bool _cargando = false;
  DateTime _mesSeleccionado = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final data = await provider.getEmpleadosConUsuario();
      if (mounted) {
        setState(() => _empleadosConDatos = data);
      }
    } catch (e) {
      mostrarSnackBar(mensaje: 'Error al cargar: ${mensajeAmigable(e)}',
          esExito: false);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _generarNomina(Empleado emp) async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.generarNomina(emp.id, _mesSeleccionado);
      await _cargarDatos();
      mostrarSnackBar(mensaje: 'Nómina generada', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    }
  }

  Future<void> _seleccionarMes() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mesSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() =>
          _mesSeleccionado = DateTime(picked.year, picked.month, 1));
      await _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    if (provider.rol != 'admin' && provider.rol != 'dueno') {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          elevation: 0,
          title: const Text('Nóminas'),
        ),
        body: Center(
          child: Text(
            'Acceso restringido a administradores.',
            style: TextStyle(color: p.textMid, fontSize: 15),
          ),
        ),
      );
    }

    final isDesktop = ResponsiveHelper.isDesktop();

    final nominasMes = provider.getNominasDelMes();
    final double totalMes =
        nominasMes.fold(0.0, (s, n) => s + n.totalPagado);
    final int empleadosActivos = _empleadosConDatos
        .where((e) => (e['empleado'] as Empleado).activo)
        .length;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(context, provider, p),
      body: Stack(
        children: [
          _background(p),
          RefreshIndicator(
            onRefresh: _cargarDatos,
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 14, 14, isDesktop ? 24 : 14, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _resumenMes(
                              p, provider, totalMes, empleadosActivos,
                              nominasMes.length,
                            ),
                            const SizedBox(height: 18),
                            if (_empleadosConDatos.isEmpty)
                              _emptyState(p)
                            else ...[
                              Row(
                                children: [
                                  Text(
                                    'Empleados',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                      color: p.textHigh,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _C.primary.withOpacity(
                                          p.dark ? .18 : .10),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_empleadosConDatos.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _C.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._empleadosConDatos.map((item) {
                                final usuario = item['usuario'] as Usuario;
                                final empleado = item['empleado'] as Empleado;
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _empleadoCard(
                                    context, provider, usuario, empleado, p,
                                    isDesktop,
                                  ),
                                );
                              }),
                            ],
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

  // ============================================================
  //  FONDO
  // ============================================================
  Widget _background(_P p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -160,
              child: _orb(420, _C.purple.withOpacity(p.dark ? .12 : .07)),
            ),
            Positioned(
              bottom: -220,
              left: -140,
              child: _orb(440, _C.primary.withOpacity(p.dark ? .10 : .06)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  APP BAR
  // ============================================================
  PreferredSizeWidget _appBar(
      BuildContext context, AppProvider provider, _P p) {
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
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.payments_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Nóminas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Pago de personal',
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
      actions: [
        IconButton(
          tooltip: 'Seleccionar mes',
          onPressed: _seleccionarMes,
          icon: Icon(Icons.calendar_month_rounded, color: p.textHigh),
        ),
        IconButton(
          tooltip: 'Recargar',
          onPressed: _cargarDatos,
          icon: Icon(Icons.refresh_rounded, color: p.textHigh),
        ),
      ],
    );
  }

  // ============================================================
  //  RESUMEN DEL MES
  // ============================================================
  Widget _resumenMes(
    _P p,
    AppProvider provider,
    double totalMes,
    int empleadosActivos,
    int pagosRealizados,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.20),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(.32)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('MMMM yyyy', 'es')
                          .format(_mesSeleccionado)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _seleccionarMes,
                icon: const Icon(Icons.edit_calendar_rounded,
                    size: 14, color: Colors.white),
                label: const Text(
                  'Cambiar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total pagado en nóminas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '\$${_fmt(totalMes)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                    'Empleados', '$empleadosActivos'),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withOpacity(.20),
              ),
              Expanded(
                child: _miniStat(
                  'Pagos este mes', '$pagosRealizados',
                  right: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {bool right = false}) {
    return Column(
      crossAxisAlignment: right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(.75),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  CARD EMPLEADO
  // ============================================================
  Widget _empleadoCard(
    BuildContext context,
    AppProvider provider,
    Usuario usuario,
    Empleado empleado,
    _P p,
    bool isDesktop,
  ) {
    final nominasEmp = provider.getNominasByEmpleado(empleado.id);
    final yaPagadoEsteMes = nominasEmp.any((n) =>
        n.periodo.year == _mesSeleccionado.year &&
        n.periodo.month == _mesSeleccionado.month);
    final ultima = nominasEmp.isNotEmpty ? nominasEmp.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yaPagadoEsteMes
              ? _C.success.withOpacity(.32)
              : p.border,
          width: yaPagadoEsteMes ? 1.4 : 1,
        ),
        boxShadow: p.shadowSm,
      ),
      child: isDesktop
          ? _desktopRow(context, usuario, empleado, yaPagadoEsteMes, ultima, p)
          : _mobileColumn(
              context, usuario, empleado, yaPagadoEsteMes, ultima, p),
    );
  }

  Widget _desktopRow(
    BuildContext context,
    Usuario usuario,
    Empleado empleado,
    bool yaPagado,
    Nomina? ultima,
    _P p,
  ) {
    return Row(
      children: [
        _avatar(usuario.email, p),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                empleado.tipoContrato,
                style: TextStyle(fontSize: 11, color: p.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALARIO BASE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${_fmt(empleado.salarioBase)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ÚLTIMO PAGO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: p.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ultima != null
                    ? '${DateFormat('dd/MM/yy').format(ultima.fechaPago)}'
                    : 'Sin pagos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textMid,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (yaPagado)
          _badgePagado(p)
        else
          _botonPagar(
            onTap: () => _generarNomina(empleado),
            p: p,
          ),
      ],
    );
  }

  Widget _mobileColumn(
    BuildContext context,
    Usuario usuario,
    Empleado empleado,
    bool yaPagado,
    Nomina? ultima,
    _P p,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(usuario.email, p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: p.textHigh,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    empleado.tipoContrato,
                    style: TextStyle(fontSize: 11, color: p.textMuted),
                  ),
                ],
              ),
            ),
            if (yaPagado)
              _badgePagado(p)
            else
              _botonPagar(
                onTap: () => _generarNomina(empleado),
                p: p,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _miniStatDark(
                  p, 'Salario base', '\$${_fmt(empleado.salarioBase)}',
                ),
              ),
              Container(width: 1, height: 26, color: p.border),
              Expanded(
                child: _miniStatDark(
                  p,
                  'Último pago',
                  ultima != null
                      ? DateFormat('dd/MM/yy').format(ultima.fechaPago)
                      : '—',
                  right: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatDark(_P p, String label, String value,
      {bool right = false}) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: p.textHigh,
          ),
        ),
      ],
    );
  }

  Widget _avatar(String email, _P p) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.purple.withOpacity(.22),
            _C.indigo.withOpacity(.06),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.purple.withOpacity(.24)),
      ),
      child: Text(
        email.isNotEmpty ? email[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: _C.purple,
        ),
      ),
    );
  }

  Widget _badgePagado(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ColorSuccess.start, _ColorSuccess.end],
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: _C.success.withOpacity(.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'PAGADO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonPagar({required VoidCallback onTap, required _P p}) {
    return Material(
      color: _C.success.withOpacity(p.dark ? .16 : .10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _C.success.withOpacity(.24)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_rounded,
                  size: 15, color: _C.success),
              SizedBox(width: 6),
              Text(
                'Pagar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _C.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  VACÍO
  // ============================================================
  Widget _emptyState(_P p) {
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.purple.withOpacity(.16),
                  _C.indigo.withOpacity(.06),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                size: 38, color: _C.purple),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin empleados configurados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: p.textHigh,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ve a la sección de Vendedores y asigna un salario a cada usuario.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return NumberFormat('#,###').format(n);
    return NumberFormat('#,##0.00').format(n);
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

class _ColorSuccess {
  static const start = Color(0xFF10B981);
  static const end = Color(0xFF06B6D4);
}