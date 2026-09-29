// ============================================================
//  models/categoria_tienda.dart
//  Alineado con el schema real: categorias_tienda.id es uuid
// ============================================================

class CategoriaTienda {
  final String id;
  final String nombre;
  final String? icono;

  const CategoriaTienda({
    required this.id,
    required this.nombre,
    this.icono,
  });

  factory CategoriaTienda.fromMap(Map<String, dynamic> map) => CategoriaTienda(
        id: map['id'].toString(),
        nombre: (map['nombre'] ?? '').toString(),
        icono: map['icono']?.toString(),
      );
}