import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/bloc/portalborn_bloc.dart';
import '../../presentation/bloc/portalborn_event.dart';
import '../../presentation/bloc/portalborn_state.dart';
import '../../data/seed_data/classes.dart';
import 'portalborn_hub.dart';

class PortalbornCreateCharacterPage extends StatefulWidget {
  const PortalbornCreateCharacterPage({super.key});

  @override
  State<PortalbornCreateCharacterPage> createState() =>
      _PortalbornCreateCharacterPageState();
}

class _PortalbornCreateCharacterPageState
    extends State<PortalbornCreateCharacterPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedClass = 'warrior';
  String _selectedLineage = 'wanderer';
  bool _isCreating = false;
  String? _errorMessage;

  final Map<String, String> _lineageMap = {
    'scholar': '📚 学者 - 初始解锁2个词条，INT+1',
    'wanderer': '🚶 流浪者 - 初始金币+50，DEX+1',
    'warrior': '⚔️ 战士后裔 - 初始STR+2，战斗直觉被动',
    'mystic': '🔮 神秘血脉 - 初始INT+2，魔法感应被动',
    'merchant': '💰 商人世家 - 初始金币+100，交易优惠10%',
    'hunter': '🏹 猎户之子 - 初始DEX+2，追踪被动',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0f),
      appBar: AppBar(
        title: const Text('创建角色'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<PortalbornBloc, PortalbornState>(
        listener: (context, state) {
          // 当创建成功时，直接跳转大厅
          if (state is PortalbornHub) {
            if (!mounted) return;
            // 使用 pushReplacement 替换当前页面，直接进入大厅
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PortalbornBloc>(),
                  child: const PortalbornHubPage(),
                ),
              ),
            );
          }
          if (state is PortalbornError) {
            setState(() {
              _isCreating = false;
              _errorMessage = state.message;
            });
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚔️ 开始你的冒险',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00ff88),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '创建你的角色，踏入传送门的世界',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  '角色名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '输入 2-12 个字符',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF141425),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00ff88)),
                    ),
                    errorText: _errorMessage,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  '选择职业',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: classData.map((cls) {
                    final isSelected = _selectedClass == cls.id;
                    return _ClassCard(
                      classData: cls,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedClass = cls.id;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                const Text(
                  '选择继承系',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _lineageMap.keys.map((key) {
                    final isSelected = _selectedLineage == key;
                    final label = _lineageMap[key] ?? key;
                    final parts = label.split(' - ');
                    final emoji = parts.isNotEmpty ? parts[0] : '🎯';
                    final desc = parts.length > 1 ? parts[1] : '';
                    return FilterChip(
                      label: Text(
                        '$emoji ${desc.isNotEmpty ? desc.substring(0, desc.length.clamp(0, 20)) : key}',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedLineage = key;
                        });
                      },
                      backgroundColor: const Color(0xFF141425),
                      selectedColor: const Color(0xFF00ff88),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF00ff88) : Colors.grey[800]!,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createCharacter,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00ff88),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                    child: _isCreating
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      '✨ 创建角色',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createCharacter() async {
    final name = _nameController.text.trim();

    if (name.length < 2 || name.length > 12) {
      setState(() {
        _errorMessage = '角色名长度应为 2-12 个字符';
      });
      return;
    }

    if (name.contains(RegExp(r'[^\w\u4e00-\u9fa5]'))) {
      setState(() {
        _errorMessage = '角色名只能包含字母、数字、中文';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    context.read<PortalbornBloc>().add(
      PortalbornCreateCharacter(
        name: name,
        classType: _selectedClass,
        lineage: _selectedLineage,
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassData classData;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassCard({
    required this.classData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00ff88).withOpacity(0.15)
              : const Color(0xFF141425),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00ff88)
                : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              classData.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              classData.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF00ff88)
                    : Colors.grey[300],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'STR ${classData.baseStats['strength'] ?? 5}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}