// ============================================================
//  referidos_screen.dart · NEXORA BUSINESS
//  Sistema de referidos con código, bonos y tracking
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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
  static const gold = Color(0xFFCA8A04);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradGold = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
  static const gradPurple = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
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

class ReferidosScreen extends StatefulWidget {
  const ReferidosScreen({Key? key}) : super(key: key);

  @override
  State<ReferidosScreen> createState() => _ReferidosScreenState();
}

class _ReferidosScreenState extends State<ReferidosScreen> {
  String _filtroEstado = 'todos';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    final referidos = provider.referidos
        .where((r) => r.empresaId == provider.empresaId)
        .toList();

    var filtrados = referidos;
    if (_filtroEstado != 'todos') {
      filtrados =
          filtrados.where((r) => r.estado == _filtroEstado).toList();
    }
    filtrados.sort((a, b) => b.fechaReferido.compareTo(a.fechaReferido));

    final total = referidos.length;
    final pendientes =
        referidos.where((r) => r.estado == 'pending').length;
    final pagados =
        referidos.where((r) => r.estado == 'rewarded').length;

    final bono = provider.bonoActivo;

    final codigoReferido =
        provider.supabase.auth.currentUser?.email ??
            provider.nombreEmpresa ??
            provider.empresaId ??
            '';

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, provider),
      body: Column(
        children: [
          _codeCard(codigoReferido, p),
          _statsRow(total, pendientes, pagados, p),
          if (bono != null) _bonoBanner(bono, p),
          _filterRow(p),
          Expanded(
            child: filtrados.isEmpty
                ? _emptyState(p)
                : RefreshIndicator(
                    onRefresh: () => provider.sincronizarManual(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      itemCount: filtrados.length,
                      itemBuilder: (_, i) =>
                          _referidoCard(filtrados[i], p),
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
              gradient: const LinearGradient(colors: _C.gradPurple),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sistema de Referidos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Gana bonos invitando empresas',
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
  //  CÓDIGO
  // ============================================================
  Widget _codeCard(String codigo, _P p) {
    final display = codigo.isEmpty ? 'No disponible' : codigo;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.purple.withOpacity(p.dark ? .14 : .08),
            _C.pink.withOpacity(p.dark ? .06 : .03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.purple.withOpacity(.30)),
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
                  gradient: const LinearGradient(colors: _C.gradPurple),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu código de referido',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .3,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: p.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (codigo.isEmpty) {
                      mostrarSnackBar(
                          mensaje: 'Sin código disponible',
                          esExito: false);
                      return;
                    }
                    Clipboard.setData(ClipboardData(text: codigo));
                    mostrarSnackBar(
                        mensaje: 'Código copiado',
                        esExito: true,
                        icono: Icons.copy_rounded);
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text('Copiar',
                      style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.purple,
                    side: BorderSide(color: _C.purple.withOpacity(.45)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (codigo.isEmpty) return;
                    Share.share(
                      '🎁 ¡Te invito a usar $APP_NAME!\n\n'
                      'Usa mi código de referido: $codigo\n'
                      'Cuando te registres y pagues, ambos ganamos beneficios.\n\n'
                      'Descarga: https://leifdev0306.github.io/Tu-MiPyme/',
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: const Text('Compartir',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  STATS
  // ============================================================
  Widget _statsRow(int total, int pendientes, int pagados, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Expanded(
              child: _statCard('Total', '$total', Icons.people_rounded,
                  _C.primary, p)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard('Pendientes', '$pendientes',
                  Icons.hourglass_empty_rounded, _C.warning, p)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard('Pagados', '$pagados',
                  Icons.check_circle_rounded, _C.success, p)),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: p.textHigh,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BONO
  // ============================================================
  Widget _bonoBanner(Bono bono, _P p) {
    final pct = bono.porcentajeDescuento;
    final pctLabel = pct % 1 == 0
        ? pct.toStringAsFixed(0)
        : pct.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _C.gradGold),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.gold.withOpacity(.40),
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
            child: const Icon(Icons.emoji_events_rounded,
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
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-$pctLabel%',
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
                  'Se aplicará en tu próximo pago',
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

  // ============================================================
  //  FILTROS
  // ============================================================
  Widget _filterRow(_P p) {
    final estados = [
      ('todos', 'Todos', _C.primary),
      ('pending', 'Pendientes', _C.warning),
      ('rewarded', 'Recompensados', _C.success),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
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
  //  CARD REFERIDO
  // ============================================================
  Widget _referidoCard(Referido r, _P p) {
    // ✅ Fix: estados en inglés
    final estadoData = _estadoData(r.estado);

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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  estadoData.color.withOpacity(.22),
                  estadoData.color.withOpacity(.05),
                ]),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: estadoData.color.withOpacity(.32)),
              ),
              child: Icon(estadoData.icon,
                  color: estadoData.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empresa ${r.empresaReferidaId.substring(0, 8)}…',
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
                    'Referido: ${DateFormat('dd/MM/yyyy').format(r.fechaReferido)}'
                    '${r.fechaPago != null ? '  ·  Pagado: ${DateFormat('dd/MM/yyyy').format(r.fechaPago!)}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
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
                border:
                    Border.all(color: estadoData.color.withOpacity(.32)),
              ),
              child: Text(
                estadoData.label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                  color: estadoData.color,
                ),
              ),
            ),
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
                  _C.purple.withOpacity(.16),
                  _C.pink.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.share_outlined,
                  size: 40, color: _C.purple.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            Text(
              _filtroEstado != 'todos'
                  ? 'Sin referidos en este estado'
                  : 'Aún no has referido a nadie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filtroEstado != 'todos'
                  ? 'Prueba cambiando el filtro.'
                  : 'Comparte tu código con otros emprendedores.\nCada 2 pagos ganas un bono del 50%.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, color: p.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  _EstadoData _estadoData(String estado) {
    switch (estado) {
      case 'rewarded':
        return _EstadoData(
            'RECOMPENSADO', _C.success, Icons.check_circle_rounded);
      case 'qualified':
        return _EstadoData(
            'CALIFICADO', _C.cyan, Icons.thumb_up_rounded);
      case 'cancelled':
        return _EstadoData(
            'CANCELADO', _C.danger, Icons.cancel_rounded);
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