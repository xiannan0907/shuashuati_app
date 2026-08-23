// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerBudgetAdapter extends TypeAdapter<LedgerBudget> {
  @override
  final typeId = 54;

  @override
  LedgerBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerBudget(
      id: fields[0] as String,
      month: fields[1] as String,
      amountCents: (fields[2] as num).toInt(),
      categoryId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerBudget obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.amountCents)
      ..writeByte(3)
      ..write(obj.categoryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
