// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as int?,
      name: fields[1] as String,
      stock: fields[2] as int,
      sku: fields[3] as String,
      purchasePrice: fields[4] as int,
      sellingPrice: fields[5] as int,
      category: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stock)
      ..writeByte(3)
      ..write(obj.sku)
      ..writeByte(4)
      ..write(obj.purchasePrice)
      ..writeByte(5)
      ..write(obj.sellingPrice)
      ..writeByte(6)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PurchaseTransactionAdapter extends TypeAdapter<PurchaseTransaction> {
  @override
  final int typeId = 1;

  @override
  PurchaseTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchaseTransaction(
      id: fields[0] as int?,
      items: fields[1] as String,
      total: fields[2] as int,
      paymentMethod: fields[3] as String,
      cashier: fields[4] as String,
      supplier: fields[5] as String,
      discount: fields[6] as int,
      tax: fields[7] as int,
      date: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PurchaseTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.total)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.cashier)
      ..writeByte(5)
      ..write(obj.supplier)
      ..writeByte(6)
      ..write(obj.discount)
      ..writeByte(7)
      ..write(obj.tax)
      ..writeByte(8)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 2;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as int?,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoreProfileAdapter extends TypeAdapter<StoreProfile> {
  @override
  final int typeId = 3;

  @override
  StoreProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreProfile(
      id: fields[0] as int?,
      storeName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StoreProfile obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CashierAdapter extends TypeAdapter<Cashier> {
  @override
  final int typeId = 4;

  @override
  Cashier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cashier(
      id: fields[0] as int?,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Cashier obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockTransactionAdapter extends TypeAdapter<StockTransaction> {
  @override
  final int typeId = 5;

  @override
  StockTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockTransaction(
      id: fields[0] as int?,
      productId: fields[1] as int,
      productName: fields[2] as String,
      quantity: fields[3] as int,
      type: fields[4] as String,
      date: fields[5] as DateTime,
      sku: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StockTransaction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.sku);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
