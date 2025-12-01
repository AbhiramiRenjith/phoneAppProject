// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallModelAdapter extends TypeAdapter<CallModel> {
  @override
  final int typeId = 0;

  @override
  CallModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallModel(
      number: fields[0] as String,
      time: fields[1] as DateTime,
      simSlot: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CallModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.simSlot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
