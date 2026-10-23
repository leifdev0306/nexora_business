// lib/screens/printer_settings_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_monster/flutter_pos_printer_platform.dart';
import '../main.dart';
import '../services/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _service = PrinterService.instance;
  final List<PrinterDevice> _devices = [];
  PrinterDevice? _selected;
  bool _scanning = false;
  bool _connecting = false;
  String? _error;

  StreamSubscription<PrinterDevice>? _scanSub;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  void _scan() {
    setState(() {
      _scanning = true;
      _connecting = false;
      _error = null;
      _devices.clear();
    });

    _timeout?.cancel();
    try {
      _scanSub?.cancel();
    } catch (_) {}

    try {
      _scanSub = _service.discoverUsb().listen(
        (device) {
          if (!mounted) return;
          setState(() => _devices.add(device));
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _error = e.toString());
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _scanning = false);
        },
      );

      _timeout = Timer(const Duration(seconds: 6), () {
        if (mounted && _scanning) {
          setState(() => _scanning = false);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _connect(PrinterDevice device) async {
    if (_connecting) return;
    setState(() => _connecting = true);

    try {
      // Cancelar escaneo antes de conectar (evita race condition)
      try {
        await _scanSub?.cancel();
      } catch (_) {}
      _scanSub = null;
      _timeout?.cancel();
      _timeout = null;

      final ok = await _service.connect(device);

      if (!mounted) return;

      if (ok) {
        setState(() {
          _selected = device;
          _connecting = false;
        });
        mostrarSnackBar(
          mensaje: 'Impresora conectada: ${device.name ?? "USB"}',
          esExito: true,
        );
      } else {
        setState(() => _connecting = false);
        mostrarSnackBar(
          mensaje: 'No se pudo conectar. Verifica el cable USB/OTG.',
          esExito: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error al conectar: $e');
      if (mounted) {
        setState(() => _connecting = false);
        mostrarSnackBar(
          mensaje: 'Error al conectar: $e',
          esExito: false,
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      _scanSub?.cancel();
    } catch (_) {}
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
    final surface = isDark ? const Color(0xFF122340) : Colors.white;
    final surface2 =
        isDark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
    final textHigh = isDark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
    final textMid = isDark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
    final textMuted = isDark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
    final border = isDark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);

    const primary = Color(0xFF1A5CFF);
    const success = Color(0xFF10B981);
    const danger = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: textHigh,
        elevation: 0,
        title: const Text(
          'Impresora',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Sección 1: Buscar impresoras
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.usb_rounded,
                          color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. Conecta la impresora',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Por cable USB/OTG',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(
                      _scanning ? 'Buscando…' : 'Buscar impresoras',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Error de escaneo
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: danger.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: danger.withOpacity(.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Lista de dispositivos
          if (_devices.isEmpty && !_scanning && _error == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Icon(Icons.print_disabled_rounded,
                      size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No se encontraron impresoras',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: textHigh,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Verifica el cable USB/OTG y que la impresora esté encendida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Cards de dispositivos
          ..._devices.map((d) {
            final name = d.name ?? 'Impresora USB';
            final isSelected = _selected?.name == d.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _connecting ? null : () => _connect(d),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? success.withOpacity(.50)
                            : border,
                        width: isSelected ? 1.6 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.print_rounded,
                              color: primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textHigh,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'VID: ${d.vendorId ?? '—'} · '
                                'PID: ${d.productId ?? '—'}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _connecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primary,
                                ),
                              )
                            : isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: success,
                                    size: 22,
                                  )
                                : Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: textMuted,
                                  ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // ─── Sección 2: Tamaño de papel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.receipt_rounded,
                          color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Tamaño de papel',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Según tu modelo de impresora',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
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
                      child: _paperBtn(
                        label: '58 mm',
                        sublabel: 'Compacta',
                        selected: _service.paperMm == 58,
                        onTap: () async {
                          await _service.setPaperMm(58);
                          setState(() {});
                        },
                        surface2: surface2,
                        border: border,
                        textHigh: textHigh,
                        textMuted: textMuted,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _paperBtn(
                        label: '80 mm',
                        sublabel: 'Estándar',
                        selected: _service.paperMm == 80,
                        onTap: () async {
                          await _service.setPaperMm(80);
                          setState(() {});
                        },
                        surface2: surface2,
                        border: border,
                        textHigh: textHigh,
                        textMuted: textMuted,
                        primary: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── Info general
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La configuración se guarda automáticamente. La impresora se reconectará la próxima vez que abras la app.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMid,
                      height: 1.4,
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

  Widget _paperBtn({
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
    required Color surface2,
    required Color border,
    required Color textHigh,
    required Color textMuted,
    required Color primary,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(.10) : surface2,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_rounded,
                    size: 16,
                    color: selected ? primary : textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? primary : textHigh,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: primary),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}