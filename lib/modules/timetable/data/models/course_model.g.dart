// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final typeId = 30;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course(
      id: fields[0] as String,
      name: fields[1] as String,
      teacher: fields[2] == null ? '' : fields[2] as String,
      classroom: fields[3] == null ? '' : fields[3] as String,
      weekday: (fields[4] as num).toInt(),
      startSlot: (fields[5] as num).toInt(),
      endSlot: (fields[6] as num).toInt(),
      weekStart: fields[7] == null ? 1 : (fields[7] as num).toInt(),
      weekEnd: fields[8] == null ? 20 : (fields[8] as num).toInt(),
      color: fields[9] == null ? 'blue' : fields[9] as String,
      note: fields[10] as String?,
      credit: fields[11] == null ? 0.0 : (fields[11] as num).toDouble(),
      scheduleType: fields[12] == null ? 'course' : fields[12] as String,
      startMinute: (fields[13] as num?)?.toInt(),
      endMinute: (fields[14] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.teacher)
      ..writeByte(3)
      ..write(obj.classroom)
      ..writeByte(4)
      ..write(obj.weekday)
      ..writeByte(5)
      ..write(obj.startSlot)
      ..writeByte(6)
      ..write(obj.endSlot)
      ..writeByte(7)
      ..write(obj.weekStart)
      ..writeByte(8)
      ..write(obj.weekEnd)
      ..writeByte(9)
      ..write(obj.color)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.credit)
      ..writeByte(12)
      ..write(obj.scheduleType)
      ..writeByte(13)
      ..write(obj.startMinute)
      ..writeByte(14)
      ..write(obj.endMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
