import 'package:hive_ce/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 100)
class UserModel {
  @HiveField(0)
  String nickname;

  @HiveField(1)
  String avatarKey;

  @HiveField(2)
  String signature;

  UserModel({
    this.nickname = '学习者',
    this.avatarKey = 'avatar_1',
    this.signature = '学无止境',
  });
}