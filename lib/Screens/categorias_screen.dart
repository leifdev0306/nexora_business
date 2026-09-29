import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({Key? key}) : super(key: key);

  @override
  _CategoriasScreenState createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  Categoria? _editando;

  void _mostrarDialogo({Categoria? categoria}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    _editando = categoria;
    if (categoria != null) {
      _nombreCtrl.text = categoria.nombre;
      _descripcionCtrl.text = categoria.descripcion ?? '';
    } else {
      _nombreCtrl.clear();
      _descripcionCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          categoria == null ? 'Nueva Categoría' : 'Editar Categoría',
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
                  controller: _descripcionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: TextStyle(fontSize: isDesktop ? 16 : 14),
                  ),
                  style: TextStyle(fontSize: isDesktop ? 16 : 14),
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
            child: Text(categoria == null ? 'Crear' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final nombre = _nombreCtrl.text.trim();
      final descripcion = _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim();

      if (_editando == null) {
        final categoria = Categoria(
          id: '',
          nombre: nombre,
          descripcion: descripcion,
        );
        await provider.agregarCategoria(categoria);
        setState(() {});
      } else {
        final categoria = Categoria(
          id: _editando!.id,
          nombre: nombre,
          descripcion: descripcion,
          empresaId: _editando!.empresaId,
          updatedAt: _editando!.updatedAt,
        );
        await provider.editarCategoria(categoria);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        elevation: 0,
        backgroundColor: isDark ? colorFondoOscuroCard : Theme.of(context).primaryColor,
        foregroundColor: isDark ? colorTextoOscuro : Colors.white,
        actions: [
          // Botón de agregar categoría con estilo similar al de productos
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _mostrarDialogo(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar categoría', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveHelper.wrapScaffoldBody(
        context,
        provider.categorias.isEmpty
            ? Center(
                child: Text(
                  'No hay categorías creadas.',
                  style: TextStyle(
                    color: isDark ? colorTextoOscuroSecundario : Colors.grey,
                    fontSize: isDesktop ? 18 : 14,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.categorias.length,
                itemBuilder: (context, index) {
                  final c = provider.categorias[index];
                  return Card(
                    color: isDark ? colorFondoOscuroCard : Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? colorAcentoOscuro.withOpacity(0.2) : Colors.purple.shade100,
                        child: Text(
                          c.nombre[0].toUpperCase(),
                          style: TextStyle(
                            color: isDark ? colorTextoOscuro : Colors.purple,
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
                      subtitle: c.descripcion != null
                          ? Text(
                              c.descripcion!,
                              style: TextStyle(
                                color: isDark ? colorTextoOscuroSecundario : Colors.black54,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: isDesktop ? 22 : 18),
                            onPressed: () => _mostrarDialogo(categoria: c),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red, size: isDesktop ? 22 : 18),
                            onPressed: () => _eliminarCategoria(c.id),
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

  void _eliminarCategoria(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text('¿Estás seguro de eliminar esta categoría? Los productos se reasignarán a "Sin categoría".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              try {
                await provider.eliminarCategoria(id);
                setState(() {});
                Navigator.pop(context);
                mostrarSnackBar(mensaje: 'Categoría eliminada', esExito: true);
              } catch (e) {
                mostrarSnackBar(mensaje: 'Error al eliminar categoría: $e', esExito: false);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}