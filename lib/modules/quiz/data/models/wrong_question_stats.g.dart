// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_question_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WrongQuestionStatsAdapter extends TypeAdapter<WrongQuestionStats> {
  @override
  final int typeId = 2;

  @override
  WrongQuestionStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WrongQuestionStats(
      questionId: fields[0] as String,
      wrongCount: fields[1] as int,
      correctCount: fields[2] as int,
      lastReviewed: fields[3] as DateTime?,
      masteryLevel: fields[4] as double,
      consecutiveCorrect: fields[5] as int,
      lastReviewDate: fields[6] as DateTime?,
      easinessFactor: fields[7] as double,
      interval: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WrongQuestionStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.wrongCount)
      ..writeByte(2)
      ..write(obj.correctCount)
      ..writeByte(3)
      ..write(obj.lastReviewed)
      ..writeByte(4)
      ..write(obj.masteryLevel)
      ..writeByte(5)
      ..write(obj.consecutiveCorrect)
      ..writeByte(6)
      ..write(obj.lastReviewDate)
      ..writeByte(7)
      ..write(obj.easinessFactor)
      ..writeByte(8)
      ..write(obj.interval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrongQuestionStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
