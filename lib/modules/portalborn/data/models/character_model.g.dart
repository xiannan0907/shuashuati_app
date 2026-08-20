// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameCharacterAdapter extends TypeAdapter<GameCharacter> {
  @override
  final int typeId = 33;

  @override
  GameCharacter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameCharacter(
      id: fields[0] as String?,
      name: fields[1] as String,
      mainClass: fields[2] as String,
      unlockedClasses: (fields[3] as List).cast<String>(),
      equippedSkills: (fields[4] as List).cast<String>(),
      level: fields[5] as int,
      exp: fields[6] as int,
      maxHp: fields[7] as int,
      currentHp: fields[8] as int,
      baseAttack: fields[9] as int,
      baseDefense: fields[10] as int,
      strength: fields[11] as int,
      dexterity: fields[12] as int,
      intelligence: fields[13] as int,
      constitution: fields[14] as int,
      availablePoints: fields[15] as int,
      inventoryIds: (fields[16] as List).cast<String>(),
      materials: (fields[17] as Map).cast<String, int>(),
      weaponId: fields[18] as String?,
      armorId: fields[19] as String?,
      accessoryId: fields[20] as String?,
      completedRealms: (fields[21] as List).cast<String>(),
      discoveredLore: (fields[22] as List).cast<String>(),
      gold: fields[23] as int,
      totalDeaths: fields[24] as int,
      totalKills: fields[25] as int,
      playTimeSeconds: fields[26] as int,
      lineage: fields[27] as String,
      heritagePoints: fields[28] as int,
      heritageTree: (fields[29] as Map).cast<String, int>(),
      lastPlayDate: fields[30] as DateTime?,
      todayFortune: fields[31] as String,
      hasRerolledFortuneToday: fields[32] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GameCharacter obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.mainClass)
      ..writeByte(3)
      ..write(obj.unlockedClasses)
      ..writeByte(4)
      ..write(obj.equippedSkills)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.exp)
      ..writeByte(7)
      ..write(obj.maxHp)
      ..writeByte(8)
      ..write(obj.currentHp)
      ..writeByte(9)
      ..write(obj.baseAttack)
      ..writeByte(10)
      ..write(obj.baseDefense)
      ..writeByte(11)
      ..write(obj.strength)
      ..writeByte(12)
      ..write(obj.dexterity)
      ..writeByte(13)
      ..write(obj.intelligence)
      ..writeByte(14)
      ..write(obj.constitution)
      ..writeByte(15)
      ..write(obj.availablePoints)
      ..writeByte(16)
      ..write(obj.inventoryIds)
      ..writeByte(17)
      ..write(obj.materials)
      ..writeByte(18)
      ..write(obj.weaponId)
      ..writeByte(19)
      ..write(obj.armorId)
      ..writeByte(20)
      ..write(obj.accessoryId)
      ..writeByte(21)
      ..write(obj.completedRealms)
      ..writeByte(22)
      ..write(obj.discoveredLore)
      ..writeByte(23)
      ..write(obj.gold)
      ..writeByte(24)
      ..write(obj.totalDeaths)
      ..writeByte(25)
      ..write(obj.totalKills)
      ..writeByte(26)
      ..write(obj.playTimeSeconds)
      ..writeByte(27)
      ..write(obj.lineage)
      ..writeByte(28)
      ..write(obj.heritagePoints)
      ..writeByte(29)
      ..write(obj.heritageTree)
      ..writeByte(30)
      ..write(obj.lastPlayDate)
      ..writeByte(31)
      ..write(obj.todayFortune)
      ..writeByte(32)
      ..write(obj.hasRerolledFortuneToday);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCharacterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
