// ============================================================
//  sucursales_screen.dart · NEXORA BUSINESS
//  Gestión de sucursales con asignación de gestor
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
  static const teal = Color(0xFF14B8A6);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradTeal = [Color(0xFF14B8A6), Color(0xFF06B6D4)];
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

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({Key? key}) : super(key: key);

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  Sucursal? _editando;
  List<Usuario> _gestoresDisponibles = [];
  bool _cargandoGestores = false;

  @override
  void initState() {
    super.initState();
    _cargarGestores();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarGestores() async {
    setState(() => _cargandoGestores = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _gestoresDisponibles = await provider.listarGestores();
    } finally {
      if (mounted) setState(() => _cargandoGestores = false);
    }
  }

  // ============================================================
  //  DIALOG CREAR/EDITAR
  // ============================================================
  void _mostrarDialogo({Sucursal? sucursal}) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    _editando = sucursal;

    if (sucursal != null) {
      _nombreCtrl.text = sucursal.nombre;
      _direccionCtrl.text = sucursal.direccion;
      _telefonoCtrl.text = sucursal.telefono ?? '';
    } else {
      _nombreCtrl.clear();
      _direccionCtrl.clear();
      _telefonoCtrl.clear();
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

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
              child: Icon(
                sucursal == null
                    ? Icons.add_business_rounded
                    : Icons.edit_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              sucursal == null ? 'Nueva sucursal' : 'Editar sucursal',
              style: TextStyle(
                fontSize: 16,
                color: p.textHigh,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: isDesktop ? 460 : double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  controller: _nombreCtrl,
                  label: 'Nombre',
                  icon: Icons.storefront_rounded,
                  p: p,
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _direccionCtrl,
                  label: 'Dirección',
                  icon: Icons.location_on_rounded,
                  p: p,
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono (opcional)',
                  icon: Icons.phone_rounded,
                  p: p,
                  keyboardType: TextInputType.phone,
                ),
                if (sucursal != null &&
                    _gestoresDisponibles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Asignar gestor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.textMid,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: sucursal.gestorId,
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
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          size: 18, color: p.textMuted),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin gestor'),
                      ),
                      ..._gestoresDisponibles.map((g) =>
                          DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.email,
                                overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (value) async {
                      Navigator.pop(context);
                      try {
                        await provider.asignarGestor(sucursal.id, value ?? '');
                        await _cargarGestores();
                        if (mounted) {
                          mostrarSnackBar(
                              mensaje: 'Gestor actualizado',
                              esExito: true);
                        }
                      } catch (e) {
                        if (mounted) {
                          mostrarSnackBar(
                              mensaje: 'Error: ${mensajeAmigable(e)}',
                              esExito: false);
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: p.textMid)),
          ),
          ElevatedButton.icon(
            onPressed: _guardar,
            icon: Icon(
                sucursal == null
                    ? Icons.add_rounded
                    : Icons.save_rounded,
                size: 16),
            label: Text(sucursal == null ? 'Crear' : 'Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required _P p,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final nombre = _nombreCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    try {
      if (_editando == null) {
        await provider.crearSucursal(Sucursal(
          id: uuid.v4(),
          nombre: nombre,
          direccion: direccion,
          telefono: telefono.isEmpty ? null : telefono,
        ));
      } else {
        await provider.editarSucursal(Sucursal(
          id: _editando!.id,
          nombre: nombre,
          direccion: direccion,
          telefono: telefono.isEmpty ? null : telefono,
          empresaId: _editando!.empresaId,
          gestorId: _editando!.gestorId,
          createdAt: _editando!.createdAt,
        ));
      }
      if (!mounted) return;
      Navigator.pop(context);
      await _cargarGestores();
      mostrarSnackBar(
        mensaje:
            _editando == null ? 'Sucursal creada' : 'Sucursal actualizada',
        esExito: true,
      );
    } catch (e) {
      if (mounted) {
        mostrarSnackBar(
            mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
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
    final esAdmin = provider.rol == 'dueno';

    final sucursales = provider.sucursalesPermitidas;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p, esAdmin),
      floatingActionButton: esAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogo(),
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargarGestores,
        child: sucursales.isEmpty
            ? _emptyState(p, esAdmin)
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: sucursales.length,
                itemBuilder: (_, i) => _sucursalCard(
                  sucursales[i],
                  provider,
                  p,
                  esAdmin,
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar(_P p, bool esAdmin) {
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
              gradient: const LinearGradient(colors: _C.gradTeal),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sucursales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Gestiona tus puntos de venta',
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

  Widget _sucursalCard(
    Sucursal s,
    AppProvider provider,
    _P p,
    bool esAdmin,
  ) {
    final gestor = _gestoresDisponibles.firstWhere(
      (g) => g.id == s.gestorId,
      orElse: () => Usuario(id: '', email: '', rol: ''),
    );
    final productosCount =
        provider.productos.where((pp) => pp.sucursalId == s.id).length;
    final ventasCount =
        provider.ventas.where((v) => v.sucursalId == s.id).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _C.gradTeal),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _C.teal.withOpacity(.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: p.textHigh,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: p.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.direccion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (s.telefono != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded,
                                size: 12, color: p.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              s.telefono!,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (esAdmin)
                  PopupMenuButton<String>(
                    color: p.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: p.border),
                    ),
                    onSelected: (v) {
                      if (v == 'edit') {
                        _mostrarDialogo(sucursal: s);
                      } else if (v == 'delete') {
                        _eliminarSucursal(s.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 16, color: p.textMid),
                            const SizedBox(width: 8),
                            Text('Editar',
                                style: TextStyle(
                                    fontSize: 13, color: p.textHigh)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                size: 16, color: _C.danger),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(
                                    fontSize: 13, color: _C.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: s.gestorId != null
                    ? _C.primary.withOpacity(.10)
                    : p.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: s.gestorId != null
                      ? _C.primary.withOpacity(.28)
                      : p.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    s.gestorId != null
                        ? Icons.person_rounded
                        : Icons.person_off_rounded,
                    size: 15,
                    color: s.gestorId != null
                        ? _C.primary
                        : p.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.gestorId != null && gestor.email.isNotEmpty
                          ? gestor.email
                          : 'Sin gestor asignado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.gestorId != null
                            ? _C.primary
                            : p.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    'Productos',
                    '$productosCount',
                    Icons.inventory_2_rounded,
                    _C.purple,
                    p,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    'Ventas',
                    '$ventasCount',
                    Icons.receipt_long_rounded,
                    _C.success,
                    p,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(
    String label,
    String value,
    IconData icon,
    Color color,
    _P p,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withOpacity(.28)),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 9),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
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

  Widget _emptyState(_P p, bool esAdmin) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      _C.teal.withOpacity(.16),
                      _C.cyan.withOpacity(.04),
                    ]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storefront_outlined,
                      size: 42, color: _C.teal.withOpacity(.75)),
                ),
                const SizedBox(height: 18),
                Text(
                  esAdmin
                      ? 'Sin sucursales creadas'
                      : 'Sin sucursales asignadas',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  esAdmin
                      ? 'Crea tu primera sucursal para comenzar.'
                      : 'Contacta al administrador para que te asigne una.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textMuted),
                ),
                if (esAdmin) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarDialogo(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Crear sucursal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _eliminarSucursal(String id) async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: _C.danger, size: 18),
            ),
            const SizedBox(width: 10),
            Text('¿Eliminar sucursal?',
                style: TextStyle(
                    color: p.textHigh, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Solo se pueden eliminar sucursales sin productos ni ventas asociadas.\n\nEsta acción no se puede deshacer.',
          style: TextStyle(color: p.textMid, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final provider =
            Provider.of<AppProvider>(context, listen: false);
        await provider.eliminarSucursal(id);
        await _cargarGestores();
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Sucursal eliminada', esExito: true);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackBar(
              mensaje: 'Error: ${mensajeAmigable(e)}', esExito: false);
        }
      }
    }
  }
}