// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameItemAdapter extends TypeAdapter<GameItem> {
  @override
  final int typeId = 34;

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
      atkBonus: fields[4] as int,
      defBonus: fields[5] as int,
      healAmount: fields[6] as int,
      manaRestore: fields[7] as int,
      description: fields[8] as String,
      emoji: fields[9] as String,
      value: fields[10] as int,
      isEquipped: fields[11] as bool,
      quantity: fields[12] as int,
      durability: fields[13] as int,
      maxDurability: fields[14] as int,
      tags: (fields[15] as List).cast<String>(),
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
