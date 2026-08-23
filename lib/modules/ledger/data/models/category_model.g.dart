// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerCategoryAdapter extends TypeAdapter<LedgerCategory> {
  @override
  final typeId = 51;

  @override
  LedgerCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      icon: fields[3] == null ? '🏷️' : fields[3] as String,
      colorKey: fields[4] == null ? 'grey' : fields[4] as String,
      isCustom: fields[5] == null ? false : fields[5] as bool,
      sortIndex: fields[6] == null ? 0 : (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, LedgerCategory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.colorKey)
      ..writeByte(5)
      ..write(obj.isCustom)
      ..writeByte(6)
      ..write(obj.sortIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
