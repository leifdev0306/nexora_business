// ============================================================
//  categorias_screen.dart
//  Pantalla de gestión de categorías con soporte multi-empresa
//  · Categorías del sistema (globales) — solo lectura
//  · Categorías propias — crear, editar, eliminar
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();

    final globales = provider.categoriasGlobales;
    final propias = provider.categoriasPropias;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC),
      appBar: AppBar(
        title: const Text('Categorías'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.public_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Sistema (${globales.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Mis categorías (${propias.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaGlobales(context, globales),
          _buildListaPropias(context, propias),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEditorCategoria(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva categoría',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN: CATEGORÍAS DEL SISTEMA
  // ═══════════════════════════════════════════════════════════
  Widget _buildListaGlobales(BuildContext context, List<Categoria> lista) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (lista.isEmpty) {
      return _buildEmptyState(
        icon: Icons.public_off_rounded,
        titulo: 'Sin categorías del sistema',
        subtitulo:
            'Aún no hay categorías globales configuradas por el administrador.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: lista.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildInfoBanner(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF1A5CFF),
            texto:
                'Estas categorías son comunes a todos los negocios. No se pueden editar ni eliminar.',
          );
        }
        return _buildCardCategoria(
          context,
          lista[index - 1],
          esGlobal: true,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN: CATEGORÍAS PROPIAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildListaPropias(BuildContext context, List<Categoria> lista) {
    if (lista.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        titulo: 'Aún no tienes categorías propias',
        subtitulo:
            'Crea categorías personalizadas para organizar tus productos como mejor te convenga.',
        onAction: () => _abrirEditorCategoria(context, null),
        actionLabel: 'Crear primera categoría',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: lista.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildInfoBanner(
            icon: Icons.lightbulb_outline_rounded,
            color: const Color(0xFF06B6D4),
            texto:
                'Estas categorías son solo tuyas. Puedes editarlas o eliminarlas cuando quieras.',
          );
        }
        return _buildCardCategoria(
          context,
          lista[index - 1],
          esGlobal: false,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CARD DE CATEGORÍA
  // ═══════════════════════════════════════════════════════════
  Widget _buildCardCategoria(
    BuildContext context,
    Categoria categoria, {
    required bool esGlobal,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();

    final surface = isDark ? const Color(0xFF122340) : Colors.white;
    final border =
        isDark ? const Color(0x294A8BFF) : const Color(0x1F1A5CFF);
    final textHigh =
        isDark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
    final textMid = isDark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
    final textMuted =
        isDark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);

    final colorGlobal = const Color(0xFF1A5CFF);
    final colorPropia = const Color(0xFF06B6D4);

    final color = esGlobal ? colorGlobal : colorPropia;
    final iconData = _parseIcon(categoria.icon);
    final productosCount =
        provider.productos.where((p) => p.categoriaId == categoria.id).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: esGlobal
              ? null
              : () => _abrirEditorCategoria(context, categoria),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icono con color de acento
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.28)),
                  ),
                  child: Icon(iconData, color: color, size: 24),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              categoria.nombre,
                              style: TextStyle(
                                color: textHigh,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            esGlobal ? 'Sistema' : 'Propia',
                            esGlobal ? colorGlobal : colorPropia,
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 13,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$productosCount producto${productosCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: textMid,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (categoria.descripcion != null &&
                              categoria.descripcion!.isNotEmpty) ...[
                            Text(
                              ' · ',
                              style: TextStyle(color: textMuted),
                            ),
                            Flexible(
                              child: Text(
                                categoria.descripcion!,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones
                if (esGlobal)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: textMuted.withOpacity(0.5),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: textMid),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'editar') {
                        _abrirEditorCategoria(context, categoria);
                      } else if (value == 'eliminar') {
                        _confirmarEliminar(context, categoria);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BADGE "Sistema" / "Propia"
  // ═══════════════════════════════════════════════════════════
  Widget _buildBadge(String texto, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BANNER INFORMATIVO (arriba de cada lista)
  // ═══════════════════════════════════════════════════════════
  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String texto,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMid = isDark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: textMid,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ESTADO VACÍO
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textHigh =
        isDark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
    final textMuted =
        isDark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5CFF).withOpacity(isDark ? .12 : .08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: const Color(0xFF1A5CFF).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textHigh,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel ?? 'Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MODAL CREAR/EDITAR CATEGORÍA
  // ═══════════════════════════════════════════════════════════
  Future<void> _abrirEditorCategoria(
    BuildContext context,
    Categoria? categoria,
  ) async {
    final esEdicion = categoria != null;
    final nombreCtrl = TextEditingController(text: categoria?.nombre ?? '');
    final descripcionCtrl =
        TextEditingController(text: categoria?.descripcion ?? '');
    String? iconoSeleccionado = categoria?.icon ?? 'category';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF122340) : Colors.white;
    final textHigh =
        isDark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
    final border = isDark ? const Color(0x294A8BFF) : const Color(0x1F1A5CFF);

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A5CFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              esEdicion
                                  ? Icons.edit_outlined
                                  : Icons.add_rounded,
                              color: const Color(0xFF1A5CFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  esEdicion
                                      ? 'Editar categoría'
                                      : 'Nueva categoría',
                                  style: TextStyle(
                                    color: textHigh,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  esEdicion
                                      ? 'Modifica los datos de tu categoría'
                                      : 'Solo tú podrás ver esta categoría',
                                  style: TextStyle(
                                    color: textHigh.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Campo: Nombre
                      TextField(
                        controller: nombreCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Ej: Bebidas, Snacks, Lácteos...',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Campo: Descripción
                      TextField(
                        controller: descripcionCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          hintText: 'Breve descripción de la categoría',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Selector de icono
                      Text(
                        'Icono',
                        style: TextStyle(
                          color: textHigh,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSelectorIconos(
                        iconoSeleccionado,
                        (nuevo) => setStateModal(() {
                          iconoSeleccionado = nuevo;
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final nombre = nombreCtrl.text.trim();
                                if (nombre.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Escribe un nombre válido'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                final prov = context.read<AppProvider>();
                                final descripcion =
                                    descripcionCtrl.text.trim();

                                if (esEdicion) {
                                  categoria.nombre = nombre;
                                  categoria.descripcion = descripcion.isEmpty
                                      ? null
                                      : descripcion;
                                  categoria.icon = iconoSeleccionado;
                                  await prov.editarCategoria(categoria);
                                } else {
                                  final nueva = Categoria(
                                    id: const Uuid().v4(),
                                    nombre: nombre,
                                    descripcion: descripcion.isEmpty
                                        ? null
                                        : descripcion,
                                    icon: iconoSeleccionado,
                                    updatedAt: DateTime.now(),
                                  );
                                  await prov.agregarCategoria(nueva);
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx, true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A5CFF),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                esEdicion ? 'Guardar cambios' : 'Crear',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (resultado == true) {
      nombreCtrl.dispose();
      descripcionCtrl.dispose();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  GRID DE ICONOS DISPONIBLES
  // ═══════════════════════════════════════════════════════════
  Widget _buildSelectorIconos(
    String? seleccionado,
    ValueChanged<String> onSelect,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0x294A8BFF) : const Color(0x1F1A5CFF);
    final primary = const Color(0xFF1A5CFF);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _iconosDisponibles.map((entry) {
        final isSelected = seleccionado == entry.key;
        return GestureDetector(
          onTap: () => onSelect(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withOpacity(0.15)
                  : (isDark ? const Color(0xFF1A2942) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? primary : border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              entry.value,
              color: isSelected
                  ? primary
                  : (isDark
                      ? const Color(0xFFB8CBE8)
                      : const Color(0xFF1C3352)),
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CONFIRMAR ELIMINACIÓN
  // ═══════════════════════════════════════════════════════════
  Future<void> _confirmarEliminar(
    BuildContext context,
    Categoria categoria,
  ) async {
    final provider = context.read<AppProvider>();
    final productosCount =
        provider.productos.where((p) => p.categoriaId == categoria.id).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF122340) : Colors.white;
    final textHigh =
        isDark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
    final textMid = isDark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿Eliminar categoría?',
                style: TextStyle(
                  color: textHigh,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vas a eliminar "${categoria.nombre}".',
              style: TextStyle(
                color: textMid,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (productosCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$productosCount producto${productosCount == 1 ? '' : 's'} '
                        'serán movidos a "Sin categoría".',
                        style: TextStyle(
                          color: textMid,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await provider.eliminarCategoria(categoria.id);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Mapea el string de icono guardado a un IconData real.
  IconData _parseIcon(String? iconKey) {
    final entry = _iconosDisponibles.firstWhere(
      (e) => e.key == iconKey,
      orElse: () => _iconosDisponibles.first,
    );
    return entry.value;
  }

  /// Iconos disponibles para categorías.
  static const List<MapEntry<String, IconData>> _iconosDisponibles = [
    MapEntry('category', Icons.category_rounded),
    MapEntry('fastfood', Icons.fastfood_rounded),
    MapEntry('local_drink', Icons.local_drink_rounded),
    MapEntry('bakery_dining', Icons.bakery_dining_rounded),
    MapEntry('local_grocery', Icons.local_grocery_store_rounded),
    MapEntry('shopping_bag', Icons.shopping_bag_rounded),
    MapEntry('kitchen', Icons.kitchen_rounded),
    MapEntry('restaurant', Icons.restaurant_rounded),
    MapEntry('icecream', Icons.icecream_rounded),
    MapEntry('local_pizza', Icons.local_pizza_rounded),
    MapEntry('coffee', Icons.coffee_rounded),
    MapEntry('liquor', Icons.liquor_rounded),
    MapEntry('cleaning', Icons.cleaning_services_rounded),
    MapEntry('soap', Icons.soap_rounded),
    MapEntry('checkroom', Icons.checkroom_rounded),
    MapEntry('face', Icons.face_retouching_natural_rounded),
    MapEntry('hardware', Icons.hardware_rounded),
    MapEntry('build', Icons.build_rounded),
    MapEntry('electrical', Icons.electrical_services_rounded),
    MapEntry('phone_android', Icons.phone_android_rounded),
    MapEntry('computer', Icons.computer_rounded),
    MapEntry('sports', Icons.sports_soccer_rounded),
    MapEntry('pets', Icons.pets_rounded),
    MapEntry('child_care', Icons.child_care_rounded),
    MapEntry('medical', Icons.medical_services_rounded),
    MapEntry('spa', Icons.spa_rounded),
    MapEntry('book', Icons.menu_book_rounded),
    MapEntry('school', Icons.school_rounded),
    MapEntry('toys', Icons.toys_rounded),
    MapEntry('auto', Icons.directions_car_rounded),
    MapEntry('gardening', Icons.local_florist_rounded),
    MapEntry('paint', Icons.format_paint_rounded),
  ];
}