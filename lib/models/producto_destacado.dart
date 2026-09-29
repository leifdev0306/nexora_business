// ============================================================
//  models/producto_destacado.dart
//  Producto popular dentro del catálogo público.
//  Viene de la vista `productos_mas_vendidos_publicos`.
// ============================================================

class ProductoDestacado {
  final String id;
  final String tiendaId;
  final String tiendaNombre;
  final String? tiendaLogo;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String moneda;
  final String? imagenPrincipalUrl;
  final bool disponible;
  final String? unidadMedida;
  final int totalVendido;

  const ProductoDestacado({
    required this.id,
    required this.tiendaId,
    required this.tiendaNombre,
    this.tiendaLogo,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.moneda,
    this.imagenPrincipalUrl,
    required this.disponible,
    this.unidadMedida,
    this.totalVendido = 0,
  });

  factory ProductoDestacado.fromMap(Map<String, dynamic> map) {
    return ProductoDestacado(
      id: map['id'].toString(),
      tiendaId: (map['tienda_id'] ?? '').toString(),
      tiendaNombre: (map['tienda_nombre'] ?? '').toString(),
      tiendaLogo: map['tienda_logo']?.toString(),
      nombre: (map['nombre'] ?? '').toString(),
      descripcion: map['descripcion']?.toString(),
      precio: (map['precio'] as num?)?.toDouble() ?? 0,
      moneda: (map['moneda'] ?? 'CUP').toString(),
      imagenPrincipalUrl: map['imagen_principal_url']?.toString(),
      disponible: map['disponible'] != false,
      unidadMedida: map['unidad_medida']?.toString(),
      totalVendido: (map['total_vendido'] as num?)?.toInt() ?? 0,
    );
  }
}