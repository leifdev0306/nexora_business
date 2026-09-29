// ============================================================
//  nuevo_gasto_screen.dart  ·  NEXORA BUSINESS
//  Registro de gasto premium con categorías visuales
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const pink      = Color(0xFFEC4899);
  static const indigo    = Color(0xFF6366F1);
  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg          => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface     => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2    => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get textHigh    => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid     => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted   => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border      => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong => dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);

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

class _CatItem {
  final String nombre;
  final IconData icono;
  final Color color;
  const _CatItem(this.nombre, this.icono, this.color);
}

class NuevoGastoScreen extends StatefulWidget {
  const NuevoGastoScreen({Key? key}) : super(key: key);

  @override
  _NuevoGastoScreenState createState() => _NuevoGastoScreenState();
}

class _NuevoGastoScreenState extends State<NuevoGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  String _categoria = 'Insumos';
  bool _isSaving = false;

  static const List<_CatItem> _categorias = [
    _CatItem('Alquiler', Icons.home_rounded, Color(0xFF8B5CF6)),
    _CatItem('Luz', Icons.lightbulb_rounded, Color(0xFFFBBF24)),
    _CatItem('Agua', Icons.water_drop_rounded, Color(0xFF06B6D4)),
    _CatItem('Insumos', Icons.inventory_2_rounded, Color(0xFF10B981)),
    _CatItem('Transporte', Icons.local_shipping_rounded, Color(0xFF3B82F6)),
    _CatItem('Compras', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
    _CatItem('Servicios', Icons.build_rounded, Color(0xFF6366F1)),
    _CatItem('Otros', Icons.more_horiz_rounded, Color(0xFF607B9E)),
  ];

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    _notaCtrl.dispose();
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

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.textHigh,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _C.warning.withOpacity(.32),
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
                  'Nuevo gasto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Registra un egreso',
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -160,
                    right: -140,
                    child: _orb(400, _C.warning.withOpacity(p.dark ? .10 : .06)),
                  ),
                  Positioned(
                    bottom: -200,
                    left: -160,
                    child: _orb(420, _C.danger.withOpacity(p.dark ? .08 : .05)),
                  ),
                ],
              ),
            ),
          ),
          Form(
            key: _formKey,
            child: isDesktop
                ? _desktopLayout(context, p)
                : _mobileLayout(context, p),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  MOBILE
  // ============================================================
  Widget _mobileLayout(BuildContext context, _P p) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _totalCard(p),
          const SizedBox(height: 16),
          _sectionCard(
            p,
            icon: Icons.edit_rounded,
            color: _C.primary,
            title: 'Detalles del gasto',
            children: [
              _inputField(
                controller: _conceptoCtrl,
                label: 'Concepto',
                hint: 'Ej: Pago de luz del local',
                icon: Icons.text_fields_rounded,
                p: p,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
              _inputField(
                controller: _montoCtrl,
                label: 'Monto',
                hint: '0.00',
                icon: Icons.attach_money_rounded,
                p: p,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Requerido';
                  final valor = double.tryParse(v!);
                  if (valor == null || valor <= 0) return 'Monto debe ser > 0';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            p,
            icon: Icons.category_rounded,
            color: _C.purple,
            title: 'Categoría',
            children: [_categoriaGrid(p)],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            p,
            icon: Icons.notes_rounded,
            color: _C.cyan,
            title: 'Nota (opcional)',
            children: [
              _inputField(
                controller: _notaCtrl,
                label: 'Nota',
                hint: 'Detalles adicionales del gasto',
                icon: Icons.notes_rounded,
                p: p,
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _botonGuardar(context, p),
        ],
      ),
    );
  }

  // ============================================================
  //  DESKTOP
  // ============================================================
  Widget _desktopLayout(BuildContext context, _P p) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _totalCard(p),
                    const SizedBox(height: 16),
                    _sectionCard(
                      p,
                      icon: Icons.edit_rounded,
                      color: _C.primary,
                      title: 'Detalles del gasto',
                      children: [
                        _inputField(
                          controller: _conceptoCtrl,
                          label: 'Concepto',
                          hint: 'Ej: Pago de luz del local',
                          icon: Icons.text_fields_rounded,
                          p: p,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _montoCtrl,
                          label: 'Monto',
                          hint: '0.00',
                          icon: Icons.attach_money_rounded,
                          p: p,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Requerido';
                            final valor = double.tryParse(v!);
                            if (valor == null || valor <= 0) {
                              return 'Monto debe ser > 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _notaCtrl,
                          label: 'Nota (opcional)',
                          hint: 'Detalles adicionales del gasto',
                          icon: Icons.notes_rounded,
                          p: p,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _sectionCard(
                      p,
                      icon: Icons.category_rounded,
                      color: _C.purple,
                      title: 'Categoría',
                      children: [_categoriaGrid(p, desktop: true)],
                    ),
                    const SizedBox(height: 16),
                    _botonGuardar(context, p),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  TOTAL CARD (vista previa)
  // ============================================================
  Widget _totalCard(_P p) {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final cat = _categorias.firstWhere(
      (c) => c.nombre == _categoria,
      orElse: () => _categorias.first,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cat.color.withOpacity(.20), cat.color.withOpacity(.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cat.color.withOpacity(.32), width: 1.3),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cat.color.withOpacity(.28), cat.color.withOpacity(.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: cat.color.withOpacity(.32)),
            ),
            child: Icon(cat.icono, color: cat.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoria.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: cat.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _conceptoCtrl.text.trim().isEmpty
                      ? 'Nuevo gasto'
                      : _conceptoCtrl.text.trim(),
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
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${monto.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: monto > 0 ? cat.color : p.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  SECTION CARD
  // ============================================================
  Widget _sectionCard(
    _P p, {
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.shadowSm,
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
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(.20),
                      color.withOpacity(.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(.24)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: p.textHigh,
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

  // ============================================================
  //  INPUT FIELD
  // ============================================================
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required _P p,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: p.textHigh,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13.5,
          color: p.textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          color: p.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 19, color: p.textMuted),
        filled: true,
        fillColor: p.surface2,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _C.danger, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: _C.danger,
        ),
      ),
    );
  }

  // ============================================================
  //  CATEGORÍA GRID
  // ============================================================
  Widget _categoriaGrid(_P p, {bool desktop = false}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: desktop ? 2 : 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: desktop ? 3.0 : 2.9,
      children: _categorias.map((cat) {
        final selected = _categoria == cat.nombre;
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => setState(() => _categoria = cat.nombre),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          cat.color.withOpacity(.18),
                          cat.color.withOpacity(.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : p.surface2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? cat.color.withOpacity(.55)
                      : p.border,
                  width: selected ? 1.5 : 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: cat.color.withOpacity(.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(selected ? .22 : .12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(cat.icono, color: cat.color, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                        color: selected ? cat.color : p.textMid,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: cat.color),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  //  BOTÓN GUARDAR
  // ============================================================
  Widget _botonGuardar(BuildContext context, _P p) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : () => _guardarGasto(context),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _isSaving ? 'Guardando…' : 'Registrar gasto',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _C.primary.withOpacity(.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  GUARDAR
  // ============================================================
  Future<void> _guardarGasto(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      mostrarSnackBar(
        mensaje: 'Completa los campos correctamente',
        esExito: false,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final gasto = Gasto(
        id: '',
        concepto: _conceptoCtrl.text.trim(),
        monto: double.parse(_montoCtrl.text),
        categoria: _categoria,
        fecha: DateTime.now(),
        nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      );
      await provider.agregarGasto(gasto);
      if (!mounted) return;
      Navigator.pop(context);
      mostrarSnackBar(
        mensaje: 'Gasto registrado correctamente',
        esExito: true,
      );
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
          mensaje: 'Error al registrar gasto: ${mensajeAmigable(e)}',
          esExito: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}