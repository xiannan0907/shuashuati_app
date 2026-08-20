// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tower_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TowerProgressAdapter extends TypeAdapter<TowerProgress> {
  @override
  final int typeId = 3;

  @override
  TowerProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TowerProgress(
      currentFloor: fields[0] as int,
      correctCount: fields[1] as int,
      wrongCount: fields[2] as int,
      totalCorrect: fields[3] as int,
      totalWrong: fields[4] as int,
      maxFloor: fields[5] as int,
      usedQuestionIds: (fields[6] as List?)?.cast<String>(),
      currentQuestionIndex: fields[7] as int,
      hp: fields[8] as int,
      maxHp: fields[9] as int,
      appleCount: fields[10] as int,
      shieldCount: fields[11] as int,
      doubleExpCount: fields[12] as int,
      lastRestFloor: fields[13] as int,
      currentNodeIndex: fields[14] as int,
      completedNodeIndices: (fields[15] as List?)?.cast<int>(),
      floorNodeCount: fields[16] as int,
      isBossDefeated: fields[17] as bool,
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
