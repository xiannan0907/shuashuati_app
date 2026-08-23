// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerBookAdapter extends TypeAdapter<LedgerBook> {
  @override
  final typeId = 53;

  @override
  LedgerBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerBook(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] == null ? '📘' : fields[2] as String,
      isDefault: fields[3] == null ? false : fields[3] as bool,
      createdAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerBook obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.isDefault)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerBookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
