import 'package:hive/hive.dart';
import '../models/user_model.dart';

class UserRepository {
  static const String boxName = 'userBox';

  Future<Box<UserModel>> _getBox() async {
    return await Hive.openBox<UserModel>(boxName);
  }

  Future<UserModel> getUser() async {
    try {
      final box = await _getBox();
      final user = box.get('user');
      if (user != null) {
        if (user.nickname.isEmpty) user.nickname = '学习者';
        if (user.avatarKey.isEmpty) user.avatarKey = 'avatar_1';
        if (user.signature.isEmpty) user.signature = '学无止境';
        await saveUser(user);
        return user;
      }
      final defaultUser = UserModel();
      await box.put('user', defaultUser);
      return defaultUser;
    } catch (e) {
      final defaultUser = UserModel();
      try {
        final box = await _getBox();
        await box.put('user', defaultUser);
      } catch (_) {}
      return defaultUser;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final box = await _getBox();
    await box.put('user', user);
  }

  Future<void> updateNickname(String nickname) async {
    final user = await getUser();
    user.nickname = nickname;
    await saveUser(user);
  }

  Future<void> updateAvatar(String avatarKey) async {
    final user = await getUser();
    user.avatarKey = avatarKey;
    await saveUser(user);
  }

  Future<void> updateSignature(String signature) async {
    final user = await getUser();
    user.signature = signature;
    await saveUser(user);
  }
}