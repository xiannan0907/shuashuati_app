// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameCharacterAdapter extends TypeAdapter<GameCharacter> {
  @override
  final typeId = 33;

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
      unlockedClasses:
          fields[3] == null ? const [] : (fields[3] as List).cast<String>(),
      equippedSkills:
          fields[4] == null ? const [] : (fields[4] as List).cast<String>(),
      level: fields[5] == null ? 1 : (fields[5] as num).toInt(),
      exp: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      maxHp: fields[7] == null ? 20 : (fields[7] as num).toInt(),
      currentHp: fields[8] == null ? 20 : (fields[8] as num).toInt(),
      baseAttack: fields[9] == null ? 2 : (fields[9] as num).toInt(),
      baseDefense: fields[10] == null ? 1 : (fields[10] as num).toInt(),
      strength: fields[11] == null ? 5 : (fields[11] as num).toInt(),
      dexterity: fields[12] == null ? 5 : (fields[12] as num).toInt(),
      intelligence: fields[13] == null ? 5 : (fields[13] as num).toInt(),
      constitution: fields[14] == null ? 5 : (fields[14] as num).toInt(),
      availablePoints: fields[15] == null ? 0 : (fields[15] as num).toInt(),
      inventoryIds:
          fields[16] == null ? const [] : (fields[16] as List).cast<String>(),
      materials: fields[17] == null
          ? const {}
          : (fields[17] as Map).cast<String, int>(),
      weaponId: fields[18] as String?,
      armorId: fields[19] as String?,
      accessoryId: fields[20] as String?,
      completedRealms:
          fields[21] == null ? const [] : (fields[21] as List).cast<String>(),
      discoveredLore:
          fields[22] == null ? const [] : (fields[22] as List).cast<String>(),
      gold: fields[23] == null ? 0 : (fields[23] as num).toInt(),
      totalDeaths: fields[24] == null ? 0 : (fields[24] as num).toInt(),
      totalKills: fields[25] == null ? 0 : (fields[25] as num).toInt(),
      playTimeSeconds: fields[26] == null ? 0 : (fields[26] as num).toInt(),
      lineage: fields[27] == null ? 'wanderer' : fields[27] as String,
      heritagePoints: fields[28] == null ? 0 : (fields[28] as num).toInt(),
      heritageTree: fields[29] == null
          ? const {}
          : (fields[29] as Map).cast<String, int>(),
      lastPlayDate: fields[30] as DateTime?,
      todayFortune: fields[31] == null ? 'normal' : fields[31] as String,
      hasRerolledFortuneToday: fields[32] == null ? false : fields[32] as bool,
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
