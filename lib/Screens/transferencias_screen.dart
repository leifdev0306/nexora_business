// ============================================================
//  transferencias_screen.dart · NEXORA BUSINESS
//  Registro de transferencias bancarias con exportación Excel
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
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

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradGold = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
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

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({Key? key}) : super(key: key);

  @override
  State<TransferenciasScreen> createState() =>
      _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  int _filtroMes = 0;
  bool _exportando = false;

  // ✅ Fix: usar Venta? en lugar de null as Venta
  int _getCantidadVenta(AppProvider provider, String ventaId) {
    Venta? venta;
    for (final v in provider.ventas) {
      if (v.id == ventaId) {
        venta = v;
        break;
      }
    }
    if (venta == null) return 0;

    if (venta.saleGroupId != null && venta.saleGroupId!.isNotEmpty) {
      return provider.ventas
          .where((v) => v.saleGroupId == venta!.saleGroupId)
          .fold<int>(0, (s, v) => s + v.cantidad.toInt());
    }
    return venta.cantidad.toInt();
  }

  Future<void> _exportarExcel(
    List<Transferencia> transferencias,
    AppProvider provider,
  ) async {
    if (_exportando) return;
    setState(() => _exportando = true);

    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Transferencias'];
      sheet.appendRow([
        'Nombre Completo',
        'Carnet Identidad',
        'Teléfono',
        'N° Transferencia',
        'Fecha/Hora',
        'Monto',
        'Cantidad de productos',
      ]);

      for (var t in transferencias) {
        final cantidad = _getCantidadVenta(provider, t.ventaId);
        sheet.appendRow([
          t.nombreCompleto,
          t.carnetIdentidad,
          t.numeroTelefono,
          t.numeroTransferencia,
          DateFormat('dd/MM/yyyy HH:mm').format(t.fechaHora),
          t.monto,
          cantidad,
        ]);
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/transferencias_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final File file = File(path);
      await file.writeAsBytes(excelFile.encode()!);

      await Share.shareXFiles([XFile(path)],
          text: 'Reporte de transferencias');
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al exportar: $e', esExito: false);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    var transferencias = provider.transferencias.toList();

    if (_filtroMes != 0) {
      transferencias = transferencias
          .where((t) => t.fechaHora.month == _filtroMes)
          .toList();
    }

    transferencias.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    final montoTotal =
        transferencias.fold<double>(0.0, (s, t) => s + t.monto);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, provider, transferencias),
      body: Column(
        children: [
          _header(transferencias.length, montoTotal, p),
          Expanded(
            child: transferencias.isEmpty
                ? _emptyState(p)
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(14),
                      itemCount: transferencias.length,
                      itemBuilder: (_, i) => _card(
                          transferencias[i], provider, p),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(
    _P p,
    AppProvider provider,
    List<Transferencia> transferencias,
  ) {
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
              gradient: const LinearGradient(colors: _C.gradGold),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.gold.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Transferencias',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${transferencias.length} registrada${transferencias.length == 1 ? "" : "s"}',
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: (transferencias.isEmpty || _exportando)
                ? null
                : () => _exportarExcel(transferencias, provider),
            icon: _exportando
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.file_download_rounded, size: 15),
            label: Text(
              _exportando ? 'Exportando…' : 'Excel',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(int total, double monto, _P p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _statCard('Registros', '$total',
                Icons.receipt_long_rounded, _C.primary, p),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard('Monto total', '\$${monto.toStringAsFixed(2)}',
                Icons.attach_money_rounded, _C.success, p),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                color.withOpacity(.22),
                color.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
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

  Widget _card(Transferencia t, AppProvider provider, _P p) {
    final cantidad = _getCantidadVenta(provider, t.ventaId);

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
                    gradient: const LinearGradient(colors: _C.gradGold),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: _C.gold.withOpacity(.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: p.textHigh,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy · HH:mm')
                            .format(t.fechaHora),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${t.monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: _C.success,
                      ),
                    ),
                    if (cantidad > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$cantidad prod.',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _C.primary,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.border),
              ),
              child: Column(
                children: [
                  _kv(p, 'CI', t.carnetIdentidad),
                  _kv(p, 'Teléfono', t.numeroTelefono),
                  _kv(p, 'N° Transacción', t.numeroTransferencia),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _eliminar(t.id, provider),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text('Eliminar',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: _C.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(_P p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
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
                  _C.gold.withOpacity(.16),
                  _C.primary.withOpacity(.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 40, color: _C.gold.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin transferencias',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aquí aparecerán las transferencias bancarias\nregistradas desde la app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, color: p.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(String id, AppProvider provider) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('¿Eliminar transferencia?',
            style: TextStyle(
                color: p.textHigh, fontWeight: FontWeight.w900)),
        content: Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: p.textMid, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await provider.eliminarTransferencia(id);
        mostrarSnackBar(
            mensaje: 'Transferencia eliminada', esExito: true);
      } catch (e) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }
}