// ============================================================
//  vendedores_screen.dart · NEXORA BUSINESS
//  Gestión de vendedores y gestores con salarios y promociones
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../responsive_helper.dart';
import '../main.dart';

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
  static const gradPurple = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const gradWarm = [Color(0xFFF59E0B), Color(0xFFF97316)];
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

class VendedoresScreen extends StatefulWidget {
  const VendedoresScreen({Key? key}) : super(key: key);

  @override
  State<VendedoresScreen> createState() => _VendedoresScreenState();
}

class _VendedoresScreenState extends State<VendedoresScreen>
    with WidgetsBindingObserver {
  List<Usuario> usuarios = [];
  bool _cargando = false;
  String _filtroRol = 'todos';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _sucursalSeleccionada;

  final _salarioCtrl = TextEditingController();
  String _tipoContrato = 'fijo';
  final _comisionCtrl = TextEditingController();
  Timer? _repeticionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _salarioCtrl.dispose();
    _comisionCtrl.dispose();
    _repeticionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      usuarios = await provider.listarUsuariosDeEmpresa();
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ============================================================
  //  CREAR VENDEDOR
  // ============================================================
  void _mostrarDialogoCrear() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    // ✅ Fix: rol 'dueno'
    if (provider.rol != 'dueno') return;

    _sucursalSeleccionada = null;
    _emailCtrl.clear();
    _passwordCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              'Nuevo vendedor',
              style: TextStyle(
                fontSize: 16,
                color: p.textHigh,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isDesktop ? 440 : double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  p: p,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return 'Requerido';
                    if (!s.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  p: p,
                  obscure: true,
                  validator: (v) => (v ?? '').length < 6
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sucursal asignada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: p.textMid,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  initialValue: _sucursalSeleccionada,
                  isExpanded: true,
                  dropdownColor: p.surface,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: p.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    fillColor: p.surface2,
                    prefixIcon: Icon(Icons.storefront_rounded,
                        size: 18, color: p.textMuted),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin sucursal (global)'),
                    ),
                    ...provider.sucursales.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.nombre,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _sucursalSeleccionada = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancelar', style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: _crearVendedor,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Crear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required _P p,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(
        fontSize: 13.5,
        color: p.textHigh,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: p.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 18, color: p.textMuted),
        filled: true,
        fillColor: p.surface2,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.border),
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
      ),
    );
  }

  Future<void> _crearVendedor() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final nuevoId = await provider.crearVendedor(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (_sucursalSeleccionada != null) {
        await provider.actualizarSucursalUsuario(
            nuevoId, _sucursalSeleccionada);
      }
      if (!mounted) return;
      Navigator.pop(context);
      await _cargar();
      mostrarSnackBar(
          mensaje: 'Vendedor creado exitosamente', esExito: true);
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }

  // ============================================================
  //  SALARIO
  // ============================================================
  void _mostrarDialogoSalario(Usuario usuario) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final empleado = provider.getEmpleadoByUsuarioId(usuario.id);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    if (empleado != null) {
      _salarioCtrl.text = empleado.salarioBase.toString();
      _tipoContrato = empleado.tipoContrato;
      _comisionCtrl.text =
          empleado.comisionPorcentaje?.toString() ?? '';
    } else {
      _salarioCtrl.text = '';
      _tipoContrato = 'fijo';
      _comisionCtrl.text = '';
    }

    final salarioKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setSt) => AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradSuccess),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Colors.white, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salario',
                      style: TextStyle(
                        fontSize: 15,
                        color: p.textHigh,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      usuario.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: isDesktop ? 440 : double.maxFinite,
            child: Form(
              key: salarioKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    controller: _salarioCtrl,
                    label: 'Salario base (CUP)',
                    icon: Icons.attach_money_rounded,
                    p: p,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Requerido';
                      final val = double.tryParse(v!);
                      if (val == null || val < 0) return 'Monto válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tipo de contrato',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoContrato,
                    dropdownColor: p.surface,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: p.textHigh,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      fillColor: p.surface2,
                      prefixIcon: Icon(Icons.work_outline_rounded,
                          size: 18, color: p.textMuted),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'fijo', child: Text('Fijo')),
                      DropdownMenuItem(
                          value: 'comision', child: Text('Comisión')),
                      DropdownMenuItem(
                          value: 'mixto', child: Text('Mixto')),
                    ],
                    onChanged: (v) =>
                        setSt(() => _tipoContrato = v ?? 'fijo'),
                  ),
                  if (_tipoContrato != 'fijo') ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            controller: _comisionCtrl,
                            label: '% comisión',
                            icon: Icons.percent_rounded,
                            p: p,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if ((v ?? '').isEmpty) {
                                return 'Requerido';
                              }
                              final val = double.tryParse(v!);
                              if (val == null || val < 0 || val > 100) {
                                return 'Valor 0-100';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            _stepBtn(
                              icon: Icons.add_rounded,
                              color: _C.success,
                              onTap: () => setSt(() {
                                final cur =
                                    double.tryParse(_comisionCtrl.text) ?? 0;
                                _comisionCtrl.text =
                                    (cur + 0.5).clamp(0, 100).toStringAsFixed(1);
                              }),
                              onLongPress: () =>
                                  _startRepetir(incrementar: true, setSt: setSt),
                              onLongPressUp: _stopRepetir,
                            ),
                            const SizedBox(height: 4),
                            _stepBtn(
                              icon: Icons.remove_rounded,
                              color: _C.danger,
                              onTap: () => setSt(() {
                                final cur =
                                    double.tryParse(_comisionCtrl.text) ?? 0;
                                _comisionCtrl.text =
                                    (cur - 0.5).clamp(0, 100).toStringAsFixed(1);
                              }),
                              onLongPress: () =>
                                  _startRepetir(incrementar: false, setSt: setSt),
                              onLongPressUp: _stopRepetir,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text('Cancelar', style: TextStyle(color: p.textMid)),
            ),
            ElevatedButton.icon(
              onPressed: () => _guardarSalario(usuario, salarioKey),
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressUp: onLongPressUp,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.32)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _startRepetir(
      {required bool incrementar, required StateSetter setSt}) {
    _repeticionTimer?.cancel();
    _repeticionTimer =
        Timer.periodic(const Duration(milliseconds: 150), (_) {
      setSt(() {
        final cur = double.tryParse(_comisionCtrl.text) ?? 0;
        final next = incrementar ? cur + 0.5 : cur - 0.5;
        _comisionCtrl.text =
            next.clamp(0.0, 100.0).toStringAsFixed(1);
      });
    });
  }

  void _stopRepetir() {
    _repeticionTimer?.cancel();
    _repeticionTimer = null;
  }

  Future<void> _guardarSalario(Usuario usuario, GlobalKey<FormState> key) async {
    if (!(key.currentState?.validate() ?? false)) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final salario = double.parse(_salarioCtrl.text);
      double? comision;

      if (_tipoContrato != 'fijo') {
        comision = double.tryParse(_comisionCtrl.text) ?? 0;
      }

      final empleado = Empleado(
        id: provider.getEmpleadoByUsuarioId(usuario.id)?.id ?? '',
        usuarioId: usuario.id,
        salarioBase: salario,
        tipoContrato: _tipoContrato,
        comisionPorcentaje: comision,
        fechaContratacion: DateTime.now(),
        activo: true,
        empresaId: provider.empresaId,
      );

      await provider.guardarEmpleado(empleado);
      if (!mounted) return;
      Navigator.pop(context);
      await _cargar();
      mostrarSnackBar(
          mensaje: 'Salario guardado', esExito: true);
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }

  // ============================================================
  //  ACCIONES
  // ============================================================
  Future<void> _eliminarUsuario(Usuario usuario) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.rol != 'dueno') {
      mostrarSnackBar(
          mensaje: 'Solo el dueño puede eliminar', esExito: false);
      return;
    }
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('¿Eliminar usuario?',
            style: TextStyle(
                color: p.textHigh, fontWeight: FontWeight.w900)),
        content: Text(
          'Se desactivará la cuenta de ${usuario.email}.',
          style: TextStyle(color: p.textMid, fontSize: 13),
        ),
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
        await provider.eliminarVendedor(usuario.id);
        await _cargar();
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Usuario desactivado', esExito: true);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Error: ${mensajeAmigable(e)}',
              esExito: false);
        }
      }
    }
  }

  Future<void> _cambiarSucursal(
      Usuario usuario, String? nuevaSucursalId) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.rol != 'dueno') return;
    try {
      await provider.actualizarSucursalUsuario(
          usuario.id, nuevaSucursalId);
      await _cargar();
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Sucursal actualizada', esExito: true);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
      }
    }
  }

  Future<void> _toggleRol(Usuario usuario) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.rol != 'dueno') return;

    final p = _P(Theme.of(context).brightness == Brightness.dark);

    if (usuario.rol == 'vendedor') {
      // Promover a gestor
      String? seleccion;
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            backgroundColor: p.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: _C.gradSuccess),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Promover a gestor',
                    style: TextStyle(
                        color: p.textHigh,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usuario.email} pasará a ser gestor.',
                  style: TextStyle(color: p.textMid, fontSize: 13),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: seleccion,
                  isExpanded: true,
                  dropdownColor: p.surface,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: p.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sucursal a gestionar',
                    isDense: true,
                    fillColor: p.surface2,
                  ),
                  items: provider.sucursales
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre),
                          ))
                      .toList(),
                  onChanged: (v) => setSt(() => seleccion = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar',
                    style: TextStyle(color: p.textMid)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (seleccion == null) {
                    mostrarSnackBar(
                        mensaje: 'Selecciona una sucursal',
                        esExito: false);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _C.success),
                child: const Text('Promover'),
              ),
            ],
          ),
        ),
      );
      if (confirmado != true || seleccion == null) return;
      try {
        await provider.promoverAGestor(usuario.id, seleccion!);
        await _cargar();
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Promovido a gestor', esExito: true);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Error: ${mensajeAmigable(e)}',
              esExito: false);
        }
      }
    } else {
      // Revertir a vendedor
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Text('Revertir a vendedor',
              style: TextStyle(
                  color: p.textHigh, fontWeight: FontWeight.w900)),
          content: Text(
            '${usuario.email} perderá la asignación de sucursal.',
            style: TextStyle(color: p.textMid, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar',
                  style: TextStyle(color: p.textMid)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _C.warning),
              child: const Text('Revertir'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      try {
        await provider.revertirAVendedor(usuario.id);
        await _cargar();
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Revertido a vendedor', esExito: true);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Error: ${mensajeAmigable(e)}',
              esExito: false);
        }
      }
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    final limite = provider.getLimiteVendedores();
    final cantidadVendedores =
        usuarios.where((u) => u.rol == 'vendedor').length;
    final esAdmin = provider.rol == 'dueno';
    final excedeLimite = cantidadVendedores > limite;

    var filtrados = usuarios;
    if (_filtroRol != 'todos') {
      filtrados =
          filtrados.where((u) => u.rol == _filtroRol).toList();
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, esAdmin, cantidadVendedores, limite),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: cantidadVendedores >= limite && !excedeLimite
                  ? null
                  : _mostrarDialogoCrear,
              backgroundColor: cantidadVendedores >= limite && !excedeLimite
                  ? p.textMuted
                  : _C.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Nuevo',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            )
          : null,
      body: Column(
        children: [
          _statsRow(
              usuarios.length, cantidadVendedores, limite, p, excedeLimite),
          _filterRow(p),
          if (excedeLimite && esAdmin) _limitWarning(limite, cantidadVendedores, p),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? _emptyState(p)
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(
                              14, 8, 14, 90),
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) => _usuarioCard(
                              filtrados[i], provider, p, esAdmin),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(
    _P p,
    bool esAdmin,
    int cantidad,
    int limite,
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
            child: const Icon(Icons.people_alt_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Equipo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Vendedores y gestores',
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

  Widget _statsRow(int total, int vendedores, int limite, _P p,
      bool excedeLimite) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: _statCard('Total', '$total',
                Icons.people_alt_rounded, _C.primary, p),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              'Vendedores',
              '$vendedores/$limite',
              Icons.person_rounded,
              excedeLimite ? _C.danger : _C.success,
              p,
            ),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: p.textHigh,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(_P p) {
    final roles = [
      ('todos', 'Todos', _C.primary),
      ('vendedor', 'Vendedores', _C.info),
      ('gerente', 'Gestores', _C.success),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: roles.map((r) {
            final selected = _filtroRol == r.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _filtroRol = r.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? r.$3.withOpacity(.14)
                        : p.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? r.$3 : p.border,
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? r.$3 : p.textMid,
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

  Widget _limitWarning(int limite, int cantidad, _P p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.danger.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.danger.withOpacity(.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded,
              color: _C.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Excedes el límite de $limite vendedores (tienes $cantidad). Elimina algunos para cumplir con tu plan.',
              style: TextStyle(
                fontSize: 11.5,
                color: p.textMid,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usuarioCard(
      Usuario u, AppProvider provider, _P p, bool esAdmin) {
    final esGestor = u.rol == 'gerente';
    final color = esGestor ? _C.success : _C.info;
    final empleado = provider.getEmpleadoByUsuarioId(u.id);

    String nombreSucursal = 'Sin sucursal';
    if (u.sucursalId != null) {
      final suc = provider.sucursales.firstWhere(
        (s) => s.id == u.sucursalId,
        orElse: () =>
            Sucursal(id: '', nombre: 'Sin sucursal', direccion: ''),
      );
      nombreSucursal = suc.nombre;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: esGestor ? _C.success.withOpacity(.32) : p.border,
            width: esGestor ? 1.4 : 1.2,
          ),
          boxShadow: p.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      color.withOpacity(.22),
                      color.withOpacity(.06),
                    ]),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: color.withOpacity(.32)),
                  ),
                  child: Text(
                    (u.email.isNotEmpty ? u.email[0] : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withOpacity(.32)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  esGestor
                                      ? Icons.verified_user_rounded
                                      : Icons.person_rounded,
                                  size: 11,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  esGestor ? 'GESTOR' : 'VENDEDOR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .4,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!u.active)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _C.danger.withOpacity(.14),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'INACTIVO',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: _C.danger,
                                    letterSpacing: .3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 14, color: p.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nombreSucursal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.textMid,
                      ),
                    ),
                  ),
                  if (empleado != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _C.success.withOpacity(.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _C.success.withOpacity(.28)),
                      ),
                      child: Text(
                        '\$${empleado.salarioBase.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: _C.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (esAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: p.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: u.sucursalId,
                          isExpanded: true,
                          dropdownColor: p.surface,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                          hint: Text('Sucursal',
                              style: TextStyle(
                                  fontSize: 12, color: p.textMuted)),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: p.textMuted),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sin sucursal'),
                            ),
                            ...provider.sucursales.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(s.nombre,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => _cambiarSucursal(u, v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.payments_rounded,
                    color: _C.primary,
                    tooltip: 'Salario',
                    onTap: () => _mostrarDialogoSalario(u),
                    p: p,
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(
                    icon: esGestor
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: esGestor ? _C.warning : _C.success,
                    tooltip: esGestor ? 'Revertir' : 'Promover',
                    onTap: () => _toggleRol(u),
                    p: p,
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _C.danger,
                    tooltip: 'Eliminar',
                    onTap: () => _eliminarUsuario(u),
                    p: p,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    required _P p,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(.24)),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
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
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: _C.purple.withOpacity(.75)),
            ),
            const SizedBox(height: 16),
            Text(
              _filtroRol != 'todos'
                  ? 'Sin resultados'
                  : 'Sin vendedores registrados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filtroRol != 'todos'
                  ? 'Prueba cambiando el filtro.'
                  : 'Crea tu primer vendedor con el botón de abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}