// lib/services/printer_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_monster/flutter_pos_printer_platform.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart' show Venta, mostrarSnackBar;
import 'invoice_template.dart';

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  final PrinterManager _manager = PrinterManager.instance;
  final Box<dynamic> _settings = Hive.box<dynamic>('settings');

  static const String _kPrinterName = 'printer_name';
  static const String _kPrinterVendorId = 'printer_vendor_id';
  static const String _kPrinterProductId = 'printer_product_id';
  static const String _kPaperMm = 'printer_paper_mm';

  bool _connected = false;
  PrinterDevice? _device;

  bool get isConnected => _connected;
  PrinterDevice? get device => _device;

  int get paperMm => (_settings.get(_kPaperMm) as int?) ?? 58;

  Future<void> setPaperMm(int mm) async {
    await _settings.put(_kPaperMm, mm == 80 ? 80 : 58);
  }

  Stream<PrinterDevice> discoverUsb() {
    return _manager.discovery(type: PrinterType.usb);
  }

  Future<bool> connect(PrinterDevice device) async {
    try {
      await _manager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: device.name,
          productId: device.productId,
          vendorId: device.vendorId,
        ),
      );
      _device = device;
      _connected = true;

      await Future.delayed(const Duration(milliseconds: 300));

      await _settings.put(_kPrinterName, device.name);
      if (device.vendorId != null) {
        await _settings.put(_kPrinterVendorId, device.vendorId);
      }
      if (device.productId != null) {
        await _settings.put(_kPrinterProductId, device.productId);
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error al conectar impresora: $e');
      _connected = false;
      return false;
    }
  }

  Future<bool> autoConnect() async {
    final name = _settings.get(_kPrinterName) as String?;
    final vendorId = _settings.get(_kPrinterVendorId) as String?;
    final productId = _settings.get(_kPrinterProductId) as String?;

    if (name == null) return false;

    try {
      await _manager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: name,
          productId: productId,
          vendorId: vendorId,
        ),
      );
      _connected = true;
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      debugPrint('⚠️ Auto-connect falló: $e');
      _connected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _manager.disconnect(type: PrinterType.usb);
    } catch (_) {}
    _connected = false;
    _device = null;
  }

  Future<bool> printSale({
    required Venta venta,
    required List<Map<String, dynamic>> items,
    required String empresaNombre,
    String? empresaDireccion,
    String? empresaTelefono,
    String? clienteNombre,
    double subtotal = 0,
    double descuento = 0,
    double impuesto = 0,
  }) async {
    if (!_connected) {
      final ok = await autoConnect();
      if (!ok) {
        mostrarSnackBar(
          mensaje: 'No hay impresora conectada. Configúrala en Ajustes → Impresora.',
          esExito: false,
        );
        return false;
      }
    }

    try {
      final bytes = await InvoiceTemplate.build(
        venta: venta,
        items: items,
        empresaNombre: empresaNombre,
        empresaDireccion: empresaDireccion,
        empresaTelefono: empresaTelefono,
        clienteNombre: clienteNombre,
        subtotal: subtotal,
        descuento: descuento,
        impuesto: impuesto,
        paperMm: paperMm,
      );

      await _manager.send(type: PrinterType.usb, bytes: bytes);
      return true;
    } catch (e) {
      debugPrint('❌ Error al imprimir: $e');
      mostrarSnackBar(
        mensaje: 'Error al imprimir: $e',
        esExito: false,
      );
      return false;
    }
  }
}