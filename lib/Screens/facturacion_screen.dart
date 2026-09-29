// ============================================================
//  facturacion_screen.dart · NEXORA BUSINESS
//  Generación de facturas XML (ONAT) y tickets PDF
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../main.dart';
import '../responsive_helper.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradInfo = [Color(0xFF3B82F6), Color(0xFF06B6D4)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
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

class FacturacionScreen extends StatefulWidget {
  final Venta? venta;
  const FacturacionScreen({Key? key, this.venta}) : super(key: key);

  @override
  State<FacturacionScreen> createState() => _FacturacionScreenState();
}

class _FacturacionScreenState extends State<FacturacionScreen> {
  bool _generandoXML = false;
  bool _generandoPDF = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    // ✅ Fix roles
    final esAdmin = provider.rol == 'dueno';
    final esGerente = provider.rol == 'gerente';

    if (!esAdmin && !esGerente) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          title: const Text('Facturación'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 64, color: p.textMuted),
              const SizedBox(height: 16),
              Text(
                'No tienes permisos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final venta = widget.venta;
    final producto =
        venta != null ? provider.getProductoById(venta.productoId) : null;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(14),
          children: [
            if (venta != null) ...[
              _facturaCard(venta, producto, provider, p),
              const SizedBox(height: 16),
              _acciones(venta, provider, p),
            ] else
              _emptySelection(p),
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
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradInfo),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.info.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.receipt_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Facturación Electrónica',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Genera XML y PDF',
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

  Widget _facturaCard(
    Venta v,
    Producto? producto,
    AppProvider provider,
    _P p,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                width: 42,
                height: 42,
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
                child: const Icon(Icons.description_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Factura de venta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: p.textHigh,
                      ),
                    ),
                    Text(
                      'F-${v.id.length >= 8 ? v.id.substring(0, 8) : v.id}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.success.withOpacity(.14),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: _C.success.withOpacity(.32)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 11, color: _C.success),
                    SizedBox(width: 4),
                    Text(
                      'COMPLETADA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                        color: _C.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                _kv(p, 'Emisor', provider.nombreEmpresa ?? 'Mi Empresa'),
                _kv(p, 'Producto',
                    producto?.nombre ?? v.productoNombre),
                _kv(p, 'Cantidad',
                    '${v.cantidad} ${producto?.unidadMedida ?? 'u'}'),
                _kv(p, 'Precio unitario',
                    '\$${v.precioUnitario.toStringAsFixed(2)}'),
                _kv(p, 'Método de pago', v.metodoPago),
                _kv(p, 'Fecha',
                    DateFormat('dd/MM/yyyy HH:mm').format(v.fecha)),
                if (v.moneda != null) _kv(p, 'Moneda', v.moneda!),
                if (v.totalUSD != null)
                  _kv(p, 'Total USD',
                      '\$${v.totalUSD!.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradSuccess),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${v.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(_P p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: p.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acciones(Venta v, AppProvider provider, _P p) {
    return Column(
      children: [
        _actionButton(
          p,
          label: 'Generar XML (ONAT)',
          sub: 'Formato oficial para facturación electrónica',
          icon: Icons.code_rounded,
          gradient: _C.gradInfo,
          color: _C.info,
          loading: _generandoXML,
          onTap: () => _generarXML(v, provider),
        ),
        const SizedBox(height: 10),
        _actionButton(
          p,
          label: 'Generar Ticket (PDF)',
          sub: 'Comprobante imprimible para el cliente',
          icon: Icons.picture_as_pdf_rounded,
          gradient: _C.gradSuccess,
          color: _C.success,
          loading: _generandoPDF,
          onTap: () => _generarPDF(v, provider),
        ),
      ],
    );
  }

  Widget _actionButton(
    _P p, {
    required String label,
    required String sub,
    required IconData icon,
    required List<Color> gradient,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(.30)),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: p.textHigh,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    color: color, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySelection(_P p) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.info.withOpacity(.16),
                _C.cyan.withOpacity(.04),
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 40, color: _C.info.withOpacity(.75)),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona una venta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: p.textHigh,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Abre el historial y elige una venta para generar su factura.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  GENERAR XML
  // ============================================================
  Future<void> _generarXML(Venta venta, AppProvider provider) async {
    setState(() => _generandoXML = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln(
          '<FacturaElectronica xmlns="http://www.onat.gob.cu/fe">');
      buffer.writeln('  <Encabezado>');
      buffer.writeln(
          '    <NumeroFactura>F-${venta.id.substring(0, 8)}</NumeroFactura>');
      buffer.writeln(
          '    <FechaEmision>${venta.fecha.toIso8601String()}</FechaEmision>');
      buffer.writeln('    <Emisor>');
      buffer.writeln(
          '      <Nombre>${_escapeXml(provider.nombreEmpresa ?? 'Mi Empresa')}</Nombre>');
      buffer.writeln(
          '      <NIT>CU-${provider.empresaId?.substring(0, 8) ?? ''}</NIT>');
      buffer.writeln('    </Emisor>');
      buffer.writeln('    <Receptor>');
      buffer.writeln(
          '      <Nombre>${venta.clienteId != null ? 'Cliente ${venta.clienteId!.substring(0, 6)}' : 'Consumidor Final'}</Nombre>');
      buffer.writeln('    </Receptor>');
      buffer.writeln('    <Detalles>');
      buffer.writeln('      <Linea>');
      buffer.writeln(
          '        <Producto>${_escapeXml(venta.productoNombre)}</Producto>');
      buffer.writeln('        <Cantidad>${venta.cantidad}</Cantidad>');
      buffer.writeln(
          '        <PrecioUnitario>${venta.precioUnitario.toStringAsFixed(2)}</PrecioUnitario>');
      buffer.writeln(
          '        <Importe>${venta.total.toStringAsFixed(2)}</Importe>');
      buffer.writeln('      </Linea>');
      buffer.writeln('    </Detalles>');
      buffer.writeln('    <Totales>');
      buffer.writeln(
          '      <Total>${venta.total.toStringAsFixed(2)}</Total>');
      if (venta.moneda != null) {
        buffer.writeln('      <Moneda>${venta.moneda}</Moneda>');
      }
      buffer.writeln('    </Totales>');
      buffer.writeln('  </Encabezado>');
      buffer.writeln('</FacturaElectronica>');

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/factura_${venta.id}.xml';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [
          XFile(filePath,
              mimeType: 'application/xml',
              name: 'factura_${venta.id}.xml')
        ],
        text: 'Factura Electrónica ONAT',
      );
      mostrarSnackBar(
          mensaje: 'XML generado y compartido', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _generandoXML = false);
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ============================================================
  //  GENERAR PDF
  // ============================================================
  Future<void> _generarPDF(Venta venta, AppProvider provider) async {
    setState(() => _generandoPDF = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TICKET DE VENTA',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(provider.nombreEmpresa ?? 'Mi Empresa',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha)}'),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text('Producto: ${venta.productoNombre}'),
                pw.Text('Cantidad: ${venta.cantidad}'),
                pw.Text(
                    'Precio unitario: \$${venta.precioUnitario.toStringAsFixed(2)}'),
                pw.SizedBox(height: 8),
                pw.Text('Total: \$${venta.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                if (venta.moneda != null)
                  pw.Text('Moneda: ${venta.moneda}'),
                if (venta.totalUSD != null)
                  pw.Text(
                      'Total USD: \$${venta.totalUSD!.toStringAsFixed(2)}'),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Text('Método de pago: ${venta.metodoPago}'),
                pw.SizedBox(height: 20),
                pw.Text('¡Gracias por su compra!',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey700)),
              ],
            );
          },
        ),
      );
      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/ticket_${venta.id}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [
          XFile(filePath,
              mimeType: 'application/pdf',
              name: 'ticket_${venta.id}.pdf')
        ],
        text: 'Ticket de venta',
      );
      mostrarSnackBar(
          mensaje: 'PDF generado y compartido', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
    } finally {
      if (mounted) setState(() => _generandoPDF = false);
    }
  }
}