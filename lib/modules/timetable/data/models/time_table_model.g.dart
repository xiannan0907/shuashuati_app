// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_table_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimeTableAdapter extends TypeAdapter<TimeTable> {
  @override
  final typeId = 32;

  @override
  TimeTable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeTable(
      id: fields[0] as String,
      name: fields[1] as String,
      morningStart: fields[2] == null ? 8 * 60 : (fields[2] as num).toInt(),
      afternoonStart: fields[3] == null ? 14 * 60 : (fields[3] as num).toInt(),
      classDuration: fields[4] == null ? 45 : (fields[4] as num).toInt(),
      breakDuration: fields[5] == null ? 5 : (fields[5] as num).toInt(),
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeTable obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.morningStart)
      ..writeByte(3)
      ..write(obj.afternoonStart)
      ..writeByte(4)
      ..write(obj.classDuration)
      ..writeByte(5)
      ..write(obj.breakDuration)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeTableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
