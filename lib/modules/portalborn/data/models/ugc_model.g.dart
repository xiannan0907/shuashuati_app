// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ugc_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UGCCustomRealmAdapter extends TypeAdapter<UGCCustomRealm> {
  @override
  final typeId = 36;

  @override
  UGCCustomRealm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCCustomRealm(
      id: fields[0] as String?,
      name: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String,
      version: fields[4] == null ? '1.0.0' : fields[4] as String,
      rooms: fields[5] == null ? const [] : (fields[5] as List).cast<UGCRoom>(),
      entryRoomId: fields[6] as String,
      customMonsters:
          fields[7] == null ? const [] : (fields[7] as List).cast<UGCMonster>(),
      customItems:
          fields[8] == null ? const [] : (fields[8] as List).cast<UGCItem>(),
      requiredItems:
          fields[9] == null ? const [] : (fields[9] as List).cast<String>(),
      isImported: fields[10] == null ? false : fields[10] as bool,
      createdAt: fields[11] as DateTime?,
      lastPlayedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UGCCustomRealm obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.version)
      ..writeByte(5)
      ..write(obj.rooms)
      ..writeByte(6)
      ..write(obj.entryRoomId)
      ..writeByte(7)
      ..write(obj.customMonsters)
      ..writeByte(8)
      ..write(obj.customItems)
      ..writeByte(9)
      ..write(obj.requiredItems)
      ..writeByte(10)
      ..write(obj.isImported)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastPlayedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCCustomRealmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCRoomAdapter extends TypeAdapter<UGCRoom> {
  @override
  final typeId = 37;

  @override
  UGCRoom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCRoom(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      exits: fields[3] == null ? const [] : (fields[3] as List).cast<UGCExit>(),
      objects: fields[4] == null
          ? const []
          : (fields[4] as List).cast<UGCInteractable>(),
      monsterId: fields[5] as String?,
      tags: fields[6] == null ? const [] : (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UGCRoom obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.exits)
      ..writeByte(4)
      ..write(obj.objects)
      ..writeByte(5)
      ..write(obj.monsterId)
      ..writeByte(6)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCRoomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCExitAdapter extends TypeAdapter<UGCExit> {
  @override
  final typeId = 38;

  @override
  UGCExit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCExit(
      id: fields[0] as String?,
      direction: fields[1] as String,
      targetRoomId: fields[2] as String,
      description: fields[3] as String,
      isHidden: fields[4] == null ? false : fields[4] as bool,
      isLocked: fields[5] == null ? false : fields[5] as bool,
      keyItemId: fields[6] as String?,
      isOneWay: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UGCExit obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.direction)
      ..writeByte(2)
      ..write(obj.targetRoomId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isHidden)
      ..writeByte(5)
      ..write(obj.isLocked)
      ..writeByte(6)
      ..write(obj.keyItemId)
      ..writeByte(7)
      ..write(obj.isOneWay);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCExitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCInteractableAdapter extends TypeAdapter<UGCInteractable> {
  @override
  final typeId = 39;

  @override
  UGCInteractable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCInteractable(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      actions:
          fields[3] == null ? const [] : (fields[3] as List).cast<String>(),
      result: (fields[4] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UGCInteractable obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.actions)
      ..writeByte(4)
      ..write(obj.result);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCInteractableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCMonsterAdapter extends TypeAdapter<UGCMonster> {
  @override
  final typeId = 40;

  @override
  UGCMonster read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCMonster(
      id: fields[0] as String?,
      name: fields[1] as String,
      emoji: fields[2] as String,
      description: fields[3] as String,
      baseHp: fields[4] == null ? 10 : (fields[4] as num).toInt(),
      attack: fields[5] == null ? 3 : (fields[5] as num).toInt(),
      defense: fields[6] == null ? 1 : (fields[6] as num).toInt(),
      expReward: fields[7] == null ? 5 : (fields[7] as num).toInt(),
      goldReward: fields[8] == null ? 2 : (fields[8] as num).toInt(),
      drops: fields[9] == null ? const [] : (fields[9] as List).cast<UGCDrop>(),
      tags: fields[10] == null ? const [] : (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UGCMonster obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.baseHp)
      ..writeByte(5)
      ..write(obj.attack)
      ..writeByte(6)
      ..write(obj.defense)
      ..writeByte(7)
      ..write(obj.expReward)
      ..writeByte(8)
      ..write(obj.goldReward)
      ..writeByte(9)
      ..write(obj.drops)
      ..writeByte(10)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCMonsterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCDropAdapter extends TypeAdapter<UGCDrop> {
  @override
  final typeId = 41;

  @override
  UGCDrop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCDrop(
      itemId: fields[0] as String,
      probability: (fields[1] as num).toDouble(),
      minCount: fields[2] == null ? 1 : (fields[2] as num).toInt(),
      maxCount: fields[3] == null ? 1 : (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, UGCDrop obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.probability)
      ..writeByte(2)
      ..write(obj.minCount)
      ..writeByte(3)
      ..write(obj.maxCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCDropAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UGCItemAdapter extends TypeAdapter<UGCItem> {
  @override
  final typeId = 42;

  @override
  UGCItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UGCItem(
      id: fields[0] as String?,
      name: fields[1] as String,
      type: fields[2] as String,
      subType: fields[3] as String,
      atkBonus: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      defBonus: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      healAmount: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      description: fields[7] as String,
      emoji: fields[8] as String,
      value: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      tags: fields[10] == null ? const [] : (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UGCItem obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.emoji)
      ..writeByte(9)
      ..write(obj.value)
      ..writeByte(10)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UGCItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
