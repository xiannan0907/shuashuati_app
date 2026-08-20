// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameItemAdapter extends TypeAdapter<GameItem> {
  @override
  final typeId = 34;

  @override
  GameItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameItem(
      id: fields[0] as String?,
      name: fields[1] as String,
      type: fields[2] as String,
      subType: fields[3] as String,
      atkBonus: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      defBonus: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      healAmount: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      manaRestore: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      description: fields[8] as String,
      emoji: fields[9] as String,
      value: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      isEquipped: fields[11] == null ? false : fields[11] as bool,
      quantity: fields[12] == null ? 1 : (fields[12] as num).toInt(),
      durability: fields[13] == null ? -1 : (fields[13] as num).toInt(),
      maxDurability: fields[14] == null ? -1 : (fields[14] as num).toInt(),
      tags: fields[15] == null ? const [] : (fields[15] as List).cast<String>(),
      extraData: (fields[16] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, GameItem obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.subType)
      ..writeByte(4)
      ..write(obj.atkBonus)
      ..writeByte(5)
      ..write(obj.defBonus)
      ..writeByte(6)
      ..write(obj.healAmount)
      ..writeByte(7)
      ..write(obj.manaRestore)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.emoji)
      ..writeByte(10)
      ..write(obj.value)
      ..writeByte(11)
      ..write(obj.isEquipped)
      ..writeByte(12)
      ..write(obj.quantity)
      ..writeByte(13)
      ..write(obj.durability)
      ..writeByte(14)
      ..write(obj.maxDurability)
      ..writeByte(15)
      ..write(obj.tags)
      ..writeByte(16)
      ..write(obj.extraData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
