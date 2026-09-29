// models/municipio.dart
class Municipio {
  final int id;
  final int provinciaId;
  final String nombre;
  const Municipio({
    required this.id,
    required this.provinciaId,
    required this.nombre,
  });
  factory Municipio.fromMap(Map<String, dynamic> map) => Municipio(
        id: (map['id'] as num).toInt(),
        provinciaId: (map['provincia_id'] as num).toInt(),
        nombre: (map['nombre'] ?? '').toString(),
      );
}