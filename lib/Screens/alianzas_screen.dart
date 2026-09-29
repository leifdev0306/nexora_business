// ============================================================
//  alianzas_screen.dart · NEXORA BUSINESS
//  Alianzas comerciales con búsqueda por email y estados EN
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';
import '../responsive_helper.dart';

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
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradWarm = [Color(0xFFF59E0B), Color(0xFFF97316)];
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

class AlianzasScreen extends StatefulWidget {
  const AlianzasScreen({Key? key}) : super(key: key);

  @override
  State<AlianzasScreen> createState() => _AlianzasScreenState();
}

class _AlianzasScreenState extends State<AlianzasScreen> {
  final _emailCtrl = TextEditingController();
  String _filtroEstado = 'todos';
  bool _enviando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    // ✅ Fix: estados en inglés
    final alianzas = provider.alianzas.where((a) =>
        a.empresaId == provider.empresaId ||
        a.empresaAliadaId == provider.empresaId).toList();

    var filtradas = alianzas;
    if (_filtroEstado != 'todos') {
      filtradas = filtradas.where((a) => a.estado == _filtroEstado).toList();
    }

    filtradas.sort((a, b) {
      if (a.estado == 'pending' && b.estado != 'pending') return -1;
      if (a.estado != 'pending' && b.estado == 'pending') return 1;
      return b.fechaSolicitud.compareTo(a.fechaSolicitud);
    });

    final total = alianzas.length;
    final pendientes = alianzas.where((a) => a.estado == 'pending').length;
    final aceptadas = alianzas.where((a) => a.estado == 'accepted').length;
    final pendientesRecibidas = alianzas
        .where((a) =>
            a.estado == 'pending' && a.empresaAliadaId == provider.empresaId)
        .toList();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, provider),
      body: Column(
        children: [
          _inviteSection(provider, p, isDesktop, pendientesRecibidas),
          _statsRow(total, pendientes, aceptadas, p),
          _filterRow(p),
          Expanded(
            child: filtradas.isEmpty
                ? _emptyState(p)
                : RefreshIndicator(
                    onRefresh: () => provider.sincronizarManual(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      itemCount: filtradas.length,
                      itemBuilder: (_, i) =>
                          _alianzaCard(filtradas[i], provider, p),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(_P p, AppProvider provider) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
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
            child: const Icon(Icons.handshake_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Alianzas Comerciales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Colabora con otras empresas',
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
          icon: Icon(Icons.sync_rounded, color: p.textMid),
          onPressed: provider.sincronizarManual,
        ),
      ],
    );
  }

  // ============================================================
  //  INVITAR
  // ============================================================
  Widget _inviteSection(
    AppProvider provider,
    _P p,
    bool isDesktop,
    List<Alianza> pendientesRecibidas,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                'Invitar empresa',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 16 : 14.5,
                  color: p.textHigh,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa el email del dueño de la otra empresa',
            style: TextStyle(fontSize: 11.5, color: p.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: p.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'email@empresa.com',
                      hintStyle: TextStyle(
                        color: p.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                          size: 18, color: p.textMuted),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : () => _invitar(provider),
                  icon: _enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Invitar',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          if (pendientesRecibidas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _C.warning.withOpacity(.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: _C.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tienes ${pendientesRecibidas.length} solicitud${pendientesRecibidas.length == 1 ? "" : "es"} pendiente${pendientesRecibidas.length == 1 ? "" : "s"} por responder',
                      style: TextStyle(
                        color: p.textMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

  Future<void> _invitar(AppProvider provider) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      mostrarSnackBar(
          mensaje: 'Ingresa un email válido', esExito: false);
      return;
    }
    setState(() => _enviando = true);
    try {
      // ✅ Fix: tabla `users` (no `usuarios`), columna `company_id`
      final userData = await provider.supabase
          .from('users')
          .select('company_id')
          .eq('email', email)
          .maybeSingle();

      if (userData == null || userData['company_id'] == null) {
        mostrarSnackBar(
          mensaje: 'No existe un usuario con ese email',
          esExito: false,
        );
        return;
      }
      final empresaId = userData['company_id'] as String;
      if (empresaId == provider.empresaId) {
        mostrarSnackBar(
            mensaje: 'No puedes aliarte contigo mismo',
            esExito: false);
        return;
      }
      await provider.solicitarAlianza(empresaId);
      _emailCtrl.clear();
      mostrarSnackBar(
          mensaje: 'Solicitud de alianza enviada', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ============================================================
  //  STATS
  // ============================================================
  Widget _statsRow(int total, int pendientes, int aceptadas, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
              child: _statCard('Total', '$total', Icons.groups_rounded,
                  _C.primary, p)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard('Pendientes', '$pendientes',
                  Icons.hourglass_empty_rounded, _C.warning, p)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard('Aceptadas', '$aceptadas',
                  Icons.check_circle_rounded, _C.success, p)),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, _P p) {
    return Container(
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: p.textHigh,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  FILTROS
  // ============================================================
  Widget _filterRow(_P p) {
    // ✅ Fix: valores en inglés
    final estados = [
      ('todos', 'Todas', _C.primary),
      ('pending', 'Pendientes', _C.warning),
      ('accepted', 'Aceptadas', _C.success),
      ('rejected', 'Rechazadas', _C.danger),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: estados.map((e) {
            final selected = _filtroEstado == e.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _filtroEstado = e.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? e.$3.withOpacity(.14)
                        : p.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? e.$3 : p.border,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    e.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? e.$3 : p.textMid,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  //  CARD
  // ============================================================
  Widget _alianzaCard(Alianza a, AppProvider provider, _P p) {
    final esPropia = a.empresaId == provider.empresaId;
    final esPendienteRecibida =
        a.estado == 'pending' && !esPropia;
    final estadoData = _estadoData(a.estado);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          boxShadow: p.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      estadoData.color.withOpacity(.20),
                      estadoData.color.withOpacity(.05),
                    ]),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: estadoData.color.withOpacity(.32)),
                  ),
                  child: Icon(
                    esPropia
                        ? Icons.arrow_outward_rounded
                        : Icons.arrow_downward_rounded,
                    color: estadoData.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esPropia
                            ? 'Enviada a ${_nombreAliado(provider, a.empresaAliadaId)}'
                            : 'Recibida de ${_nombreAliado(provider, a.empresaId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(a.fechaSolicitud),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: estadoData.color.withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: estadoData.color.withOpacity(.32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoData.icon,
                          size: 12, color: estadoData.color),
                      const SizedBox(width: 4),
                      Text(
                        estadoData.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .4,
                          color: estadoData.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (esPendienteRecibida) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          provider.responderAlianza(a.id, false),
                      icon: const Icon(Icons.close_rounded, size: 15),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.danger,
                        side: BorderSide(
                            color: _C.danger.withOpacity(.45)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          provider.responderAlianza(a.id, true),
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (a.fechaRespuesta != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: p.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Respondida: ${DateFormat('dd/MM/yyyy HH:mm').format(a.fechaRespuesta!)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: p.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _C.primary.withOpacity(.16),
                  _C.cyan.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.handshake_outlined,
                  size: 40, color: _C.primary.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin alianzas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Invita a otras empresas para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  HELPERS
  // ============================================================
  String _nombreAliado(AppProvider provider, String empresaId) {
    if (empresaId.length >= 8) return '${empresaId.substring(0, 8)}…';
    return empresaId;
  }

  _EstadoData _estadoData(String estado) {
    // ✅ Fix: usar estados en inglés
    switch (estado) {
      case 'accepted':
        return _EstadoData('ACEPTADA', _C.success,
            Icons.check_circle_rounded);
      case 'rejected':
        return _EstadoData(
            'RECHAZADA', _C.danger, Icons.cancel_rounded);
      default:
        return _EstadoData('PENDIENTE', _C.warning,
            Icons.hourglass_empty_rounded);
    }
  }
}

class _EstadoData {
  final String label;
  final Color color;
  final IconData icon;
  _EstadoData(this.label, this.color, this.icon);
}