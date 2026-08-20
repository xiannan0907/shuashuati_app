// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tower_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TowerProgressAdapter extends TypeAdapter<TowerProgress> {
  @override
  final typeId = 3;

  @override
  TowerProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TowerProgress(
      currentFloor: fields[0] == null ? 1 : (fields[0] as num).toInt(),
      correctCount: fields[1] == null ? 0 : (fields[1] as num).toInt(),
      wrongCount: fields[2] == null ? 0 : (fields[2] as num).toInt(),
      totalCorrect: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      totalWrong: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      maxFloor: fields[5] == null ? 1 : (fields[5] as num).toInt(),
      usedQuestionIds: (fields[6] as List?)?.cast<String>(),
      currentQuestionIndex: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      hp: fields[8] == null ? 5 : (fields[8] as num).toInt(),
      maxHp: fields[9] == null ? 5 : (fields[9] as num).toInt(),
      appleCount: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      shieldCount: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      doubleExpCount: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      lastRestFloor: fields[13] == null ? 0 : (fields[13] as num).toInt(),
      currentNodeIndex: fields[14] == null ? 0 : (fields[14] as num).toInt(),
      completedNodeIndices: (fields[15] as List?)?.cast<int>(),
      floorNodeCount: fields[16] == null ? 4 : (fields[16] as num).toInt(),
      isBossDefeated: fields[17] == null ? false : fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TowerProgress obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.currentFloor)
      ..writeByte(1)
      ..write(obj.correctCount)
      ..writeByte(2)
      ..write(obj.wrongCount)
      ..writeByte(3)
      ..write(obj.totalCorrect)
      ..writeByte(4)
      ..write(obj.totalWrong)
      ..writeByte(5)
      ..write(obj.maxFloor)
      ..writeByte(6)
      ..write(obj.usedQuestionIds)
      ..writeByte(7)
      ..write(obj.currentQuestionIndex)
      ..writeByte(8)
      ..write(obj.hp)
      ..writeByte(9)
      ..write(obj.maxHp)
      ..writeByte(10)
      ..write(obj.appleCount)
      ..writeByte(11)
      ..write(obj.shieldCount)
      ..writeByte(12)
      ..write(obj.doubleExpCount)
      ..writeByte(13)
      ..write(obj.lastRestFloor)
      ..writeByte(14)
      ..write(obj.currentNodeIndex)
      ..writeByte(15)
      ..write(obj.completedNodeIndices)
      ..writeByte(16)
      ..write(obj.floorNodeCount)
      ..writeByte(17)
      ..write(obj.isBossDefeated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TowerProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
