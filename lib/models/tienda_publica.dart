// ============================================================
//  tienda_publica.dart  ·  NEXORA BUSINESS
//  Modelo extendido + catálogo + servicios + reseñas
//  SIN DATOS SIMULADOS — solo estructura para producción
// ============================================================

class TiendaPublica {
  final String empresaId;
  final String nombre;
  final String slug;
  final String descripcion;
  final String? telefono;
  final String? whatsapp;
  final String? email;
  final String? direccion;
  final String? horario;

  final List<String> productosPublicados;   // IDs de tus productos
  final List<ProductoPublicado> catalogo;   // catálogo público
  final List<ServicioPublico> servicios;    // servicios ofrecidos
  final List<ResenaPublica> resenas;        // reseñas

  final String categoriaId;
  final double rating;
  final int totalResenas;
  final bool verificado;
  final bool destacada;
  final DateTime? ultimaActividad;

  final bool activa;
  final int visitas;
  final DateTime updatedAt;
  final double? latitud;
  final double? longitud;

  TiendaPublica({
    required this.empresaId,
    required this.nombre,
    required this.slug,
    required this.descripcion,
    this.telefono,
    this.whatsapp,
    this.email,
    this.direccion,
    this.horario,
    this.productosPublicados = const [],
    this.catalogo = const [],
    this.servicios = const [],
    this.resenas = const [],
    this.categoriaId = 'otros',
    this.rating = 0,
    this.totalResenas = 0,
    this.verificado = false,
    this.destacada = false,
    this.ultimaActividad,
    this.activa = true,
    this.visitas = 0,
    required this.updatedAt,
    this.latitud,
    this.longitud,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;

  String get urlPublica => 'https://nexora.app/tienda/$slug';

  int get totalProductos =>
      catalogo.isNotEmpty ? catalogo.length : productosPublicados.length;

  factory TiendaPublica.porDefecto({
    required String empresaId,
    required String nombreEmpresa,
  }) =>
      TiendaPublica(
        empresaId: empresaId,
        nombre: nombreEmpresa,
        slug: generarSlug(nombreEmpresa),
        descripcion: 'Bienvenido a nuestra tienda',
        activa: true,
        updatedAt: DateTime.now(),
      );

  static String generarSlug(String input) {
    final lower = input.toLowerCase().trim();
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to   = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final c = lower[i];
      final idx = from.indexOf(c);
      if (idx >= 0) {
        buffer.write(to[idx]);
      } else if (RegExp(r'[a-z0-9]').hasMatch(c)) {
        buffer.write(c);
      } else if (c == ' ' || c == '-' || c == '_') {
        buffer.write('-');
      }
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  TiendaPublica copyWith({
    String? empresaId, String? nombre, String? slug, String? descripcion,
    String? telefono, String? whatsapp, String? email, String? direccion,
    String? horario, List<String>? productosPublicados,
    List<ProductoPublicado>? catalogo, List<ServicioPublico>? servicios,
    List<ResenaPublica>? resenas, String? categoriaId, double? rating,
    int? totalResenas, bool? verificado, bool? destacada,
    DateTime? ultimaActividad, bool? activa, int? visitas,
    DateTime? updatedAt, double? latitud, double? longitud,
    bool limpiarUbicacion = false,
  }) =>
      TiendaPublica(
        empresaId: empresaId ?? this.empresaId,
        nombre: nombre ?? this.nombre,
        slug: slug ?? this.slug,
        descripcion: descripcion ?? this.descripcion,
        telefono: telefono ?? this.telefono,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email ?? this.email,
        direccion: direccion ?? this.direccion,
        horario: horario ?? this.horario,
        productosPublicados: productosPublicados ?? this.productosPublicados,
        catalogo: catalogo ?? this.catalogo,
        servicios: servicios ?? this.servicios,
        resenas: resenas ?? this.resenas,
        categoriaId: categoriaId ?? this.categoriaId,
        rating: rating ?? this.rating,
        totalResenas: totalResenas ?? this.totalResenas,
        verificado: verificado ?? this.verificado,
        destacada: destacada ?? this.destacada,
        ultimaActividad: ultimaActividad ?? this.ultimaActividad,
        activa: activa ?? this.activa,
        visitas: visitas ?? this.visitas,
        updatedAt: updatedAt ?? this.updatedAt,
        latitud: limpiarUbicacion ? null : (latitud ?? this.latitud),
        longitud: limpiarUbicacion ? null : (longitud ?? this.longitud),
      );

  Map<String, dynamic> toJson() => {
        'empresaId': empresaId, 'nombre': nombre, 'slug': slug,
        'descripcion': descripcion, 'telefono': telefono,
        'whatsapp': whatsapp, 'email': email, 'direccion': direccion,
        'horario': horario, 'productosPublicados': productosPublicados,
        'catalogo': catalogo.map((p) => p.toJson()).toList(),
        'servicios': servicios.map((s) => s.toJson()).toList(),
        'resenas': resenas.map((r) => r.toJson()).toList(),
        'categoriaId': categoriaId, 'rating': rating,
        'totalResenas': totalResenas, 'verificado': verificado,
        'destacada': destacada,
        'ultimaActividad': ultimaActividad?.toIso8601String(),
        'activa': activa, 'visitas': visitas,
        'updatedAt': updatedAt.toIso8601String(),
        'latitud': latitud, 'longitud': longitud,
      };

  factory TiendaPublica.fromJson(Map<String, dynamic> j) => TiendaPublica(
        empresaId: j['empresaId'] ?? '',
        nombre: j['nombre'] ?? '',
        slug: j['slug'] ?? '',
        descripcion: j['descripcion'] ?? '',
        telefono: j['telefono'], whatsapp: j['whatsapp'],
        email: j['email'], direccion: j['direccion'], horario: j['horario'],
        productosPublicados:
            (j['productosPublicados'] as List?)?.cast<String>() ?? const [],
        catalogo: (j['catalogo'] as List?)
                ?.map((e) => ProductoPublicado.fromJson(Map<String, dynamic>.from(e)))
                .toList() ?? const [],
        servicios: (j['servicios'] as List?)
                ?.map((e) => ServicioPublico.fromJson(Map<String, dynamic>.from(e)))
                .toList() ?? const [],
        resenas: (j['resenas'] as List?)
                ?.map((e) => ResenaPublica.fromJson(Map<String, dynamic>.from(e)))
                .toList() ?? const [],
        categoriaId: j['categoriaId'] ?? 'otros',
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        totalResenas: (j['totalResenas'] ?? 0) as int,
        verificado: j['verificado'] ?? false,
        destacada: j['destacada'] ?? false,
        ultimaActividad: j['ultimaActividad'] != null
            ? DateTime.tryParse(j['ultimaActividad']) : null,
        activa: j['activa'] ?? true,
        visitas: (j['visitas'] ?? 0) as int,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
        latitud: (j['latitud'] as num?)?.toDouble(),
        longitud: (j['longitud'] as num?)?.toDouble(),
      );
}

// ============================================================
//  ProductoPublicado
// ============================================================
class ProductoPublicado {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final String categoria;
  final String unidad;
  final int unidadesVendidas;
  final bool destacado;
  final bool disponible;

  const ProductoPublicado({
    required this.id, required this.nombre, this.descripcion,
    required this.precio, this.imagenUrl, this.categoria = 'General',
    this.unidad = 'unidad', this.unidadesVendidas = 0,
    this.destacado = false, this.disponible = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'nombre': nombre, 'descripcion': descripcion,
        'precio': precio, 'imagenUrl': imagenUrl, 'categoria': categoria,
        'unidad': unidad, 'unidadesVendidas': unidadesVendidas,
        'destacado': destacado, 'disponible': disponible,
      };

  factory ProductoPublicado.fromJson(Map<String, dynamic> j) => ProductoPublicado(
        id: j['id'] ?? '', nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'],
        precio: ((j['precio'] ?? 0) as num).toDouble(),
        imagenUrl: j['imagenUrl'], categoria: j['categoria'] ?? 'General',
        unidad: j['unidad'] ?? 'unidad',
        unidadesVendidas: (j['unidadesVendidas'] ?? 0) as int,
        destacado: j['destacado'] ?? false,
        disponible: j['disponible'] ?? true,
      );
}

// ============================================================
//  ServicioPublico
// ============================================================
class ServicioPublico {
  final String id;
  final String empresaId;
  final String nombreEmpresa;
  final String categoriaId;
  final String nombre;
  final String descripcion;
  final double? precioDesde;
  final String? precioNota;
  final String? imagenUrl;
  final List<String> galeria;
  final String? telefono;
  final String? whatsapp;
  final bool activo;
  final bool destacado;
  final List<String> tags;
  final String? horario;
  final double? latitud;
  final double? longitud;
  final int vistas;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServicioPublico({
    required this.id, required this.empresaId, required this.nombreEmpresa,
    required this.categoriaId, required this.nombre, required this.descripcion,
    this.precioDesde, this.precioNota, this.imagenUrl,
    this.galeria = const [], this.telefono, this.whatsapp,
    this.activo = true, this.destacado = false, this.tags = const [],
    this.horario, this.latitud, this.longitud, this.vistas = 0,
    required this.createdAt, required this.updatedAt,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;

  String get precioTexto {
    if (precioNota != null && precioNota!.isNotEmpty) return precioNota!;
    if (precioDesde != null) return 'Desde \$${precioDesde!.toStringAsFixed(0)}';
    return 'A consultar';
  }

  ServicioPublico copyWith({
    String? categoriaId, String? nombre, String? descripcion,
    double? precioDesde, String? precioNota, String? imagenUrl,
    List<String>? galeria, String? telefono, String? whatsapp,
    bool? activo, bool? destacado, List<String>? tags, String? horario,
    double? latitud, double? longitud, int? vistas, DateTime? updatedAt,
    bool limpiarPrecio = false, bool limpiarUbicacion = false,
  }) =>
      ServicioPublico(
        id: id, empresaId: empresaId, nombreEmpresa: nombreEmpresa,
        categoriaId: categoriaId ?? this.categoriaId,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        precioDesde: limpiarPrecio ? null : (precioDesde ?? this.precioDesde),
        precioNota: precioNota ?? this.precioNota,
        imagenUrl: imagenUrl ?? this.imagenUrl,
        galeria: galeria ?? this.galeria,
        telefono: telefono ?? this.telefono,
        whatsapp: whatsapp ?? this.whatsapp,
        activo: activo ?? this.activo,
        destacado: destacado ?? this.destacado,
        tags: tags ?? this.tags,
        horario: horario ?? this.horario,
        latitud: limpiarUbicacion ? null : (latitud ?? this.latitud),
        longitud: limpiarUbicacion ? null : (longitud ?? this.longitud),
        vistas: vistas ?? this.vistas,
        createdAt: createdAt, updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'empresaId': empresaId, 'nombreEmpresa': nombreEmpresa,
        'categoriaId': categoriaId, 'nombre': nombre, 'descripcion': descripcion,
        'precioDesde': precioDesde, 'precioNota': precioNota,
        'imagenUrl': imagenUrl, 'galeria': galeria, 'telefono': telefono,
        'whatsapp': whatsapp, 'activo': activo, 'destacado': destacado,
        'tags': tags, 'horario': horario, 'latitud': latitud,
        'longitud': longitud, 'vistas': vistas,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ServicioPublico.fromJson(Map<String, dynamic> j) => ServicioPublico(
        id: j['id'] ?? '', empresaId: j['empresaId'] ?? '',
        nombreEmpresa: j['nombreEmpresa'] ?? '',
        categoriaId: j['categoriaId'] ?? 'otros',
        nombre: j['nombre'] ?? '', descripcion: j['descripcion'] ?? '',
        precioDesde: (j['precioDesde'] as num?)?.toDouble(),
        precioNota: j['precioNota'], imagenUrl: j['imagenUrl'],
        galeria: (j['galeria'] as List?)?.cast<String>() ?? const [],
        telefono: j['telefono'], whatsapp: j['whatsapp'],
        activo: j['activo'] ?? true, destacado: j['destacado'] ?? false,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        horario: j['horario'],
        latitud: (j['latitud'] as num?)?.toDouble(),
        longitud: (j['longitud'] as num?)?.toDouble(),
        vistas: (j['vistas'] ?? 0) as int,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt']) : DateTime.now(),
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt']) : DateTime.now(),
      );
}

// ============================================================
//  ResenaPublica
// ============================================================
class ResenaPublica {
  final String id;
  final String targetId;
  final String targetTipo;
  final String autorNombre;
  final double rating;
  final String? comentario;
  final DateTime fecha;

  const ResenaPublica({
    required this.id, required this.targetId, required this.targetTipo,
    required this.autorNombre, required this.rating,
    this.comentario, required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'targetId': targetId, 'targetTipo': targetTipo,
        'autorNombre': autorNombre, 'rating': rating,
        'comentario': comentario, 'fecha': fecha.toIso8601String(),
      };

  factory ResenaPublica.fromJson(Map<String, dynamic> j) => ResenaPublica(
        id: j['id'] ?? '', targetId: j['targetId'] ?? '',
        targetTipo: j['targetTipo'] ?? 'tienda',
        autorNombre: j['autorNombre'] ?? 'Anónimo',
        rating: ((j['rating'] ?? 0) as num).toDouble(),
        comentario: j['comentario'],
        fecha: j['fecha'] != null ? DateTime.parse(j['fecha']) : DateTime.now(),
      );
}

// ============================================================
//  Categorías
// ============================================================
class CategoriasPublicas {
  static const tienda = <String, String>{
    'bodega': 'Bodega / Víveres',
    'farmacia': 'Farmacia',
    'restaurante': 'Restaurante',
    'cafeteria': 'Cafetería',
    'panaderia': 'Panadería',
    'ferreteria': 'Ferretería',
    'ropa': 'Ropa y calzado',
    'electronica': 'Electrónica',
    'hogar': 'Hogar',
    'belleza': 'Belleza',
    'mascotas': 'Mascotas',
    'otros': 'Otros',
  };

  static const servicio = <String, String>{
    'reparacion': 'Reparación',
    'fabricacion': 'Fabricación',
    'estetica': 'Estética / Belleza',
    'barberia': 'Barbería',
    'limpieza': 'Limpieza',
    'transporte': 'Transporte',
    'diseno': 'Diseño',
    'informatica': 'Informática',
    'educacion': 'Educación',
    'fotografia': 'Fotografía',
    'mantenimiento': 'Mantenimiento',
    'construccion': 'Construcción',
    'eventos': 'Eventos',
    'otros': 'Otros',
  };

  static String nombreTienda(String id) => tienda[id] ?? 'Otros';
  static String nombreServicio(String id) => servicio[id] ?? 'Otros';
}