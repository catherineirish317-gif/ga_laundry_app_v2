// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LaundryOrderAdapter extends TypeAdapter<LaundryOrder> {
  @override
  final int typeId = 0;

  @override
  LaundryOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LaundryOrder(
      orderId: fields[0] as String,
      customerId: fields[1] as String,
      customerName: fields[2] as String,
      category: fields[3] as String,
      totalWeight: fields[4] as double,
      queueNumber: fields[5] as int,
      orderStatus: fields[6] as String,
      paymentStatus: fields[7] as String,
      paymentMethod: fields[8] as String,
      totalAmount: fields[9] as double,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      pendingSync: fields[12] as bool,
      estimatedCompletionTime: fields[13] as DateTime?,
      specialInstructions: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LaundryOrder obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.totalWeight)
      ..writeByte(5)
      ..write(obj.queueNumber)
      ..writeByte(6)
      ..write(obj.orderStatus)
      ..writeByte(7)
      ..write(obj.paymentStatus)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.totalAmount)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.pendingSync)
      ..writeByte(13)
      ..write(obj.estimatedCompletionTime)
      ..writeByte(14)
      ..write(obj.specialInstructions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaundryOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
