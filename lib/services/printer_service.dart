// lib/services/printer_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_monster/flutter_pos_printer_platform.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart' show Venta, mostrarSnackBar;
import 'invoice_template.dart';

/// Estado del servicio de impresión.
enum PrinterStatus { unknown, connected, disconnected, unavailable }

/// Servicio singleton de impresión térmica USB.
///
/// - Auto-inicializa al primer acceso (detección + reconexión con la guardada).
/// - Health check cada 45 s para detectar desconexiones.
/// - `ensureReady()` verifica disponibilidad antes de imprimir.
/// - `printSale()` avisa al usuario si no hay impresora.
class PrinterService extends ChangeNotifier {
  PrinterService._() {
    _bootstrap();
  }
  static final PrinterService instance = PrinterService._();

  final PrinterManager _manager = PrinterManager.instance;
  Box<dynamic>? _settingsCache;

  Box<dynamic> get _settings =>
      _settingsCache ??= Hive.box<dynamic>('settings');

  static const String _kPrinterName = 'printer_name';
  static const String _kPrinterVendorId = 'printer_vendor_id';
  static const String _kPrinterProductId = 'printer_product_id';
  static const String _kPaperMm = 'printer_paper_mm';

  bool _connected = false;
  bool _scanning = false;
  bool _initialized = false;
  bool _initializing = false;

  PrinterDevice? _device;
  List<PrinterDevice> _available = const [];
  Timer? _healthTimer;
  DateTime? _lastCheck;

  bool get isConnected => _connected;
  bool get isScanning => _scanning;
  bool get isInitialized => _initialized;
  bool get isAvailable => _available.isNotEmpty;
  PrinterDevice? get device => _device;
  List<PrinterDevice> get availablePrinters => List.unmodifiable(_available);
  DateTime? get lastCheck => _lastCheck;

  int get paperMm => (_settings.get(_kPaperMm) as int?) ?? 58;

  Future<void> setPaperMm(int mm) async {
    await _settings.put(_kPaperMm, mm == 80 ? 80 : 58);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  //  Descubrimiento
  // ─────────────────────────────────────────────────
  Stream<PrinterDevice> discoverUsb() {
    return _manager.discovery(type: PrinterType.usb);
  }

  /// Escanea USB durante [timeout] y devuelve los dispositivos encontrados.
  /// Si [notify] es false, no dispara `notifyListeners` (para health checks).
  Future<List<PrinterDevice>> scanUsb({
    Duration timeout = const Duration(seconds: 3),
    bool notify = true,
  }) async {
    final found = <PrinterDevice>[];
    if (notify) {
      _scanning = true;
      notifyListeners();
    }

    StreamSubscription<PrinterDevice>? sub;
    try {
      sub = _manager.discovery(type: PrinterType.usb).listen(
        (d) {
          if (!found.any((x) => _sameDevice(x, d))) found.add(d);
        },
        onError: (e) => debugPrint('⚠️ scanUsb: $e'),
      );
      await Future.delayed(timeout);
    } catch (e) {
      debugPrint('⚠️ scanUsb: $e');
    } finally {
      await sub?.cancel();
    }

    _available = found;
    _lastCheck = DateTime.now();
    if (notify) {
      _scanning = false;
      notifyListeners();
    }
    return found;
  }

  bool _sameDevice(PrinterDevice a, PrinterDevice b) {
    if (a.name != null && b.name != null && a.name == b.name) return true;
    return a.vendorId == b.vendorId && a.productId == b.productId;
  }

  // ─────────────────────────────────────────────────
  //  Conexión
  // ─────────────────────────────────────────────────
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
      notifyListeners();

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
      _device = null;
      notifyListeners();
      return false;
    }
  }

  /// Intenta conectarse a la impresora guardada.
  /// Si [rescan] es true, escanea USB primero para confirmar que existe.
  Future<bool> autoConnect({bool rescan = false}) async {
    if (_connected && !rescan) return true;

    final name = _settings.get(_kPrinterName) as String?;
    final vendorId = _settings.get(_kPrinterVendorId) as String?;
    final productId = _settings.get(_kPrinterProductId) as String?;

    if (name == null) {
      _connected = false;
      notifyListeners();
      return false;
    }

    final encontrados = await scanUsb(
      timeout: const Duration(seconds: 2),
      notify: false,
    );

    PrinterDevice? match;
    for (final d in encontrados) {
      if (d.name == name ||
          (d.vendorId != null &&
              vendorId != null &&
              productId != null &&
              d.vendorId == vendorId &&
              d.productId == productId)) {
        match = d;
        break;
      }
    }

    if (match == null) {
      _connected = false;
      notifyListeners();
      return false;
    }

    return connect(match);
  }

  Future<void> disconnect() async {
    try {
      await _manager.disconnect(type: PrinterType.usb);
    } catch (_) {}
    _connected = false;
    _device = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────
  //  Detección automática
  // ─────────────────────────────────────────────────
  /// Inicializa el servicio (detección + reconexión + health check).
  Future<void> initialize() async {
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_initializing) return;
    _initializing = true;

    try {
      // Esperar a que Hive esté listo (por si se llama muy temprano)
      if (!Hive.isBoxOpen('settings')) {
        for (int i = 0; i < 10 && !Hive.isBoxOpen('settings'); i++) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
      if (!Hive.isBoxOpen('settings')) {
        debugPrint('⚠️ PrinterService: caja "settings" no disponible.');
        return;
      }

      await autoConnect(rescan: true);
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ bootstrap impresora: $e');
      _initialized = true;
    } finally {
      _initializing = false;
      _scheduleHealthCheck();
    }
  }

  void _scheduleHealthCheck() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      try {
        if (_connected) {
          final still = await _isDeviceStillPresent();
          if (!still) {
            _connected = false;
            _device = null;
            notifyListeners();
          }
        } else {
          final saved = _settings.get(_kPrinterName) as String?;
          if (saved != null) {
            await autoConnect(rescan: true);
          }
        }
      } catch (e) {
        debugPrint('⚠️ health check impresora: $e');
      }
    });
  }

  Future<bool> _isDeviceStillPresent() async {
    final name = _device?.name ?? _settings.get(_kPrinterName) as String?;
    if (name == null) return false;

    final found = await scanUsb(
      timeout: const Duration(milliseconds: 1500),
      notify: false,
    );
    if (found.isEmpty) return false;

    final vId = _device?.vendorId;
    final pId = _device?.productId;
    return found.any((d) {
      if (d.name == name) return true;
      return vId != null &&
          pId != null &&
          d.vendorId == vId &&
          d.productId == pId;
    });
  }

  /// Verifica disponibilidad real y reconecta si es posible.
  /// Devuelve true si la impresora está lista para imprimir.
  Future<bool> ensureReady({bool silent = true}) async {
    if (_connected) {
      final still = await _isDeviceStillPresent();
      if (still) return true;
      _connected = false;
      _device = null;
      notifyListeners();
    }

    final ok = await autoConnect(rescan: true);
    if (!ok && !silent) {
      debugPrint('⚠️ No hay impresora disponible');
    }
    return ok;
  }

  // ─────────────────────────────────────────────────
  //  Impresión
  // ─────────────────────────────────────────────────
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
    final ready = await ensureReady(silent: false);
    if (!ready) {
      mostrarSnackBar(
        mensaje:
            'No hay impresora conectada o disponible. Verifica el cable USB y que esté encendida.',
        esExito: false,
      );
      return false;
    }

    List<int>? bytes;
    try {
      bytes = await InvoiceTemplate.build(
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

      // Un reintento tras reconectar
      try {
        _connected = false;
        _device = null;
        final reconectado = await autoConnect(rescan: true);
        if (reconectado && bytes != null) {
          await _manager.send(type: PrinterType.usb, bytes: bytes);
          return true;
        }
      } catch (retryErr) {
        debugPrint('⚠️ Reintento de impresión falló: $retryErr');
      }

      mostrarSnackBar(
        mensaje: 'Error al imprimir: $e',
        esExito: false,
      );
      return false;
    }
  }

  void disposeService() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }
}