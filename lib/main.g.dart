// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductoAdapter extends TypeAdapter<Producto> {
  @override
  final int typeId = 0;

  @override
  Producto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Producto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      precioCompra: fields[2] as double,
      precioVenta: fields[3] as double,
      stock: fields[4] as double,
      categoriaId: fields[5] as String?,
      lotes: (fields[6] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      empresaId: fields[7] as String?,
      updatedAt: fields[8] as DateTime?,
      sucursalId: fields[9] as String?,
      precioTransferencia: fields[10] as double,
      precioMayoristaEfectivo: fields[11] as double,
      precioMayoristaTransferencia: fields[12] as double,
      unidadMedida: fields[13] as String,
      sku: fields[14] as String?,
      barcode: fields[15] as String?,
      imageUrl: fields[16] as String?,
      descripcion: fields[17] as String?,
      lowStockThreshold: fields[18] as double,
      activo: fields[19] as bool,
      isTrialData: fields[20] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Producto obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.precioCompra)
      ..writeByte(3)
      ..write(obj.precioVenta)
      ..writeByte(4)
      ..write(obj.stock)
      ..writeByte(5)
      ..write(obj.categoriaId)
      ..writeByte(6)
      ..write(obj.lotes)
      ..writeByte(7)
      ..write(obj.empresaId)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.sucursalId)
      ..writeByte(10)
      ..write(obj.precioTransferencia)
      ..writeByte(11)
      ..write(obj.precioMayoristaEfectivo)
      ..writeByte(12)
      ..write(obj.precioMayoristaTransferencia)
      ..writeByte(13)
      ..write(obj.unidadMedida)
      ..writeByte(14)
      ..write(obj.sku)
      ..writeByte(15)
      ..write(obj.barcode)
      ..writeByte(16)
      ..write(obj.imageUrl)
      ..writeByte(17)
      ..write(obj.descripcion)
      ..writeByte(18)
      ..write(obj.lowStockThreshold)
      ..writeByte(19)
      ..write(obj.activo)
      ..writeByte(20)
      ..write(obj.isTrialData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VentaAdapter extends TypeAdapter<Venta> {
  @override
  final int typeId = 1;

  @override
  Venta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Venta(
      id: fields[0] as String,
      productoId: fields[1] as String,
      productoNombre: fields[2] as String,
      cantidad: fields[3] as double,
      precioUnitario: fields[4] as double,
      total: fields[5] as double,
      metodoPago: fields[6] as String,
      fecha: fields[7] as DateTime,
      nota: fields[8] as String?,
      clienteId: fields[9] as String?,
      costoUnitario: fields[10] as double,
      costoTotal: fields[11] as double,
      saleGroupId: fields[12] as String?,
      empresaId: fields[13] as String?,
      updatedAt: fields[14] as DateTime?,
      usuarioId: fields[15] as String?,
      sucursalId: fields[16] as String?,
      tipoCliente: fields[17] as String?,
      totalUSD: fields[18] as double?,
      tasaCambio: fields[19] as double?,
      moneda: fields[20] as String?,
      subtotal: fields[21] as double,
      descuento: fields[22] as double,
      impuesto: fields[23] as double,
      estado: fields[24] as String?,
      saleNumber: fields[25] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Venta obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productoId)
      ..writeByte(2)
      ..write(obj.productoNombre)
      ..writeByte(3)
      ..write(obj.cantidad)
      ..writeByte(4)
      ..write(obj.precioUnitario)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.metodoPago)
      ..writeByte(7)
      ..write(obj.fecha)
      ..writeByte(8)
      ..write(obj.nota)
      ..writeByte(9)
      ..write(obj.clienteId)
      ..writeByte(10)
      ..write(obj.costoUnitario)
      ..writeByte(11)
      ..write(obj.costoTotal)
      ..writeByte(12)
      ..write(obj.saleGroupId)
      ..writeByte(13)
      ..write(obj.empresaId)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.usuarioId)
      ..writeByte(16)
      ..write(obj.sucursalId)
      ..writeByte(17)
      ..write(obj.tipoCliente)
      ..writeByte(18)
      ..write(obj.totalUSD)
      ..writeByte(19)
      ..write(obj.tasaCambio)
      ..writeByte(20)
      ..write(obj.moneda)
      ..writeByte(21)
      ..write(obj.subtotal)
      ..writeByte(22)
      ..write(obj.descuento)
      ..writeByte(23)
      ..write(obj.impuesto)
      ..writeByte(24)
      ..write(obj.estado)
      ..writeByte(25)
      ..write(obj.saleNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VentaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GastoAdapter extends TypeAdapter<Gasto> {
  @override
  final int typeId = 2;

  @override
  Gasto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gasto(
      id: fields[0] as String,
      concepto: fields[1] as String,
      monto: fields[2] as double,
      categoria: fields[3] as String,
      fecha: fields[4] as DateTime,
      nota: fields[5] as String?,
      empresaId: fields[6] as String?,
      updatedAt: fields[7] as DateTime?,
      sucursalId: fields[8] as String?,
      moneda: fields[9] as String?,
      tasaCambio: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Gasto obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.concepto)
      ..writeByte(2)
      ..write(obj.monto)
      ..writeByte(3)
      ..write(obj.categoria)
      ..writeByte(4)
      ..write(obj.fecha)
      ..writeByte(5)
      ..write(obj.nota)
      ..writeByte(6)
      ..write(obj.empresaId)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.sucursalId)
      ..writeByte(9)
      ..write(obj.moneda)
      ..writeByte(10)
      ..write(obj.tasaCambio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GastoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClienteAdapter extends TypeAdapter<Cliente> {
  @override
  final int typeId = 3;

  @override
  Cliente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cliente(
      id: fields[0] as String,
      nombre: fields[1] as String,
      telefono: fields[2] as String?,
      direccion: fields[3] as String?,
      saldoPendiente: fields[4] as double?,
      empresaId: fields[5] as String?,
      updatedAt: fields[6] as DateTime?,
      email: fields[7] as String?,
      taxId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Cliente obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.telefono)
      ..writeByte(3)
      ..write(obj.direccion)
      ..writeByte(4)
      ..write(obj.saldoPendiente)
      ..writeByte(5)
      ..write(obj.empresaId)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.email)
      ..writeByte(8)
      ..write(obj.taxId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClienteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoriaAdapter extends TypeAdapter<Categoria> {
  @override
  final int typeId = 4;

  @override
  Categoria read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Categoria(
      id: fields[0] as String,
      nombre: fields[1] as String,
      descripcion: fields[2] as String?,
      empresaId: fields[3] as String?,
      updatedAt: fields[4] as DateTime?,
      icon: fields[5] as String?,
      sortOrder: fields[6] as int,
      activo: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Categoria obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.empresaId)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.icon)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.activo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MetaVentaAdapter extends TypeAdapter<MetaVenta> {
  @override
  final int typeId = 5;

  @override
  MetaVenta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MetaVenta(
      id: fields[0] as String,
      metaDiaria: fields[1] as double,
      metaSemanal: fields[2] as double,
      metaMensual: fields[3] as double,
      fechaActualizacion: fields[4] as DateTime,
      empresaId: fields[5] as String?,
      updatedAt: fields[6] as DateTime?,
      sucursalId: fields[7] as String?,
      usuarioId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MetaVenta obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.metaDiaria)
      ..writeByte(2)
      ..write(obj.metaSemanal)
      ..writeByte(3)
      ..write(obj.metaMensual)
      ..writeByte(4)
      ..write(obj.fechaActualizacion)
      ..writeByte(5)
      ..write(obj.empresaId)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.sucursalId)
      ..writeByte(8)
      ..write(obj.usuarioId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetaVentaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UsuarioAdapter extends TypeAdapter<Usuario> {
  @override
  final int typeId = 6;

  @override
  Usuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Usuario(
      id: fields[0] as String,
      email: fields[1] as String,
      rol: fields[2] as String,
      empresaId: fields[3] as String?,
      updatedAt: fields[4] as DateTime?,
      sucursalId: fields[5] as String?,
      fullName: fields[6] as String?,
      phone: fields[7] as String?,
      avatarUrl: fields[8] as String?,
      active: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Usuario obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.rol)
      ..writeByte(3)
      ..write(obj.empresaId)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.sucursalId)
      ..writeByte(6)
      ..write(obj.fullName)
      ..writeByte(7)
      ..write(obj.phone)
      ..writeByte(8)
      ..write(obj.avatarUrl)
      ..writeByte(9)
      ..write(obj.active);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SucursalAdapter extends TypeAdapter<Sucursal> {
  @override
  final int typeId = 7;

  @override
  Sucursal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sucursal(
      id: fields[0] as String,
      nombre: fields[1] as String,
      direccion: fields[2] as String,
      telefono: fields[3] as String?,
      empresaId: fields[4] as String?,
      gestorId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      activo: fields[8] as bool,
      isMain: fields[9] as bool,
      code: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sucursal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.telefono)
      ..writeByte(4)
      ..write(obj.empresaId)
      ..writeByte(5)
      ..write(obj.gestorId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.activo)
      ..writeByte(9)
      ..write(obj.isMain)
      ..writeByte(10)
      ..write(obj.code);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SucursalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmpleadoAdapter extends TypeAdapter<Empleado> {
  @override
  final int typeId = 8;

  @override
  Empleado read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Empleado(
      id: fields[0] as String,
      usuarioId: fields[1] as String,
      salarioBase: fields[2] as double,
      tipoContrato: fields[3] as String,
      comisionPorcentaje: fields[4] as double?,
      fechaContratacion: fields[5] as DateTime,
      activo: fields[6] as bool,
      empresaId: fields[7] as String?,
      updatedAt: fields[8] as DateTime?,
      sucursalId: fields[9] as String?,
      nombre: fields[10] as String?,
      position: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Empleado obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.usuarioId)
      ..writeByte(2)
      ..write(obj.salarioBase)
      ..writeByte(3)
      ..write(obj.tipoContrato)
      ..writeByte(4)
      ..write(obj.comisionPorcentaje)
      ..writeByte(5)
      ..write(obj.fechaContratacion)
      ..writeByte(6)
      ..write(obj.activo)
      ..writeByte(7)
      ..write(obj.empresaId)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.sucursalId)
      ..writeByte(10)
      ..write(obj.nombre)
      ..writeByte(11)
      ..write(obj.position);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmpleadoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NominaAdapter extends TypeAdapter<Nomina> {
  @override
  final int typeId = 9;

  @override
  Nomina read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Nomina(
      id: fields[0] as String,
      empleadoId: fields[1] as String,
      periodo: fields[2] as DateTime,
      salarioBase: fields[3] as double,
      comisiones: fields[4] as double,
      deducciones: fields[5] as double,
      totalPagado: fields[6] as double,
      fechaPago: fields[7] as DateTime,
      metodoPago: fields[8] as String,
      nota: fields[9] as String?,
      empresaId: fields[10] as String?,
      updatedAt: fields[11] as DateTime?,
      sucursalId: fields[12] as String?,
      status: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Nomina obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.empleadoId)
      ..writeByte(2)
      ..write(obj.periodo)
      ..writeByte(3)
      ..write(obj.salarioBase)
      ..writeByte(4)
      ..write(obj.comisiones)
      ..writeByte(5)
      ..write(obj.deducciones)
      ..writeByte(6)
      ..write(obj.totalPagado)
      ..writeByte(7)
      ..write(obj.fechaPago)
      ..writeByte(8)
      ..write(obj.metodoPago)
      ..writeByte(9)
      ..write(obj.nota)
      ..writeByte(10)
      ..write(obj.empresaId)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.sucursalId)
      ..writeByte(13)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NominaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlianzaAdapter extends TypeAdapter<Alianza> {
  @override
  final int typeId = 10;

  @override
  Alianza read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alianza(
      id: fields[0] as String,
      empresaId: fields[1] as String,
      empresaAliadaId: fields[2] as String,
      estado: fields[3] as String,
      fechaSolicitud: fields[4] as DateTime,
      fechaRespuesta: fields[5] as DateTime?,
      empresaIdLocal: fields[6] as String?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Alianza obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.empresaId)
      ..writeByte(2)
      ..write(obj.empresaAliadaId)
      ..writeByte(3)
      ..write(obj.estado)
      ..writeByte(4)
      ..write(obj.fechaSolicitud)
      ..writeByte(5)
      ..write(obj.fechaRespuesta)
      ..writeByte(6)
      ..write(obj.empresaIdLocal)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlianzaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransferenciaAdapter extends TypeAdapter<Transferencia> {
  @override
  final int typeId = 11;

  @override
  Transferencia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transferencia(
      id: fields[0] as String,
      ventaId: fields[1] as String,
      nombreCompleto: fields[2] as String,
      carnetIdentidad: fields[3] as String,
      numeroTelefono: fields[4] as String,
      numeroTransferencia: fields[5] as String,
      fechaHora: fields[6] as DateTime,
      monto: fields[7] as double,
      empresaId: fields[8] as String?,
      updatedAt: fields[9] as DateTime?,
      sucursalOrigenId: fields[10] as String?,
      sucursalDestinoId: fields[11] as String?,
      status: fields[12] as String?,
      nota: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Transferencia obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ventaId)
      ..writeByte(2)
      ..write(obj.nombreCompleto)
      ..writeByte(3)
      ..write(obj.carnetIdentidad)
      ..writeByte(4)
      ..write(obj.numeroTelefono)
      ..writeByte(5)
      ..write(obj.numeroTransferencia)
      ..writeByte(6)
      ..write(obj.fechaHora)
      ..writeByte(7)
      ..write(obj.monto)
      ..writeByte(8)
      ..write(obj.empresaId)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.sucursalOrigenId)
      ..writeByte(11)
      ..write(obj.sucursalDestinoId)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.nota);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferenciaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReferidoAdapter extends TypeAdapter<Referido> {
  @override
  final int typeId = 12;

  @override
  Referido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Referido(
      id: fields[0] as String,
      empresaId: fields[1] as String,
      empresaReferidaId: fields[2] as String,
      fechaReferido: fields[3] as DateTime,
      fechaPago: fields[4] as DateTime?,
      estado: fields[5] as String,
      updatedAt: fields[6] as DateTime?,
      code: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Referido obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.empresaId)
      ..writeByte(2)
      ..write(obj.empresaReferidaId)
      ..writeByte(3)
      ..write(obj.fechaReferido)
      ..writeByte(4)
      ..write(obj.fechaPago)
      ..writeByte(5)
      ..write(obj.estado)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.code);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferidoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BonoAdapter extends TypeAdapter<Bono> {
  @override
  final int typeId = 13;

  @override
  Bono read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bono(
      id: fields[0] as String,
      empresaId: fields[1] as String,
      descripcion: fields[2] as String,
      porcentajeDescuento: fields[3] as double,
      fechaInicio: fields[4] as DateTime,
      fechaFin: fields[5] as DateTime,
      utilizado: fields[6] as bool,
      fechaUso: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      referralId: fields[9] as String?,
      tipo: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bono obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.empresaId)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.porcentajeDescuento)
      ..writeByte(4)
      ..write(obj.fechaInicio)
      ..writeByte(5)
      ..write(obj.fechaFin)
      ..writeByte(6)
      ..write(obj.utilizado)
      ..writeByte(7)
      ..write(obj.fechaUso)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.referralId)
      ..writeByte(10)
      ..write(obj.tipo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BonoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MermaAdapter extends TypeAdapter<Merma> {
  @override
  final int typeId = 14;

  @override
  Merma read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Merma(
      id: fields[0] as String,
      productoId: fields[1] as String,
      cantidad: fields[2] as double,
      motivo: fields[3] as String,
      costoUnitario: fields[4] as double,
      costoTotal: fields[5] as double,
      fecha: fields[6] as DateTime,
      usuarioId: fields[7] as String?,
      sucursalId: fields[8] as String?,
      empresaId: fields[9] as String?,
      updatedAt: fields[10] as DateTime?,
      cancelado: fields[11] as bool,
      nota: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Merma obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productoId)
      ..writeByte(2)
      ..write(obj.cantidad)
      ..writeByte(3)
      ..write(obj.motivo)
      ..writeByte(4)
      ..write(obj.costoUnitario)
      ..writeByte(5)
      ..write(obj.costoTotal)
      ..writeByte(6)
      ..write(obj.fecha)
      ..writeByte(7)
      ..write(obj.usuarioId)
      ..writeByte(8)
      ..write(obj.sucursalId)
      ..writeByte(9)
      ..write(obj.empresaId)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.cancelado)
      ..writeByte(12)
      ..write(obj.nota);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MermaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MovimientoSucursalAdapter extends TypeAdapter<MovimientoSucursal> {
  @override
  final int typeId = 15;

  @override
  MovimientoSucursal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovimientoSucursal(
      id: fields[0] as String,
      productoId: fields[1] as String,
      cantidad: fields[2] as double,
      sucursalOrigenId: fields[3] as String,
      sucursalDestinoId: fields[4] as String,
      costoUnitario: fields[5] as double,
      costoTotal: fields[6] as double,
      fecha: fields[7] as DateTime,
      usuarioId: fields[8] as String?,
      empresaId: fields[9] as String?,
      updatedAt: fields[10] as DateTime?,
      cancelado: fields[11] as bool,
      productoOrigenId: fields[12] as String?,
      productoDestinoId: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MovimientoSucursal obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productoId)
      ..writeByte(2)
      ..write(obj.cantidad)
      ..writeByte(3)
      ..write(obj.sucursalOrigenId)
      ..writeByte(4)
      ..write(obj.sucursalDestinoId)
      ..writeByte(5)
      ..write(obj.costoUnitario)
      ..writeByte(6)
      ..write(obj.costoTotal)
      ..writeByte(7)
      ..write(obj.fecha)
      ..writeByte(8)
      ..write(obj.usuarioId)
      ..writeByte(9)
      ..write(obj.empresaId)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.cancelado)
      ..writeByte(12)
      ..write(obj.productoOrigenId)
      ..writeByte(13)
      ..write(obj.productoDestinoId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovimientoSucursalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DeudaAdapter extends TypeAdapter<Deuda> {
  @override
  final int typeId = 16;

  @override
  Deuda read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Deuda(
      id: fields[0] as String,
      tipo: fields[1] as String,
      entidadId: fields[2] as String,
      concepto: fields[3] as String,
      monto: fields[4] as double,
      fecha: fields[5] as DateTime,
      fechaVencimiento: fields[6] as DateTime?,
      pagada: fields[7] as bool,
      fechaPago: fields[8] as DateTime?,
      metodoPago: fields[9] as String?,
      nota: fields[10] as String?,
      empresaId: fields[11] as String?,
      updatedAt: fields[12] as DateTime?,
      moneda: fields[13] as String?,
      tasaCambio: fields[14] as double?,
      montoUSD: fields[15] as double?,
      pagado: fields[16] as double,
      sucursalId: fields[17] as String?,
      status: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Deuda obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.entidadId)
      ..writeByte(3)
      ..write(obj.concepto)
      ..writeByte(4)
      ..write(obj.monto)
      ..writeByte(5)
      ..write(obj.fecha)
      ..writeByte(6)
      ..write(obj.fechaVencimiento)
      ..writeByte(7)
      ..write(obj.pagada)
      ..writeByte(8)
      ..write(obj.fechaPago)
      ..writeByte(9)
      ..write(obj.metodoPago)
      ..writeByte(10)
      ..write(obj.nota)
      ..writeByte(11)
      ..write(obj.empresaId)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.moneda)
      ..writeByte(14)
      ..write(obj.tasaCambio)
      ..writeByte(15)
      ..write(obj.montoUSD)
      ..writeByte(16)
      ..write(obj.pagado)
      ..writeByte(17)
      ..write(obj.sucursalId)
      ..writeByte(18)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeudaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
