import 'app_module.dart';
import '../../../modules/quiz/quiz_module.dart';
import '../../../modules/timetable/timetable_module.dart'; // ✅ 添加这行
import '../../../modules/portalborn/portalborn_module.dart';

class ModuleRegistry {
  static final List<AppModule> _modules = [
    QuizModule(),
    TimetableModule(),
    PortalbornModule(),
    // 未来在这里添加其他模块：
    // NoteModule(),
    // FitnessModule(),
  ];

  static List<AppModule> get modules {
    return _modules.where((m) => m.enabled).toList();
  }

  static AppModule? findById(String id) {
    try {
      return modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}