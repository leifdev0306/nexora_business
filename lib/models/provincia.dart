// models/provincia.dart
class Provincia {
  final int id;
  final String nombre;
  const Provincia({required this.id, required this.nombre});
  factory Provincia.fromMap(Map<String, dynamic> map) => Provincia(
        id: (map['id'] as num).toInt(),
        nombre: (map['nombre'] ?? '').toString(),
      );
}