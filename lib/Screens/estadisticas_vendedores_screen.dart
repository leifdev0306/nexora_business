// ============================================================
//  estadisticas_vendedores_screen.dart · NEXORA BUSINESS
//  Ranking y métricas de vendedores
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  static const gold = Color(0xFFCA8A04);
  static const pink = Color(0xFFEC4899);

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

class EstadisticasVendedoresScreen extends StatefulWidget {
  const EstadisticasVendedoresScreen({Key? key}) : super(key: key);

  @override
  State<EstadisticasVendedoresScreen> createState() =>
      _EstadisticasVendedoresScreenState();
}

class _EstadisticasVendedoresScreenState
    extends State<EstadisticasVendedoresScreen> {
  bool _cargando = false;
  List<EstadisticasVendedor> _stats = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _stats = await provider.getEstadisticasVendedores();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, provider),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? _emptyState(p)
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    itemCount: _stats.length,
                    itemBuilder: (_, i) =>
                        _vendedorCard(_stats[i], i, p, isDesktop),
                  ),
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
            child: const Icon(Icons.leaderboard_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Estadísticas de Vendedores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${_stats.length} vendedor${_stats.length == 1 ? "" : "es"} activo${_stats.length == 1 ? "" : "s"}',
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
          icon: Icon(Icons.refresh_rounded, color: p.textMid),
          onPressed: _cargar,
        ),
      ],
    );
  }

  // ============================================================
  //  CARD VENDEDOR
  // ============================================================
  Widget _vendedorCard(
      EstadisticasVendedor s, int index, _P p, bool isDesktop) {
    final totalVentas = s.totalVentas;
    final totalMonto = s.totalMonto;
    final totalGanancia = s.totalGanancia;
    final promedio =
        totalVentas > 0 ? totalMonto / totalVentas : 0.0;
    final margen =
        totalMonto > 0 ? (totalGanancia / totalMonto) * 100 : 0.0;

    // Medalla para top 3
    Color rankColor = p.textMuted;
    Color rankBg = p.surface2;
    IconData? rankIcon;
    String rankLabel = '#${index + 1}';

    if (index == 0) {
      rankColor = _C.gold;
      rankBg = _C.gold.withOpacity(.14);
      rankIcon = Icons.emoji_events_rounded;
    } else if (index == 1) {
      rankColor = const Color(0xFF94A3B8); // plata
      rankBg = rankColor.withOpacity(.14);
      rankIcon = Icons.emoji_events_rounded;
    } else if (index == 2) {
      rankColor = const Color(0xFFCD7F32); // bronce
      rankBg = rankColor.withOpacity(.14);
      rankIcon = Icons.emoji_events_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: index == 0
                ? _C.gold.withOpacity(.40)
                : p.border,
            width: index == 0 ? 1.5 : 1.2,
          ),
          boxShadow: index == 0
              ? [
                  BoxShadow(
                    color: _C.gold.withOpacity(.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : p.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + nombre + rank
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _C.primary.withOpacity(.22),
                          _C.cyan.withOpacity(.06),
                        ]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.primary.withOpacity(.28),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        (s.email.isNotEmpty
                                ? s.email[0].toUpperCase()
                                : '?'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _C.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: rankColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: rankColor.withOpacity(.30),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: rankIcon != null
                            ? Icon(rankIcon,
                                size: 13, color: rankColor)
                            : Text(
                                rankLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: rankColor,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: p.textHigh,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalVentas > 0
                            ? '${_fmtMoney(totalMonto)} generados'
                            : 'Sin ventas aún',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: _C.gradGold),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _C.gold.withOpacity(.32),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'TOP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Grid de métricas
            LayoutBuilder(
              builder: (_, cst) {
                final cols = isDesktop ? 5 : 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metric(
                      p,
                      label: 'Ventas',
                      value: '$totalVentas',
                      icon: Icons.receipt_long_rounded,
                      color: _C.primary,
                      width: (cst.maxWidth - 8 * (cols - 1)) / cols,
                    ),
                    _metric(
                      p,
                      label: 'Facturado',
                      value: _fmtCompact(totalMonto),
                      icon: Icons.attach_money_rounded,
                      color: _C.success,
                      width: (cst.maxWidth - 8 * (cols - 1)) / cols,
                    ),
                    _metric(
                      p,
                      label: 'Ganancia',
                      value: _fmtCompact(totalGanancia),
                      icon: Icons.trending_up_rounded,
                      color: _C.cyan,
                      width: (cst.maxWidth - 8 * (cols - 1)) / cols,
                    ),
                    _metric(
                      p,
                      label: 'Ticket',
                      value: _fmtCompact(promedio),
                      icon: Icons.calculate_rounded,
                      color: _C.purple,
                      width: (cst.maxWidth - 8 * (cols - 1)) / cols,
                    ),
                    _metric(
                      p,
                      label: 'Margen',
                      value: '${margen.toStringAsFixed(1)}%',
                      icon: Icons.percent_rounded,
                      color: margen >= 20 ? _C.success : _C.warning,
                      width: (cst.maxWidth - 8 * (cols - 1)) / cols,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
    _P p, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.20),
                color.withOpacity(.05),
              ]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: p.textHigh,
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
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: _C.purple.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin vendedores',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra vendedores para ver sus estadísticas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMoney(double n) => '\$${NumberFormat('#,##0.00').format(n)}';

  String _fmtCompact(double n) {
    if (n >= 1000000) return '\$${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '\$${(n / 1000).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(0)}';
  }
}