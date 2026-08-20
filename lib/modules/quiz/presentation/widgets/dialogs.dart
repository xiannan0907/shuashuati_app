import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quiz_bloc.dart';

class QuizDialogs {
  static Future<void> showCreateSetDialog(
      BuildContext context, {
        required VoidCallback onCreated,
      }) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('📚 创建新题库'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入题库名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (controller.text.isNotEmpty) {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(SwitchQuizSet(controller.text));
              Future.delayed(const Duration(milliseconds: 300), onCreated);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                context.read<QuizBloc>().add(SwitchQuizSet(controller.text));
                Future.delayed(const Duration(milliseconds: 300), onCreated);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  static Future<void> showRenameDialog(
      BuildContext context, {
        required String oldName,
        required VoidCallback onRenamed,
      }) async {
    final controller = TextEditingController(text: oldName);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('📝 重命名题库'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入新名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            if (controller.text.isNotEmpty && controller.text != oldName) {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(RenameQuizSet(oldName, controller.text));
              Future.delayed(const Duration(milliseconds: 300), onRenamed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != oldName) {
                Navigator.pop(dialogContext);
                context.read<QuizBloc>().add(RenameQuizSet(oldName, controller.text));
                Future.delayed(const Duration(milliseconds: 300), onRenamed);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  static Future<void> showDeleteConfirm(
      BuildContext context, {
        required String name,
        required VoidCallback onDeleted,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🗑️ 删除题库'),
        content: Text('确定要删除题库 "$name" 吗？\n所有题目将丢失！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<QuizBloc>().add(DeleteQuizSet(name));
              Future.delayed(const Duration(milliseconds: 300), onDeleted);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}