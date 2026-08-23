// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerAccountAdapter extends TypeAdapter<LedgerAccount> {
  @override
  final typeId = 50;

  @override
  LedgerAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerAccount(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] == null ? '💰' : fields[2] as String,
      initialBalanceCents: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      sortIndex: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      includeInNet: fields[5] == null ? true : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerAccount obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.initialBalanceCents)
      ..writeByte(4)
      ..write(obj.sortIndex)
      ..writeByte(5)
      ..write(obj.includeInNet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
