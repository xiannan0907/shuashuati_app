// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_import, directives_ordering

part of 'question_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 0;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      content: fields[1] as String,
      options: (fields[2] as List).cast<String>(),
      correctIndex: fields[3] as int,
      selectedOption: fields[4] as int?,
      isAnswered: fields[5] as bool?,
      source: fields[6] as String,
      answer: fields[7] as String?,
      isWrong: fields[8] as bool?,
      isFavorite: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctIndex)
      ..writeByte(4)
      ..write(obj.selectedOption)
      ..writeByte(5)
      ..write(obj.isAnswered)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.answer)
      ..writeByte(8)
      ..write(obj.isWrong)
      ..writeByte(9)
      ..write(obj.isFavorite);
  }

  @override
  void writeBinary(BinaryWriter writer, Question obj) {
    write(writer, obj);
  }
}