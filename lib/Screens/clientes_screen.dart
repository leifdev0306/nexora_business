import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({Key? key}) : super(key: key);

  @override
  _ClientesScreenState createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  Cliente? _editando;
  bool _esProveedor = false;
  String _filtroBusqueda = '';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _mostrarDialogo({Cliente? cliente}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    _editando = cliente;
    if (cliente != null) {
      _nombreCtrl.text = cliente.nombre;
      _telefonoCtrl.text = cliente.telefono ?? '';
      _direccionCtrl.text = cliente.direccion ?? '';
      _esProveedor = Provider.of<AppProvider>(context, listen: false)
          .esProveedor(cliente.id);
    } else {
      _nombreCtrl.clear();
      _telefonoCtrl.clear();
      _direccionCtrl.clear();
      _esProveedor = false;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
          style: TextStyle(fontSize: isDesktop ? 22 : 18),
        ),
        content: SizedBox(
          width: isDesktop ? 400 : double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    labelStyle: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                  style: TextStyle(fontSize: isDesktop ? 16 : 14),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    labelStyle: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                  style: TextStyle(fontSize: isDesktop ? 16 : 14),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    labelStyle: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                  style: TextStyle(fontSize: isDesktop ? 16 : 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _esProveedor,
                      onChanged: (value) => setState(() => _esProveedor = value!),
                    ),
                    Text(
                      'Marcar como proveedor',
                      style: TextStyle(fontSize: isDesktop ? 16 : 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _guardar,
            child: Text(cliente == null ? 'Crear' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final nombre = _nombreCtrl.text.trim();
      final telefono = _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim();
      final direccion = _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim();

      if (_editando == null) {
        final cliente = Cliente(
          id: '',
          nombre: nombre,
          telefono: telefono,
          direccion: direccion,
          saldoPendiente: 0,
        );
        await provider.agregarCliente(cliente);
        if (_esProveedor) {
          provider.agregarProveedor(cliente.id);
        }
        setState(() {});
      } else {
        final cliente = Cliente(
          id: _editando!.id,
          nombre: nombre,
          telefono: telefono,
          direccion: direccion,
          saldoPendiente: _editando!.saldoPendiente,
          empresaId: _editando!.empresaId,
          updatedAt: _editando!.updatedAt,
        );
        await provider.editarCliente(cliente);
        if (_esProveedor) {
          provider.agregarProveedor(cliente.id);
        } else {
          provider.quitarProveedor(cliente.id);
        }
        setState(() {});
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    final esAdmin = provider.rol == 'admin';

    List<Cliente> clientesFiltrados = provider.clientes;
    if (_filtroBusqueda.isNotEmpty) {
      clientesFiltrados = clientesFiltrados.where((c) =>
          c.nombre.toLowerCase().contains(_filtroBusqueda.toLowerCase()) ||
          (c.telefono?.contains(_filtroBusqueda) ?? false)
      ).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes y Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarDialogo(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: TextStyle(
                  color: isDark ? colorTextoOscuroSecundario : Colors.grey,
                  fontSize: isDesktop ? 16 : 14,
                ),
                prefixIcon: Icon(Icons.search, color: isDark ? colorTextoOscuroSecundario : Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? colorFondoOscuroCard : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(
                color: isDark ? colorTextoOscuro : Colors.black,
                fontSize: isDesktop ? 16 : 14,
              ),
              onChanged: (value) => setState(() => _filtroBusqueda = value),
            ),
          ),
        ),
      ),
      body: ResponsiveHelper.wrapScaffoldBody(
        context,
        clientesFiltrados.isEmpty
            ? Center(
                child: Text(
                  'No hay clientes registrados.',
                  style: TextStyle(
                    color: isDark ? colorTextoOscuroSecundario : Colors.grey,
                    fontSize: isDesktop ? 18 : 14,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: clientesFiltrados.length,
                itemBuilder: (context, index) {
                  final c = clientesFiltrados[index];
                  final esProveedor = provider.esProveedor(c.id);
                  return Card(
                    color: isDark ? colorFondoOscuroCard : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esProveedor
                            ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade100)
                            : (isDark ? colorAcentoOscuro.withOpacity(0.2) : Colors.blue.shade100),
                        child: Text(
                          c.nombre[0].toUpperCase(),
                          style: TextStyle(
                            color: esProveedor ? Colors.orange : (isDark ? colorTextoOscuro : Colors.blue),
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 18 : 14,
                          ),
                        ),
                      ),
                      title: Text(
                        c.nombre,
                        style: TextStyle(
                          color: isDark ? colorTextoOscuro : Colors.black,
                          fontSize: isDesktop ? 18 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.telefono != null)
                            Text(
                              '📞 ${c.telefono}',
                              style: TextStyle(
                                color: isDark ? colorTextoOscuroSecundario : Colors.black54,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                          if (c.direccion != null)
                            Text(
                              '📍 ${c.direccion}',
                              style: TextStyle(
                                color: isDark ? colorTextoOscuroSecundario : Colors.black54,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                          if (esProveedor)
                            Chip(
                              label: Text(
                                'Proveedor',
                                style: TextStyle(fontSize: isDesktop ? 12 : 10),
                              ),
                              backgroundColor: Colors.orange.shade100,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (c.saldoPendiente != null && c.saldoPendiente! > 0)
                            Text(
                              'Saldo: \$${c.saldoPendiente!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                          if (esAdmin)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: isDesktop ? 22 : 18),
                                  onPressed: () => _mostrarDialogo(cliente: c),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red, size: isDesktop ? 22 : 18),
                                  onPressed: () => _eliminarCliente(c.id),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _eliminarCliente(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro de eliminar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              try {
                await provider.eliminarCliente(id);
                setState(() {});
                Navigator.pop(context);
                mostrarSnackBar(mensaje: 'Cliente eliminado', esExito: true);
              } catch (e) {
                mostrarSnackBar(mensaje: 'Error al eliminar cliente: $e', esExito: false);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}