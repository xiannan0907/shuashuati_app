// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerTransactionAdapter extends TypeAdapter<LedgerTransaction> {
  @override
  final typeId = 52;

  @override
  LedgerTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerTransaction(
      id: fields[0] as String,
      type: fields[1] as String,
      amountCents: (fields[2] as num).toInt(),
      categoryId: fields[3] as String?,
      accountId: fields[4] as String,
      toAccountId: fields[5] as String?,
      note: fields[6] == null ? '' : fields[6] as String,
      date: fields[7] as DateTime,
      ledgerId: fields[8] as String,
      createdAt: fields[9] as DateTime?,
      reimbursable: fields[10] == null ? false : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerTransaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amountCents)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.toAccountId)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.ledgerId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.reimbursable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
