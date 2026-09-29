// ============================================================
//  nuevo_producto_screen.dart  ·  NEXORA BUSINESS
//  Crear / editar producto con imagen (galería + cámara)
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

// ============================================================
//  PALETA NEXORA
// ============================================================
class _N {
  static const primary = Color(0xFF5B5BFF);
  static const primaryDark = Color(0xFF3B3BE8);
  static const accent = Color(0xFFFF4D8D);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF06B6D4);

  static const bgLight = Color(0xFFF4F6FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE8ECF4);

  static const bgDark = Color(0xFF0A0E1A);
  static const surfaceDark = Color(0xFF131A2A);
  static const surfaceDark2 = Color(0xFF1B2438);
  static const borderDark = Color(0xFF26314A);

  static const textLight = Color(0xFF0B1120);
  static const textSoftLight = Color(0xFF5B6780);
  static const textMuteLight = Color(0xFF8E99AE);
  static const textDark = Color(0xFFF1F4FA);
  static const textSoftDark = Color(0xFF9CA7BF);
  static const textMuteDark = Color(0xFF6A7590);
}

// ============================================================
//  SCREEN
// ============================================================
class NuevoProductoScreen extends StatefulWidget {
  final Producto? producto;
  const NuevoProductoScreen({Key? key, this.producto}) : super(key: key);

  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _precioTransferenciaCtrl = TextEditingController();
  final _precioMayoristaEfectivoCtrl = TextEditingController();
  final _precioMayoristaTransferenciaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  String _unidadMedida = 'unidad';
  String? _categoriaId;
  String? _sucursalId;
  Producto? _editando;
  bool _isSaving = false;
  bool _loaded = false;

  // ─── Imagen
  File? _imagenLocal;
  String? _imagenUrlActual;
  bool _subiendoImagen = false;
  double _uploadProgress = 0.0;

  // ─── Gestión de foco
  final _nombreFocus = FocusNode();

  bool get _isEditing => _editando != null;
  bool get _tieneImagen =>
      _imagenLocal != null ||
      (_imagenUrlActual != null && _imagenUrlActual!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      _editando = widget.producto;
      _cargarDatosProducto(_editando!);
      _loaded = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args != null && args is Producto) {
          _editando = args;
          _cargarDatosProducto(_editando!);
          if (mounted) setState(() => _loaded = true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant NuevoProductoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.producto != oldWidget.producto && widget.producto != null) {
      _editando = widget.producto;
      _cargarDatosProducto(_editando!);
      setState(() => _loaded = true);
    }
  }

  void _cargarDatosProducto(Producto producto) {
    _nombreCtrl.text = producto.nombre;
    double precioCompraActual = producto.precioCompra;
    if (producto.lotes.isNotEmpty) {
      final ultimoLote = producto.lotes.last;
      precioCompraActual = (ultimoLote['precioCompra'] as num).toDouble();
    }
    _precioCompraCtrl.text = precioCompraActual.toStringAsFixed(2);
    _precioVentaCtrl.text = producto.precioVenta.toStringAsFixed(2);
    _precioTransferenciaCtrl.text =
        (producto.precioTransferencia == producto.precioVenta)
            ? ''
            : producto.precioTransferencia.toStringAsFixed(2);
    _precioMayoristaEfectivoCtrl.text =
        (producto.precioMayoristaEfectivo == producto.precioVenta)
            ? ''
            : producto.precioMayoristaEfectivo.toStringAsFixed(2);
    _precioMayoristaTransferenciaCtrl.text =
        (producto.precioMayoristaTransferencia == producto.precioVenta)
            ? ''
            : producto.precioMayoristaTransferencia.toStringAsFixed(2);
    _stockCtrl.text = producto.stock.toString();
    _unidadMedida = producto.unidadMedida;
    _categoriaId = producto.categoriaId;
    _sucursalId = producto.sucursalId;
    _imagenUrlActual = producto.imageUrl;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    _precioTransferenciaCtrl.dispose();
    _precioMayoristaEfectivoCtrl.dispose();
    _precioMayoristaTransferenciaCtrl.dispose();
    _stockCtrl.dispose();
    _nombreFocus.dispose();
    super.dispose();
  }

  // ============================================================
  //  IMAGEN
  // ============================================================
  Future<void> _pickImagen({required bool fromCamera}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 80,
      );
      if (picked == null) return;

      final file = File(picked.path);
      // Validar tamaño (5 MB max igual que el bucket)
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        mostrarSnackBar(
          mensaje: 'La imagen pesa más de 5 MB. Elige una más pequeña.',
          esExito: false,
        );
        return;
      }

      setState(() => _imagenLocal = file);
    } catch (e) {
      mostrarSnackBar(
        mensaje: 'No se pudo abrir la imagen: ${mensajeAmigable(e)}',
        esExito: false,
      );
    }
  }

  void _mostrarFuenteImagen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soportaCamara = Platform.isAndroid || Platform.isIOS;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? _N.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? _N.borderDark : _N.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto del producto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? _N.textDark : _N.textLight,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _N.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: _N.primary, size: 22),
                ),
                title: Text(
                  'Elegir de la galería',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? _N.textDark : _N.textLight,
                  ),
                ),
                subtitle: Text(
                  'Selecciona una imagen existente',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? _N.textSoftDark : _N.textSoftLight,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImagen(fromCamera: false);
                },
              ),
              if (soportaCamara)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _N.accent.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        color: _N.accent, size: 22),
                  ),
                  title: Text(
                    'Tomar foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? _N.textDark : _N.textLight,
                    ),
                  ),
                  subtitle: Text(
                    'Usa la cámara del dispositivo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? _N.textSoftDark : _N.textSoftLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImagen(fromCamera: true);
                  },
                ),
              if (_tieneImagen)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _N.danger.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _N.danger, size: 22),
                  ),
                  title: Text(
                    'Eliminar foto',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _N.danger,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imagenLocal = null;
                      _imagenUrlActual = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sube la imagen nueva si hace falta. Devuelve la URL final.
  Future<String?> _subirImagenSiHaceFalta() async {
    if (_imagenLocal == null) return _imagenUrlActual;

    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.empresaId == null) {
      mostrarSnackBar(
        mensaje: 'No se pudo identificar la empresa.',
        esExito: false,
      );
      return _imagenUrlActual;
    }

    setState(() {
      _subiendoImagen = true;
      _uploadProgress = 0.1;
    });

    try {
      final bytes = await _imagenLocal!.readAsBytes();
      final ext = _imagenLocal!.path.split('.').last.toLowerCase();
      final safeExt =
          ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final fileName = '${const Uuid().v4()}.$safeExt';
      final path = '${provider.empresaId}/$fileName';

      setState(() => _uploadProgress = 0.3);

      final storage = Supabase.instance.client.storage;

      // Upload
      await storage.from('product-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$safeExt',
              upsert: true,
            ),
          );

      setState(() => _uploadProgress = 0.9);

      // Obtener URL pública
      final url = storage.from('product-images').getPublicUrl(path);

      setState(() => _uploadProgress = 1.0);
      return url;
    } catch (e) {
      print('⚠️ Error subiendo imagen: $e');

      // Detectar bucket inexistente
      final errStr = e.toString().toLowerCase();
      String mensaje;
      if (errStr.contains('bucket') && errStr.contains('not found') ||
          errStr.contains('does not exist')) {
        mensaje =
            'El bucket "product-images" no existe en el servidor. Contacta a soporte.';
      } else if (errStr.contains('exceeded') ||
          errStr.contains('payload too large') ||
          errStr.contains('too large')) {
        mensaje = 'La imagen pesa más de 5 MB. Elige una más pequeña.';
      } else if (errStr.contains('mime') || errStr.contains('content type')) {
        mensaje = 'Formato no soportado. Usa JPG, PNG o WEBP.';
      } else if (errStr.contains('row-level security') ||
          errStr.contains('permission') ||
          errStr.contains('unauthorized')) {
        mensaje = 'No tienes permisos para subir la imagen.';
      } else {
        mensaje = 'No se pudo subir la imagen: ${mensajeAmigable(e)}';
      }

      mostrarSnackBar(mensaje: mensaje, esExito: false);
      return _imagenUrlActual;
    } finally {
      if (mounted) {
        setState(() {
          _subiendoImagen = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  // ============================================================
  //  SUGERENCIA DE PRECIO
  // ============================================================
  double _redondearPorExceso(double valor) {
    if (valor <= 0) return 0.0;
    return (valor / 10).ceil() * 10.0;
  }

  void _sugerirPrecioVenta(String _) {
    final textoCompra = _precioCompraCtrl.text.replaceAll(',', '.').trim();
    final precioCompra = double.tryParse(textoCompra);
    if (precioCompra == null || precioCompra <= 0) return;
    final sugerido = _redondearPorExceso(precioCompra * 1.40);
    if (sugerido > 0) {
      _precioVentaCtrl.text = sugerido.toStringAsFixed(0);
    }
    setState(() {});
  }

  double get _precioVentaFinal =>
      double.tryParse(_precioVentaCtrl.text) ?? 0.0;

  double get _precioTransferenciaFinal {
    final txt = _precioTransferenciaCtrl.text.trim();
    return txt.isNotEmpty ? double.parse(txt) : _precioVentaFinal;
  }

  double get _precioMayoristaEfectivoFinal {
    final txt = _precioMayoristaEfectivoCtrl.text.trim();
    return txt.isNotEmpty ? double.parse(txt) : _precioVentaFinal;
  }

  double get _precioMayoristaTransferenciaFinal {
    final txt = _precioMayoristaTransferenciaCtrl.text.trim();
    return txt.isNotEmpty ? double.parse(txt) : _precioTransferenciaFinal;
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    final isAdmin = provider.rol == 'admin' || provider.rol == 'dueno';
    final esGestor = provider.rol == 'gestor' || provider.rol == 'gerente';

    if (esGestor && _sucursalId == null) {
      _sucursalId = provider.sucursalIdUsuario;
    }

    if (_isEditing && !_loaded) {
      return Scaffold(
        backgroundColor: isDark ? _N.bgDark : _N.bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _N.bgDark : _N.bgLight,
      appBar: _buildAppBar(context, isDark, isDesktop),
      body: Stack(
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _N.primary.withOpacity(isDark ? .12 : .06),
                      _N.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isSaving
                ? _buildSavingOverlay(isDark)
                : isDesktop
                    ? _buildDesktopBody(
                        context, provider, isDark, isAdmin, esGestor)
                    : _buildMobileBody(
                        context, provider, isDark, isAdmin, esGestor),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _subiendoImagen
                ? 'Subiendo imagen… ${(_uploadProgress * 100).toInt()}%'
                : 'Guardando producto…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? _N.textDark : _N.textLight,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, bool isDesktop) {
    return AppBar(
      backgroundColor: isDark ? _N.surfaceDark : Colors.white,
      foregroundColor: isDark ? _N.textDark : _N.textLight,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? _N.textDark : _N.textLight,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_N.primary, _N.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _N.primary.withOpacity(.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isEditing ? 'Editar producto' : 'Nuevo producto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                  color: isDark ? _N.textDark : _N.textLight,
                ),
              ),
              Text(
                _isEditing
                    ? 'Modifica la información del producto'
                    : 'Completa los datos para crearlo',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? _N.textSoftDark : _N.textSoftLight,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _guardar,
              icon: Icon(
                  _isEditing ? Icons.save_rounded : Icons.add_rounded,
                  size: 18),
              label: Text(_isEditing ? 'Actualizar' : 'Crear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? _N.primary : _N.success,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  //  DESKTOP
  // ------------------------------------------------------------
  Widget _buildDesktopBody(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    bool isAdmin,
    bool esGestor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _sectionCard(
                    title: 'Información básica',
                    subtitle: 'Nombre, foto y clasificación',
                    icon: Icons.info_outline_rounded,
                    isDark: isDark,
                    children: [
                      _imagenPicker(isDark, grande: true),
                      const SizedBox(height: 18),
                      _inputField(
                        controller: _nombreCtrl,
                        focusNode: _nombreFocus,
                        label: 'Nombre del producto',
                        icon: Icons.text_fields_rounded,
                        isDark: isDark,
                        required: true,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Ingresa el nombre'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _unidadSelector(isDark, provider),
                      const SizedBox(height: 14),
                      _categoriaSelector(isDark, provider),
                      if (isAdmin || esGestor) ...[
                        const SizedBox(height: 14),
                        _sucursalSelector(isDark, provider),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: _isEditing ? 'Stock actual' : 'Stock inicial',
                    subtitle: _isEditing
                        ? 'El stock solo cambia por ventas, mermas o reabastecimiento'
                        : 'Cantidad disponible en esta sucursal',
                    icon: Icons.inventory_2_rounded,
                    isDark: isDark,
                    children: [
                      _inputField(
                        controller: _stockCtrl,
                        label: 'Cantidad',
                        icon: Icons.inventory_rounded,
                        isDark: isDark,
                        required: true,
                        enabled: !_isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Requerido';
                          final n = double.tryParse(v!);
                          if (n == null || n < 0) return 'Cantidad ≥ 0';
                          return null;
                        },
                      ),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 14, color: _N.info),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Para modificar el stock usa "Merma" o "Reabastecer".',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? _N.textSoftDark
                                        : _N.textSoftLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: _sectionCard(
                title: 'Estructura de precios',
                subtitle: 'Configura los precios para cada método de pago',
                icon: Icons.attach_money_rounded,
                isDark: isDark,
                children: [
                  if (isAdmin || esGestor) ...[
                    _inputField(
                      controller: _precioCompraCtrl,
                      label: 'Precio de compra (CUP)',
                      icon: Icons.arrow_downward_rounded,
                      isDark: isDark,
                      required: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      hintText: _editando?.lotes.isNotEmpty == true
                          ? 'Último lote: \$${(_editando!.lotes.last['precioCompra'] as num).toStringAsFixed(2)}'
                          : null,
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Requerido';
                        final n = double.tryParse(v!);
                        if (n == null || n <= 0) return 'Precio > 0';
                        return null;
                      },
                      onChanged: _sugerirPrecioVenta,
                    ),
                    const SizedBox(height: 18),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _priceColumn(
                          title: 'Minorista',
                          subtitle: 'Venta al público',
                          color: _N.primary,
                          isDark: isDark,
                          children: [
                            _inputField(
                              controller: _precioVentaCtrl,
                              label: 'Efectivo',
                              icon: Icons.payments_rounded,
                              isDark: isDark,
                              required: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (v) {
                                if ((v ?? '').isEmpty) return 'Requerido';
                                final n = double.tryParse(v!);
                                if (n == null || n <= 0) return 'Precio > 0';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            _inputField(
                              controller: _precioTransferenciaCtrl,
                              label: 'Transferencia',
                              icon: Icons.credit_card_rounded,
                              isDark: isDark,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              hintText: 'Opcional',
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _priceColumn(
                          title: 'Mayorista',
                          subtitle: 'Ventas por volumen',
                          color: _N.accent,
                          isDark: isDark,
                          children: [
                            _inputField(
                              controller: _precioMayoristaEfectivoCtrl,
                              label: 'Efectivo',
                              icon: Icons.shopping_bag_rounded,
                              isDark: isDark,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              hintText: 'Opcional',
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            _inputField(
                              controller: _precioMayoristaTransferenciaCtrl,
                              label: 'Transferencia',
                              icon: Icons.payment_rounded,
                              isDark: isDark,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              hintText: 'Opcional',
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _pricePreview(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  MOBILE
  // ------------------------------------------------------------
  Widget _buildMobileBody(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    bool isAdmin,
    bool esGestor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _sectionCard(
              title: 'Información básica',
              subtitle: 'Foto, nombre y clasificación',
              icon: Icons.info_outline_rounded,
              isDark: isDark,
              children: [
                _imagenPicker(isDark),
                const SizedBox(height: 16),
                _inputField(
                  controller: _nombreCtrl,
                  focusNode: _nombreFocus,
                  label: 'Nombre del producto',
                  icon: Icons.text_fields_rounded,
                  isDark: isDark,
                  required: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 12),
                _unidadSelector(isDark, provider),
                const SizedBox(height: 12),
                _categoriaSelector(isDark, provider),
                if (isAdmin || esGestor) ...[
                  const SizedBox(height: 12),
                  _sucursalSelector(isDark, provider),
                ],
              ],
            ),
            const SizedBox(height: 14),

            _sectionCard(
              title: 'Precios',
              subtitle: 'Configura cada método de pago',
              icon: Icons.attach_money_rounded,
              isDark: isDark,
              children: [
                if (isAdmin || esGestor) ...[
                  _inputField(
                    controller: _precioCompraCtrl,
                    label: 'Precio de compra (CUP)',
                    icon: Icons.arrow_downward_rounded,
                    isDark: isDark,
                    required: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    hintText: _editando?.lotes.isNotEmpty == true
                        ? 'Último: \$${(_editando!.lotes.last['precioCompra'] as num).toStringAsFixed(2)}'
                        : null,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Requerido';
                      final n = double.tryParse(v!);
                      if (n == null || n <= 0) return 'Precio > 0';
                      return null;
                    },
                    onChanged: _sugerirPrecioVenta,
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _priceColumn(
                        title: 'Minorista',
                        subtitle: null,
                        color: _N.primary,
                        isDark: isDark,
                        compact: true,
                        children: [
                          _inputField(
                            controller: _precioVentaCtrl,
                            label: 'Efectivo',
                            icon: Icons.payments_rounded,
                            isDark: isDark,
                            required: true,
                            compact: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (v) {
                              if ((v ?? '').isEmpty) return 'Requerido';
                              final n = double.tryParse(v!);
                              if (n == null || n <= 0) return '> 0';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          _inputField(
                            controller: _precioTransferenciaCtrl,
                            label: 'Transferencia',
                            icon: Icons.credit_card_rounded,
                            isDark: isDark,
                            compact: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            hintText: 'Opcional',
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _priceColumn(
                        title: 'Mayorista',
                        subtitle: null,
                        color: _N.accent,
                        isDark: isDark,
                        compact: true,
                        children: [
                          _inputField(
                            controller: _precioMayoristaEfectivoCtrl,
                            label: 'Efectivo',
                            icon: Icons.shopping_bag_rounded,
                            isDark: isDark,
                            compact: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            hintText: 'Opcional',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          _inputField(
                            controller: _precioMayoristaTransferenciaCtrl,
                            label: 'Transferencia',
                            icon: Icons.payment_rounded,
                            isDark: isDark,
                            compact: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            hintText: 'Opcional',
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _pricePreview(isDark),
              ],
            ),
            const SizedBox(height: 14),

            _sectionCard(
              title: _isEditing ? 'Stock actual' : 'Stock inicial',
              subtitle: _isEditing
                  ? 'Solo se modifica desde ventas, mermas o reabastecimiento'
                  : 'Cantidad disponible',
              icon: Icons.inventory_2_rounded,
              isDark: isDark,
              children: [
                _inputField(
                  controller: _stockCtrl,
                  label: 'Cantidad',
                  icon: Icons.inventory_rounded,
                  isDark: isDark,
                  required: true,
                  enabled: !_isEditing,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'Requerido';
                    final n = double.tryParse(v!);
                    if (n == null || n < 0) return 'Cantidad ≥ 0';
                    return null;
                  },
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: _N.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Para modificar el stock usa "Merma" o "Reabastecer".',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? _N.textSoftDark
                                  : _N.textSoftLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _guardar,
                icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded,
                    size: 20),
                label: Text(
                  _isEditing ? 'Actualizar producto' : 'Crear producto',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? _N.primary : _N.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  IMAGEN PICKER (UI)
  // ------------------------------------------------------------
  Widget _imagenPicker(bool isDark, {bool grande = false}) {
    final size = grande ? 160.0 : 130.0;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _subiendoImagen ? null : _mostrarFuenteImagen,
            child: Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? _N.surfaceDark2 : _N.bgLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _tieneImagen
                          ? _N.primary.withOpacity(.55)
                          : _N.primary.withOpacity(.25),
                      width: 1.5,
                    ),
                  ),
                  child: !_tieneImagen
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_N.primary, _N.accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Añadir foto',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.2,
                                color: isDark ? _N.textDark : _N.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Galería o cámara',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? _N.textMuteDark
                                    : _N.textMuteLight,
                              ),
                            ),
                          ],
                        )
                      : _imagenPreview(),
                ),
                // Overlay de subida
                if (_subiendoImagen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                                value: _uploadProgress > 0
                                    ? _uploadProgress
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Subiendo…',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_tieneImagen && !_subiendoImagen) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniBtn(
                  icon: Icons.edit_rounded,
                  label: 'Cambiar',
                  color: _N.primary,
                  isDark: isDark,
                  onTap: _mostrarFuenteImagen,
                ),
                const SizedBox(width: 8),
                _miniBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Quitar',
                  color: _N.danger,
                  isDark: isDark,
                  onTap: () => setState(() {
                    _imagenLocal = null;
                    _imagenUrlActual = null;
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagenPreview() {
    if (_imagenLocal != null) {
      return Image.file(
        _imagenLocal!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.network(
      _imagenUrlActual!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (_, __, ___) => Container(
        color: _N.surfaceDark2,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: _N.textMuteDark,
          ),
        ),
      ),
    );
  }

  Widget _miniBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(isDark ? .16 : .10),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  WIDGETS AUXILIARES
  // ------------------------------------------------------------
  Widget _sectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? _N.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _N.borderDark : _N.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .25 : .03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  gradient: LinearGradient(
                    colors: [
                      _N.primary.withOpacity(.18),
                      _N.primary.withOpacity(.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _N.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.2,
                        color: isDark ? _N.textDark : _N.textLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? _N.textSoftDark : _N.textSoftLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _priceColumn({
    required String title,
    required String? subtitle,
    required Color color,
    required bool isDark,
    required List<Widget> children,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? .08 : .04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? _N.textSoftDark : _N.textSoftLight,
              ),
            ),
          ],
          SizedBox(height: compact ? 10 : 12),
          ...children,
        ],
      ),
    );
  }

  Widget _unidadSelector(bool isDark, AppProvider provider) {
    return _dropdownField<String>(
      value: _unidadMedida,
      label: 'Unidad de medida',
      icon: Icons.scale_rounded,
      isDark: isDark,
      items: const [
        'unidad',
        'kg',
        'g',
        'lb',
        'L',
        'mL',
        'm',
        'cm',
        'pieza',
        'docena',
        'caja',
        'paquete',
      ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => setState(() => _unidadMedida = v ?? 'unidad'),
    );
  }

  Widget _categoriaSelector(bool isDark, AppProvider provider) {
    return _dropdownField<String?>(
      value: _categoriaId,
      label: 'Categoría',
      icon: Icons.category_rounded,
      isDark: isDark,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Sin categoría'),
        ),
        ...provider.categorias.map(
          (c) => DropdownMenuItem<String?>(
            value: c.id,
            child: Text(c.nombre),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _categoriaId = v),
    );
  }

  Widget _sucursalSelector(bool isDark, AppProvider provider) {
    return _dropdownField<String?>(
      value: _sucursalId,
      label: 'Sucursal',
      icon: Icons.storefront_rounded,
      isDark: isDark,
      required: true,
      items: provider.sucursalesPermitidas.map((s) {
        return DropdownMenuItem<String?>(
          value: s.id,
          child: Text(s.nombre),
        );
      }).toList(),
      onChanged: (v) => setState(() => _sucursalId = v),
      validator: (v) => v == null ? 'Selecciona una sucursal' : null,
    );
  }

  Widget _dropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool required = false,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? _N.textSoftDark : _N.textSoftLight,
      ),
      dropdownColor: isDark ? _N.surfaceDark : Colors.white,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: isDark ? _N.textDark : _N.textLight,
      ),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? _N.textSoftDark : _N.textSoftLight,
        ),
        prefixIcon: Icon(icon, size: 19, color: _N.primary),
        filled: true,
        fillColor: isDark ? _N.surfaceDark2 : _N.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? _N.borderDark : _N.borderLight,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _N.primary, width: 1.6),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool required = false,
    bool compact = false,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? hintText,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        fontSize: compact ? 12.5 : 14,
        fontWeight: FontWeight.w600,
        color: enabled
            ? (isDark ? _N.textDark : _N.textLight)
            : (isDark ? _N.textMuteDark : _N.textMuteLight),
      ),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(
          fontSize: compact ? 11.5 : 12.5,
          color: isDark ? _N.textSoftDark : _N.textSoftLight,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: compact ? 11 : 12,
          color: isDark ? _N.textMuteDark : _N.textMuteLight,
        ),
        prefixIcon: Icon(
          icon,
          size: compact ? 16 : 19,
          color: enabled
              ? _N.primary
              : (isDark ? _N.textMuteDark : _N.textMuteLight),
        ),
        suffixIcon: !enabled
            ? Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: isDark ? _N.textMuteDark : _N.textMuteLight,
              )
            : null,
        filled: true,
        fillColor: enabled
            ? (isDark ? _N.surfaceDark2 : _N.bgLight)
            : (isDark
                ? _N.surfaceDark2.withOpacity(.5)
                : _N.bgLight.withOpacity(.5)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? _N.borderDark : _N.borderLight,
            width: 1.2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? _N.borderDark : _N.borderLight,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _N.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _N.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _N.danger, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _N.danger,
        ),
      ),
    );
  }

  Widget _pricePreview(bool isDark) {
    final venta = _precioVentaFinal;

    if (venta <= 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? _N.surfaceDark2 : _N.bgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? _N.borderDark : _N.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _N.primary.withOpacity(isDark ? .16 : .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: _N.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completa el precio minorista en efectivo para ver el resumen.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? _N.textSoftDark : _N.textSoftLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  _N.primary.withOpacity(.14),
                  _N.accent.withOpacity(.06),
                ]
              : [
                  _N.primary.withOpacity(.06),
                  _N.accent.withOpacity(.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _N.primary.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_N.primary, _N.accent]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen de precios',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                  color: isDark ? _N.textDark : _N.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _priceRow('Minorista · Efectivo', venta, isDark, bold: true),
          _priceRow(
              'Minorista · Transferencia', _precioTransferenciaFinal, isDark),
          const SizedBox(height: 4),
          _priceRow(
              'Mayorista · Efectivo', _precioMayoristaEfectivoFinal, isDark),
          _priceRow('Mayorista · Transferencia',
              _precioMayoristaTransferenciaFinal, isDark),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value, bool isDark,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: isDark ? _N.textSoftDark : _N.textSoftLight,
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold
                  ? _N.primary
                  : (isDark ? _N.textDark : _N.textLight),
              letterSpacing: -.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  GUARDAR
  // ============================================================
  Future<void> _guardar() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      mostrarSnackBar(
        mensaje: 'Completa todos los campos correctamente',
        esExito: false,
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    setState(() => _isSaving = true);

    try {
      final puedeVerCostos =
          provider.rol == 'admin' || provider.rol == 'gestor' || provider.rol == 'dueno' || provider.rol == 'gerente';

      final precioCompra = puedeVerCostos && _precioCompraCtrl.text.isNotEmpty
          ? double.parse(_precioCompraCtrl.text)
          : (_editando?.precioCompra ?? 0.0);

      final double precioVenta = _precioVentaFinal;
      final double precioTransferencia = _precioTransferenciaFinal;
      final double precioMayoristaEfectivo = _precioMayoristaEfectivoFinal;
      final double precioMayoristaTransferencia =
          _precioMayoristaTransferenciaFinal;
      final double stock = double.tryParse(_stockCtrl.text) ?? 0.0;

      // Subir imagen antes de guardar
      final imageUrl = await _subirImagenSiHaceFalta();

      final producto = Producto(
        id: _editando?.id ?? '',
        nombre: _nombreCtrl.text.trim(),
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        stock: stock,
        categoriaId: _categoriaId,
        lotes: _editando?.lotes ?? [],
        sucursalId: _sucursalId,
        precioTransferencia: precioTransferencia,
        precioMayoristaEfectivo: precioMayoristaEfectivo,
        precioMayoristaTransferencia: precioMayoristaTransferencia,
        unidadMedida: _unidadMedida,
        empresaId: provider.empresaId,
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      if (_editando == null) {
        await provider.agregarProducto(producto);
        mostrarSnackBar(
          mensaje: 'Producto creado exitosamente',
          esExito: true,
        );
        if (mounted) Navigator.pop(context);
      } else {
        producto.id = _editando!.id;
        // Si no puede ver costos, mantener precio compra original
        if (!puedeVerCostos) {
          producto.precioCompra = _editando!.precioCompra;
        }
        await provider.editarProducto(producto);
        _editando = producto;
        mostrarSnackBar(
          mensaje: 'Producto actualizado correctamente',
          esExito: true,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      mostrarSnackBar(
        mensaje: 'Error al guardar: ${mensajeAmigable(e)}',
        esExito: false,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}