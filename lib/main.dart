import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tu_mipyme/Screens/mi_tienda_screen.dart'
    show keyTiendaDeEmpresa, MiTiendaScreen;
import 'package:tu_mipyme/Screens/productos_publicados_screen.dart';
import 'package:tu_mipyme/Screens/publicar_producto_screen.dart';
import 'package:tu_mipyme/Screens/tiendas_screen.dart';
import 'package:tu_mipyme/Screens/vista_tienda_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/estadisticas_vendedores_screen.dart';
import 'screens/vendedores_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/about_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/nuevo_producto_screen.dart';
import 'screens/reabastecer_screen.dart';
import 'screens/gastos_screen.dart';
import 'screens/nuevo_gasto_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/metas_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/nueva_venta_screen.dart';
import 'screens/pago_screen.dart';
import 'screens/servicio_cancelado_screen.dart';
import 'screens/user_guide_screen.dart';
import 'screens/fiscal_screen.dart';
import 'screens/sucursales_screen.dart';
import 'screens/nominas_screen.dart';
import 'screens/mermas_screen.dart';
import 'screens/movimientos_sucursales_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/deudas_screen.dart';
import 'screens/facturacion_screen.dart';
import 'screens/soporte_screen.dart';
import 'screens/alianzas_screen.dart';
import 'screens/referidos_screen.dart';
import 'screens/transferencias_screen.dart';
import 'screens/cierre_diario_screen.dart';

import 'models/tienda_publica.dart';
import 'responsive_helper.dart';
import 'services/image_cache_warmer.dart';
import 'widgets/cached_product_image.dart';

part 'main.g.dart';

const String APP_NAME = 'Nexora Business';
const String APP_VERSION = '2.4.0';

const String supabaseUrl = 'https://kmqffbxzzfbfrcbsluqs.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttcWZmYnh6emZiZnJjYnNsdXFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzODYzNTAsImV4cCI6MjEwNTk2MjM1MH0.'
    'gq7gHh5mJE31jexMMLjouBS3_QcWB68BI1plbHK0bSg';

final uuid = Uuid();

const int LIMITE_VENDEDORES_BASE = 2;
const int LIMITE_VENDEDORES_PREMIUM = 5;
const double COSTO_PLAN_BASE = 500.0;
const double COSTO_PLAN_PREMIUM = 1000.0;
const double COSTO_POR_SUCURSAL = 500.0;
const int DIAS_PRUEBA = 3;
const int DIAS_PAGO_VIGENCIA = 30;
const int DIAS_GRACIA = 3;
const int DIAS_TOTAL_VIGENCIA = DIAS_PAGO_VIGENCIA + DIAS_GRACIA;

const Color colorFondoOscuro = Color(0xFF1E1E2E);
const Color colorFondoOscuroCard = Color(0xFF2D2D44);
const Color colorAcentoOscuro = Color(0xFF7C8BFF);
const Color colorAcentoMorado = Color(0xFF9B6BFF);
const Color colorTextoOscuro = Color(0xFFE4E4F0);
const Color colorTextoOscuroSecundario = Color(0xFFA0A0B8);
const Color colorBordeOscuro = Color(0xFF3A3A52);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================================
//  MODELOS HIVE
// ============================================================

@HiveType(typeId: 0)
class Producto extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) double precioCompra;
  @HiveField(3) double precioVenta;
  @HiveField(4) double stock;
  @HiveField(5) String? categoriaId;
  @HiveField(6) List<Map<String, dynamic>> lotes;
  @HiveField(7) String? empresaId;
  @HiveField(8) DateTime? updatedAt;
  @HiveField(9) String? sucursalId;
  @HiveField(10) double precioTransferencia;
  @HiveField(11) double precioMayoristaEfectivo;
  @HiveField(12) double precioMayoristaTransferencia;
  @HiveField(13) String unidadMedida;
  @HiveField(14) String? sku;
  @HiveField(15) String? barcode;
  @HiveField(16) String? imageUrl;
  @HiveField(17) String? descripcion;
  @HiveField(18) double lowStockThreshold;
  @HiveField(19) bool activo;
  @HiveField(20) bool isTrialData;

  Producto({
    required this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    this.categoriaId,
    this.lotes = const [],
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.precioTransferencia = 0,
    this.precioMayoristaEfectivo = 0,
    this.precioMayoristaTransferencia = 0,
    this.unidadMedida = 'unidad',
    this.sku,
    this.barcode,
    this.imageUrl,
    this.descripcion,
    this.lowStockThreshold = 0,
    this.activo = true,
    this.isTrialData = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'category_id': categoriaId,
        'name': nombre,
        'sku': sku,
        'barcode': barcode,
        'image_url': imageUrl,
        'unit': unidadMedida,
        'purchase_price': precioCompra,
        'retail_price': precioVenta,
        'wholesale_price': precioMayoristaEfectivo,
        'description': descripcion,
        'low_stock_threshold': lowStockThreshold,
        'active': activo,
        'is_trial_data': isTrialData,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Producto.fromJson(Map<String, dynamic> json,
      {String? branchId, double? stock, List<Map<String, dynamic>>? lotes}) {
    return Producto(
      id: json['id'],
      nombre: json['name'] ?? '',
      precioCompra: ((json['purchase_price'] ?? 0) as num).toDouble(),
      precioVenta: ((json['retail_price'] ?? 0) as num).toDouble(),
      stock: stock ?? 0,
      categoriaId: json['category_id'],
      lotes: lotes ?? const [],
      empresaId: json['company_id'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      sucursalId: branchId,
      precioTransferencia: ((json['wholesale_price'] ?? 0) as num).toDouble(),
      precioMayoristaEfectivo:
          ((json['wholesale_price'] ?? 0) as num).toDouble(),
      precioMayoristaTransferencia:
          ((json['wholesale_price'] ?? 0) as num).toDouble(),
      unidadMedida: json['unit'] ?? 'unidad',
      sku: json['sku'],
      barcode: json['barcode'],
      imageUrl: json['image_url'],
      descripcion: json['description'],
      lowStockThreshold:
          ((json['low_stock_threshold'] ?? 0) as num).toDouble(),
      activo: json['active'] ?? true,
      isTrialData: json['is_trial_data'] ?? false,
    );
  }
}

@HiveType(typeId: 1)
class Venta extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String productoId;
  @HiveField(2) String productoNombre;
  @HiveField(3) double cantidad;
  @HiveField(4) double precioUnitario;
  @HiveField(5) double total;
  @HiveField(6) String metodoPago;
  @HiveField(7) DateTime fecha;
  @HiveField(8) String? nota;
  @HiveField(9) String? clienteId;
  @HiveField(10) double costoUnitario;
  @HiveField(11) double costoTotal;
  @HiveField(12) String? saleGroupId;
  @HiveField(13) String? empresaId;
  @HiveField(14) DateTime? updatedAt;
  @HiveField(15) String? usuarioId;
  @HiveField(16) String? sucursalId;
  @HiveField(17) String? tipoCliente;
  @HiveField(18) double? totalUSD;
  @HiveField(19) double? tasaCambio;
  @HiveField(20) String? moneda;
  @HiveField(21) double subtotal;
  @HiveField(22) double descuento;
  @HiveField(23) double impuesto;
  @HiveField(24) String? estado;
  @HiveField(25) int? saleNumber;

  Venta({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    required this.metodoPago,
    required this.fecha,
    this.nota,
    this.clienteId,
    required this.costoUnitario,
    required this.costoTotal,
    this.saleGroupId,
    this.empresaId,
    this.updatedAt,
    this.usuarioId,
    this.sucursalId,
    this.tipoCliente,
    this.totalUSD,
    this.tasaCambio,
    this.moneda,
    this.subtotal = 0,
    this.descuento = 0,
    this.impuesto = 0,
    this.estado = 'completed',
    this.saleNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'customer_id': clienteId,
        'seller_id': usuarioId,
        'status': estado ?? 'completed',
        'subtotal': subtotal,
        'discount': descuento,
        'tax': impuesto,
        'total': total,
        'total_cup': total,
        'exchange_rate': tasaCambio ?? 1,
        'mode': 'real_time',
        'note': nota,
        'is_trial_data': false,
        'completed_at': fecha.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Venta.fromJson(Map<String, dynamic> json,
      {String? productoId,
      String? productoNombre,
      double? cantidad,
      double? precioUnitario,
      double? costoUnitario,
      double? costoTotal,
      String? metodoPago}) {
    return Venta(
      id: json['id'],
      productoId: productoId ?? '',
      productoNombre: productoNombre ?? '',
      cantidad: cantidad ?? 0,
      precioUnitario: precioUnitario ?? 0,
      total: ((json['total'] ?? 0) as num).toDouble(),
      metodoPago: metodoPago ?? 'Efectivo CUP',
      fecha: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      nota: json['note'],
      clienteId: json['customer_id'],
      costoUnitario: costoUnitario ?? 0,
      costoTotal: costoTotal ?? 0,
      saleGroupId: json['id'],
      empresaId: json['company_id'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      usuarioId: json['seller_id'],
      sucursalId: json['branch_id'],
      totalUSD: (json['total_usd'] as num?)?.toDouble(),
      tasaCambio: (json['exchange_rate'] as num?)?.toDouble(),
      moneda: json['currency_code'],
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
      descuento: ((json['discount'] ?? 0) as num).toDouble(),
      impuesto: ((json['tax'] ?? 0) as num).toDouble(),
      estado: json['status'] ?? 'completed',
      saleNumber: json['sale_number'] is int ? json['sale_number'] : null,
    );
  }
}

@HiveType(typeId: 2)
class Gasto extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String concepto;
  @HiveField(2) double monto;
  @HiveField(3) String categoria;
  @HiveField(4) DateTime fecha;
  @HiveField(5) String? nota;
  @HiveField(6) String? empresaId;
  @HiveField(7) DateTime? updatedAt;
  @HiveField(8) String? sucursalId;
  @HiveField(9) String? moneda;
  @HiveField(10) double? tasaCambio;

  Gasto({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.nota,
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.moneda,
    this.tasaCambio,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'category': categoria,
        'description': concepto,
        'amount': monto,
        'expense_date': DateFormat('yyyy-MM-dd').format(fecha),
        'note': nota,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
        id: json['id'],
        concepto: json['description'] ?? '',
        monto: ((json['amount'] ?? 0) as num).toDouble(),
        categoria: json['category'] ?? 'Otros',
        fecha: json['expense_date'] != null
            ? DateTime.parse(json['expense_date'])
            : DateTime.now(),
        nota: json['note'],
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        sucursalId: json['branch_id'],
      );
}

@HiveType(typeId: 3)
class Cliente extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) String? telefono;
  @HiveField(3) String? direccion;
  @HiveField(4) double? saldoPendiente;
  @HiveField(5) String? empresaId;
  @HiveField(6) DateTime? updatedAt;
  @HiveField(7) String? email;
  @HiveField(8) String? taxId;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    this.saldoPendiente,
    this.empresaId,
    this.updatedAt,
    this.email,
    this.taxId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'name': nombre,
        'phone': telefono,
        'email': email,
        'address': direccion,
        'tax_id': taxId,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'],
        nombre: json['name'] ?? '',
        telefono: json['phone'],
        direccion: json['address'],
        saldoPendiente: (json['saldo_pendiente'] as num?)?.toDouble(),
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        email: json['email'],
        taxId: json['tax_id'],
      );
}

@HiveType(typeId: 4)
class Categoria extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) String? descripcion;
  @HiveField(3) String? empresaId;
  @HiveField(4) DateTime? updatedAt;
  @HiveField(5) String? icon;
  @HiveField(6) int sortOrder;
  @HiveField(7) bool activo;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.empresaId,
    this.updatedAt,
    this.icon,
    this.sortOrder = 0,
    this.activo = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': nombre,
        'icon': icon,
        'active': activo,
        'sort_order': sortOrder,
      };

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['name'] ?? '',
        empresaId: null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        icon: json['icon'],
        sortOrder: (json['sort_order'] ?? 0) as int,
        activo: json['active'] ?? true,
      );
}

@HiveType(typeId: 5)
class MetaVenta extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) double metaDiaria;
  @HiveField(2) double metaSemanal;
  @HiveField(3) double metaMensual;
  @HiveField(4) DateTime fechaActualizacion;
  @HiveField(5) String? empresaId;
  @HiveField(6) DateTime? updatedAt;
  @HiveField(7) String? sucursalId;
  @HiveField(8) String? usuarioId;

  MetaVenta({
    required this.id,
    required this.metaDiaria,
    required this.metaSemanal,
    required this.metaMensual,
    required this.fechaActualizacion,
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.usuarioId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'user_id': usuarioId,
        'period_start': DateFormat('yyyy-MM-dd').format(fechaActualizacion),
        'period_end': DateFormat('yyyy-MM-dd').format(
            DateTime(fechaActualizacion.year, fechaActualizacion.month + 1, 1)),
        'target_amount': metaMensual,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory MetaVenta.fromJson(Map<String, dynamic> json) => MetaVenta(
        id: json['id'],
        metaDiaria: ((json['meta_diaria'] ?? 0) as num).toDouble(),
        metaSemanal: ((json['meta_semanal'] ?? 0) as num).toDouble(),
        metaMensual: ((json['target_amount'] ?? 0) as num).toDouble(),
        fechaActualizacion: json['period_start'] != null
            ? DateTime.parse(json['period_start'])
            : DateTime.now(),
        empresaId: json['company_id'],
        sucursalId: json['branch_id'],
        usuarioId: json['user_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

@HiveType(typeId: 6)
class Usuario extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String email;
  @HiveField(2) String rol;
  @HiveField(3) String? empresaId;
  @HiveField(4) DateTime? updatedAt;
  @HiveField(5) String? sucursalId;
  @HiveField(6) String? fullName;
  @HiveField(7) String? phone;
  @HiveField(8) String? avatarUrl;
  @HiveField(9) bool active;

  Usuario({
    required this.id,
    required this.email,
    required this.rol,
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'role': rol,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'active': active,
        'default_branch_id': sucursalId,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        email: json['email'] ?? '',
        rol: json['role'] ?? 'vendedor',
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        sucursalId: json['default_branch_id'],
        fullName: json['full_name'],
        phone: json['phone'],
        avatarUrl: json['avatar_url'],
        active: json['active'] ?? true,
      );
}

@HiveType(typeId: 7)
class Sucursal extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String nombre;
  @HiveField(2) String direccion;
  @HiveField(3) String? telefono;
  @HiveField(4) String? empresaId;
  @HiveField(5) String? gestorId;
  @HiveField(6) DateTime? createdAt;
  @HiveField(7) DateTime? updatedAt;
  @HiveField(8) bool activo;
  @HiveField(9) bool isMain;
  @HiveField(10) String? code;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.telefono,
    this.empresaId,
    this.gestorId,
    this.createdAt,
    this.updatedAt,
    this.activo = true,
    this.isMain = false,
    this.code,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'name': nombre,
        'code': code,
        'address': direccion,
        'phone': telefono,
        'active': activo,
        'is_main': isMain,
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        id: json['id'],
        nombre: json['name'] ?? '',
        direccion: json['address'] ?? '',
        telefono: json['phone'],
        empresaId: json['company_id'],
        gestorId: null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        activo: json['active'] ?? true,
        isMain: json['is_main'] ?? false,
        code: json['code'],
      );
}

@HiveType(typeId: 8)
class Empleado extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String usuarioId;
  @HiveField(2) double salarioBase;
  @HiveField(3) String tipoContrato;
  @HiveField(4) double? comisionPorcentaje;
  @HiveField(5) DateTime fechaContratacion;
  @HiveField(6) bool activo;
  @HiveField(7) String? empresaId;
  @HiveField(8) DateTime? updatedAt;
  @HiveField(9) String? sucursalId;
  @HiveField(10) String? nombre;
  @HiveField(11) String? position;

  Empleado({
    required this.id,
    required this.usuarioId,
    required this.salarioBase,
    required this.tipoContrato,
    this.comisionPorcentaje,
    required this.fechaContratacion,
    this.activo = true,
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.nombre,
    this.position,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'user_id': usuarioId.isEmpty ? null : usuarioId,
        'branch_id': sucursalId,
        'name': nombre ?? 'Empleado',
        'position': position ?? tipoContrato,
        'salary': salarioBase,
        'active': activo,
        'hire_date': DateFormat('yyyy-MM-dd').format(fechaContratacion),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Empleado.fromJson(Map<String, dynamic> json) => Empleado(
        id: json['id'],
        usuarioId: json['user_id'] ?? '',
        salarioBase: ((json['salary'] ?? 0) as num).toDouble(),
        tipoContrato: json['position'] ?? 'fijo',
        comisionPorcentaje: null,
        fechaContratacion: json['hire_date'] != null
            ? DateTime.parse(json['hire_date'])
            : DateTime.now(),
        activo: json['active'] ?? true,
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        sucursalId: json['branch_id'],
        nombre: json['name'],
        position: json['position'],
      );
}

@HiveType(typeId: 9)
class Nomina extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String empleadoId;
  @HiveField(2) DateTime periodo;
  @HiveField(3) double salarioBase;
  @HiveField(4) double comisiones;
  @HiveField(5) double deducciones;
  @HiveField(6) double totalPagado;
  @HiveField(7) DateTime fechaPago;
  @HiveField(8) String metodoPago;
  @HiveField(9) String? nota;
  @HiveField(10) String? empresaId;
  @HiveField(11) DateTime? updatedAt;
  @HiveField(12) String? sucursalId;
  @HiveField(13) String? status;

  Nomina({
    required this.id,
    required this.empleadoId,
    required this.periodo,
    required this.salarioBase,
    required this.comisiones,
    required this.deducciones,
    required this.totalPagado,
    required this.fechaPago,
    required this.metodoPago,
    this.nota,
    this.empresaId,
    this.updatedAt,
    this.sucursalId,
    this.status = 'paid',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'period_start': DateFormat('yyyy-MM-dd').format(periodo),
        'period_end': DateFormat('yyyy-MM-dd')
            .format(DateTime(periodo.year, periodo.month + 1, 0)),
        'status': status,
        'total_amount': totalPagado,
        'paid_at': fechaPago.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Nomina.fromJson(Map<String, dynamic> json) => Nomina(
        id: json['id'],
        empleadoId: json['empleado_id'] ?? '',
        periodo: json['period_start'] != null
            ? DateTime.parse(json['period_start'])
            : DateTime.now(),
        salarioBase: ((json['base_salary'] ?? 0) as num).toDouble(),
        comisiones: ((json['bonuses'] ?? 0) as num).toDouble(),
        deducciones: ((json['deductions'] ?? 0) as num).toDouble(),
        totalPagado: ((json['total_amount'] ?? 0) as num).toDouble(),
        fechaPago: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'])
            : DateTime.now(),
        metodoPago: 'Efectivo',
        empresaId: json['company_id'],
        sucursalId: json['branch_id'],
        status: json['status'] ?? 'draft',
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

@HiveType(typeId: 10)
class Alianza extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String empresaId;
  @HiveField(2) String empresaAliadaId;
  @HiveField(3) String estado;
  @HiveField(4) DateTime fechaSolicitud;
  @HiveField(5) DateTime? fechaRespuesta;
  @HiveField(6) String? empresaIdLocal;
  @HiveField(7) DateTime? updatedAt;

  Alianza({
    required this.id,
    required this.empresaId,
    required this.empresaAliadaId,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaRespuesta,
    this.empresaIdLocal,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'partner_company_id': empresaAliadaId,
        'status': estado,
        'created_at': fechaSolicitud.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Alianza.fromJson(Map<String, dynamic> json) => Alianza(
        id: json['id'],
        empresaId: json['company_id'] ?? '',
        empresaAliadaId: json['partner_company_id'] ?? '',
        estado: json['status'] ?? 'pending',
        fechaSolicitud: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        fechaRespuesta: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

@HiveType(typeId: 11)
class Transferencia extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String ventaId;
  @HiveField(2) String nombreCompleto;
  @HiveField(3) String carnetIdentidad;
  @HiveField(4) String numeroTelefono;
  @HiveField(5) String numeroTransferencia;
  @HiveField(6) DateTime fechaHora;
  @HiveField(7) double monto;
  @HiveField(8) String? empresaId;
  @HiveField(9) DateTime? updatedAt;
  @HiveField(10) String? sucursalOrigenId;
  @HiveField(11) String? sucursalDestinoId;
  @HiveField(12) String? status;
  @HiveField(13) String? nota;

  Transferencia({
    required this.id,
    required this.ventaId,
    required this.nombreCompleto,
    required this.carnetIdentidad,
    required this.numeroTelefono,
    required this.numeroTransferencia,
    required this.fechaHora,
    required this.monto,
    this.empresaId,
    this.updatedAt,
    this.sucursalOrigenId,
    this.sucursalDestinoId,
    this.status,
    this.nota,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'source_branch_id': sucursalOrigenId,
        'destination_branch_id': sucursalDestinoId,
        'status': status ?? 'pending',
        'note': nota,
        'created_at': fechaHora.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Transferencia.fromJson(Map<String, dynamic> json) => Transferencia(
        id: json['id'],
        ventaId: '',
        nombreCompleto: '',
        carnetIdentidad: '',
        numeroTelefono: '',
        numeroTransferencia: '',
        fechaHora: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        monto: 0,
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        sucursalOrigenId: json['source_branch_id'],
        sucursalDestinoId: json['destination_branch_id'],
        status: json['status'],
        nota: json['note'],
      );
}

@HiveType(typeId: 12)
class Referido extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String empresaId;
  @HiveField(2) String empresaReferidaId;
  @HiveField(3) DateTime fechaReferido;
  @HiveField(4) DateTime? fechaPago;
  @HiveField(5) String estado;
  @HiveField(6) DateTime? updatedAt;
  @HiveField(7) String? code;

  Referido({
    required this.id,
    required this.empresaId,
    required this.empresaReferidaId,
    required this.fechaReferido,
    this.fechaPago,
    required this.estado,
    this.updatedAt,
    this.code,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'referrer_company_id': empresaId,
        'referred_company_id': empresaReferidaId,
        'code': code,
        'status': estado,
        'created_at': fechaReferido.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Referido.fromJson(Map<String, dynamic> json) => Referido(
        id: json['id'],
        empresaId: json['referrer_company_id'] ?? '',
        empresaReferidaId: json['referred_company_id'] ?? '',
        fechaReferido: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        fechaPago: json['rewarded_at'] != null
            ? DateTime.parse(json['rewarded_at'])
            : null,
        estado: json['status'] ?? 'pending',
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        code: json['code'],
      );
}

@HiveType(typeId: 13)
class Bono extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String empresaId;
  @HiveField(2) String descripcion;
  @HiveField(3) double porcentajeDescuento;
  @HiveField(4) DateTime fechaInicio;
  @HiveField(5) DateTime fechaFin;
  @HiveField(6) bool utilizado;
  @HiveField(7) DateTime? fechaUso;
  @HiveField(8) DateTime? updatedAt;
  @HiveField(9) String? referralId;
  @HiveField(10) String? tipo;

  Bono({
    required this.id,
    required this.empresaId,
    required this.descripcion,
    required this.porcentajeDescuento,
    required this.fechaInicio,
    required this.fechaFin,
    this.utilizado = false,
    this.fechaUso,
    this.updatedAt,
    this.referralId,
    this.tipo = 'referral',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'referral_id': referralId,
        'company_id': empresaId,
        'reward_type': tipo,
        'amount': porcentajeDescuento,
        'starts_at': fechaInicio.toIso8601String(),
        'ends_at': fechaFin.toIso8601String(),
        'used_at': fechaUso?.toIso8601String(),
      };

  factory Bono.fromJson(Map<String, dynamic> json) => Bono(
        id: json['id'],
        empresaId: json['company_id'] ?? '',
        descripcion: 'Bono ${json['reward_type']}',
        porcentajeDescuento: ((json['amount'] ?? 0) as num).toDouble(),
        fechaInicio: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'])
            : DateTime.now(),
        fechaFin: json['ends_at'] != null
            ? DateTime.parse(json['ends_at'])
            : DateTime.now().add(const Duration(days: 30)),
        utilizado: json['used_at'] != null,
        fechaUso: json['used_at'] != null
            ? DateTime.parse(json['used_at'])
            : null,
        referralId: json['referral_id'],
        tipo: json['reward_type'],
      );
}

@HiveType(typeId: 14)
class Merma extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String productoId;
  @HiveField(2) double cantidad;
  @HiveField(3) String motivo;
  @HiveField(4) double costoUnitario;
  @HiveField(5) double costoTotal;
  @HiveField(6) DateTime fecha;
  @HiveField(7) String? usuarioId;
  @HiveField(8) String? sucursalId;
  @HiveField(9) String? empresaId;
  @HiveField(10) DateTime? updatedAt;
  @HiveField(11) bool cancelado;
  @HiveField(12) String? nota;

  Merma({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.motivo,
    required this.costoUnitario,
    required this.costoTotal,
    required this.fecha,
    this.usuarioId,
    this.sucursalId,
    this.empresaId,
    this.updatedAt,
    this.cancelado = false,
    this.nota,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'product_id': productoId,
        'quantity': cantidad,
        'unit_cost': costoUnitario,
        'reason': motivo,
        'note': nota,
        'created_at': fecha.toIso8601String(),
      };

  factory Merma.fromJson(Map<String, dynamic> json) => Merma(
        id: json['id'],
        productoId: json['product_id'] ?? '',
        cantidad: ((json['quantity'] ?? 0) as num).toDouble(),
        motivo: json['reason'] ?? 'otros',
        costoUnitario: ((json['unit_cost'] ?? 0) as num).toDouble(),
        costoTotal: (((json['quantity'] ?? 0) as num) *
                ((json['unit_cost'] ?? 0) as num))
            .toDouble(),
        fecha: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        sucursalId: json['branch_id'],
        empresaId: json['company_id'],
        nota: json['note'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

@HiveType(typeId: 15)
class MovimientoSucursal extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String productoId;
  @HiveField(2) double cantidad;
  @HiveField(3) String sucursalOrigenId;
  @HiveField(4) String sucursalDestinoId;
  @HiveField(5) double costoUnitario;
  @HiveField(6) double costoTotal;
  @HiveField(7) DateTime fecha;
  @HiveField(8) String? usuarioId;
  @HiveField(9) String? empresaId;
  @HiveField(10) DateTime? updatedAt;
  @HiveField(11) bool cancelado;
  @HiveField(12) String? productoOrigenId;
  @HiveField(13) String? productoDestinoId;

  MovimientoSucursal({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.sucursalOrigenId,
    required this.sucursalDestinoId,
    required this.costoUnitario,
    required this.costoTotal,
    required this.fecha,
    this.usuarioId,
    this.empresaId,
    this.updatedAt,
    this.cancelado = false,
    this.productoOrigenId,
    this.productoDestinoId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalDestinoId,
        'product_id': productoId,
        'movement_type': 'transfer_in',
        'quantity': cantidad,
        'unit_cost': costoUnitario,
        'reference_type': 'transfer',
        'reference_id': id,
        'note': null,
        'created_at': fecha.toIso8601String(),
      };

  factory MovimientoSucursal.fromJson(Map<String, dynamic> json) =>
      MovimientoSucursal(
        id: json['id'],
        productoId: json['product_id'] ?? '',
        cantidad: ((json['quantity'] ?? 0) as num).toDouble(),
        sucursalOrigenId: json['source_branch_id'] ?? '',
        sucursalDestinoId: json['branch_id'] ?? '',
        costoUnitario: ((json['unit_cost'] ?? 0) as num).toDouble(),
        costoTotal: (((json['quantity'] ?? 0) as num) *
                ((json['unit_cost'] ?? 0) as num))
            .toDouble(),
        fecha: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        empresaId: json['company_id'],
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

@HiveType(typeId: 16)
class Deuda extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String tipo;
  @HiveField(2) String entidadId;
  @HiveField(3) String concepto;
  @HiveField(4) double monto;
  @HiveField(5) DateTime fecha;
  @HiveField(6) DateTime? fechaVencimiento;
  @HiveField(7) bool pagada;
  @HiveField(8) DateTime? fechaPago;
  @HiveField(9) String? metodoPago;
  @HiveField(10) String? nota;
  @HiveField(11) String? empresaId;
  @HiveField(12) DateTime? updatedAt;
  @HiveField(13) String? moneda;
  @HiveField(14) double? tasaCambio;
  @HiveField(15) double? montoUSD;
  @HiveField(16) double pagado;
  @HiveField(17) String? sucursalId;
  @HiveField(18) String? status;

  Deuda({
    required this.id,
    required this.tipo,
    required this.entidadId,
    required this.concepto,
    required this.monto,
    required this.fecha,
    this.fechaVencimiento,
    this.pagada = false,
    this.fechaPago,
    this.metodoPago,
    this.nota,
    this.empresaId,
    this.updatedAt,
    this.moneda,
    this.tasaCambio,
    this.montoUSD,
    this.pagado = 0,
    this.sucursalId,
    this.status = 'open',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': empresaId,
        'branch_id': sucursalId,
        'customer_id': tipo == 'cliente' ? entidadId : null,
        'original_amount': monto,
        'paid_amount': pagado,
        'due_date': fechaVencimiento != null
            ? DateFormat('yyyy-MM-dd').format(fechaVencimiento!)
            : null,
        'notes': nota,
        'status': status,
        'created_at': fecha.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Deuda.fromJson(Map<String, dynamic> json) => Deuda(
        id: json['id'],
        tipo: json['customer_id'] != null ? 'cliente' : 'proveedor',
        entidadId: json['customer_id'] ?? '',
        concepto: json['notes'] ?? 'Deuda',
        monto: ((json['original_amount'] ?? 0) as num).toDouble(),
        fecha: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        fechaVencimiento: json['due_date'] != null
            ? DateTime.parse(json['due_date'])
            : null,
        pagada: json['status'] == 'paid',
        fechaPago: null,
        metodoPago: null,
        nota: json['notes'],
        empresaId: json['company_id'],
        sucursalId: json['branch_id'],
        pagado: ((json['paid_amount'] ?? 0) as num).toDouble(),
        status: json['status'] ?? 'open',
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );
}

// ============================================================
//  MODELOS AUXILIARES
// ============================================================
class Anuncio {
  final String id;
  final String titulo;
  final String contenido;
  final DateTime fechaPublicacion;
  final bool activo;
  final String? imageUrl;
  final String? actionUrl;
  final String? targetPlan;
  final String? targetRole;
  final int priority;

  Anuncio({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fechaPublicacion,
    required this.activo,
    this.imageUrl,
    this.actionUrl,
    this.targetPlan,
    this.targetRole,
    this.priority = 0,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) => Anuncio(
        id: json['id'],
        titulo: json['title'] ?? '',
        contenido: json['body'] ?? '',
        fechaPublicacion: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'])
            : DateTime.now(),
        activo: json['active'] ?? true,
        imageUrl: json['image_url'],
        actionUrl: json['action_url'],
        targetPlan: json['target_plan'],
        targetRole: json['target_role'],
        priority: (json['priority'] ?? 0) as int,
      );
}

class EstadisticasVendedor {
  final String id;
  final String email;
  final int totalVentas;
  final double totalMonto;
  final double totalGanancia;

  EstadisticasVendedor({
    required this.id,
    required this.email,
    required this.totalVentas,
    required this.totalMonto,
    required this.totalGanancia,
  });
}

class SolicitudPago {
  final String id;
  final String empresaId;
  final String nombreEmpresa;
  final String noTransaccion;
  final double monto;
  final String planSolicitado;
  final int dias;
  final int branchCount;
  final DateTime fechaSolicitud;
  final String estado;
  final DateTime? fechaAprobacion;
  final String metodoPago;
  final String? motivoRechazo;

  SolicitudPago({
    required this.id,
    required this.empresaId,
    required this.nombreEmpresa,
    required this.noTransaccion,
    required this.monto,
    required this.planSolicitado,
    required this.dias,
    required this.branchCount,
    required this.fechaSolicitud,
    required this.estado,
    this.fechaAprobacion,
    this.metodoPago = 'Transferencia',
    this.motivoRechazo,
  });

  factory SolicitudPago.fromJson(Map<String, dynamic> json) {
    return SolicitudPago(
      id: json['id'],
      empresaId: json['company_id'],
      nombreEmpresa: json['nombre_empresa'] ?? '',
      noTransaccion: json['transfer_reference'] ?? '',
      monto: ((json['calculated_amount'] ?? 0) as num).toDouble(),
      planSolicitado: json['requested_plan'] ?? 'premium',
      dias: (json['requested_days'] ?? 30) as int,
      branchCount: (json['branch_count'] ?? 1) as int,
      fechaSolicitud: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      estado: json['status'] ?? 'pending',
      fechaAprobacion: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      metodoPago: 'Transferencia',
      motivoRechazo: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': empresaId,
        'requested_plan': planSolicitado,
        'requested_days': dias,
        'branch_count': branchCount,
        'calculated_amount': monto,
        'currency_code': 'CUP',
        'transfer_reference': noTransaccion,
        'note': null,
      };
}

class NotificationService {
  static Future<void> initialize() async {}
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
  static Future<void> cancelAll() async {}
}

// ============================================================
//  MENSAJES AMIGABLES
// ============================================================
String mensajeAmigable(dynamic error) {
  final msg = error.toString();
  final low = msg.toLowerCase();

  final esTecnico = low.contains('exception') ||
      low.contains('postgrest') ||
      low.contains('sqlstate') ||
      low.contains('socketexception') ||
      low.contains('#0 ') ||
      low.contains('stack trace') ||
      low.contains('function public.') ||
      low.contains('relation "') ||
      low.contains('violates ') ||
      low.contains('duplicate key') ||
      low.contains('null value in column') ||
      RegExp(r'^[a-z_]+_[a-z_]+\(.*\)$').hasMatch(low);
  if (!esTecnico && msg.length > 3 && msg.length < 400) return msg;

  if (low.contains('violates row-level security') ||
      low.contains('permission denied')) {
    return 'No tienes permisos para realizar esta acción. Contacta al administrador.';
  }
  if (low.contains('duplicate key') || low.contains('already exists')) {
    return 'Este registro ya existe.';
  }
  if (low.contains('network') ||
      low.contains('timeout') ||
      low.contains('socket') ||
      low.contains('connection')) {
    return 'Error de conexión. Revisa tu internet y vuelve a intentarlo.';
  }
  if (low.contains('not found') || low.contains('does not exist')) {
    return 'El elemento que buscas no existe.';
  }
  if (low.contains('invalid login') || low.contains('wrong password')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (low.contains('stock') || low.contains('insufficient')) {
    return 'Stock insuficiente para completar la operación.';
  }
  if (low.contains('no autorizado')) {
    return 'Problema de sincronización. Vuelve a intentarlo.';
  }
  return 'Ocurrió un error inesperado. Intenta de nuevo más tarde.';
}

void mostrarSnackBar({
  required String mensaje,
  required bool esExito,
  IconData? icono,
  Duration? duracion,
}) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final color = esExito ? Colors.green.shade700 : Colors.red.shade700;
  final icon =
      icono ?? (esExito ? Icons.check_circle_outline : Icons.error_outline);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      duration: duracion ?? const Duration(seconds: 7),
    ),
  );
}

// ============================================================
//  APP PROVIDER
// ============================================================
class AppProvider extends ChangeNotifier {
  // ===== HIVE BOXES =====
  late Box<Producto> productoBox;
  late Box<Venta> ventaBox;
  late Box<Gasto> gastoBox;
  late Box<Cliente> clienteBox;
  late Box<Categoria> categoriaBox;
  late Box<MetaVenta> metaBox;
  late Box<dynamic> pendientesBox;
  Box<dynamic>? settingsBox;
  late Box<Sucursal> sucursalBox;
  late Box<Empleado> empleadoBox;
  late Box<Nomina> nominaBox;
  late Box<Alianza> alianzaBox;
  late Box<Transferencia> transferenciaBox;
  late Box<Referido> referidoBox;
  late Box<Bono> bonoBox;
  late Box<Merma> mermaBox;
  late Box<MovimientoSucursal> movimientoBox;
  late Box<Deuda> deudaBox;
  late Box<dynamic> cierreDiarioBox;
  late Box<dynamic> catalogosBox;

  // ===== DATOS EN MEMORIA =====
  List<Producto> productos = [];
  List<Venta> ventas = [];
  List<Gasto> gastos = [];
  List<Cliente> clientes = [];
  List<Categoria> categorias = [];
  List<Sucursal> sucursales = [];
  List<Empleado> empleados = [];
  List<Nomina> nominas = [];
  List<Alianza> alianzas = [];
  List<Transferencia> transferencias = [];
  List<Referido> referidos = [];
  List<Bono> bonos = [];
  List<Merma> mermas = [];
  List<MovimientoSucursal> movimientos = [];
  List<Deuda> deudas = [];

  List<Map<String, dynamic>> monedas = [];
  List<Map<String, dynamic>> metodosPago = [];
  List<Map<String, dynamic>> planesSuscripcion = [];
  List<Map<String, dynamic>> descuentosSuscripcion = [];
  List<Map<String, dynamic>> provincias = [];
  List<Map<String, dynamic>> municipios = [];
  List<Map<String, dynamic>> categoriasServicio = [];

  final Map<String, String> _usuariosEmailCache = {};

  final Map<String, DateTime> _ultimaNotificacionStock = {};
  static const Duration _cooldownNotifStock = Duration(hours: 6);

  MetaVenta? meta;
  String? empresaId;
  String? nombreEmpresa;
  String? usuarioId;
  String? rol;
  bool empresaActiva = true;
  String plan = 'premium';
  Anuncio? ultimoAnuncio;
  DateTime? fechaRegistro;
  String? sucursalIdUsuario;
  DateTime? _ultimoLogin;
  DateTime? get ultimoLogin => _ultimoLogin;

  bool isOnline = false;
  bool syncing = false;
  bool _initialized = false;

  int periodoSeleccionado = 0;
  String filtroCategoria = 'Todas';

  SolicitudPago? _ultimaSolicitudPago;
  SolicitudPago? get ultimaSolicitudPago => _ultimaSolicitudPago;

  Timer? _stockNotificationTimer;
  Timer? _syncRetryTimer;

  List<String> _proveedoresIds = [];
  List<String> get proveedoresIds => _proveedoresIds;

  // ===== CLAVES =====
  static const String KEY_EMPRESA_ID = 'empresaId';
  static const String KEY_ROL = 'rol';
  static const String KEY_EMPRESA_NOMBRE = 'nombreEmpresa';
  static const String KEY_PROVEEDORES = 'proveedoresIds';
  static const String KEY_FECHA_REGISTRO = 'fechaRegistro';
  static const String KEY_SUCURSAL_ID = 'sucursalId';
  static const String KEY_ULTIMO_LOGIN = 'ultimoLogin';
  static const String KEY_USUARIO_ID = 'usuarioId';
  static const String KEY_FECHA_APROBACION_PAGO = 'fechaAprobacionPago';
  static const String KEY_FECHA_VENCIMIENTO = 'fechaVencimiento';
  static const String KEY_MOSTRAR_GUIA = 'mostrarGuia';
  static const String KEY_TAXA_VENTAS = 'taxaVentas';
  static const String KEY_TAXA_UTILIDADES = 'taxaUtilidades';
  static const String KEY_TASA_CAMBIO_USD = 'tasaCambioUSD';
  static const String KEY_THEME_MODE = 'themeMode';
  static const String KEY_MODO_VENTAS = 'modoVentas';
  static const String KEY_CURRENCY_ID = 'currencyId';
  static const String MODO_TIEMPO_REAL = 'real_time';
  static const String MODO_CIERRE_DIARIO = 'daily_closure';

  final supabase = Supabase.instance.client;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hayConexion = false;

  static const List<int> _retryBackoffSeconds = [15, 30, 60, 120, 300];
  static const int _MAX_INTENTOS_SYNC = 10;

  AppProvider() {
    _initConnectivity();
    _initialize();
  }

  double get taxaVentas {
    if (settingsBox == null) return 10.0;
    return (settingsBox!.get(KEY_TAXA_VENTAS) as double?) ?? 10.0;
  }

  double get taxaUtilidades {
    if (settingsBox == null) return 15.0;
    return (settingsBox!.get(KEY_TAXA_UTILIDADES) as double?) ?? 15.0;
  }

  double get tasaCambioUSD {
    if (settingsBox == null) return 675.0;
    return (settingsBox!.get(KEY_TASA_CAMBIO_USD) as double?) ?? 675.0;
  }

  ThemeMode get themeMode {
    if (settingsBox == null) return ThemeMode.system;
    final mode = settingsBox!.get(KEY_THEME_MODE) as String?;
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get modoVentas {
    if (settingsBox == null) return MODO_TIEMPO_REAL;
    return (settingsBox!.get(KEY_MODO_VENTAS) as String?) ?? MODO_TIEMPO_REAL;
  }

  bool get usaCierreDiario => modoVentas == MODO_CIERRE_DIARIO;

  String? get currencyIdActual {
    if (settingsBox == null) return null;
    return settingsBox!.get(KEY_CURRENCY_ID) as String?;
  }

  Future<void> setModoVentas(String modo) async {
    if (settingsBox != null) {
      await settingsBox!.put(KEY_MODO_VENTAS, modo);
      notifyListeners();
    }
  }

  Future<void> setTaxaVentas(double value) async {
    if (settingsBox != null) {
      await settingsBox!.put(KEY_TAXA_VENTAS, value);
      notifyListeners();
    }
  }

  Future<void> setTaxaUtilidades(double value) async {
    if (settingsBox != null) {
      await settingsBox!.put(KEY_TAXA_UTILIDADES, value);
      notifyListeners();
    }
  }

  Future<void> setTasaCambioUSD(double value) async {
    if (settingsBox != null) {
      await settingsBox!.put(KEY_TASA_CAMBIO_USD, value);
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (settingsBox != null) {
      String value;
      if (mode == ThemeMode.light) {
        value = 'light';
      } else if (mode == ThemeMode.dark) {
        value = 'dark';
      } else {
        value = 'system';
      }
      await settingsBox!.put(KEY_THEME_MODE, value);
      notifyListeners();
    }
  }

  Future<void> setCurrencyId(String? id) async {
    if (settingsBox != null) {
      if (id == null) {
        await settingsBox!.delete(KEY_CURRENCY_ID);
      } else {
        await settingsBox!.put(KEY_CURRENCY_ID, id);
      }
      notifyListeners();
    }
  }

  bool get esAdminGlobal => rol == 'dueno';
  bool get esGerente => rol == 'gerente';
  bool get esGestor => rol == 'gerente';
  bool get esVendedor => rol == 'vendedor';

  String getUsuarioEmail(String? usuarioId) {
    if (usuarioId == null) return 'Sin vendedor';
    return _usuariosEmailCache[usuarioId] ?? 'Vendedor ID: $usuarioId';
  }

  Future<void> _initialize() async {
    try {
      await _initHive();
      await _cargarCatalogosGlobales();
      await _cargarDatosLocales();

      final box = settingsBox!;
      empresaId = box.get(KEY_EMPRESA_ID) as String?;
      rol = box.get(KEY_ROL) as String?;
      nombreEmpresa = box.get(KEY_EMPRESA_NOMBRE) as String?;
      _proveedoresIds =
          (box.get(KEY_PROVEEDORES) as List?)?.cast<String>() ?? [];
      sucursalIdUsuario = box.get(KEY_SUCURSAL_ID) as String?;
      final fechaRegistroStr = box.get(KEY_FECHA_REGISTRO) as String?;
      if (fechaRegistroStr != null) {
        fechaRegistro = DateTime.tryParse(fechaRegistroStr);
      }
      final ultimoLoginStr = box.get(KEY_ULTIMO_LOGIN) as String?;
      if (ultimoLoginStr != null) {
        _ultimoLogin = DateTime.tryParse(ultimoLoginStr);
      }
      usuarioId = box.get(KEY_USUARIO_ID) as String?;

      bool autoLoginOffline = false;
      if (usuarioId != null && _ultimoLogin != null) {
        final hoy = DateTime.now();
        final diaLogin = DateTime(
            _ultimoLogin!.year, _ultimoLogin!.month, _ultimoLogin!.day);
        if (hoy.year == diaLogin.year &&
            hoy.month == diaLogin.month &&
            hoy.day == diaLogin.day) {
          autoLoginOffline = true;
        }
      }

      if (autoLoginOffline) {
        _initialized = true;
        notifyListeners();
        _sincronizarEnBackground();
        await obtenerUltimoAnuncio();
        await obtenerUltimaSolicitudPago();
        _startStockNotificationTimer();
        await checkForUpdate();
        await _cargarUsuariosCache();
        return;
      }

      await NotificationService.initialize();

      Session? session;
      int intentos = 0;
      while (intentos < 6) {
        session = supabase.auth.currentSession;
        if (session != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
        intentos++;
      }

      if (session != null) {
        final user = session.user;
        if (user != null) {
          try {
            final data = await supabase
                .from('users')
                .select('*, companies(*)')
                .eq('id', user.id)
                .maybeSingle();
            if (data != null && data['company_id'] != null) {
              usuarioId = user.id;
              empresaId = data['company_id'];
              rol = data['role'];
              sucursalIdUsuario = data['default_branch_id'];
              if (sucursalIdUsuario != null && settingsBox != null) {
                await settingsBox!.put(KEY_SUCURSAL_ID, sucursalIdUsuario);
              }
              if (data['companies'] != null) {
                nombreEmpresa = data['companies']['name'] ?? APP_NAME;
                empresaActiva = data['companies']['is_active'] ?? true;
                plan = data['companies']['plan'] ?? 'premium';
                if (data['companies']['created_at'] != null) {
                  fechaRegistro =
                      DateTime.tryParse(data['companies']['created_at']);
                  if (fechaRegistro != null && settingsBox != null) {
                    await settingsBox!.put(KEY_FECHA_REGISTRO,
                        fechaRegistro!.toIso8601String());
                  }
                }
                if (data['companies']['current_period_end'] != null &&
                    settingsBox != null) {
                  await settingsBox!.put(KEY_FECHA_VENCIMIENTO,
                      data['companies']['current_period_end'].toString());
                }
              } else {
                nombreEmpresa = APP_NAME;
                empresaActiva = true;
                plan = 'premium';
              }
              if (settingsBox != null) {
                await settingsBox!.put(KEY_EMPRESA_ID, empresaId);
                await settingsBox!.put(KEY_ROL, rol);
                await settingsBox!.put(KEY_EMPRESA_NOMBRE, nombreEmpresa);
                await settingsBox!.put(KEY_USUARIO_ID, user.id);
                _ultimoLogin = DateTime.now();
                await settingsBox!.put(
                    KEY_ULTIMO_LOGIN, _ultimoLogin!.toIso8601String());
              }

              await _cargarDatosLocales();
              _sincronizarEnBackground();
              await obtenerUltimoAnuncio();
              await obtenerUltimaSolicitudPago();
              _startStockNotificationTimer();
              await checkForUpdate();
              await _cargarUsuariosCache();
            }
          } catch (e) {
            print('⚠️ Error al obtener datos del usuario: $e');
            if (empresaId == null || usuarioId == null) {
              usuarioId = null;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error en inicialización: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _initHive() async {
    try {
      productoBox = await Hive.openBox<Producto>('productos');
      ventaBox = await Hive.openBox<Venta>('ventas');
      gastoBox = await Hive.openBox<Gasto>('gastos');
      clienteBox = await Hive.openBox<Cliente>('clientes');
      categoriaBox = await Hive.openBox<Categoria>('categorias');
      metaBox = await Hive.openBox<MetaVenta>('metas');
      pendientesBox = await Hive.openBox<dynamic>('pendientes');
      settingsBox = await Hive.openBox<dynamic>('settings');
      sucursalBox = await Hive.openBox<Sucursal>('sucursales');
      empleadoBox = await Hive.openBox<Empleado>('empleados');
      nominaBox = await Hive.openBox<Nomina>('nominas');
      alianzaBox = await Hive.openBox<Alianza>('alianzas');
      transferenciaBox = await Hive.openBox<Transferencia>('transferencias');
      referidoBox = await Hive.openBox<Referido>('referidos');
      bonoBox = await Hive.openBox<Bono>('bonos');
      mermaBox = await Hive.openBox<Merma>('mermas');
      movimientoBox = await Hive.openBox<MovimientoSucursal>('movimientos');
      deudaBox = await Hive.openBox<Deuda>('deudas');
      cierreDiarioBox = await Hive.openBox<dynamic>('cierre_diario');
      catalogosBox = await Hive.openBox<dynamic>('catalogos');
    } catch (e) {
      print('❌ Error al inicializar Hive: $e');
      rethrow;
    }
  }

  bool get isInitialized => _initialized;
  int get contarPendientes => pendientesBox.length;
  bool get hayPendientes => pendientesBox.isNotEmpty;

  void verificarEmpresaActiva() {
    if (!empresaActiva) {
      throw Exception(
          'Tu servicio ha sido cancelado. Contacta al administrador.');
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final initial = await Connectivity().checkConnectivity();
      _hayConexion = initial.any((r) => r != ConnectivityResult.none);
      isOnline = _hayConexion;
      notifyListeners();
    } catch (_) {
      _hayConexion = false;
      isOnline = false;
    }

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final ahoraConectado =
          results.any((r) => r != ConnectivityResult.none);
      if (ahoraConectado && !_hayConexion) {
        _sincronizarEnBackground();
      }
      _hayConexion = ahoraConectado;
      isOnline = _hayConexion;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _syncRetryTimer?.cancel();
    _stockNotificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarCatalogosGlobales() async {
    try {
      monedas = List<Map<String, dynamic>>.from(
          (catalogosBox.get('monedas') as List?) ?? []);
      metodosPago = List<Map<String, dynamic>>.from(
          (catalogosBox.get('metodosPago') as List?) ?? []);
      planesSuscripcion = List<Map<String, dynamic>>.from(
          (catalogosBox.get('planes') as List?) ?? []);
      descuentosSuscripcion = List<Map<String, dynamic>>.from(
          (catalogosBox.get('descuentos') as List?) ?? []);
      provincias = List<Map<String, dynamic>>.from(
          (catalogosBox.get('provincias') as List?) ?? []);
      municipios = List<Map<String, dynamic>>.from(
          (catalogosBox.get('municipios') as List?) ?? []);
      categoriasServicio = List<Map<String, dynamic>>.from(
          (catalogosBox.get('categoriasServicio') as List?) ?? []);

      if (!_hayConexion) return;

      final cur =
          await supabase.from('currencies').select('*').eq('active', true);
      monedas = List<Map<String, dynamic>>.from(cur);
      await catalogosBox.put('monedas', monedas);

      final pm = await supabase
          .from('payment_methods')
          .select('*')
          .eq('active', true);
      metodosPago = List<Map<String, dynamic>>.from(pm);
      await catalogosBox.put('metodosPago', metodosPago);

      final plans = await supabase
          .from('subscription_plans')
          .select('*')
          .eq('active', true);
      planesSuscripcion = List<Map<String, dynamic>>.from(plans);
      await catalogosBox.put('planes', planesSuscripcion);

      final disc = await supabase
          .from('subscription_discounts')
          .select('*')
          .eq('active', true);
      descuentosSuscripcion = List<Map<String, dynamic>>.from(disc);
      await catalogosBox.put('descuentos', descuentosSuscripcion);

      final prov =
          await supabase.from('provinces').select('*').eq('active', true);
      provincias = List<Map<String, dynamic>>.from(prov);
      await catalogosBox.put('provincias', provincias);

      final muni =
          await supabase.from('municipalities').select('*').eq('active', true);
      municipios = List<Map<String, dynamic>>.from(muni);
      await catalogosBox.put('municipios', municipios);

      final ssc = await supabase
          .from('store_service_categories')
          .select('*')
          .eq('active', true);
      categoriasServicio = List<Map<String, dynamic>>.from(ssc);
      await catalogosBox.put('categoriasServicio', categoriasServicio);

      final pc = await supabase
          .from('product_categories')
          .select('*')
          .eq('active', true)
          .order('sort_order', ascending: true);
      for (var json in pc) {
        final cat = Categoria.fromJson(json);
        await categoriaBox.put(cat.id, cat);
      }
      categorias = categoriaBox.values.toList();
    } catch (e) {
      print('⚠️ Error al cargar catálogos globales: $e');
    }
  }

  void _sincronizarEnBackground() {
    if (syncing) return;
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await sincronizarTodo(mostrarMensaje: false);
      } catch (e) {
        if (pendientesBox.isNotEmpty) _programarReintento(0);
      }
    });
  }

  void _programarReintento(int intentos) {
    _syncRetryTimer?.cancel();
    final idx = intentos.clamp(0, _retryBackoffSeconds.length - 1);
    final segundos = _retryBackoffSeconds[idx];
    _syncRetryTimer = Timer(Duration(seconds: segundos), () {
      if (_hayConexion && pendientesBox.isNotEmpty) {
        _sincronizarEnBackground();
      }
    });
  }

  Future<void> sincronizarManual() async {
    if (!_hayConexion) {
      mostrarSnackBar(mensaje: 'Sin conexión a internet', esExito: false);
      return;
    }
    await _actualizarDatosEmpresa();
    await sincronizarTodo(mostrarMensaje: true);
  }

  // ══════════════════════════════════════════════════════════
  //  SINCRONIZAR TODO
  // ══════════════════════════════════════════════════════════
  Future<void> sincronizarTodo({bool mostrarMensaje = true}) async {
    if (!_hayConexion || empresaId == null) return;
    try {
      verificarEmpresaActiva();
    } catch (_) {
      return;
    }
    if (syncing) return;
    syncing = true;
    notifyListeners();
    try {
      await _procesarPendientes();
      await _descargarCambios();
      await sincronizarRedNexora();
      await _cargarDatosLocales();
      await obtenerUltimaSolicitudPago();
      if (mostrarMensaje) {
        mostrarSnackBar(mensaje: 'Datos sincronizados', esExito: true);
      }
    } catch (e) {
      if (mostrarMensaje) {
        mostrarSnackBar(
            mensaje: 'Error al sincronizar: ${mensajeAmigable(e)}',
            esExito: false);
      }
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> procesarPendientesAhora() async {
    if (!_hayConexion) {
      mostrarSnackBar(mensaje: 'Sin conexión a internet', esExito: false);
      return;
    }
    if (pendientesBox.isEmpty) {
      mostrarSnackBar(mensaje: 'No hay operaciones pendientes', esExito: false);
      return;
    }
    await sincronizarTodo(mostrarMensaje: true);
  }

  // ============================================================
  //  PROCESAR PENDIENTES
  // ============================================================
  Future<void> _procesarPendientes() async {
    final keys = pendientesBox.keys.toList();
    if (keys.isEmpty) return;

    final ordenTablas = [
      'rpc',
      'productos',
      'clientes',
      'categorias',
      'sucursales',
      'empleados',
      'nominas',
      'alianzas',
      'transferencias',
      'referidos',
      'bonos',
      'mermas',
      'movimientos_sucursal',
      'gastos',
      'deudas',
      'debt_payments',
      'ventas',
    ];

    final pendientesPorTabla = <String, List<dynamic>>{};
    for (var key in keys) {
      final p = pendientesBox.get(key);
      if (p == null) continue;
      pendientesPorTabla.putIfAbsent(p['tabla'] as String, () => []).add(key);
    }

    // ── VENTAS: agrupar por saleGroupId
    final ventasKeys = pendientesPorTabla['ventas'] ?? [];
    if (ventasKeys.isNotEmpty) {
      final porGrupo = <String, List<dynamic>>{};
      for (final key in ventasKeys) {
        final p = pendientesBox.get(key);
        if (p == null) continue;
        final grupoId = (p['saleGroupId'] ?? p['id'] ?? key).toString();
        porGrupo.putIfAbsent(grupoId, () => []).add(key);
      }

      for (final grupoId in porGrupo.keys) {
        final grupoKeys = porGrupo[grupoId]!;
        try {
          final items = <Map<String, dynamic>>[];
          final idsLocales = <String>[];
          String? branchId;
          String? customerId;
          String? note;
          String? mode;
          String? currencyId;
          double exchangeRate = 1;

          for (final key in grupoKeys) {
            final p = pendientesBox.get(key);
            if (p == null) continue;
            final datos = Map<String, dynamic>.from(p['datos'] as Map);
            final it = datos['_items'];
            if (it is List) {
              for (final x in it) {
                items.add(Map<String, dynamic>.from(x as Map));
              }
            }
            idsLocales.add(p['id'] as String);
            branchId ??= datos['_branch_id'] as String?;
            mode ??= datos['_mode'] as String?;
            customerId ??= datos['_customer_id'] as String?;
            note ??= datos['_note'] as String?;
            currencyId ??= datos['_currency_id'] as String?;
            exchangeRate = ((datos['_exchange_rate'] ?? 1) as num).toDouble();
          }

          if (items.isEmpty) {
            for (final k in grupoKeys) {
              await pendientesBox.delete(k);
            }
            continue;
          }

          // ✅ FIX: sin p_client_group_id (no existe en la firma SQL)
          final remoteId = await supabase.rpc('create_sale', params: {
            'p_branch_id': branchId,
            'p_items': items,
            'p_customer_id': customerId,
            'p_discount': 0,
            'p_tax': 0,
            'p_currency_id': currencyId,
            'p_exchange_rate': exchangeRate,
            'p_mode': mode ?? 'real_time',
            'p_note': note,
            'p_is_trial_data': false,
          });

          if (remoteId != null) {
            for (final idLocal in idsLocales) {
              final v = ventaBox.get(idLocal);
              if (v != null) {
                await ventaBox.delete(idLocal);
                v.id = '${remoteId}_$idLocal';
                v.saleGroupId = remoteId.toString();
                await ventaBox.put(v.id, v);
              }
            }
            ventas = ventaBox.values.toList();
          }

          for (final k in grupoKeys) {
            await pendientesBox.delete(k);
          }
        } catch (e) {
          for (final key in grupoKeys) {
            final p = pendientesBox.get(key);
            if (p == null) continue;
            final intentos = ((p['intentos'] ?? 0) as int) + 1;
            p['intentos'] = intentos;
            p['ultimoError'] = e.toString();
            p['ultimoErrorFecha'] = DateTime.now().toIso8601String();
            await pendientesBox.put(key, p);

            // ✅ FIX: descartar tras _MAX_INTENTOS_SYNC
            if (intentos >= _MAX_INTENTOS_SYNC) {
              await pendientesBox.delete(key);
              mostrarSnackBar(
                mensaje:
                    '⚠️ Venta descartada tras $_MAX_INTENTOS_SYNC intentos fallidos.',
                esExito: false,
              );
            } else if (intentos >= 5) {
              mostrarSnackBar(
                mensaje: '⚠️ Error persistente al sincronizar venta.',
                esExito: false,
              );
            }
          }
        }
      }

      pendientesPorTabla.remove('ventas');
    }

    // ── Resto de tablas
    for (final tabla in ordenTablas) {
      if (tabla == 'ventas') continue;
      if (!pendientesPorTabla.containsKey(tabla)) continue;
      for (final key in pendientesPorTabla[tabla]!) {
        final p = pendientesBox.get(key);
        if (p == null) continue;
        final accion = p['accion'] as String;
        final datos = Map<String, dynamic>.from(p['datos'] as Map);
        final idLocal = p['id'] as String;
        int intentos = (p['intentos'] ?? 0) as int;

        try {
          if (accion == 'delete') {
            await _ejecutarDelete(tabla, idLocal);
            await pendientesBox.delete(key);
            continue;
          }
          await _ejecutarUpsert(tabla, accion, datos, idLocal);
          await pendientesBox.delete(key);
        } catch (e) {
          intentos++;
          p['intentos'] = intentos;
          p['ultimoError'] = e.toString();
          p['ultimoErrorFecha'] = DateTime.now().toIso8601String();
          await pendientesBox.put(key, p);

          // ✅ FIX: descartar tras _MAX_INTENTOS_SYNC
          if (intentos >= _MAX_INTENTOS_SYNC) {
            await pendientesBox.delete(key);
            mostrarSnackBar(
              mensaje:
                  '⚠️ Operación $tabla descartada tras $_MAX_INTENTOS_SYNC intentos.',
              esExito: false,
            );
          } else if (intentos >= 5) {
            mostrarSnackBar(
              mensaje:
                  '⚠️ Error persistente al sincronizar $tabla (id: $idLocal).',
              esExito: false,
            );
          }
        }
      }
    }

    if (pendientesBox.isEmpty) {
      await _descargarCambios();
      await _cargarDatosLocales();
    } else {
      _programarReintento(1);
    }
  }

  Future<void> _ejecutarUpsert(
      String tabla, String accion, Map<String, dynamic> datos, String id) async {
    if (tabla == 'rpc') {
      final rpcName = datos['_rpc'] as String;
      final params = Map<String, dynamic>.from(datos['_params'] as Map);
      await supabase.rpc(rpcName, params: params);
      return;
    }

    switch (tabla) {
      case 'productos':
        final datosProd = Map<String, dynamic>.from(datos);
        final initialStock = datosProd.remove('_initial_stock');
        final branchId = datosProd.remove('_branch_id');
        datosProd.remove('stock');
        datosProd.remove('lotes');

        await supabase.from('products').upsert(datosProd);

        if (initialStock != null && branchId != null) {
          final stock = (initialStock as num).toDouble();
          if (stock > 0) {
            try {
              // ✅ FIX: sin p_reference_id (no existe en la firma SQL)
              await supabase.rpc('receive_inventory', params: {
                'p_branch_id': branchId,
                'p_product_id': datosProd['id'],
                'p_quantity': stock,
                'p_unit_cost': (datosProd['purchase_price'] ?? 0),
                'p_lot_number': null,
                'p_expiration_date': null,
                'p_supplier_name': null,
                'p_is_trial_data': false,
              });
            } catch (e) {
              print('ℹ️ receive_inventory duplicado o falló (se ignora): $e');
            }
          }
        }
        return;
      case 'gastos':
        await supabase.from('expenses').upsert(datos);
        return;
      case 'clientes':
        await supabase.from('customers').upsert(datos);
        return;
      case 'categorias':
        await supabase.from('product_categories').upsert(datos);
        return;
      case 'sucursales':
        await supabase.from('branches').upsert(datos);
        return;
      case 'empleados':
        await supabase.from('employees').upsert(datos);
        return;
      case 'nominas':
        await supabase.from('payrolls').upsert(datos);
        return;
      case 'alianzas':
        await supabase.from('partnerships').upsert(datos);
        return;
      case 'transferencias':
        await supabase.from('stock_transfers').upsert(datos);
        return;
      case 'referidos':
        await supabase.from('referrals').upsert(datos);
        return;
      case 'bonos':
        await supabase.from('referral_rewards').upsert(datos);
        return;
      case 'mermas':
        await supabase.from('wastages').upsert(datos);
        return;
      case 'movimientos_sucursal':
        await supabase.from('inventory_movements').upsert(datos);
        return;
      case 'deudas':
        await supabase.from('debts').upsert(datos);
        return;
      case 'debt_payments':
        await supabase.from('debt_payments').upsert(datos);
        return;
      case 'metas_venta':
        await supabase.from('sales_goals').upsert(datos);
        return;
      default:
        if (accion == 'insert') {
          await supabase.from(tabla).upsert(datos);
        } else if (accion == 'update') {
          await supabase.from(tabla).update(datos).eq('id', id);
        }
    }
  }

  Future<void> _ejecutarDelete(String tabla, String id) async {
    switch (tabla) {
      case 'productos':
        await supabase.from('products').update({'active': false}).eq('id', id);
        return;
      case 'ventas':
        await supabase
            .from('sales')
            .update({'status': 'cancelled'}).eq('id', id);
        return;
      case 'gastos':
        await supabase.from('expenses').delete().eq('id', id);
        return;
      case 'clientes':
        await supabase.from('customers').delete().eq('id', id);
        return;
      case 'categorias':
        await supabase.from('product_categories').delete().eq('id', id);
        return;
      case 'sucursales':
        await supabase.from('branches').delete().eq('id', id);
        return;
      case 'empleados':
        await supabase.from('employees').delete().eq('id', id);
        return;
      case 'nominas':
        await supabase.from('payrolls').delete().eq('id', id);
        return;
      case 'alianzas':
        await supabase.from('partnerships').delete().eq('id', id);
        return;
      case 'transferencias':
        await supabase.from('stock_transfers').delete().eq('id', id);
        return;
      case 'referidos':
        await supabase.from('referrals').delete().eq('id', id);
        return;
      case 'bonos':
        await supabase.from('referral_rewards').delete().eq('id', id);
        return;
      case 'mermas':
        await supabase.from('wastages').delete().eq('id', id);
        return;
      case 'movimientos_sucursal':
        await supabase.from('inventory_movements').delete().eq('id', id);
        return;
      case 'deudas':
        await supabase.from('debts').delete().eq('id', id);
        return;
      default:
        await supabase.from(tabla).delete().eq('id', id);
    }
  }

  Future<void> _guardarPendiente(
    String accion,
    String tabla,
    Map<String, dynamic> datos,
    String id, {
    String? saleGroupId,
  }) async {
    final datosParaGuardar = Map<String, dynamic>.from(datos);
    datosParaGuardar.remove('created_at');
    final key =
        '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4().substring(0, 6)}';
    await pendientesBox.put(key, {
      'accion': accion,
      'tabla': tabla,
      'datos': datosParaGuardar,
      'id': id,
      'saleGroupId': saleGroupId,
      'timestamp': DateTime.now().toIso8601String(),
      'intentos': 0,
    });
    if (_hayConexion) _sincronizarEnBackground();
  }

  Future<void> _descargarCambios() async {
    if (empresaId == null) return;
    await _actualizarDatosEmpresa();

    final pendientesIds = <String>{};
    for (var k in pendientesBox.keys) {
      final p = pendientesBox.get(k);
      if (p == null) continue;
      final pid = p['id'] as String?;
      if (pid != null) pendientesIds.add(pid);
    }

    final pc = await supabase
        .from('product_categories')
        .select('*')
        .eq('active', true)
        .order('sort_order', ascending: true);
    for (var json in pc) {
      final cat = Categoria.fromJson(json);
      await categoriaBox.put(cat.id, cat);
    }
    categorias = categoriaBox.values.toList();

    final prodRemotos = await supabase
        .from('products')
        .select('*')
        .eq('company_id', empresaId!)
        .eq('active', true);
    for (var json in prodRemotos) {
      final prodId = json['id'] as String;
      if (pendientesIds.contains(prodId)) continue;
      final branchId = sucursalIdUsuario;
      double stock = 0;
      List<Map<String, dynamic>> lotes = [];
      if (branchId != null) {
        final inv = await supabase
            .from('branch_inventory')
            .select('quantity, average_cost, last_cost')
            .eq('branch_id', branchId)
            .eq('product_id', prodId)
            .maybeSingle();
        if (inv != null) {
          stock = ((inv['quantity'] ?? 0) as num).toDouble();
        }
        final lots = await supabase
            .from('product_lots')
            .select('*')
            .eq('branch_id', branchId)
            .eq('product_id', prodId)
            .gt('remaining_quantity', 0);
        lotes = (lots as List).map((l) {
          return {
            'id': l['id'],
            'cantidad': (l['remaining_quantity'] as num).toDouble(),
            'precioCompra': (l['unit_cost'] as num).toDouble(),
            'fecha': l['received_at'],
            'lot_number': l['lot_number'],
          };
        }).toList();
      }
      final prod = Producto.fromJson(json,
          branchId: branchId, stock: stock, lotes: lotes);
      await productoBox.put(prod.id, prod);
    }
    productos = productoBox.values.toList();

    // ✅ FIX: no duplicar ventas que ya existen localmente con el mismo id
    final ventasRemotas = await supabase
        .from('sales')
        .select('*, sale_items(*)')
        .eq('company_id', empresaId!)
        .order('completed_at', ascending: false)
        .limit(500);
    for (var json in ventasRemotas) {
      final remoteSaleId = json['id'] as String;
      final items = (json['sale_items'] as List?) ?? [];
      for (var item in items) {
        final itemId = item['id'] as String;
        final idUnificado = '${remoteSaleId}_$itemId';
        if (ventaBox.containsKey(idUnificado)) continue;
        final v = Venta.fromJson(json,
            productoId: item['product_id'],
            productoNombre: '',
            cantidad: ((item['quantity'] ?? 0) as num).toDouble(),
            precioUnitario: ((item['unit_price'] ?? 0) as num).toDouble(),
            costoUnitario: ((item['unit_cost'] ?? 0) as num).toDouble(),
            costoTotal: ((item['cost_total'] ?? 0) as num).toDouble(),
            metodoPago: 'Efectivo CUP');
        v.id = idUnificado;
        v.saleGroupId = remoteSaleId;
        await ventaBox.put(v.id, v);
      }
    }
    ventas = ventaBox.values.toList();

    final gastosRemotos = await supabase
        .from('expenses')
        .select('*')
        .eq('company_id', empresaId!)
        .order('expense_date', ascending: false);
    for (var json in gastosRemotos) {
      final g = Gasto.fromJson(json);
      if (pendientesIds.contains(g.id)) continue;
      await gastoBox.put(g.id, g);
    }
    gastos = gastoBox.values.toList();

    final clientesRemotos = await supabase
        .from('customers')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in clientesRemotos) {
      final c = Cliente.fromJson(json);
      if (pendientesIds.contains(c.id)) continue;
      await clienteBox.put(c.id, c);
    }
    clientes = clienteBox.values.toList();

    await sucursalBox.clear();
    final sucRemotas = await supabase
        .from('branches')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in sucRemotas) {
      final s = Sucursal.fromJson(json);
      await sucursalBox.put(s.id, s);
    }
    sucursales = sucursalBox.values.toList();

    final empRemotas = await supabase
        .from('employees')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in empRemotas) {
      final e = Empleado.fromJson(json);
      if (pendientesIds.contains(e.id)) continue;
      await empleadoBox.put(e.id, e);
    }
    empleados = empleadoBox.values.toList();

    final nomRemotas = await supabase
        .from('payrolls')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in nomRemotas) {
      final n = Nomina.fromJson(json);
      if (pendientesIds.contains(n.id)) continue;
      await nominaBox.put(n.id, n);
    }
    nominas = nominaBox.values.toList();

    final alRemotas = await supabase
        .from('partnerships')
        .select('*')
        .or('company_id.eq.$empresaId,partner_company_id.eq.$empresaId');
    for (var json in alRemotas) {
      final a = Alianza.fromJson(json);
      await alianzaBox.put(a.id, a);
    }
    alianzas = alianzaBox.values.toList();

    final trRemotas = await supabase
        .from('stock_transfers')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in trRemotas) {
      final t = Transferencia.fromJson(json);
      await transferenciaBox.put(t.id, t);
    }
    transferencias = transferenciaBox.values.toList();

    final refRemotas = await supabase
        .from('referrals')
        .select('*')
        .or('referrer_company_id.eq.$empresaId,referred_company_id.eq.$empresaId');
    for (var json in refRemotas) {
      final r = Referido.fromJson(json);
      await referidoBox.put(r.id, r);
    }
    referidos = referidoBox.values.toList();

    final bRemotas = await supabase
        .from('referral_rewards')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in bRemotas) {
      final b = Bono.fromJson(json);
      await bonoBox.put(b.id, b);
    }
    bonos = bonoBox.values.toList();

    final mRemotas = await supabase
        .from('wastages')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in mRemotas) {
      final m = Merma.fromJson(json);
      if (pendientesIds.contains(m.id)) continue;
      await mermaBox.put(m.id, m);
    }
    mermas = mermaBox.values.toList();

    final mvRemotas = await supabase
        .from('inventory_movements')
        .select('*')
        .eq('company_id', empresaId!);
    for (var json in mvRemotas) {
      final mv = MovimientoSucursal.fromJson(json);
      if (pendientesIds.contains(mv.id)) continue;
      await movimientoBox.put(mv.id, mv);
    }
    movimientos = movimientoBox.values.toList();

    final dRemotas =
        await supabase.from('debts').select('*').eq('company_id', empresaId!);
    for (var json in dRemotas) {
      final d = Deuda.fromJson(json);
      if (pendientesIds.contains(d.id)) continue;
      await deudaBox.put(d.id, d);
    }
    deudas = deudaBox.values.toList();

    final metaRemota = await supabase
        .from('sales_goals')
        .select('*')
        .eq('company_id', empresaId!)
        .order('created_at', ascending: false)
        .limit(1);
    if (metaRemota.isNotEmpty) {
      final m = MetaVenta.fromJson(metaRemota.first);
      await metaBox.put(m.id, m);
      meta = metaBox.getAt(0);
    }

    await _cargarDatosLocales();

    ImageCacheWarmer.warmInBackground(
      productos.map((p) => p.imageUrl),
    );

    notifyListeners();
  }

  Future<void> _actualizarDatosEmpresa() async {
    if (empresaId == null) return;
    try {
      final data = await supabase
          .from('companies')
          .select('name, plan, is_active, created_at, current_period_end, '
              'subscription_status, trial_ends_at')
          .eq('id', empresaId!)
          .maybeSingle();
      if (data != null) {
        nombreEmpresa = data['name'] ?? APP_NAME;
        plan = data['plan'] ?? 'premium';
        empresaActiva = data['is_active'] ?? true;
        if (data['created_at'] != null) {
          fechaRegistro = DateTime.tryParse(data['created_at']);
          if (fechaRegistro != null && settingsBox != null) {
            await settingsBox!
                .put(KEY_FECHA_REGISTRO, fechaRegistro!.toIso8601String());
          }
        }
        if (data['current_period_end'] != null && settingsBox != null) {
          await settingsBox!.put(
              KEY_FECHA_VENCIMIENTO, data['current_period_end'].toString());
        }
        if (settingsBox != null) {
          await settingsBox!.put(KEY_EMPRESA_NOMBRE, nombreEmpresa);
        }
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error al actualizar datos de empresa: $e');
    }
  }

  Future<void> _cargarUsuariosCache() async {
    try {
      final id = empresaId ?? await _obtenerEmpresaIdAutenticado();
      if (id == null) return;
      final data = await supabase
          .from('users')
          .select('id, email, full_name')
          .eq('company_id', id);
      for (final u in (data as List)) {
        final map = Map<String, dynamic>.from(u);
        final uid = map['id'] as String?;
        final mail = (map['email'] as String?) ?? '';
        if (uid != null && mail.isNotEmpty) {
          _usuariosEmailCache[uid] = mail;
        }
      }
      if (usuarioId != null && !_usuariosEmailCache.containsKey(usuarioId)) {
        _usuariosEmailCache[usuarioId!] = 'Yo';
      }
    } catch (e) {
      print('⚠️ Error cargando cache de usuarios: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  RED NEXORA · SUPABASE
  // ══════════════════════════════════════════════════════════
  Future<void> publicarTiendaEnRed({
    required String nombre,
    required String slug,
    required String descripcion,
    String? telefono,
    String? whatsapp,
    String? email,
    String? direccion,
    String? horario,
    String categoriaId = 'otros',
    double? latitud,
    double? longitud,
    required List<Map<String, dynamic>> catalogo,
    bool activa = true,
  }) async {
    if (empresaId == null) throw Exception('Sin empresa');

    await supabase.from('network_stores').upsert(
      {
        'company_id': empresaId,
        'nombre': nombre,
        'slug': slug,
        'descripcion': descripcion,
        'telefono': telefono,
        'whatsapp': whatsapp,
        'email': email,
        'direccion': direccion,
        'horario': horario,
        'categoria_id': categoriaId,
        'latitud': latitud,
        'longitud': longitud,
        'activa': activa,
        'catalogo': catalogo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'company_id',
    );
  }

  Future<void> sincronizarRedNexora() async {
    if (!_hayConexion || empresaId == null) return;
    try {
      await _pushTiendaLocalPendiente();
      await _pushMisServiciosPendientes();

      final dataStores = await supabase
          .from('network_stores')
          .select('*')
          .eq('activa', true);

      final list = <Map<String, dynamic>>[];
      for (final row in (dataStores as List)) {
        final map = Map<String, dynamic>.from(row);
        final catalogoRaw = map['catalogo'] as List? ?? [];
        final catalogo = catalogoRaw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        list.add({
          'empresaId': map['company_id'],
          'nombre': map['nombre'],
          'slug': map['slug'],
          'descripcion': map['descripcion'] ?? '',
          'telefono': map['telefono'],
          'whatsapp': map['whatsapp'],
          'email': map['email'],
          'direccion': map['direccion'],
          'horario': map['horario'],
          'categoriaId': map['categoria_id'] ?? 'otros',
          'latitud': map['latitud'],
          'longitud': map['longitud'],
          'rating': (map['rating'] as num?)?.toDouble() ?? 0,
          'totalResenas': (map['total_resenas'] ?? 0) as int,
          'visitas': (map['visitas'] ?? 0) as int,
          'verificado': map['verificado'] ?? false,
          'activa': map['activa'] ?? true,
          'catalogo': catalogo,
          'productosPublicados': <String>[],
          'servicios': <Map<String, dynamic>>[],
          'resenas': <Map<String, dynamic>>[],
          'updatedAt':
              map['updated_at'] ?? DateTime.now().toIso8601String(),
        });
      }
      await catalogosBox.put('network_stores', list);
      print('✅ Red Nexora: ${list.length} tiendas cargadas');

      final dataSvcs = await supabase
          .from('network_services')
          .select('*')
          .eq('activo', true);

      final svcsList = <Map<String, dynamic>>[];
      for (final row in (dataSvcs as List)) {
        final map = Map<String, dynamic>.from(row);
        svcsList.add({
          'id': map['id'],
          'empresaId': map['company_id'],
          'nombreEmpresa': map['nombre_empresa'] ?? '',
          'categoriaId': map['categoria_id'] ?? 'otros',
          'nombre': map['nombre'],
          'descripcion': map['descripcion'] ?? '',
          'precioDesde': map['precio_desde'],
          'precioNota': map['precio_nota'],
          'telefono': map['telefono'],
          'whatsapp': map['whatsapp'],
          'horario': map['horario'],
          'tags': map['tags'] ?? [],
          'latitud': map['latitud'],
          'longitud': map['longitud'],
          'activo': map['activo'] ?? true,
          'vistas': map['vistas'] ?? 0,
          'destacado': false,
          'createdAt':
              map['created_at'] ?? DateTime.now().toIso8601String(),
          'updatedAt':
              map['updated_at'] ?? DateTime.now().toIso8601String(),
        });
      }
      await catalogosBox.put('network_services', svcsList);
      print('✅ Red Nexora: ${svcsList.length} servicios cargados');

      notifyListeners();
    } catch (e) {
      print('⚠️ Error sincronizando Red Nexora: $e');
    }
  }

  Future<void> _pushTiendaLocalPendiente() async {
    if (empresaId == null) return;

    final raw = catalogosBox.get(keyTiendaDeEmpresa(empresaId!));
    if (raw is! Map) return;

    final local =
        TiendaPublica.fromJson(Map<String, dynamic>.from(raw));

    String? remoteUpdatedAt;
    try {
      final remote = await supabase
          .from('network_stores')
          .select('updated_at')
          .eq('company_id', empresaId!)
          .maybeSingle();
      if (remote != null) {
        remoteUpdatedAt = remote['updated_at']?.toString();
      }
    } catch (_) {
      return;
    }

    bool debeSubir = false;
    if (remoteUpdatedAt == null) {
      debeSubir = true;
    } else {
      final remoteDate = DateTime.tryParse(remoteUpdatedAt);
      if (remoteDate == null || local.updatedAt.isAfter(remoteDate)) {
        debeSubir = true;
      }
    }

    if (!debeSubir) return;

    try {
      await publicarTiendaEnRed(
        nombre: local.nombre,
        slug: local.slug,
        descripcion: local.descripcion,
        telefono: local.telefono,
        whatsapp: local.whatsapp,
        email: local.email,
        direccion: local.direccion,
        horario: local.horario,
        categoriaId: local.categoriaId,
        latitud: local.latitud,
        longitud: local.longitud,
        catalogo: local.catalogo.map((p) => p.toJson()).toList(),
        activa: local.activa,
      );
      print('⬆️ Tienda local subida a Supabase');
    } catch (e) {
      print('⚠️ No se pudo subir tienda local: $e');
    }
  }

  Future<void> _pushMisServiciosPendientes() async {
    if (empresaId == null) return;

    final myKey = 'my_services_$empresaId';
    final raw = (catalogosBox.get(myKey) as List?) ?? [];
    if (raw.isEmpty) return;

    final Set<String> idsRemotos = {};
    final Map<String, String?> updatedRemotos = {};
    try {
      final remote = await supabase
          .from('network_services')
          .select('id, updated_at')
          .eq('company_id', empresaId!);
      for (final r in (remote as List)) {
        final id = r['id'] as String?;
        if (id != null) {
          idsRemotos.add(id);
          updatedRemotos[id] = r['updated_at']?.toString();
        }
      }
    } catch (_) {
      return;
    }

    for (final e in raw) {
      try {
        final s =
            ServicioPublico.fromJson(Map<String, dynamic>.from(e));
        final remoto = updatedRemotos[s.id];
        bool debeSubir = false;
        if (!idsRemotos.contains(s.id)) {
          debeSubir = true;
        } else if (remoto != null) {
          final rd = DateTime.tryParse(remoto);
          if (rd == null || s.updatedAt.isAfter(rd)) debeSubir = true;
        }
        if (!debeSubir) continue;

        await publicarServicioEnRed(
          id: s.id,
          categoriaId: s.categoriaId,
          nombre: s.nombre,
          descripcion: s.descripcion,
          precioDesde: s.precioDesde,
          precioNota: s.precioNota,
          telefono: s.telefono,
          whatsapp: s.whatsapp,
          horario: s.horario,
          tags: s.tags,
          latitud: s.latitud,
          longitud: s.longitud,
          activo: s.activo,
        );
        print('⬆️ Servicio local subido a Supabase: ${s.nombre}');
      } catch (err) {
        print('⚠️ No se pudo subir servicio: $err');
      }
    }
  }

  Future<void> publicarServicioEnRed({
    required String id,
    required String categoriaId,
    required String nombre,
    required String descripcion,
    double? precioDesde,
    String? precioNota,
    String? telefono,
    String? whatsapp,
    String? horario,
    List<String> tags = const [],
    double? latitud,
    double? longitud,
    bool activo = true,
  }) async {
    if (empresaId == null) throw Exception('Sin empresa');

    await supabase.from('network_services').upsert(
      {
        'id': id,
        'company_id': empresaId,
        'nombre_empresa': nombreEmpresa ?? 'Mi Empresa',
        'categoria_id': categoriaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio_desde': precioDesde,
        'precio_nota': precioNota,
        'telefono': telefono,
        'whatsapp': whatsapp,
        'horario': horario,
        'tags': tags,
        'latitud': latitud,
        'longitud': longitud,
        'activo': activo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  Future<void> eliminarServicioDeRed(String id) async {
    try {
      await supabase.from('network_services').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Error de autenticación');

    Map<String, dynamic>? data;
    String? fetchError;
    try {
      data = await supabase
          .from('users')
          .select('*, companies(*)')
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      fetchError = e.toString();
      print('⚠️ Error leyendo perfil (1er intento): $e');
      data = null;
    }

    if (data == null || data['company_id'] == null) {
      final meta = user.userMetadata ?? {};
      final nombreMeta =
          (meta['empresa_nombre'] as String?)?.trim().isNotEmpty == true
              ? (meta['empresa_nombre'] as String).trim()
              : ((meta['full_name'] as String?)?.trim().isNotEmpty == true
                  ? (meta['full_name'] as String).trim()
                  : 'Mi Empresa');

      print('🔧 Auto-reparando perfil para ${user.id} (empresa: $nombreMeta)');

      String? rpcError;
      try {
        await supabase.rpc('register_company', params: {
          'p_user_id': user.id,
          'p_email': email.trim(),
          'p_company_name': nombreMeta,
        });
      } catch (e) {
        rpcError = e.toString();
        print('⚠️ register_company en auto-reparación falló: $e');
      }

      try {
        data = await supabase
            .from('users')
            .select('*, companies(*)')
            .eq('id', user.id)
            .maybeSingle();
      } catch (e) {
        print('⚠️ Error releyendo perfil: $e');
        data = null;
      }

      if ((data == null || data['company_id'] == null)) {
        final detalles = StringBuffer();
        if (fetchError != null) detalles.write('fetch: $fetchError | ');
        if (rpcError != null) detalles.write('rpc: $rpcError | ');
        throw Exception(
            'No se pudo vincular tu usuario a una empresa. Detalles: $detalles');
      }
    }

    usuarioId = user.id;
    empresaId = data['company_id'];
    rol = data['role'];
    sucursalIdUsuario = data['default_branch_id'];
    if (sucursalIdUsuario != null && settingsBox != null) {
      await settingsBox!.put(KEY_SUCURSAL_ID, sucursalIdUsuario);
    }

    if (data['companies'] != null) {
      nombreEmpresa = data['companies']['name'] ?? APP_NAME;
      empresaActiva = data['companies']['is_active'] ?? true;
      plan = data['companies']['plan'] ?? 'premium';
      if (data['companies']['created_at'] != null) {
        fechaRegistro = DateTime.tryParse(data['companies']['created_at']);
        if (fechaRegistro != null && settingsBox != null) {
          await settingsBox!
              .put(KEY_FECHA_REGISTRO, fechaRegistro!.toIso8601String());
        }
      }
      if (data['companies']['current_period_end'] != null &&
          settingsBox != null) {
        await settingsBox!.put(KEY_FECHA_VENCIMIENTO,
            data['companies']['current_period_end'].toString());
      }
    } else {
      nombreEmpresa = APP_NAME;
      empresaActiva = true;
      plan = 'premium';
    }

    if (settingsBox != null) {
      await settingsBox!.put(KEY_EMPRESA_ID, empresaId);
      await settingsBox!.put(KEY_ROL, rol);
      await settingsBox!.put(KEY_EMPRESA_NOMBRE, nombreEmpresa);
      await settingsBox!.put(KEY_USUARIO_ID, user.id);
      _ultimoLogin = DateTime.now();
      await settingsBox!
          .put(KEY_ULTIMO_LOGIN, _ultimoLogin!.toIso8601String());
    }

    await _limpiarDatosLocales();
    await _cargarCatalogosGlobales();
    await _cargarDatosLocales();
    await sincronizarTodo(mostrarMensaje: false);
    await obtenerUltimoAnuncio();
    await obtenerUltimaSolicitudPago();
    _startStockNotificationTimer();
    await checkForUpdate();
    await _cargarUsuariosCache();
    notifyListeners();
  }

  Future<void> register(
      String email, String password, String empresaNombre,
      {String? codigoReferido}) async {
    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'empresa_nombre': empresaNombre,
        'full_name': empresaNombre,
      },
    );
    final user = response.user;
    if (user == null) throw Exception('Error al crear usuario');

    try {
      await supabase.rpc('register_company', params: {
        'p_user_id': user.id,
        'p_email': email.trim(),
        'p_company_name': empresaNombre,
      });
    } catch (e) {
      print('⚠️ register_company falló durante el registro: $e');
      rethrow;
    }

    final data = await supabase
        .from('users')
        .select('*, companies(*)')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data['company_id'] == null) {
      throw Exception('No se pudo crear la empresa');
    }

    usuarioId = user.id;
    empresaId = data['company_id'];
    rol = data['role'] ?? 'dueno';
    sucursalIdUsuario = data['default_branch_id'];
    if (sucursalIdUsuario != null && settingsBox != null) {
      await settingsBox!.put(KEY_SUCURSAL_ID, sucursalIdUsuario);
    }

    if (data['companies'] != null) {
      nombreEmpresa = data['companies']['name'] ?? empresaNombre;
      empresaActiva = data['companies']['is_active'] ?? true;
      plan = data['companies']['plan'] ?? 'premium';
      if (data['companies']['created_at'] != null) {
        fechaRegistro = DateTime.tryParse(data['companies']['created_at']);
      } else {
        fechaRegistro = DateTime.now();
      }
      if (fechaRegistro != null && settingsBox != null) {
        await settingsBox!
            .put(KEY_FECHA_REGISTRO, fechaRegistro!.toIso8601String());
      }
    } else {
      nombreEmpresa = empresaNombre;
      empresaActiva = true;
      plan = 'premium';
      fechaRegistro = DateTime.now();
      if (settingsBox != null) {
        await settingsBox!
            .put(KEY_FECHA_REGISTRO, fechaRegistro!.toIso8601String());
      }
    }

    if (settingsBox != null) {
      await settingsBox!.put(KEY_EMPRESA_ID, empresaId);
      await settingsBox!.put(KEY_ROL, rol);
      await settingsBox!.put(KEY_EMPRESA_NOMBRE, nombreEmpresa);
      await settingsBox!.put(KEY_USUARIO_ID, user.id);
      _ultimoLogin = DateTime.now();
      await settingsBox!
          .put(KEY_ULTIMO_LOGIN, _ultimoLogin!.toIso8601String());
      await settingsBox!.put(KEY_MOSTRAR_GUIA, true);
    }

    if (codigoReferido != null && codigoReferido.isNotEmpty) {
      await _procesarReferido(codigoReferido, empresaId!);
    }

    await _cargarCatalogosGlobales();
    await _cargarDatosLocales();
    await sincronizarTodo(mostrarMensaje: false);
    await obtenerUltimoAnuncio();
    await obtenerUltimaSolicitudPago();
    _startStockNotificationTimer();
    await checkForUpdate();
    await _cargarUsuariosCache();
    notifyListeners();
    mostrarSnackBar(
      mensaje:
          '¡Bienvenido a $APP_NAME! Tu empresa fue registrada con 3 días de prueba Premium.',
      esExito: true,
    );
  }

  Future<void> logout() async {
    if (_hayConexion && empresaId != null) {
      await sincronizarTodo(mostrarMensaje: false);
    }
    _stockNotificationTimer?.cancel();
    _syncRetryTimer?.cancel();
    await supabase.auth.signOut();
    usuarioId = null;
    empresaId = null;
    rol = null;
    nombreEmpresa = null;
    empresaActiva = true;
    plan = 'premium';
    ultimoAnuncio = null;
    _ultimaSolicitudPago = null;
    fechaRegistro = null;
    sucursalIdUsuario = null;
    _ultimoLogin = null;
    if (settingsBox != null) {
      for (final k in [
        KEY_EMPRESA_ID,
        KEY_ROL,
        KEY_EMPRESA_NOMBRE,
        KEY_FECHA_REGISTRO,
        KEY_SUCURSAL_ID,
        KEY_ULTIMO_LOGIN,
        KEY_USUARIO_ID,
        KEY_FECHA_APROBACION_PAGO,
        KEY_FECHA_VENCIMIENTO,
      ]) {
        await settingsBox!.delete(k);
      }
    }
    await _limpiarDatosLocales();
    for (final box in [
      productoBox,
      ventaBox,
      gastoBox,
      clienteBox,
      categoriaBox,
      metaBox,
      pendientesBox,
      sucursalBox,
      empleadoBox,
      nominaBox,
      alianzaBox,
      transferenciaBox,
      referidoBox,
      bonoBox,
      mermaBox,
      movimientoBox,
      deudaBox,
      cierreDiarioBox,
    ]) {
      await box.clear();
    }

    try {
      await ProductImageCacheManager.clear();
    } catch (_) {}

    notifyListeners();
  }

  bool get mostrarGuia {
    if (settingsBox == null) return false;
    return (settingsBox!.get(KEY_MOSTRAR_GUIA) ?? false) as bool;
  }

  Future<void> marcarGuiaVista() async {
    if (settingsBox != null) {
      await settingsBox!.put(KEY_MOSTRAR_GUIA, false);
      notifyListeners();
    }
  }

  Future<void> _procesarReferido(
      String codigoReferido, String nuevaEmpresaId) async {
    try {
      final userData = await supabase
          .from('users')
          .select('company_id')
          .eq('email', codigoReferido)
          .maybeSingle();
      if (userData == null || userData['company_id'] == null) return;
      final referenteId = userData['company_id'] as String;
      if (referenteId == nuevaEmpresaId) return;

      final referido = Referido(
        id: uuid.v4(),
        empresaId: referenteId,
        empresaReferidaId: nuevaEmpresaId,
        fechaReferido: DateTime.now(),
        estado: 'pending',
        code: codigoReferido,
      );
      await referidoBox.put(referido.id, referido);
      await _guardarPendiente(
          'insert', 'referidos', referido.toJson(), referido.id);
    } catch (e) {
      print('⚠️ Error al procesar referido: $e');
    }
  }

  Future<void> verificarBonosPorReferidos(String empresaIdPagada) async {
    try {
      final pendientes = referidos
          .where((r) =>
              r.empresaReferidaId == empresaIdPagada &&
              r.estado != 'rewarded')
          .toList();
      for (var r in pendientes) {
        r.estado = 'rewarded';
        r.fechaPago = DateTime.now();
        r.updatedAt = DateTime.now();
        await referidoBox.put(r.id, r);
        await _guardarPendiente('update', 'referidos', r.toJson(), r.id);

        final referidosPagados = referidos
            .where((ref) =>
                ref.empresaId == r.empresaId && ref.estado == 'rewarded')
            .toList();
        if (referidosPagados.length >= 2) {
          final bono = Bono(
            id: uuid.v4(),
            empresaId: r.empresaId,
            descripcion: '50% de descuento por referidos',
            porcentajeDescuento: 50.0,
            fechaInicio: DateTime.now(),
            fechaFin: DateTime.now().add(const Duration(days: 30)),
            referralId: r.id,
          );
          await bonoBox.put(bono.id, bono);
          await _guardarPendiente('insert', 'bonos', bono.toJson(), bono.id);
        }
      }
    } catch (e) {
      print('⚠️ Error al verificar bonos: $e');
    }
  }

  Future<void> solicitarAlianza(String empresaAliadaId) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      final existing = alianzas.where((a) =>
          (a.empresaId == empresaId && a.empresaAliadaId == empresaAliadaId) ||
          (a.empresaId == empresaAliadaId && a.empresaAliadaId == empresaId));
      if (existing.isNotEmpty) {
        mostrarSnackBar(
            mensaje: 'Ya existe una solicitud con esta empresa',
            esExito: false);
        return;
      }
      final alianza = Alianza(
        id: uuid.v4(),
        empresaId: empresaId!,
        empresaAliadaId: empresaAliadaId,
        estado: 'pending',
        fechaSolicitud: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await alianzaBox.put(alianza.id, alianza);
      await _cargarDatosLocales();
      await _guardarPendiente(
          'insert', 'alianzas', alianza.toJson(), alianza.id);
      mostrarSnackBar(mensaje: 'Solicitud enviada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al solicitar alianza: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> responderAlianza(String alianzaId, bool aceptar) async {
    try {
      verificarEmpresaActiva();
      final alianza = alianzaBox.get(alianzaId);
      if (alianza == null) throw Exception('Alianza no encontrada');
      if (alianza.empresaAliadaId != empresaId) {
        mostrarSnackBar(
            mensaje: 'No tienes permiso para responder esta solicitud',
            esExito: false);
        return;
      }
      alianza.estado = aceptar ? 'accepted' : 'rejected';
      alianza.fechaRespuesta = DateTime.now();
      alianza.updatedAt = DateTime.now();
      await alianzaBox.put(alianza.id, alianza);
      await _cargarDatosLocales();
      await _guardarPendiente(
          'update', 'alianzas', alianza.toJson(), alianza.id);
      mostrarSnackBar(
          mensaje: aceptar ? 'Alianza aceptada' : 'Alianza rechazada',
          esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al responder alianza: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  List<Alianza> get alianzasAceptadas =>
      alianzas.where((a) => a.estado == 'accepted').toList();
  List<Alianza> get alianzasPendientes => alianzas
      .where((a) => a.estado == 'pending' && a.empresaAliadaId == empresaId)
      .toList();

  Future<void> guardarTransferencia(Transferencia transferencia) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      transferencia.id = uuid.v4();
      transferencia.empresaId = empresaId;
      transferencia.updatedAt = DateTime.now();
      transferencia.status ??= 'pending';
      await transferenciaBox.put(transferencia.id, transferencia);
      await _cargarDatosLocales();
      await _guardarPendiente('insert', 'transferencias',
          transferencia.toJson(), transferencia.id);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al guardar transferencia: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarTransferencia(String id) async {
    try {
      verificarEmpresaActiva();
      await transferenciaBox.delete(id);
      await _cargarDatosLocales();
      await _guardarPendiente('delete', 'transferencias', {}, id);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar transferencia: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> aprobarTransferenciaRPC(String transferId) async {
    try {
      await supabase.rpc('approve_stock_transfer',
          params: {'p_transfer_id': transferId});
      await sincronizarTodo(mostrarMensaje: false);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al aprobar transferencia: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> recibirTransferenciaRPC(String transferId) async {
    try {
      await supabase.rpc('receive_stock_transfer',
          params: {'p_transfer_id': transferId});
      await sincronizarTodo(mostrarMensaje: false);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al recibir transferencia: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<String?> crearTransferenciaRPC(String sourceBranchId,
      String destBranchId, List<Map<String, dynamic>> items,
      {String? nota}) async {
    try {
      // ✅ FIX: sin p_client_group_id (no existe en la firma SQL)
      final result = await supabase.rpc('create_stock_transfer', params: {
        'p_source_branch_id': sourceBranchId,
        'p_destination_branch_id': destBranchId,
        'p_items': items,
        'p_note': nota,
      });
      await sincronizarTodo(mostrarMensaje: false);
      return result as String?;
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al crear transferencia: ${mensajeAmigable(e)}',
          esExito: false);
      return null;
    }
  }

  List<Referido> get referidosPendientes =>
      referidos.where((r) => r.estado == 'pending').toList();
  List<Referido> get referidosPagados =>
      referidos.where((r) => r.estado == 'rewarded').toList();
  int get cantidadReferidosPagados =>
      referidos.where((r) => r.estado == 'rewarded').length;

  bool get tieneBonoActivo {
    final now = DateTime.now();
    return bonos.any((b) =>
        !b.utilizado &&
        b.fechaInicio.isBefore(now) &&
        b.fechaFin.isAfter(now));
  }

  Bono? get bonoActivo {
    final now = DateTime.now();
    try {
      return bonos.firstWhere((b) =>
          !b.utilizado &&
          b.fechaInicio.isBefore(now) &&
          b.fechaFin.isAfter(now));
    } catch (_) {
      return null;
    }
  }

  Future<void> usarBono(String bonoId) async {
    try {
      final bono = bonoBox.get(bonoId);
      if (bono == null) throw Exception('Bono no encontrado');
      bono.utilizado = true;
      bono.fechaUso = DateTime.now();
      bono.updatedAt = DateTime.now();
      await bonoBox.put(bono.id, bono);
      await _cargarDatosLocales();
      await _guardarPendiente('update', 'bonos', bono.toJson(), bono.id);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al usar bono: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  void _startStockNotificationTimer() {
    _stockNotificationTimer?.cancel();
    if (rol != 'dueno' && rol != 'gerente') return;
    _stockNotificationTimer =
        Timer.periodic(const Duration(seconds: 60), (_) {
      _checkLowStockAndNotify();
    });
  }

  Future<void> _checkLowStockAndNotify() async {
    if (rol != 'dueno' && rol != 'gerente') return;
    final ahora = DateTime.now();
    for (var p in productos) {
      final stock = p.stock.toDouble();
      final threshold =
          p.lowStockThreshold > 0 ? p.lowStockThreshold.toDouble() : 5.0;

      final nivel = stock == 0.0 ? 'out' : (stock < threshold ? 'low' : null);
      if (nivel == null) continue;

      final key = '${p.id}_$nivel';
      final ult = _ultimaNotificacionStock[key];
      if (ult != null && ahora.difference(ult) < _cooldownNotifStock) {
        continue;
      }

      if (nivel == 'out') {
        await NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000 + p.id.hashCode,
          title: '⚠️ Producto agotado',
          body: '${p.nombre} está sin stock.',
        );
      } else {
        await NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000 + p.id.hashCode,
          title: '📦 Stock bajo',
          body: '${p.nombre} tiene ${p.stock} ${p.unidadMedida}.',
        );
      }
      _ultimaNotificacionStock[key] = ahora;
    }
  }

  void refreshNotificationState() => _startStockNotificationTimer();

  List<Sucursal> get sucursalesPermitidas {
    if (esAdminGlobal) return sucursales;
    return sucursales.where((s) => s.id == sucursalIdUsuario).toList();
  }

  List<Producto> _obtenerProductosFiltradosPorSucursal() {
    if (esAdminGlobal) return productos;
    return productos.where((p) => p.sucursalId == sucursalIdUsuario).toList();
  }

  List<Producto> get productosPorSucursal =>
      _obtenerProductosFiltradosPorSucursal();

  List<Venta> _obtenerVentasPermitidas() {
    if (esAdminGlobal) return ventas;
    if (esGerente) {
      return ventas.where((v) => v.sucursalId == sucursalIdUsuario).toList();
    }
    if (esVendedor) {
      return ventas
          .where((v) =>
              v.usuarioId == usuarioId && v.sucursalId == sucursalIdUsuario)
          .toList();
    }
    return ventas;
  }

  List<Venta> get ventasPermitidas => _obtenerVentasPermitidas();

  List<Venta> _ventasFiltradas() => ventasPermitidas;

  List<Gasto> _gastosFiltrados() {
    if (esAdminGlobal) return gastos;
    return gastos.where((g) => g.sucursalId == sucursalIdUsuario).toList();
  }

  double getTotalVentas(DateTime inicio, DateTime fin) => _ventasFiltradas()
      .where((v) => v.fecha.isAfter(inicio) && v.fecha.isBefore(fin))
      .fold<double>(0.0, (s, v) => s + v.total);

  double getTotalVentasUSD(DateTime inicio, DateTime fin) => _ventasFiltradas()
      .where((v) =>
          v.fecha.isAfter(inicio) &&
          v.fecha.isBefore(fin) &&
          v.totalUSD != null)
      .fold<double>(0.0, (s, v) => s + (v.totalUSD ?? 0.0));

  double getCostoVentas(DateTime inicio, DateTime fin) => _ventasFiltradas()
      .where((v) => v.fecha.isAfter(inicio) && v.fecha.isBefore(fin))
      .fold<double>(0.0, (s, v) => s + v.costoTotal);

  double getGananciaBruta(DateTime inicio, DateTime fin) =>
      getTotalVentas(inicio, fin) - getCostoVentas(inicio, fin);

  double getTotalGastos(DateTime inicio, DateTime fin) => _gastosFiltrados()
      .where((g) => g.fecha.isAfter(inicio) && g.fecha.isBefore(fin))
      .fold<double>(0.0, (s, g) => s + g.monto);

  double getTotalMermas(DateTime inicio, DateTime fin) => mermas
      .where((m) =>
          !m.cancelado && m.fecha.isAfter(inicio) && m.fecha.isBefore(fin))
      .fold<double>(0.0, (s, m) => s + m.costoTotal);

  double getGananciaNeta(DateTime inicio, DateTime fin) =>
      getTotalVentas(inicio, fin) -
      getCostoVentas(inicio, fin) -
      getTotalGastos(inicio, fin) -
      getTotalMermas(inicio, fin);

  int getNumVentas(DateTime inicio, DateTime fin) => _ventasFiltradas()
      .where((v) => v.fecha.isAfter(inicio) && v.fecha.isBefore(fin))
      .length;

  List<Map<String, dynamic>> getDatosGraficoVentas() {
    final datos = <Map<String, dynamic>>[];
    final vf = _ventasFiltradas();
    for (int i = 6; i >= 0; i--) {
      final dia = DateTime(hoy.year, hoy.month, hoy.day - i);
      final diaSig = dia.add(const Duration(days: 1));
      final total = vf
          .where((v) => v.fecha.isAfter(dia) && v.fecha.isBefore(diaSig))
          .fold<double>(0.0, (s, v) => s + v.total);
      final costo = vf
          .where((v) => v.fecha.isAfter(dia) && v.fecha.isBefore(diaSig))
          .fold<double>(0.0, (s, v) => s + v.costoTotal);
      datos.add({
        'periodo': DateFormat('E').format(dia).substring(0, 3),
        'ventas': total,
        'costo': costo,
        'ganancia': total - costo,
      });
    }
    return datos;
  }

  List<Venta> getVentasPorPeriodo(DateTime inicio, DateTime fin) =>
      ventasPermitidas
          .where((v) => v.fecha.isAfter(inicio) && v.fecha.isBefore(fin))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  List<Gasto> getGastosPorPeriodo(DateTime inicio, DateTime fin) =>
      _gastosFiltrados()
          .where((g) => g.fecha.isAfter(inicio) && g.fecha.isBefore(fin))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  List<Map<String, dynamic>> getProductosMasVendidos(
      DateTime inicio, DateTime fin) {
    final filtradas = _ventasFiltradas()
        .where((v) => v.fecha.isAfter(inicio) && v.fecha.isBefore(fin))
        .toList();
    final resumen = <String, Map<String, dynamic>>{};
    for (var v in filtradas) {
      resumen.putIfAbsent(
          v.productoId,
          () => {
                'nombre': v.productoNombre,
                'cantidad': 0.0,
                'total': 0.0,
                'costo': 0.0,
              });
      resumen[v.productoId]!['cantidad'] =
          (resumen[v.productoId]!['cantidad'] as double) + v.cantidad;
      resumen[v.productoId]!['total'] =
          (resumen[v.productoId]!['total'] as double) + v.total;
      resumen[v.productoId]!['costo'] =
          (resumen[v.productoId]!['costo'] as double) + v.costoTotal;
    }
    final list = resumen.entries
        .map((e) => {
              'id': e.key,
              'nombre': e.value['nombre'],
              'cantidad': e.value['cantidad'],
              'total': e.value['total'],
              'costo': e.value['costo'],
            })
        .toList();
    list.sort((a, b) =>
        (b['cantidad'] as double).compareTo(a['cantidad'] as double));
    return list;
  }

  String generarReporteTexto(DateTime inicio, DateTime fin) {
    final ventasPeriodo = getVentasPorPeriodo(inicio, fin);
    final gastosPeriodo = getGastosPorPeriodo(inicio, fin);
    final mermasPeriodo = mermas
        .where((m) =>
            !m.cancelado && m.fecha.isAfter(inicio) && m.fecha.isBefore(fin))
        .toList();
    final costoVentas = getCostoVentas(inicio, fin);
    final ventasTotal = getTotalVentas(inicio, fin);
    final gananciaBruta = ventasTotal - costoVentas;
    final gastosTotal = getTotalGastos(inicio, fin);
    final totalMermas = getTotalMermas(inicio, fin);
    final gananciaNeta = ventasTotal - costoVentas - gastosTotal - totalMermas;
    final b = StringBuffer();
    b.writeln('=== REPORTE $APP_NAME ===');
    b.writeln(
        'Periodo: ${DateFormat('dd/MM/yy').format(inicio)} - ${DateFormat('dd/MM/yy').format(fin)}');
    b.writeln('Total Ventas: \$${ventasTotal.toStringAsFixed(2)}');
    b.writeln('Costo de Ventas (FIFO): \$${costoVentas.toStringAsFixed(2)}');
    b.writeln('Ganancia Bruta: \$${gananciaBruta.toStringAsFixed(2)}');
    b.writeln('Total Gastos: \$${gastosTotal.toStringAsFixed(2)}');
    b.writeln('Total Mermas: \$${totalMermas.toStringAsFixed(2)}');
    b.writeln('Ganancia Neta: \$${gananciaNeta.toStringAsFixed(2)}');
    b.writeln('--- Ventas ---');
    for (var v in ventasPeriodo) {
      b.writeln(
          '${v.productoNombre} x${v.cantidad} = \$${v.total.toStringAsFixed(2)} (FIFO: \$${v.costoTotal.toStringAsFixed(2)}) - ${DateFormat('dd/MM HH:mm').format(v.fecha)}');
    }
    b.writeln('--- Gastos ---');
    for (var g in gastosPeriodo) {
      b.writeln(
          '${g.concepto}: \$${g.monto.toStringAsFixed(2)} (${DateFormat('dd/MM').format(g.fecha)})');
    }
    b.writeln('--- Mermas ---');
    for (var m in mermasPeriodo) {
      final prod = getProductoById(m.productoId);
      b.writeln(
          '${prod?.nombre ?? 'Producto'} x${m.cantidad} (${_traducirMotivo(m.motivo)}) - \$${m.costoTotal.toStringAsFixed(2)}');
    }
    b.writeln('=== Fin ===');
    return b.toString();
  }

  List<Map<String, dynamic>> generarLibroIngresosGastos(
      DateTime inicio, DateTime fin) {
    final ventasPeriodo = getVentasPorPeriodo(inicio, fin);
    final gastosPeriodo = getGastosPorPeriodo(inicio, fin);
    final mermasPeriodo = mermas
        .where((m) =>
            !m.cancelado && m.fecha.isAfter(inicio) && m.fecha.isBefore(fin))
        .toList();
    final eventos = <Map<String, dynamic>>[];
    for (var v in ventasPeriodo) {
      eventos.add({
        'fecha': v.fecha,
        'concepto': 'Venta: ${v.productoNombre} (x${v.cantidad})',
        'ingreso': v.total,
        'gasto': 0.0,
        'tipo': 'ingreso',
        'id': v.id,
      });
    }
    for (var g in gastosPeriodo) {
      eventos.add({
        'fecha': g.fecha,
        'concepto': 'Gasto: ${g.concepto}',
        'ingreso': 0.0,
        'gasto': g.monto,
        'tipo': 'gasto',
        'id': g.id,
      });
    }
    for (var m in mermasPeriodo) {
      final prod = getProductoById(m.productoId);
      eventos.add({
        'fecha': m.fecha,
        'concepto':
            'Merma: ${prod?.nombre ?? 'Producto'} (${_traducirMotivo(m.motivo)})',
        'ingreso': 0.0,
        'gasto': m.costoTotal,
        'tipo': 'gasto',
        'id': m.id,
      });
    }
    eventos.sort((a, b) =>
        (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));
    double saldo = 0.0;
    for (var e in eventos) {
      saldo += (e['ingreso'] as double) - (e['gasto'] as double);
      e['saldo'] = saldo;
    }
    return eventos;
  }

  Future<void> crearSolicitudPago(String noTransaccion, String planSolicitado,
      {int dias = 30}) async {
    verificarEmpresaActiva();
    if (empresaId == null) throw Exception('No hay empresa asociada.');

    final planCode = planSolicitado == 'normal' ? 'base' : 'premium';

    final ultima = await obtenerUltimaSolicitudPago();
    if (ultima != null && ultima.estado == 'pending') {
      throw Exception(
          'Ya tienes una solicitud pendiente. Espera a que sea procesada.');
    }

    try {
      final bono = bonoActivo;
      await supabase.rpc('create_payment_request', params: {
        'p_plan': planCode,
        'p_days': dias,
        'p_transfer_reference': noTransaccion,
        'p_sender_name': null,
        'p_sender_phone': null,
        'p_note': null,
      });
      if (bono != null) {
        await usarBono(bono.id);
      }
      mostrarSnackBar(mensaje: 'Solicitud de pago enviada', esExito: true);
      await obtenerUltimaSolicitudPago();
    } catch (e) {
      throw Exception('Error al enviar la solicitud: ${mensajeAmigable(e)}');
    }
  }

  Future<SolicitudPago?> obtenerUltimaSolicitudPago() async {
    if (empresaId == null) return _ultimaSolicitudPago;
    try {
      final data = await supabase
          .from('payment_requests')
          .select('*, companies(name)')
          .eq('company_id', empresaId!)
          .order('created_at', ascending: false)
          .limit(1);
      if (data.isNotEmpty) {
        final json = Map<String, dynamic>.from(data.first);
        json['nombre_empresa'] = json['companies']?['name'] ?? '';
        _ultimaSolicitudPago = SolicitudPago.fromJson(json);
        if (_ultimaSolicitudPago!.estado == 'approved' &&
            _ultimaSolicitudPago!.fechaAprobacion != null &&
            settingsBox != null) {
          await settingsBox!.put(KEY_FECHA_APROBACION_PAGO,
              _ultimaSolicitudPago!.fechaAprobacion!.toIso8601String());
        }
        notifyListeners();
        return _ultimaSolicitudPago;
      } else {
        _ultimaSolicitudPago = null;
        notifyListeners();
        return null;
      }
    } catch (e) {
      return _ultimaSolicitudPago;
    }
  }

  bool isPagoVigente() {
    if (rol != 'dueno') return true;

    if (fechaRegistro != null) {
      final dias = DateTime.now().difference(fechaRegistro!).inDays;
      if (dias < DIAS_PRUEBA) return true;
    }

    final venc = settingsBox?.get(KEY_FECHA_VENCIMIENTO) as String?;
    if (venc != null) {
      final fechaVenc = DateTime.tryParse(venc);
      if (fechaVenc != null) {
        return DateTime.now()
            .isBefore(fechaVenc.add(const Duration(days: DIAS_GRACIA)));
      }
    }

    final fechaAprobStr =
        settingsBox?.get(KEY_FECHA_APROBACION_PAGO) as String?;
    if (fechaAprobStr == null) return false;
    final fechaAprob = DateTime.tryParse(fechaAprobStr);
    if (fechaAprob == null) return false;
    final dias = DateTime.now().difference(fechaAprob).inDays;
    return dias <= DIAS_TOTAL_VIGENCIA;
  }

  Future<String?> _obtenerEmpresaIdAutenticado() async {
    if (settingsBox != null) {
      final id = settingsBox!.get(KEY_EMPRESA_ID) as String?;
      if (id != null) return id;
    }
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('users')
            .select('company_id')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['company_id'] != null) {
          final id = data['company_id'] as String;
          if (settingsBox != null) await settingsBox!.put(KEY_EMPRESA_ID, id);
          return id;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Usuario>> listarVendedores() async {
    final id = empresaId ?? await _obtenerEmpresaIdAutenticado();
    if (id == null) return [];
    var q = supabase
        .from('users')
        .select('*')
        .eq('company_id', id)
        .eq('role', 'vendedor');
    if (!esAdminGlobal && sucursalIdUsuario != null) {
      q = q.eq('default_branch_id', sucursalIdUsuario!);
    }
    final data = await q.order('created_at', ascending: false);
    return (data as List)
        .map<Usuario>((j) => Usuario.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<Usuario>> listarGestores() async {
    final id = empresaId ?? await _obtenerEmpresaIdAutenticado();
    if (id == null) return [];
    final data = await supabase
        .from('users')
        .select('*')
        .eq('company_id', id)
        .eq('role', 'gerente')
        .order('created_at', ascending: false);
    return (data as List)
        .map<Usuario>((j) => Usuario.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<Usuario>> listarUsuariosDeEmpresa() async {
    final id = empresaId ?? await _obtenerEmpresaIdAutenticado();
    if (id == null) return [];
    var q = supabase
        .from('users')
        .select('*')
        .eq('company_id', id)
        .inFilter('role', ['vendedor', 'gerente']);
    if (!esAdminGlobal && sucursalIdUsuario != null) {
      q = q.eq('default_branch_id', sucursalIdUsuario!);
    }
    final data = await q.order('created_at', ascending: false);
    return (data as List)
        .map<Usuario>((j) => Usuario.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  int getLimiteVendedores() {
    switch (plan) {
      case 'base':
        return LIMITE_VENDEDORES_BASE;
      case 'premium':
        return LIMITE_VENDEDORES_PREMIUM;
      default:
        return LIMITE_VENDEDORES_BASE;
    }
  }

  Future<String> crearVendedor(String email, String password) async {
    verificarEmpresaActiva();
    final empresaIdActual = await _obtenerEmpresaIdAutenticado();
    if (empresaIdActual == null) {
      throw Exception('No se encontró empresa asociada.');
    }

    final vendedores = await listarVendedores();
    final limite = getLimiteVendedores();
    if (vendedores.length >= limite) {
      throw Exception(
          'Tu plan $plan solo permite $limite vendedores por sucursal.');
    }

    final existing = await supabase
        .from('users')
        .select('id')
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    if (existing != null) {
      throw Exception('El email ya está registrado.');
    }

    final sesionDueno = supabase.auth.currentSession;
    if (sesionDueno == null) {
      throw Exception('No hay sesión activa');
    }
    final refreshToken = sesionDueno.refreshToken;
    if (refreshToken == null) {
      throw Exception('No se pudo obtener el token de sesión');
    }

    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final userNuevo = response.user;
    if (userNuevo == null) throw Exception('Error al crear usuario.');

    try {
      await supabase.auth.setSession(refreshToken);
    } catch (e) {
      // Fallback en versiones antiguas del SDK
      // ignore: deprecated_member_use
      await supabase.auth.recoverSession(refreshToken);
    }

    await supabase.rpc('create_company_vendor', params: {
      'p_new_user_id': userNuevo.id,
      'p_email': email.trim(),
      'p_branch_id': sucursalIdUsuario,
    });

    return userNuevo.id;
  }

  Future<void> eliminarVendedor(String userId) async {
    verificarEmpresaActiva();
    await supabase.from('users').update({'active': false}).eq('id', userId);
    notifyListeners();
  }

  Future<void> actualizarSucursalUsuario(
      String userId, String? sucursalId) async {
    verificarEmpresaActiva();
    await supabase
        .from('users')
        .update({'default_branch_id': sucursalId}).eq('id', userId);
    if (userId == usuarioId) {
      sucursalIdUsuario = sucursalId;
      if (settingsBox != null) {
        await settingsBox!.put(KEY_SUCURSAL_ID, sucursalId);
      }
      notifyListeners();
    }
  }

  Future<void> promoverAGestor(String userId, String sucursalId) async {
    verificarEmpresaActiva();
    await supabase.from('users').update({
      'role': 'gerente',
      'default_branch_id': sucursalId,
    }).eq('id', userId);
    notifyListeners();
  }

  Future<void> revertirAVendedor(String userId) async {
    verificarEmpresaActiva();
    await supabase
        .from('users')
        .update({'role': 'vendedor'}).eq('id', userId);
    notifyListeners();
  }

  Future<List<EstadisticasVendedor>> getEstadisticasVendedores() async {
    final vendedores = await listarVendedores();
    if (vendedores.isEmpty) return [];
    final empresaIdActual = await _obtenerEmpresaIdAutenticado();
    if (empresaIdActual == null) return [];

    final ventasData = await supabase
        .from('sales')
        .select('seller_id, total, sale_items(cost_total)')
        .eq('company_id', empresaIdActual)
        .eq('status', 'completed');

    final stats = <String, EstadisticasVendedor>{};
    for (var v in vendedores) {
      stats[v.id] = EstadisticasVendedor(
        id: v.id,
        email: v.email,
        totalVentas: 0,
        totalMonto: 0,
        totalGanancia: 0,
      );
    }
    for (var row in (ventasData as List)) {
      final sid = row['seller_id'];
      if (sid == null || !stats.containsKey(sid)) continue;
      final total = ((row['total'] ?? 0) as num).toDouble();
      double costo = 0;
      for (var it in (row['sale_items'] as List? ?? [])) {
        costo += ((it['cost_total'] ?? 0) as num).toDouble();
      }
      final s = stats[sid]!;
      stats[sid] = EstadisticasVendedor(
        id: s.id,
        email: s.email,
        totalVentas: s.totalVentas + 1,
        totalMonto: s.totalMonto + total,
        totalGanancia: s.totalGanancia + (total - costo),
      );
    }
    final lista = stats.values.toList();
    lista.sort((a, b) => b.totalVentas.compareTo(a.totalVentas));
    return lista;
  }

  Future<void> _cargarDatosLocales() async {
    try {
      productos = productoBox.values.toList();
      ventas = ventaBox.values.toList();
      gastos = gastoBox.values.toList();
      clientes = clienteBox.values.toList();
      categorias = categoriaBox.values.toList();
      sucursales = empresaId != null
          ? sucursalBox.values.where((s) => s.empresaId == empresaId).toList()
          : sucursalBox.values.toList();
      if (metaBox.isNotEmpty) meta = metaBox.getAt(0);
      empleados = empleadoBox.values.toList();
      nominas = nominaBox.values.toList();
      alianzas = alianzaBox.values.toList();
      transferencias = transferenciaBox.values.toList();
      referidos = referidoBox.values.toList();
      bonos = bonoBox.values.toList();
      mermas = mermaBox.values.toList();
      movimientos = movimientoBox.values.toList();
      deudas = deudaBox.values.toList();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error al cargar datos locales: $e');
    }
  }

  Future<void> _limpiarDatosLocales() async {
    productos.clear();
    ventas.clear();
    gastos.clear();
    clientes.clear();
    categorias.clear();
    sucursales.clear();
    empleados.clear();
    nominas.clear();
    alianzas.clear();
    transferencias.clear();
    referidos.clear();
    bonos.clear();
    mermas.clear();
    movimientos.clear();
    deudas.clear();
    meta = null;
  }

  Future<void> obtenerUltimoAnuncio() async {
    try {
      final data = await supabase
          .from('announcements')
          .select('*')
          .eq('active', true)
          .order('starts_at', ascending: false)
          .limit(1);
      if ((data as List).isNotEmpty) {
        ultimoAnuncio =
            Anuncio.fromJson(Map<String, dynamic>.from(data.first));
      } else {
        ultimoAnuncio = null;
      }
      notifyListeners();
    } catch (_) {
      ultimoAnuncio = null;
    }
  }

  String? _latestVersion;
  String? _downloadUrl;
  String? _changelog;
  bool _hasUpdate = false;

  String get currentVersion => APP_VERSION;
  String? get latestVersion => _latestVersion;
  String? get downloadUrl => _downloadUrl;
  String? get changelog => _changelog;
  bool get hasUpdate => _hasUpdate;

  Future<void> checkForUpdate() async {
    try {
      final response = await supabase
          .from('app_versions')
          .select('version, download_url, changelog')
          .eq('active', true)
          .order('release_date', ascending: false)
          .limit(1);
      if ((response as List).isNotEmpty) {
        final data = response.first;
        _latestVersion = data['version'] as String?;
        _downloadUrl = data['download_url'] as String?;
        _changelog = data['changelog'] as String?;
        if (_latestVersion != null) {
          _hasUpdate = _isNewerVersion(_latestVersion!, APP_VERSION);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  bool _isNewerVersion(String remote, String current) {
    try {
      final r = remote.split('.').map(int.parse).toList();
      final c = current.split('.').map(int.parse).toList();
      for (int i = 0; i < r.length; i++) {
        if (i >= c.length) return true;
        if (r[i] > c[i]) return true;
        if (r[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return remote != current;
    }
  }

  List<Empleado> get listaEmpleados =>
      empleados.where((e) => e.activo).toList();

  Empleado? getEmpleadoByUsuarioId(String usuarioId) {
    try {
      return empleados.firstWhere((e) => e.usuarioId == usuarioId);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarEmpleado(Empleado empleado) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      empleado.empresaId = empresaId;
      empleado.updatedAt = DateTime.now();
      if (empleado.id.isEmpty) empleado.id = uuid.v4();
      await empleadoBox.put(empleado.id, empleado);
      empleados = empleadoBox.values.toList();
      await _guardarPendiente(
          'insert', 'empleados', empleado.toJson(), empleado.id);
      mostrarSnackBar(mensaje: 'Empleado guardado', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al guardar empleado: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> desactivarEmpleado(String empleadoId) async {
    try {
      final e = empleadoBox.get(empleadoId);
      if (e != null) {
        e.activo = false;
        e.updatedAt = DateTime.now();
        await empleadoBox.put(empleadoId, e);
        empleados = empleadoBox.values.toList();
        await _guardarPendiente('update', 'empleados', e.toJson(), empleadoId);
        mostrarSnackBar(mensaje: 'Empleado desactivado', esExito: true);
      }
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al desactivar empleado: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<Nomina> generarNomina(String empleadoId, DateTime periodo,
      {String metodoPago = 'Efectivo'}) async {
    final emp = empleadoBox.get(empleadoId);
    if (emp == null) throw Exception('Empleado no encontrado');
    if (!emp.activo) throw Exception('Empleado inactivo');

    double comisiones = 0;
    if (emp.comisionPorcentaje != null && emp.comisionPorcentaje! > 0) {
      final inicio = DateTime(periodo.year, periodo.month, 1);
      final fin = DateTime(periodo.year, periodo.month + 1, 1);
      final ventasEmp = ventas.where((v) =>
          v.usuarioId == emp.usuarioId &&
          v.fecha.isAfter(inicio) &&
          v.fecha.isBefore(fin));
      final total = ventasEmp.fold<double>(0.0, (s, v) => s + v.total);
      comisiones = total * (emp.comisionPorcentaje! / 100);
    }

    final total = emp.salarioBase + comisiones;
    final nomina = Nomina(
      id: uuid.v4(),
      empleadoId: emp.id,
      periodo: DateTime(periodo.year, periodo.month, 1),
      salarioBase: emp.salarioBase,
      comisiones: comisiones,
      deducciones: 0,
      totalPagado: total,
      fechaPago: DateTime.now(),
      metodoPago: metodoPago,
      empresaId: empresaId,
      sucursalId: sucursalIdUsuario,
      updatedAt: DateTime.now(),
    );
    await nominaBox.put(nomina.id, nomina);
    nominas = nominaBox.values.toList();
    await _guardarPendiente('insert', 'nominas', nomina.toJson(), nomina.id);
    await _guardarPendiente('update', 'empleados', emp.toJson(), emp.id);
    mostrarSnackBar(mensaje: 'Nómina generada', esExito: true);
    return nomina;
  }

  List<Nomina> getNominasByEmpleado(String empleadoId) => nominas
      .where((n) => n.empleadoId == empleadoId)
      .toList()
    ..sort((a, b) => b.fechaPago.compareTo(a.fechaPago));

  List<Nomina> getNominasDelMes() {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fin = DateTime(now.year, now.month + 1, 1);
    return nominas
        .where((n) => n.fechaPago.isAfter(inicio) && n.fechaPago.isBefore(fin))
        .toList();
  }

  double getCostoPersonal(DateTime inicio, DateTime fin) => nominas
      .where((n) => n.fechaPago.isAfter(inicio) && n.fechaPago.isBefore(fin))
      .fold<double>(0.0, (s, n) => s + n.totalPagado);

  Future<List<Map<String, dynamic>>> getEmpleadosConUsuario() async {
    final result = <Map<String, dynamic>>[];
    final usuarios = await listarUsuariosDeEmpresa();
    for (var u in usuarios) {
      final emp = getEmpleadoByUsuarioId(u.id);
      if (emp != null && emp.activo) {
        result.add({'usuario': u, 'empleado': emp});
      }
    }
    return result;
  }

  Future<void> crearSucursal(Sucursal sucursal) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      sucursal.id = uuid.v4();
      sucursal.empresaId = empresaId;
      sucursal.createdAt = DateTime.now();
      sucursal.updatedAt = DateTime.now();
      await sucursalBox.put(sucursal.id, sucursal);
      sucursales =
          sucursalBox.values.where((s) => s.empresaId == empresaId).toList();
      await _guardarPendiente(
          'insert', 'sucursales', sucursal.toJson(), sucursal.id);
      mostrarSnackBar(mensaje: 'Sucursal creada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al crear sucursal: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> editarSucursal(Sucursal sucursal) async {
    try {
      verificarEmpresaActiva();
      sucursal.updatedAt = DateTime.now();
      await sucursalBox.put(sucursal.id, sucursal);
      sucursales =
          sucursalBox.values.where((s) => s.empresaId == empresaId).toList();
      await _guardarPendiente(
          'update', 'sucursales', sucursal.toJson(), sucursal.id);
      mostrarSnackBar(mensaje: 'Sucursal actualizada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al editar sucursal: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarSucursal(String id) async {
    try {
      verificarEmpresaActiva();
      final tieneProd = productos.any((p) => p.sucursalId == id);
      final tieneVentas = ventas.any((v) => v.sucursalId == id);
      if (tieneProd || tieneVentas) {
        mostrarSnackBar(
            mensaje:
                'No se puede eliminar: tiene productos o ventas asociadas.',
            esExito: false);
        return;
      }
      await sucursalBox.delete(id);
      sucursales =
          sucursalBox.values.where((s) => s.empresaId == empresaId).toList();
      await _guardarPendiente('delete', 'sucursales', {}, id);
      mostrarSnackBar(mensaje: 'Sucursal eliminada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar sucursal: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> asignarGestor(String sucursalId, String usuarioId) async {
    try {
      verificarEmpresaActiva();
      await supabase
          .from('users')
          .update({'default_branch_id': sucursalId}).eq('id', usuarioId);
      final s = sucursalBox.get(sucursalId);
      if (s != null) {
        s.gestorId = usuarioId;
        s.updatedAt = DateTime.now();
        await sucursalBox.put(sucursalId, s);
        sucursales =
            sucursalBox.values.where((s) => s.empresaId == empresaId).toList();
        mostrarSnackBar(mensaje: 'Gestor asignado', esExito: true);
        notifyListeners();
      }
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al asignar gestor: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> agregarProducto(Producto producto) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      producto.id = uuid.v4();
      producto.empresaId = empresaId;
      producto.updatedAt = DateTime.now();
      if (!esAdminGlobal) {
        producto.sucursalId = sucursalIdUsuario;
      } else {
        producto.sucursalId ??=
            sucursales.isNotEmpty ? sucursales.first.id : null;
      }

      if (producto.stock > 0 && producto.lotes.isEmpty) {
        producto.lotes.add({
          'cantidad': producto.stock,
          'precioCompra': producto.precioCompra,
        });
      }

      await productoBox.put(producto.id, producto);
      productos = productoBox.values.toList();

      final datosSync = Map<String, dynamic>.from(producto.toJson());
      datosSync['_initial_stock'] = producto.stock;
      datosSync['_branch_id'] = producto.sucursalId;

      await _guardarPendiente('insert', 'productos', datosSync, producto.id);

      mostrarSnackBar(mensaje: 'Producto creado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al crear producto: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> editarProducto(Producto producto) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      producto.empresaId = empresaId;
      producto.updatedAt = DateTime.now();
      if (!esAdminGlobal) producto.sucursalId = sucursalIdUsuario;

      final anterior = productoBox.get(producto.id);
      producto.stock = anterior?.stock ?? producto.stock;
      producto.lotes = anterior?.lotes ?? producto.lotes;

      await productoBox.put(producto.id, producto);
      productos = productoBox.values.toList();

      await _guardarPendiente(
          'update', 'productos', producto.toJson(), producto.id);

      _checkLowStockAndNotify();
      mostrarSnackBar(
        mensaje: _hayConexion
            ? 'Producto actualizado'
            : 'Producto actualizado (se sincronizará)',
        esExito: true,
      );
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al editar producto: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      verificarEmpresaActiva();
      await productoBox.delete(id);
      productos = productoBox.values.toList();
      await _guardarPendiente('delete', 'productos', {}, id);
      mostrarSnackBar(mensaje: 'Producto eliminado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar producto: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Producto? getProductoById(String id) {
    try {
      return productos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String getSucursalNombre(String sucursalId) {
    try {
      return sucursales.firstWhere((s) => s.id == sucursalId).nombre;
    } catch (_) {
      return 'Sucursal desconocida';
    }
  }

  double getPrecioProducto(
      Producto producto, String metodoPago, bool esMayorista) {
    if (esMayorista) {
      if (metodoPago == 'Efectivo CUP' || metodoPago == 'Efectivo USD') {
        return producto.precioMayoristaEfectivo > 0
            ? producto.precioMayoristaEfectivo
            : producto.precioVenta * 0.9;
      }
      return producto.precioMayoristaTransferencia > 0
          ? producto.precioMayoristaTransferencia
          : producto.precioVenta * 0.85;
    }
    if (metodoPago == 'Efectivo CUP' || metodoPago == 'Efectivo USD') {
      return producto.precioVenta;
    }
    return producto.precioTransferencia > 0
        ? producto.precioTransferencia
        : producto.precioVenta;
  }

  Future<void> reabastecerProducto(
      String id, double cantidad, double precioCompra) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      final producto = getProductoById(id);
      if (producto == null || cantidad <= 0) return;

      final branchId = producto.sucursalId ?? sucursalIdUsuario;
      if (branchId == null) throw Exception('Sin sucursal asignada');

      producto.lotes.add({
        'cantidad': cantidad,
        'precioCompra': precioCompra,
      });
      producto.stock += cantidad;
      producto.precioCompra = precioCompra;
      producto.updatedAt = DateTime.now();
      await productoBox.put(producto.id, producto);
      productos = productoBox.values.toList();

      final refId = uuid.v4();
      // ✅ FIX: sin p_reference_id (no existe en la firma SQL)
      final rpcDatos = {
        '_rpc': 'receive_inventory',
        '_params': {
          'p_branch_id': branchId,
          'p_product_id': producto.id,
          'p_quantity': cantidad,
          'p_unit_cost': precioCompra,
          'p_lot_number': null,
          'p_expiration_date': null,
          'p_supplier_name': null,
          'p_is_trial_data': false,
        },
      };
      await _guardarPendiente('rpc', 'rpc', rpcDatos, 'recv_$refId');

      mostrarSnackBar(
        mensaje: _hayConexion
            ? 'Reabastecimiento exitoso'
            : 'Reabastecimiento guardado (se sincronizará)',
        esExito: true,
      );
      _checkLowStockAndNotify();
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al reabastecer: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<String?> crearVentaRPC({
    required String branchId,
    required List<Map<String, dynamic>> items,
    String? customerId,
    double discount = 0,
    double tax = 0,
    String? currencyId,
    double exchangeRate = 1,
    String mode = 'real_time',
    String? note,
    bool isTrialData = false,
    String? clientGroupId,
  }) async {
    try {
      verificarEmpresaActiva();
      // ✅ FIX: sin p_client_group_id (no existe en la firma SQL)
      final result = await supabase.rpc('create_sale', params: {
        'p_branch_id': branchId,
        'p_items': items,
        'p_customer_id': customerId,
        'p_discount': discount,
        'p_tax': tax,
        'p_currency_id': currencyId,
        'p_exchange_rate': exchangeRate,
        'p_mode': mode,
        'p_note': note,
        'p_is_trial_data': isTrialData,
      });
      return result as String?;
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar venta: ${mensajeAmigable(e)}',
          esExito: false);
      return null;
    }
  }

  Future<void> _descontarStockLocal(Producto producto, double cantidad) async {
    if (cantidad <= 0) return;

    double restante = cantidad;
    final nuevosLotes = <Map<String, dynamic>>[];

    for (final lote in producto.lotes) {
      if (restante <= 0) {
        nuevosLotes.add(lote);
        continue;
      }

      final disponible = (lote['cantidad'] as num?)?.toDouble() ?? 0;
      if (disponible <= 0) continue;

      if (disponible <= restante) {
        restante -= disponible;
      } else {
        final nuevo = Map<String, dynamic>.from(lote);
        nuevo['cantidad'] = disponible - restante;
        restante = 0;
        nuevosLotes.add(nuevo);
      }
    }

    producto.lotes = nuevosLotes;
    producto.stock = (producto.stock - cantidad).clamp(0.0, double.infinity);
    producto.updatedAt = DateTime.now();

    await productoBox.put(producto.id, producto);
    productos = productoBox.values.toList();

    _checkLowStockAndNotify();
  }

  Future<void> agregarVenta(Venta venta) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');

      final branchId = venta.sucursalId ??
          (esAdminGlobal
              ? (sucursales.isNotEmpty ? sucursales.first.id : null)
              : sucursalIdUsuario);
      if (branchId == null) throw Exception('Sin sucursal');

      final producto = getProductoById(venta.productoId);
      if (producto == null) throw Exception('Producto no encontrado');
      if (producto.stock < venta.cantidad) {
        throw Exception(
            'Stock insuficiente para "${producto.nombre}". Disponible: ${producto.stock} ${producto.unidadMedida}');
      }

      await _descontarStockLocal(producto, venta.cantidad);

      final idLocal = venta.id.isNotEmpty ? venta.id : uuid.v4();
      final groupId = venta.saleGroupId ?? idLocal;
      venta.id = idLocal;
      venta.saleGroupId = groupId;
      venta.empresaId = empresaId;
      venta.updatedAt = DateTime.now();
      venta.usuarioId = usuarioId;
      venta.sucursalId = branchId;

      await ventaBox.put(venta.id, venta);
      ventas = ventaBox.values.toList();

      bool sincronizada = false;
      if (_hayConexion) {
        try {
          final items = [
            {
              'product_id': venta.productoId,
              'quantity': venta.cantidad,
              'unit_price': venta.precioUnitario,
              'discount': 0,
            }
          ];
          // ✅ FIX: sin p_client_group_id (no existe en la firma SQL)
          final remoteId = await supabase.rpc('create_sale', params: {
            'p_branch_id': branchId,
            'p_items': items,
            'p_customer_id': venta.clienteId,
            'p_discount': 0,
            'p_tax': 0,
            'p_currency_id': currencyIdActual,
            'p_exchange_rate': venta.tasaCambio ?? 1,
            'p_mode': usaCierreDiario ? 'daily_closure' : 'real_time',
            'p_note': venta.nota,
            'p_is_trial_data': false,
          });

          if (remoteId != null) {
            await ventaBox.delete(idLocal);
            venta.id = '$remoteId';
            venta.saleGroupId = remoteId.toString();
            await ventaBox.put(venta.id, venta);
            ventas = ventaBox.values.toList();
            sincronizada = true;
          }
        } catch (e) {
          print('⚠️ RPC create_sale falló, se encolará: $e');
        }
      }

      if (!sincronizada) {
        final datosSync = <String, dynamic>{
          'id': venta.id,
          'sale_group_id': groupId,
          '_items': [
            {
              'product_id': venta.productoId,
              'quantity': venta.cantidad,
              'unit_price': venta.precioUnitario,
              'discount': 0,
            }
          ],
          '_branch_id': branchId,
          '_mode': usaCierreDiario ? 'daily_closure' : 'real_time',
          '_customer_id': venta.clienteId,
          '_note': venta.nota,
          '_currency_id': currencyIdActual,
          '_exchange_rate': venta.tasaCambio ?? 1,
        };

        await _guardarPendiente(
          'insert',
          'ventas',
          datosSync,
          venta.id,
          saleGroupId: groupId,
        );
      }

      notifyListeners();
      mostrarSnackBar(
        mensaje: sincronizada
            ? 'Venta registrada'
            : (_hayConexion
                ? 'Venta guardada (se sincronizará pronto)'
                : 'Venta guardada sin conexión'),
        esExito: true,
      );
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar venta: ${mensajeAmigable(e)}',
          esExito: false);
      rethrow;
    }
  }

  Future<void> eliminarVenta(String id) async {
    try {
      verificarEmpresaActiva();
      final venta = ventaBox.get(id);
      if (venta == null) return;
      final remoteId = venta.saleGroupId ?? venta.id;

      await ventaBox.delete(id);
      ventas = ventaBox.values.toList();
      await _guardarPendiente('delete', 'ventas', {}, remoteId);
      mostrarSnackBar(mensaje: 'Venta cancelada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al cancelar venta: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> agregarGasto(Gasto gasto) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      gasto.id = uuid.v4();
      gasto.empresaId = empresaId;
      gasto.updatedAt = DateTime.now();
      gasto.sucursalId ??= esAdminGlobal
          ? (sucursales.isNotEmpty ? sucursales.first.id : null)
          : sucursalIdUsuario;

      await gastoBox.put(gasto.id, gasto);
      gastos = gastoBox.values.toList();
      await _guardarPendiente('insert', 'gastos', gasto.toJson(), gasto.id);
      mostrarSnackBar(mensaje: 'Gasto registrado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar gasto: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarGasto(String id) async {
    try {
      verificarEmpresaActiva();
      await gastoBox.delete(id);
      gastos = gastoBox.values.toList();
      await _guardarPendiente('delete', 'gastos', {}, id);
      mostrarSnackBar(mensaje: 'Gasto eliminado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar gasto: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> agregarCliente(Cliente cliente) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      cliente.id = uuid.v4();
      cliente.empresaId = empresaId;
      cliente.updatedAt = DateTime.now();
      await clienteBox.put(cliente.id, cliente);
      clientes = clienteBox.values.toList();
      await _guardarPendiente(
          'insert', 'clientes', cliente.toJson(), cliente.id);
      mostrarSnackBar(mensaje: 'Cliente agregado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al agregar cliente: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      verificarEmpresaActiva();
      cliente.empresaId = empresaId;
      cliente.updatedAt = DateTime.now();
      await clienteBox.put(cliente.id, cliente);
      clientes = clienteBox.values.toList();
      await _guardarPendiente(
          'update', 'clientes', cliente.toJson(), cliente.id);
      mostrarSnackBar(mensaje: 'Cliente actualizado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al editar cliente: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarCliente(String id) async {
    try {
      verificarEmpresaActiva();
      await clienteBox.delete(id);
      clientes = clienteBox.values.toList();
      await _guardarPendiente('delete', 'clientes', {}, id);
      mostrarSnackBar(mensaje: 'Cliente eliminado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar cliente: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  void agregarProveedor(String clienteId) {
    if (!_proveedoresIds.contains(clienteId)) {
      _proveedoresIds.add(clienteId);
      settingsBox?.put(KEY_PROVEEDORES, _proveedoresIds);
      notifyListeners();
    }
  }

  void quitarProveedor(String clienteId) {
    _proveedoresIds.remove(clienteId);
    settingsBox?.put(KEY_PROVEEDORES, _proveedoresIds);
    notifyListeners();
  }

  bool esProveedor(String clienteId) => _proveedoresIds.contains(clienteId);

  List<Cliente> get proveedores =>
      clientes.where((c) => _proveedoresIds.contains(c.id)).toList();

  Future<void> agregarCategoria(Categoria categoria) async {
    try {
      verificarEmpresaActiva();
      if (categorias.any((c) =>
          c.nombre.toLowerCase() == categoria.nombre.toLowerCase())) {
        throw Exception(
            'Ya existe una categoría con el nombre "${categoria.nombre}".');
      }
      categoria.id = uuid.v4();
      categoria.empresaId = empresaId;
      categoria.updatedAt = DateTime.now();
      categoria.sortOrder = categorias.length;
      await categoriaBox.put(categoria.id, categoria);
      categorias = categoriaBox.values.toList();
      await _guardarPendiente(
          'insert', 'categorias', categoria.toJson(), categoria.id);
      mostrarSnackBar(mensaje: 'Categoría creada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al crear categoría: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> editarCategoria(Categoria categoria) async {
    try {
      verificarEmpresaActiva();
      if (categorias.any((c) =>
          c.id != categoria.id &&
          c.nombre.toLowerCase() == categoria.nombre.toLowerCase())) {
        throw Exception(
            'Ya existe otra categoría con el nombre "${categoria.nombre}".');
      }
      categoria.updatedAt = DateTime.now();
      await categoriaBox.put(categoria.id, categoria);
      categorias = categoriaBox.values.toList();
      await _guardarPendiente(
          'update', 'categorias', categoria.toJson(), categoria.id);
      mostrarSnackBar(mensaje: 'Categoría actualizada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al editar categoría: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarCategoria(String id) async {
    try {
      verificarEmpresaActiva();
      var sinCategoria = categorias.firstWhere(
        (c) => c.nombre == 'Sin categoría',
        orElse: () {
          final nueva = Categoria(
            id: uuid.v4(),
            nombre: 'Sin categoría',
            descripcion: 'Categoría por defecto',
            empresaId: empresaId,
            updatedAt: DateTime.now(),
          );
          categoriaBox.put(nueva.id, nueva);
          _guardarPendiente('insert', 'categorias', nueva.toJson(), nueva.id);
          return nueva;
        },
      );
      for (var p in productos.where((p) => p.categoriaId == id)) {
        p.categoriaId = sinCategoria.id;
        p.updatedAt = DateTime.now();
        await productoBox.put(p.id, p);
        await _guardarPendiente('update', 'productos', p.toJson(), p.id);
      }
      productos = productoBox.values.toList();
      await categoriaBox.delete(id);
      categorias = categoriaBox.values.toList();
      await _guardarPendiente('delete', 'categorias', {}, id);
      mostrarSnackBar(
          mensaje: 'Categoría eliminada y productos reasignados',
          esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar categoría: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Categoria? getCategoriaById(String id) {
    try {
      return categorias.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String getNombreCategoria(String? id) {
    if (id == null) return 'Sin categoría';
    return getCategoriaById(id)?.nombre ?? 'Sin categoría';
  }

  List<String> get listaCategoriasIds =>
      ['Todas', ...categorias.map((c) => c.id)];

  Future<void> guardarMeta(MetaVenta nuevaMeta) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      nuevaMeta.id = uuid.v4();
      nuevaMeta.empresaId = empresaId;
      nuevaMeta.sucursalId ??= sucursalIdUsuario;
      nuevaMeta.usuarioId = usuarioId;
      nuevaMeta.updatedAt = DateTime.now();
      if (meta != null) {
        await metaBox.delete(meta!.id);
      }
      await metaBox.put(nuevaMeta.id, nuevaMeta);
      meta = nuevaMeta;
      await _guardarPendiente(
          'insert', 'metas_venta', nuevaMeta.toJson(), nuevaMeta.id);
      mostrarSnackBar(mensaje: 'Metas guardadas', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al guardar metas: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  String _traducirMotivo(String motivo) {
    switch (motivo) {
      case 'estropeado':
        return 'Estropeado';
      case 'autoconsumo':
        return 'Autoconsumo';
      case 'perdida':
        return 'Pérdida';
      case 'merma':
        return 'Merma';
      default:
        return motivo;
    }
  }

  Future<void> registrarMerma(
      String productoId, double cantidad, String motivo) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      final producto = getProductoById(productoId);
      if (producto == null) throw Exception('Producto no encontrado');
      if (cantidad <= 0) throw Exception('Cantidad debe ser positiva');
      if (producto.stock < cantidad) throw Exception('Stock insuficiente');

      final branchId = producto.sucursalId ?? sucursalIdUsuario;
      if (branchId == null) throw Exception('Sin sucursal');

      final mermaId = uuid.v4();
      final costoUnit = producto.precioCompra;
      final costoTotal = costoUnit * cantidad;

      final merma = Merma(
        id: mermaId,
        productoId: producto.id,
        cantidad: cantidad,
        motivo: motivo,
        costoUnitario: costoUnit,
        costoTotal: costoTotal,
        fecha: DateTime.now(),
        usuarioId: usuarioId,
        sucursalId: branchId,
        empresaId: empresaId,
        updatedAt: DateTime.now(),
      );

      await mermaBox.put(merma.id, merma);
      mermas = mermaBox.values.toList();
      await _descontarStockLocal(producto, cantidad);

      final rpcDatos = {
        '_rpc': 'consume_inventory_fifo',
        '_params': {
          'p_branch_id': branchId,
          'p_product_id': productoId,
          'p_quantity': cantidad,
          'p_reference_type': 'wastage',
          'p_reference_id': mermaId,
        },
      };
      await _guardarPendiente('rpc', 'rpc', rpcDatos, 'consume_$mermaId');
      await _guardarPendiente('insert', 'mermas', merma.toJson(), merma.id);

      mostrarSnackBar(
        mensaje: _hayConexion
            ? 'Merma registrada'
            : 'Merma guardada (se sincronizará)',
        esExito: true,
      );
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar merma: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> cancelarMerma(String mermaId) async {
    try {
      verificarEmpresaActiva();
      final merma = mermaBox.get(mermaId);
      if (merma == null) throw Exception('Merma no encontrada');
      if (merma.cancelado) throw Exception('La merma ya fue cancelada');
      merma.cancelado = true;
      merma.updatedAt = DateTime.now();
      await mermaBox.put(merma.id, merma);
      mermas = mermaBox.values.toList();
      await _guardarPendiente('update', 'mermas', merma.toJson(), merma.id);
      mostrarSnackBar(
          mensaje: 'Merma cancelada (el stock no se restaura automáticamente).',
          esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al cancelar merma: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> registrarMovimiento(String productoId, double cantidad,
      String sucursalOrigenId, String sucursalDestinoId) async {
    try {
      verificarEmpresaActiva();
      if (sucursalOrigenId == sucursalDestinoId) {
        throw Exception('Origen y destino deben ser diferentes');
      }
      if (cantidad <= 0) throw Exception('Cantidad debe ser positiva');

      final items = [
        {'product_id': productoId, 'quantity': cantidad}
      ];
      final transferId = await crearTransferenciaRPC(
          sucursalOrigenId, sucursalDestinoId, items);
      if (transferId == null) return;
      mostrarSnackBar(
          mensaje: 'Transferencia creada (pendiente de aprobación)',
          esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar movimiento: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> cancelarMovimiento(String movimientoId) async {
    try {
      verificarEmpresaActiva();
      final mov = movimientoBox.get(movimientoId);
      if (mov == null) throw Exception('Movimiento no encontrado');
      if (mov.cancelado) throw Exception('Ya cancelado');
      mov.cancelado = true;
      mov.updatedAt = DateTime.now();
      await movimientoBox.put(mov.id, mov);
      movimientos = movimientoBox.values.toList();
      await _guardarPendiente(
          'update', 'movimientos_sucursal', mov.toJson(), mov.id);
      mostrarSnackBar(
          mensaje: 'Movimiento marcado como cancelado', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al cancelar movimiento: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> registrarMovimientoInverso(MovimientoSucursal original) async {
    try {
      verificarEmpresaActiva();
      await registrarMovimiento(original.productoId, original.cantidad,
          original.sucursalDestinoId, original.sucursalOrigenId);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al invertir movimiento: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  List<MovimientoSucursal> getMovimientos(DateTime inicio, DateTime fin) =>
      movimientos
          .where((m) =>
              !m.cancelado &&
              m.fecha.isAfter(inicio) &&
              m.fecha.isBefore(fin))
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  Future<void> registrarDeuda(Deuda deuda) async {
    try {
      verificarEmpresaActiva();
      if (empresaId == null) throw Exception('No hay empresa asociada.');
      deuda.id = uuid.v4();
      deuda.empresaId = empresaId;
      deuda.sucursalId ??= sucursalIdUsuario;
      deuda.updatedAt = DateTime.now();
      await deudaBox.put(deuda.id, deuda);
      deudas = deudaBox.values.toList();
      await _guardarPendiente('insert', 'deudas', deuda.toJson(), deuda.id);
      mostrarSnackBar(mensaje: 'Deuda registrada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al registrar deuda: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> pagarDeuda(String deudaId, {String? metodoPago}) async {
    try {
      verificarEmpresaActiva();
      final deuda = deudaBox.get(deudaId);
      if (deuda == null) throw Exception('Deuda no encontrada');
      if (deuda.pagada) throw Exception('Ya está pagada');

      final montoPagadoAhora = deuda.monto - deuda.pagado;

      deuda.pagada = true;
      deuda.pagado = deuda.monto;
      deuda.fechaPago = DateTime.now();
      deuda.status = 'paid';
      deuda.metodoPago = metodoPago ?? deuda.metodoPago;
      deuda.updatedAt = DateTime.now();
      await deudaBox.put(deuda.id, deuda);
      deudas = deudaBox.values.toList();

      final pagoId = uuid.v4();
      await _guardarPendiente('insert', 'debt_payments', {
        'id': pagoId,
        'debt_id': deudaId,
        'amount': montoPagadoAhora,
        'paid_by': usuarioId,
      }, pagoId);
      await _guardarPendiente('update', 'deudas', deuda.toJson(), deuda.id);

      mostrarSnackBar(
        mensaje: _hayConexion
            ? 'Deuda pagada'
            : 'Deuda pagada (se sincronizará)',
        esExito: true,
      );
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al pagar deuda: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  Future<void> eliminarDeuda(String deudaId) async {
    try {
      verificarEmpresaActiva();
      await deudaBox.delete(deudaId);
      deudas = deudaBox.values.toList();
      await _guardarPendiente('delete', 'deudas', {}, deudaId);
      mostrarSnackBar(mensaje: 'Deuda eliminada', esExito: true);
      notifyListeners();
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al eliminar deuda: ${mensajeAmigable(e)}',
          esExito: false);
    }
  }

  List<Deuda> getDeudasCliente(String clienteId) => deudas
      .where((d) =>
          d.tipo == 'cliente' && d.entidadId == clienteId && !d.pagada)
      .toList();

  List<Deuda> getDeudasProveedor(String proveedorId) => deudas
      .where((d) =>
          d.tipo == 'proveedor' && d.entidadId == proveedorId && !d.pagada)
      .toList();

  double getTotalDeudasClientes() => deudas
      .where((d) => d.tipo == 'cliente' && !d.pagada)
      .fold<double>(0.0, (s, d) => s + d.monto);

  double getTotalDeudasProveedores() => deudas
      .where((d) => d.tipo == 'proveedor' && !d.pagada)
      .fold<double>(0.0, (s, d) => s + d.monto);

  Future<void> enviarMensajeSoporte(String mensaje) async {
    try {
      if (usuarioId == null) throw Exception('Usuario no autenticado');
      if (empresaId == null) throw Exception('Empresa no asociada');
      await supabase.from('support_tickets').insert({
        'company_id': empresaId,
        'user_id': usuarioId,
        'subject': 'Soporte $APP_NAME',
        'message': mensaje,
        'status': 'open',
        'priority': 'normal',
      });
      mostrarSnackBar(mensaje: 'Mensaje enviado a soporte', esExito: true);
    } catch (e) {
      mostrarSnackBar(
          mensaje: 'Error al enviar: ${mensajeAmigable(e)}', esExito: false);
    }
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesSoporte() async {
    try {
      if (empresaId == null) return [];
      final data = await supabase
          .from('support_tickets')
          .select('*')
          .eq('company_id', empresaId!)
          .order('created_at', ascending: false);
      return (data as List)
          .map((m) => {
                'id': m['id'],
                'mensaje': m['message'],
                'fecha': m['created_at'],
                'esAdmin': m['resolution'] != null,
                'respuesta_admin': m['resolution'],
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  DateTime get hoy =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime get inicioSemana {
    final d = (hoy.weekday - 1) % 7;
    return hoy.subtract(Duration(days: d));
  }

  DateTime get finSemana => inicioSemana.add(const Duration(days: 7));
  DateTime get inicioMes => DateTime(hoy.year, hoy.month, 1);
  DateTime get finMes => DateTime(hoy.year, hoy.month + 1, 1);

  DateTime get inicioPeriodo {
    switch (periodoSeleccionado) {
      case 1:
        return inicioSemana;
      case 2:
        return inicioMes;
      default:
        return hoy;
    }
  }

  DateTime get finPeriodo {
    switch (periodoSeleccionado) {
      case 1:
        return finSemana;
      case 2:
        return finMes;
      default:
        return hoy.add(const Duration(days: 1));
    }
  }

  String getPeriodoLabel() {
    switch (periodoSeleccionado) {
      case 1:
        return 'Semana';
      case 2:
        return 'Mes';
      default:
        return 'Hoy';
    }
  }

  void setPeriodo(int periodo) {
    periodoSeleccionado = periodo;
    notifyListeners();
  }

  void setFiltroCategoria(String categoriaId) {
    filtroCategoria = categoriaId;
    notifyListeners();
  }

  List<Producto> get productosFiltrados {
    final base = _obtenerProductosFiltradosPorSucursal();
    if (filtroCategoria == 'Todas') return base;
    return base.where((p) => p.categoriaId == filtroCategoria).toList();
  }

  String get _hoyKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, double>? get snapshotHoy {
    if (cierreDiarioBox == null) return null;
    final data = cierreDiarioBox.get(_hoyKey);
    if (data == null) return null;
    final raw = Map<dynamic, dynamic>.from(data as Map);
    final result = <String, double>{};
    raw.forEach((k, v) => result[k.toString()] = (v as num).toDouble());
    return result;
  }

  bool get haySnapshotHoy => snapshotHoy != null;

  List<Producto> get productosParaCierre {
    final base = _obtenerProductosFiltradosPorSucursal();
    final snap = snapshotHoy;
    if (snap == null) return base;
    return base.where((p) => snap.containsKey(p.id)).toList();
  }

  Future<void> iniciarDiaCierre() async {
    if (cierreDiarioBox == null) {
      throw Exception('Almacenamiento local no disponible.');
    }
    final base = _obtenerProductosFiltradosPorSucursal();
    final snap = <String, double>{};
    for (var p in base) snap[p.id] = p.stock;
    await cierreDiarioBox.put(_hoyKey, snap);
    await limpiarSnapshotsAntiguos();
    notifyListeners();
    mostrarSnackBar(
        mensaje:
            '📸 Día iniciado: stock inicial capturado para ${snap.length} productos',
        esExito: true);
  }

  Future<void> limpiarSnapshotsAntiguos() async {
    if (cierreDiarioBox == null) return;
    try {
      final limite = DateTime.now().subtract(const Duration(days: 7));
      for (var k in cierreDiarioBox.keys.toList()) {
        final fecha = DateTime.tryParse(k.toString());
        if (fecha != null && fecha.isBefore(limite)) {
          await cierreDiarioBox.delete(k);
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> cerrarDia(
    Map<String, double> stockFinalPorProducto, {
    String metodoPago = 'Efectivo CUP',
  }) async {
    verificarEmpresaActiva();
    if (empresaId == null) throw Exception('No hay empresa asociada.');
    if (cierreDiarioBox == null) {
      throw Exception('Almacenamiento local no disponible.');
    }

    final snap = snapshotHoy;
    if (snap == null) {
      throw Exception('No has iniciado el día.');
    }

    final items = <Map<String, dynamic>>[];
    double montoTotal = 0.0;
    double costoTotal = 0.0;
    final detalle = <Map<String, dynamic>>[];
    final branchId = sucursalIdUsuario ??
        (sucursales.isNotEmpty ? sucursales.first.id : null);
    if (branchId == null) throw Exception('Sin sucursal');

    for (var entry in stockFinalPorProducto.entries) {
      final stockFinal = entry.value;
      final stockInicial = snap[entry.key];
      if (stockInicial == null) continue;
      final double vendidos = stockInicial - stockFinal;
      if (vendidos <= 0) continue;
      final producto = getProductoById(entry.key);
      if (producto == null) continue;
      final double cantVender =
          vendidos > producto.stock ? producto.stock : vendidos;
      if (cantVender <= 0) continue;

      items.add({
        'product_id': producto.id,
        'quantity': cantVender,
        'unit_price': producto.precioVenta,
        'discount': 0,
      });
      montoTotal += producto.precioVenta * cantVender;
      detalle.add({
        'producto': producto.nombre,
        'cantidad': cantVender,
        'total': producto.precioVenta * cantVender,
      });
    }

    String? groupId;
    if (items.isNotEmpty) {
      final groupLocalId = uuid.v4();
      if (_hayConexion) {
        try {
          groupId = await crearVentaRPC(
            branchId: branchId,
            items: items,
            exchangeRate: 1,
            mode: 'daily_closure',
            note:
                'Cierre diario ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            clientGroupId: groupLocalId,
          );
        } catch (_) {}
      }

      if (groupId == null) {
        final datosSync = <String, dynamic>{
          'id': groupLocalId,
          'sale_group_id': groupLocalId,
          '_items': items,
          '_branch_id': branchId,
          '_mode': 'daily_closure',
          '_customer_id': null,
          '_note':
              'Cierre diario ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          '_currency_id': currencyIdActual,
          '_exchange_rate': 1,
        };
        await _guardarPendiente(
          'insert',
          'ventas',
          datosSync,
          groupLocalId,
          saleGroupId: groupLocalId,
        );
      }
    }

    for (var entry in stockFinalPorProducto.entries) {
      final producto = getProductoById(entry.key);
      if (producto == null) continue;

      final stockFinal = entry.value.clamp(0.0, double.infinity);
      final stockInicial = snap[entry.key] ?? stockFinal;
      final consumido = (stockInicial - stockFinal).clamp(0.0, double.infinity);

      if (consumido > 0 && producto.lotes.isNotEmpty) {
        double restante = consumido;
        final nuevosLotes = <Map<String, dynamic>>[];
        for (final lote in producto.lotes) {
          if (restante <= 0) {
            nuevosLotes.add(lote);
            continue;
          }
          final disponible = (lote['cantidad'] as num?)?.toDouble() ?? 0;
          if (disponible <= 0) continue;

          if (disponible <= restante) {
            restante -= disponible;
          } else {
            final nuevo = Map<String, dynamic>.from(lote);
            nuevo['cantidad'] = disponible - restante;
            restante = 0;
            nuevosLotes.add(nuevo);
          }
        }
        producto.lotes = nuevosLotes;
      } else if (stockFinal > stockInicial) {
        producto.lotes = [
          ...producto.lotes,
          {
            'cantidad': stockFinal - stockInicial,
            'precioCompra': producto.precioCompra,
          },
        ];
      }

      producto.stock = stockFinal;
      producto.updatedAt = DateTime.now();
      await productoBox.put(producto.id, producto);
    }
    productos = productoBox.values.toList();

    final mapaFinal = Map<String, double>.from(snap);
    stockFinalPorProducto.forEach((k, v) {
      if (mapaFinal.containsKey(k)) mapaFinal[k] = v;
    });
    await cierreDiarioBox.put('${_hoyKey}_cerrado', mapaFinal);

    await _cargarDatosLocales();
    _sincronizarEnBackground();
    notifyListeners();

    return {
      'ventasCreadas': items.length,
      'productosConVenta': items.length,
      'montoTotal': montoTotal,
      'costoTotal': costoTotal,
      'gananciaNeta': montoTotal - costoTotal,
      'groupId': groupId ?? '',
      'detalle': detalle,
    };
  }

  bool get diaYaCerrado {
    if (cierreDiarioBox == null) return false;
    return cierreDiarioBox.containsKey('${_hoyKey}_cerrado');
  }

  Map<String, double>? get cierreHoy {
    if (cierreDiarioBox == null) return null;
    final data = cierreDiarioBox.get('${_hoyKey}_cerrado');
    if (data == null) return null;
    final raw = Map<dynamic, dynamic>.from(data as Map);
    final result = <String, double>{};
    raw.forEach((k, v) => result[k.toString()] = (v as num).toDouble());
    return result;
  }

  List<Map<String, dynamic>> get pendientesDetalle {
    if (!pendientesBox.isOpen) return [];
    final lista = <Map<String, dynamic>>[];
    for (var key in pendientesBox.keys) {
      final p = pendientesBox.get(key);
      if (p == null) continue;
      final item = Map<String, dynamic>.from(p as Map);
      item['_key'] = key;
      lista.add(item);
    }
    lista.sort((a, b) => (a['timestamp'] ?? '')
        .toString()
        .compareTo((b['timestamp'] ?? '').toString()));
    return lista;
  }

  int get contarPendientesBloqueados {
    if (!pendientesBox.isOpen) return 0;
    int c = 0;
    for (var k in pendientesBox.keys) {
      final p = pendientesBox.get(k);
      if (p != null && ((p['intentos'] ?? 0) as int) >= 5) c++;
    }
    return c;
  }

  String exportarPendientesJSON() {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'app_version': APP_VERSION,
      'empresa_id': empresaId,
      'nombre_empresa': nombreEmpresa,
      'usuario_id': usuarioId,
      'rol': rol,
      'plan': plan,
      'total_pendientes': pendientesDetalle.length,
      'total_bloqueados': contarPendientesBloqueados,
      'pendientes': pendientesDetalle,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String?> exportarPendientesAFile() async {
    try {
      final jsonStr = exportarPendientesJSON();
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/pendientes_$ts.json');
      await file.writeAsString(jsonStr);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> eliminarPendiente(String key) async {
    await pendientesBox.delete(key);
    notifyListeners();
  }

  Future<void> reiniciarIntentosPendiente(String key) async {
    final p = pendientesBox.get(key);
    if (p == null) return;
    p['intentos'] = 0;
    p.remove('ultimoError');
    p.remove('ultimoErrorFecha');
    await pendientesBox.put(key, p);
    notifyListeners();
  }

  Future<int> reiniciarTodosLosIntentos() async {
    int c = 0;
    for (var key in pendientesBox.keys.toList()) {
      final p = pendientesBox.get(key);
      if (p == null) continue;
      p['intentos'] = 0;
      p.remove('ultimoError');
      p.remove('ultimoErrorFecha');
      await pendientesBox.put(key, p);
      c++;
    }
    notifyListeners();
    return c;
  }

  Future<int> limpiarPendientesConError() async {
    int c = 0;
    for (var key in pendientesBox.keys.toList()) {
      final p = pendientesBox.get(key);
      if (p == null) continue;
      if (((p['intentos'] ?? 0) as int) >= 5) {
        await pendientesBox.delete(key);
        c++;
      }
    }
    notifyListeners();
    return c;
  }

  Future<int> eliminarTodosLosPendientes() async {
    final c = pendientesBox.length;
    await pendientesBox.clear();
    notifyListeners();
    return c;
  }

  // ============================================================
  //  LIMPIAR PENDIENTES "ENVENENADOS" (ventas / rpc)
  //  Útil después de arreglar un bug que dejó la cola con errores.
  //  NO toca los datos locales de ventaBox, solo la cola de sync.
  // ============================================================
  Future<int> limpiarPendientesVentasRotos() async {
    int c = 0;
    for (var key in pendientesBox.keys.toList()) {
      final p = pendientesBox.get(key);
      if (p == null) continue;
      final tabla = p['tabla'] as String?;
      if (tabla == 'ventas' || tabla == 'rpc') {
        await pendientesBox.delete(key);
        c++;
      }
    }
    notifyListeners();
    return c;
  }
}

// ============================================================
//  MAIN
// ============================================================
Future<void> _initHivePaths() async {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null) {
      await Hive.initFlutter('$appData\\nexora_business');
    } else {
      await Hive.initFlutter();
    }
  } else {
    await Hive.initFlutter('nexora_business');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await initializeDateFormatting('es', '');

  await _initHivePaths();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  Hive.registerAdapter(ProductoAdapter());
  Hive.registerAdapter(VentaAdapter());
  Hive.registerAdapter(GastoAdapter());
  Hive.registerAdapter(ClienteAdapter());
  Hive.registerAdapter(CategoriaAdapter());
  Hive.registerAdapter(MetaVentaAdapter());
  Hive.registerAdapter(UsuarioAdapter());
  Hive.registerAdapter(SucursalAdapter());
  Hive.registerAdapter(EmpleadoAdapter());
  Hive.registerAdapter(NominaAdapter());
  Hive.registerAdapter(AlianzaAdapter());
  Hive.registerAdapter(TransferenciaAdapter());
  Hive.registerAdapter(ReferidoAdapter());
  Hive.registerAdapter(BonoAdapter());
  Hive.registerAdapter(MermaAdapter());
  Hive.registerAdapter(MovimientoSucursalAdapter());
  Hive.registerAdapter(DeudaAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _primary = Color(0xFF1A5CFF);
  static const _primaryDk = Color(0xFF4A8BFF);
  static const _cyan = Color(0xFF06B6D4);
  static const _cyanDk = Color(0xFF22D3EE);
  static const _danger = Color(0xFFEF4444);

  static const _bgLight = Color(0xFFEEF4FC);
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _textHighLight = Color(0xFF0A1A33);
  static const _textMidLight = Color(0xFF1C3352);
  static const _borderLight = Color(0x1F1A5CFF);

  static const _bgDark = Color(0xFF0A1628);
  static const _surfaceDark = Color(0xFF122340);
  static const _textHighDark = Color(0xFFEEF4FC);
  static const _textMidDark = Color(0xFFB8CBE8);
  static const _borderDark = Color(0x294A8BFF);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final isDesktop = ResponsiveHelper.isDesktop();
          final themeMode = provider.themeMode;

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: APP_NAME,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: _bgLight,
              colorScheme: const ColorScheme.light(
                primary: _primary,
                secondary: _cyan,
                surface: _surfaceLight,
                error: _danger,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: _textHighLight,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: _textHighLight,
                elevation: 0,
                centerTitle: false,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                color: _surfaceLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _borderLight),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: _borderLight,
                thickness: 1,
                space: 1,
              ),
              textTheme: GoogleFonts.interTextTheme().copyWith(
                bodyLarge: TextStyle(
                  fontSize: isDesktop ? 17 : 14,
                  color: _textHighLight,
                ),
                bodyMedium: TextStyle(
                  fontSize: isDesktop ? 15 : 14,
                  color: _textMidLight,
                ),
                titleLarge: TextStyle(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: _textHighLight,
                ),
                titleMedium: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w800,
                  color: _textHighLight,
                ),
                headlineLarge: TextStyle(
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: _textHighLight,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: _surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 1.6),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _danger, width: 1.4),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _danger, width: 1.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                labelStyle: const TextStyle(color: _textMidLight),
                hintStyle: TextStyle(
                  color: _textMidLight.withOpacity(0.55),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _textHighLight,
                contentTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: _surfaceLight,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 20,
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: _surfaceLight,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: _borderLight),
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: _surfaceLight,
                selectedItemColor: _primary,
                unselectedItemColor: Color(0xFF607B9E),
                elevation: 0,
              ),
              listTileTheme: const ListTileThemeData(
                iconColor: Color(0xFF1C3352),
                textColor: _textHighLight,
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: _primary,
                linearTrackColor: Color(0x1F1A5CFF),
                circularTrackColor: Color(0x1F1A5CFF),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0x141A5CFF),
                selectedColor: _primary,
                side: const BorderSide(color: _borderLight),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: _primary,
                unselectedLabelColor: Color(0xFF607B9E),
                indicatorColor: _primary,
                dividerColor: Colors.transparent,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _primary;
                  return const Color(0xFFB8CBE8);
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primary.withOpacity(0.35);
                  }
                  return const Color(0x1F1A5CFF);
                }),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: _bgDark,
              colorScheme: const ColorScheme.dark(
                primary: _primaryDk,
                secondary: _cyanDk,
                surface: _surfaceDark,
                error: _danger,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: _textHighDark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: _textHighDark,
                elevation: 0,
                centerTitle: false,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                color: _surfaceDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _borderDark),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: _borderDark,
                thickness: 1,
                space: 1,
              ),
              textTheme: GoogleFonts.interTextTheme(
                ThemeData.dark().textTheme,
              ).copyWith(
                bodyLarge: TextStyle(
                  color: _textHighDark,
                  fontSize: isDesktop ? 17 : 14,
                ),
                bodyMedium: TextStyle(
                  color: _textMidDark,
                  fontSize: isDesktop ? 15 : 14,
                ),
                titleLarge: TextStyle(
                  color: _textHighDark,
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
                titleMedium: TextStyle(
                  color: _textHighDark,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w800,
                ),
                headlineLarge: TextStyle(
                  color: _textHighDark,
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: _surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primaryDk, width: 1.6),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _danger, width: 1.4),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _danger, width: 1.6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                labelStyle: const TextStyle(color: _textMidDark),
                hintStyle: TextStyle(
                  color: _textMidDark.withOpacity(0.55),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDk,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _primaryDk,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDk,
                  side: const BorderSide(color: _borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              floatingActionButtonTheme:
                  const FloatingActionButtonThemeData(
                backgroundColor: _primaryDk,
                foregroundColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _surfaceDark,
                contentTextStyle: const TextStyle(
                  color: _textHighDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: _borderDark),
                ),
                elevation: 12,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: _surfaceDark,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                elevation: 20,
              ),
              popupMenuTheme: PopupMenuThemeData(
                color: _surfaceDark,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: _borderDark),
                ),
              ),
              bottomNavigationBarTheme:
                  const BottomNavigationBarThemeData(
                backgroundColor: _surfaceDark,
                selectedItemColor: _primaryDk,
                unselectedItemColor: Color(0xFF7D95B6),
                elevation: 0,
              ),
              listTileTheme: const ListTileThemeData(
                iconColor: _textMidDark,
                textColor: _textHighDark,
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: _primaryDk,
                linearTrackColor: Color(0x294A8BFF),
                circularTrackColor: Color(0x294A8BFF),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0x1F4A8BFF),
                selectedColor: _primaryDk,
                side: const BorderSide(color: _borderDark),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: _primaryDk,
                unselectedLabelColor: Color(0xFF7D95B6),
                indicatorColor: _primaryDk,
                dividerColor: Colors.transparent,
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryDk;
                  }
                  return const Color(0xFF4A5674);
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryDk.withOpacity(0.35);
                  }
                  return const Color(0x294A8BFF);
                }),
              ),
            ),
            themeMode: themeMode,
            onGenerateRoute: (RouteSettings settings) {
              switch (settings.name) {
                case '/productos':
                  return MaterialPageRoute(builder: (_) => ProductosScreen());
                case '/nueva-venta':
                  return MaterialPageRoute(builder: (_) => NuevaVentaScreen());
                case '/cierre-diario':
                  return MaterialPageRoute(
                      builder: (_) => const CierreDiarioScreen());
                case '/gastos':
                  return MaterialPageRoute(builder: (_) => GastosScreen());
                case '/reportes':
                  return MaterialPageRoute(builder: (_) => ReportesScreen());
                case '/clientes':
                  return MaterialPageRoute(builder: (_) => ClientesScreen());
                case '/metas':
                  return MaterialPageRoute(builder: (_) => MetasScreen());
                case '/historial':
                  return MaterialPageRoute(builder: (_) => HistorialScreen());
                case '/reabastecer':
                  return MaterialPageRoute(
                      builder: (_) => ReabastecerScreen());
                case '/nuevo-producto':
                  return MaterialPageRoute(
                      builder: (_) => NuevoProductoScreen());
                case '/nuevo-gasto':
                  return MaterialPageRoute(builder: (_) => NuevoGastoScreen());
                case '/categorias':
                  return MaterialPageRoute(builder: (_) => CategoriasScreen());
                case '/vendedores':
                  return MaterialPageRoute(builder: (_) => VendedoresScreen());
                case '/estadisticas-vendedores':
                  return MaterialPageRoute(
                      builder: (_) => EstadisticasVendedoresScreen());
                case '/pago':
                  return MaterialPageRoute(builder: (_) => PagoScreen());
                case '/user-guide':
                  return MaterialPageRoute(builder: (_) => UserGuideScreen());
                case '/fiscal':
                  return MaterialPageRoute(builder: (_) => FiscalScreen());
                case '/sucursales':
                  return MaterialPageRoute(
                      builder: (_) => SucursalesScreen());
                case '/nominas':
                  return MaterialPageRoute(builder: (_) => NominasScreen());
                case '/transferencias':
                  return MaterialPageRoute(
                      builder: (_) => TransferenciasScreen());
                case '/alianzas':
                  return MaterialPageRoute(builder: (_) => AlianzasScreen());
                case '/referidos':
                  return MaterialPageRoute(builder: (_) => ReferidosScreen());
                case '/mermas':
                  return MaterialPageRoute(builder: (_) => MermasScreen());
                case '/movimientos-sucursales':
                  return MaterialPageRoute(
                      builder: (_) => MovimientosSucursalesScreen());
                case '/settings':
                  return MaterialPageRoute(builder: (_) => SettingsScreen());
                case '/deudas':
                  return MaterialPageRoute(builder: (_) => DeudasScreen());
                case '/facturacion':
                  final Venta? venta = settings.arguments as Venta?;
                  return MaterialPageRoute(
                      builder: (_) => FacturacionScreen(venta: venta));
                case '/soporte':
                  return MaterialPageRoute(builder: (_) => SoporteScreen());
                case '/mi-tienda':
                  return MaterialPageRoute(
                      builder: (_) => const MiTiendaScreen());
                case '/tiendas':
                  return MaterialPageRoute(
                      builder: (_) => const TiendasScreen());
                case '/productos-publicados':
                  return MaterialPageRoute(
                      builder: (_) => const ProductosPublicadosScreen());
                case '/publicar-producto':
                  return MaterialPageRoute(
                      builder: (_) => const PublicarProductoScreen());
                case '/vista-tienda':
                  final TiendaPublica? tiendaArg =
                      settings.arguments is TiendaPublica
                          ? settings.arguments as TiendaPublica
                          : null;
                  return MaterialPageRoute(
                    builder: (_) => VistaTiendaScreen(
                      tiendaOverride: tiendaArg,
                      esPreviewPropio: true,
                    ),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => provider.isInitialized
                        ? (provider.usuarioId == null
                            ? LoginScreen()
                            : PaymentBlocker(
                                provider: provider,
                                child: HomeScreen(),
                              ))
                        : SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class PaymentBlocker extends StatelessWidget {
  final Widget child;
  final AppProvider provider;

  const PaymentBlocker({
    Key? key,
    required this.child,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (provider.rol != 'dueno') return child;
    if (provider.isPagoVigente()) return child;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Pago pendiente',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Ha pasado el período de vigencia de tu pago.\n'
                'Tienes un período de gracia de 3 días.\n'
                'Realiza el pago para continuar usando $APP_NAME.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/pago'),
                icon: const Icon(Icons.payment),
                label: const Text('Ir a pagar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: provider.logout,
                child: const Text('Cerrar sesión'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/soporte'),
                icon: const Icon(Icons.support_agent),
                label: const Text('Contactar soporte'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                'Si tienes dudas, contáctanos vía soporte.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}