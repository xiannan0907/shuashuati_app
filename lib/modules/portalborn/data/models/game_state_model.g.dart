// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameStateAdapter extends TypeAdapter<GameState> {
  @override
  final typeId = 35;

  @override
  GameState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameState(
      id: fields[0] as String?,
      currentCharacterId: fields[1] as String,
      currentRealmId: fields[2] as String?,
      currentRoomId: fields[3] as String?,
      visitedRoomIds:
          fields[4] == null ? const [] : (fields[4] as List).cast<String>(),
      unlockedThemes:
          fields[5] == null ? const [] : (fields[5] as List).cast<String>(),
      totalRealmsCompleted: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      totalItemsCrafted: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      createdAt: fields[8] as DateTime?,
      lastSavedAt: fields[9] as DateTime?,
      isInBattle: fields[10] == null ? false : fields[10] as bool,
      currentBattleMonsterId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GameState obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.currentCharacterId)
      ..writeByte(2)
      ..write(obj.currentRealmId)
      ..writeByte(3)
      ..write(obj.currentRoomId)
      ..writeByte(4)
      ..write(obj.visitedRoomIds)
      ..writeByte(5)
      ..write(obj.unlockedThemes)
      ..writeByte(6)
      ..write(obj.totalRealmsCompleted)
      ..writeByte(7)
      ..write(obj.totalItemsCrafted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastSavedAt)
      ..writeByte(10)
      ..write(obj.isInBattle)
      ..writeByte(11)
      ..write(obj.currentBattleMonsterId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
