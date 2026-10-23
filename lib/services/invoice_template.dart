// lib/services/invoice_template.dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../main.dart' show Venta;

class InvoiceTemplate {
  static Future<List<int>> build({
    required Venta venta,
    required List<Map<String, dynamic>> items,
    required String empresaNombre,
    String? empresaDireccion,
    String? empresaTelefono,
    String? clienteNombre,
    double subtotal = 0,
    double descuento = 0,
    double impuesto = 0,
    int paperMm = 58,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);

    List<int> bytes = [];

    bytes += generator.text(
      empresaNombre.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    if (empresaDireccion != null && empresaDireccion.trim().isNotEmpty) {
      bytes += generator.text(
        empresaDireccion,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }
    if (empresaTelefono != null && empresaTelefono.trim().isNotEmpty) {
      bytes += generator.text(
        'Tel: $empresaTelefono',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      );
    }

    bytes += generator.hr(ch: '-');

    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha);
    bytes += generator.text(
      'Fecha: $fecha',
      styles: const PosStyles(fontType: PosFontType.fontB),
    );
    final ventaIdCorto = venta.id.length >= 8
        ? venta.id.substring(0, 8).toUpperCase()
        : venta.id.toUpperCase();
    bytes += generator.text(
      'Venta: $ventaIdCorto',
      styles: const PosStyles(fontType: PosFontType.fontB),
    );

    if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
      bytes += generator.text(
        'Cliente: $clienteNombre',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
    }

    bytes += generator.hr(ch: '-');

    bytes += generator.text(
      'CANT  DESCRIPCION            TOTAL',
      styles: const PosStyles(
        bold: true,
        fontType: PosFontType.fontB,
      ),
    );
    bytes += generator.hr(ch: '-');

    for (final item in items) {
      final nombre = (item['nombre'] as String? ?? 'Producto');
      final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 0;
      final total = (item['total'] as num?)?.toDouble() ?? 0;

      final qty = cantidad.toStringAsFixed(cantidad % 1 == 0 ? 0 : 1);
      final totalStr = '\$${total.toStringAsFixed(2)}';

      final descWidth = paperMm == 80 ? 28 : 16;
      final desc = nombre.length > descWidth
          ? '${nombre.substring(0, descWidth - 1)}…'
          : nombre;
      final line = '$qty'.padRight(5) + desc.padRight(descWidth) + totalStr;

      bytes += generator.text(
        line,
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
    }

    bytes += generator.hr(ch: '-');

    if (subtotal > 0 && (descuento > 0 || impuesto > 0)) {
      bytes += generator.text(
        'Subtotal: \$${subtotal.toStringAsFixed(2)}',
        styles: const PosStyles(
          align: PosAlign.right,
          fontType: PosFontType.fontB,
        ),
      );
    }
    if (descuento > 0) {
      bytes += generator.text(
        'Descuento: -\$${descuento.toStringAsFixed(2)}',
        styles: const PosStyles(
          align: PosAlign.right,
          fontType: PosFontType.fontB,
        ),
      );
    }
    if (impuesto > 0) {
      bytes += generator.text(
        'Impuesto: \$${impuesto.toStringAsFixed(2)}',
        styles: const PosStyles(
          align: PosAlign.right,
          fontType: PosFontType.fontB,
        ),
      );
    }

    bytes += generator.text(
      'TOTAL: \$${venta.total.toStringAsFixed(2)}',
      styles: const PosStyles(
        align: PosAlign.right,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      'Pago: ${venta.metodoPago}',
      styles: const PosStyles(fontType: PosFontType.fontB),
    );

    if (venta.nota != null && venta.nota!.trim().isNotEmpty) {
      bytes += generator.text(
        'Nota: ${venta.nota}',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
    }

    bytes += generator.hr(ch: '-');

    bytes += generator.text(
      '¡Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Nexora Business',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}