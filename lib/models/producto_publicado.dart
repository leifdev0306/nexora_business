// models/producto_publicado.dart
class ProductoPublicado {
  final String id;
  final String tiendaId;
  final String tiendaSucursalId;
  final String productoId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String moneda;
  final String? categoriaId;
  final String? imagenPrincipalUrl;
  final bool disponible;
  final bool publicado;
  final bool mostrarDisponibilidad;
  final int orden;
  final String? unidadMedida; // opcional, si haces join con productos

  const ProductoPublicado({
    required this.id,
    required this.tiendaId,
    required this.tiendaSucursalId,
    required this.productoId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.moneda,
    this.categoriaId,
    this.imagenPrincipalUrl,
    required this.disponible,
    required this.publicado,
    this.mostrarDisponibilidad = true,
    this.orden = 0,
    this.unidadMedida,
  });

  factory ProductoPublicado.fromMap(Map<String, dynamic> map) {
    // Si en el select embebiste el producto original, saca unidad_medida
    String? unidad;
    final producto = map['productos'];
    if (producto is Map) {
      unidad = producto['unidad_medida']?.toString();
    }

    return ProductoPublicado(
      id: map['id'].toString(),
      tiendaId: (map['tienda_id'] ?? '').toString(),
      tiendaSucursalId: (map['tienda_sucursal_id'] ?? '').toString(),
      productoId: (map['producto_id'] ?? '').toString(),
      nombre: (map['nombre'] ?? '').toString(),
      descripcion: map['descripcion']?.toString(),
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
      moneda: (map['moneda'] ?? 'CUP').toString(),
      categoriaId: map['categoria_id']?.toString(),
      imagenPrincipalUrl: map['imagen_principal_url']?.toString(),
      disponible: map['disponible'] != false,
      publicado: map['publicado'] != false,
      mostrarDisponibilidad: map['mostrar_disponibilidad'] != false,
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      unidadMedida: unidad,
    );
  }
}