import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';
import '../../data/models/tower_model.dart';
import '../../data/repositories/tower_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../widgets/tower_question_card.dart';
import '../widgets/tower_map_widget.dart';
import '../widgets/tower_node_detail_dialog.dart';

class TowerPage extends StatefulWidget {
  const TowerPage({super.key});

  @override
  State<TowerPage> createState() => _TowerPageState();
}

class _TowerPageState extends State<TowerPage> {
  final TowerRepository _towerRepo = TowerRepository();
  final QuestionRepository _questionRepo = QuestionRepository();

  TowerProgress? _progress;
  List<Question> _availableQuestions = [];
  Question? _currentQuestion;
  bool _isLoading = true;
  bool _isAnswered = false;
  String? _feedbackMessage;
  Color? _feedbackColor;
  bool _showFloorComplete = false;
  bool _showFloorFailed = false;
// ignore: unused_field
  bool _hasShield = false;
// ignore: unused_field
  bool _hasDoubleExpActive = false;
  bool _isInBattle = false;
  bool _isBossBattle = false;

  final Map<String, String> _fillAnswers = {};

  TowerNodeType? _selectedNodeType;
  int _selectedNodeIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // ✅ 加载数据
  // ============================================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _showFloorComplete = false;
      _showFloorFailed = false;
      _isInBattle = false;
      _isBossBattle = false;
    });

    try {
      _progress = await _towerRepo.getProgress();
      print('📊 当前进度: 第${_progress!.currentFloor}层, HP: ${_progress!.hp}/${_progress!.maxHp}');

      if (_progress!.isAllNodesCompleted) {
        _progress!.currentFloor++;
        _progress!.resetFloor();
        _progress!.floorNodeCount = 3 + ((_progress!.currentFloor - 1) % 3) + (_progress!.isBossFloor ? 1 : 0);
        if (_progress!.currentFloor > _progress!.maxFloor) {
          _progress!.maxFloor = _progress!.currentFloor;
        }
        await _towerRepo.saveProgress(_progress!);
        await _loadData();
        return;
      }

      await _loadQuestions();

      setState(() {
        _isLoading = false;
        _isAnswered = false;
        _feedbackMessage = null;
        _hasShield = false;
        _hasDoubleExpActive = false;
      });
    } catch (e) {
      print('❌ 加载爬塔数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // ✅ 加载题目
  // ============================================================
  Future<void> _loadQuestions() async {
    final setNames = await _questionRepo.getAllSetNames();
    List<Question> allQuestions = [];
    for (var name in setNames) {
      final questions = await _questionRepo.getQuestions(setName: name);
      allQuestions.addAll(questions);
    }

    if (allQuestions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 没有题目，请先导入题库！'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _availableQuestions = [];
        _currentQuestion = null;
        _isLoading = false;
      });
      return;
    }

    final available = allQuestions
        .where((q) => !_progress!.usedQuestionIds.contains(q.id))
        .toList();

    if (available.length < 5 && _progress!.usedQuestionIds.isNotEmpty) {
      _progress!.usedQuestionIds.clear();
      await _towerRepo.saveProgress(_progress!);
      await _loadQuestions();
      return;
    }

    setState(() {
      _availableQuestions = available;
      if (_availableQuestions.isNotEmpty) {
        if (_progress!.currentQuestionIndex >= _availableQuestions.length) {
          _progress!.currentQuestionIndex = 0;
        }
        _currentQuestion = _availableQuestions[_progress!.currentQuestionIndex];
      } else {
        _currentQuestion = null;
      }
      _isLoading = false;
    });
  }

  // ============================================================
  // ✅ 节点点击
  // ============================================================
  void _onNodeTap(int index) {
    if (_progress == null) return;
    if (_isInBattle) return;
    if (_progress!.isNodeCompleted(index)) return;
    if (!_progress!.isNodeAccessible(index)) return;

    final type = _progress!.getNodeType(index);

    // 显示节点详情对话框
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TowerNodeDetailDialog(
        type: type,
        nodeName: _getNodeDisplayName(type, index),
        description: _getNodeDescription(type, index),
        onConfirm: () {
          _handleNodeAction(index, type);
        },
      ),
    );
  }

  String _getNodeDisplayName(TowerNodeType type, int index) {
    if (type == TowerNodeType.boss) {
      return '👑 ${_progress!.getBossName()}';
    }
    return '${_progress!.getNodeIcon(type)} ${_progress!.getNodeName(type)}';
  }

  String _getNodeDescription(TowerNodeType type, int index) {
    switch (type) {
      case TowerNodeType.normal:
        return '⚔️ 与普通怪物战斗，击败它继续前进！';
      case TowerNodeType.elite:
        return '💀 强大的精英怪物！击败它获得额外奖励！';
      case TowerNodeType.boss:
        final hp = _progress!.getBossHp();
        return '👑 魔王出现了！需要击败 $hp 次才能消灭它！\n击败后进入下一层！';
      case TowerNodeType.rest:
        return '⛺ 在此休息，恢复全部生命值！';
      case TowerNodeType.event:
        return '❓ 你遇到了一个神秘事件...';
      case TowerNodeType.treasure:
        return '🎁 你发现了一个宝箱！打开获得随机道具！';
      case TowerNodeType.trap:
        return '⚠️ 你触发了陷阱！会受到伤害！';
      case TowerNodeType.shop:
        return '🏪 你遇到了一位商人，可以用道具交换。';
    }
  }

  // ============================================================
  // ✅ 处理节点动作
  // ============================================================
  void _handleNodeAction(int index, TowerNodeType type) {
    switch (type) {
      case TowerNodeType.rest:
        _showRestNodeDialog(index);
        break;
      case TowerNodeType.event:
        _showEventNode(index);
        break;
      case TowerNodeType.treasure:
        _handleTreasure(index);
        break;
      case TowerNodeType.trap:
        _handleTrap(index);
        break;
      case TowerNodeType.shop:
        _handleShop(index);
        break;
      case TowerNodeType.normal:
      case TowerNodeType.elite:
      case TowerNodeType.boss:
        _startBattle(index, type);
        break;
    }
  }

  // ============================================================
  // ✅ 宝箱
  // ============================================================
  void _handleTreasure(int index) {
    final rewards = ['🧪 +1 生命药水', '🛡️ +1 护盾', '💥 +1 双倍攻击', '❤️ +1 生命上限'];
    final reward = rewards[DateTime.now().millisecondsSinceEpoch % rewards.length];

    if (reward.contains('生命药水')) {
      _progress!.appleCount++;
    } else if (reward.contains('护盾')) {
      _progress!.shieldCount++;
    } else if (reward.contains('双倍攻击')) {
      _progress!.doubleExpCount++;
    } else if (reward.contains('生命上限')) {
      _progress!.maxHp++;
      _progress!.hp++;
    }

    _progress!.completedNodeIndices.add(index);
    _towerRepo.saveProgress(_progress!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎁 获得：$reward！'),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 2),
      ),
    );

    _checkAllNodesComplete();
  }

  // ============================================================
  // ✅ 陷阱
  // ============================================================
  void _handleTrap(int index) {
    final damage = 1 + (_progress!.currentFloor ~/ 10);
    _progress!.hp -= damage;
    _progress!.completedNodeIndices.add(index);
    _towerRepo.saveProgress(_progress!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ 陷阱！损失 $damage 点生命值！'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    if (_progress!.hp <= 0) {
      _showFloorFailed = true;
      setState(() {});
      return;
    }

    _checkAllNodesComplete();
  }

  // ============================================================
  // ✅ 商店
  // ============================================================
  void _handleShop(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.store, color: Colors.cyan, size: 28),
            SizedBox(width: 10),
            Text(
              '🏪 商店',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '用你的道具换取奖励：',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _buildShopItem('🧪 生命药水 ×1', '❤️ 恢复3点生命', () {
              if (_progress!.appleCount > 0) {
                _progress!.appleCount--;
                _progress!.hp = (_progress!.hp + 3).clamp(0, _progress!.maxHp);
                _towerRepo.saveProgress(_progress!);
                Navigator.pop(dialogContext);
                _progress!.completedNodeIndices.add(index);
                _towerRepo.saveProgress(_progress!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❤️ 恢复3点生命值！'),
                    backgroundColor: Colors.green,
                  ),
                );
                _checkAllNodesComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('没有生命药水！'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }),
            const SizedBox(height: 8),
            _buildShopItem('🛡️ 护盾 ×1', '🛡️ 免疫下一次攻击', () {
              if (_progress!.shieldCount > 0) {
                _progress!.shieldCount--;
                _hasShield = true;
                _towerRepo.saveProgress(_progress!);
                Navigator.pop(dialogContext);
                _progress!.completedNodeIndices.add(index);
                _towerRepo.saveProgress(_progress!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🛡️ 护盾已激活！'),
                    backgroundColor: Colors.blue,
                  ),
                );
                _checkAllNodesComplete();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('没有护盾！'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text('离开'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(String label, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.deepPurple[600]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ 休息节点
  // ============================================================
  void _showRestNodeDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text(
              '⛺ 休息点',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '❤️ ${_progress!.hp}/${_progress!.maxHp}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              '在这里休息可以恢复全部生命值！',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _progress!.hp = _progress!.maxHp;
              _progress!.completedNodeIndices.add(index);
              _towerRepo.saveProgress(_progress!);
              Navigator.pop(dialogContext);
              _checkAllNodesComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('⛺ 休息'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 事件节点（修复：完成后自动跳转）
  // ============================================================
  void _showEventNode(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              '❓ 神秘事件',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: const Text(
          '你遇到了一位流浪商人，他愿意用一件道具交换你的一个随机道具。\n\n是否接受？',
          style: TextStyle(color: Colors.white70, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // 跳过事件，直接标记完成
              _progress!.completedNodeIndices.add(index);
              _towerRepo.saveProgress(_progress!);
              _checkAllNodesComplete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text('跳过'),
          ),
          ElevatedButton(
            onPressed: () {
              // 随机交换道具
              final items = ['appleCount', 'shieldCount', 'doubleExpCount'];
              final randomItem = items[DateTime.now().millisecondsSinceEpoch % items.length];
              if (randomItem == 'appleCount') {
                if (_progress!.appleCount > 0) {
                  _progress!.appleCount--;
                  _progress!.shieldCount++;
                } else {
                  // 如果没有苹果，给一个盾牌
                  _progress!.shieldCount++;
                }
              } else if (randomItem == 'shieldCount') {
                if (_progress!.shieldCount > 0) {
                  _progress!.shieldCount--;
                  _progress!.doubleExpCount++;
                } else {
                  _progress!.doubleExpCount++;
                }
              } else {
                if (_progress!.doubleExpCount > 0) {
                  _progress!.doubleExpCount--;
                  _progress!.appleCount++;
                } else {
                  _progress!.appleCount++;
                }
              }
              _progress!.completedNodeIndices.add(index);
              _towerRepo.saveProgress(_progress!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 交易成功！'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
              _checkAllNodesComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('接受交易'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 检查所有节点是否完成（修复：正确推进层数）
  // ============================================================
  void _checkAllNodesComplete() {
    if (_progress == null) return;

    if (_progress!.isAllNodesCompleted) {
      // 进入下一层
      _progress!.currentFloor++;
      _progress!.resetFloor();
      _progress!.floorNodeCount = 3 + ((_progress!.currentFloor - 1) % 3) + (_progress!.isBossFloor ? 1 : 0);
      if (_progress!.currentFloor > _progress!.maxFloor) {
        _progress!.maxFloor = _progress!.currentFloor;
      }
      _towerRepo.saveProgress(_progress!);

      setState(() {
        _showFloorComplete = false;
        _isInBattle = false;
        _isBossBattle = false;
        _isAnswered = false;
        _feedbackMessage = null;
        _selectedNodeIndex = -1;
        _selectedNodeType = null;
        _currentQuestion = null;
        _isLoading = false;
      });

      // 加载新题目
      _loadQuestions().then((_) {
        if (mounted) {
          setState(() {
            if (_availableQuestions.isNotEmpty) {
              _currentQuestion = _availableQuestions[0];
              _progress!.currentQuestionIndex = 0;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 进入第 ${_progress!.currentFloor} 层！'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      // 当前层还有节点未完成，重置战斗状态
      setState(() {
        _isInBattle = false;
        _selectedNodeIndex = -1;
        _selectedNodeType = null;
        _currentQuestion = null;
        _isAnswered = false;
        _feedbackMessage = null;
      });
      // 自动进入下一个未完成的节点
      _autoAdvanceNode();
    }
  }

  // ============================================================
  // ✅ 自动跳转到下一个未完成节点
  // ============================================================
  void _autoAdvanceNode() {
    if (_progress == null) return;
    for (int i = 0; i < _progress!.floorNodeCount; i++) {
      if (!_progress!.isNodeCompleted(i) && _progress!.isNodeAccessible(i)) {
        _progress!.currentNodeIndex = i;
        _towerRepo.saveProgress(_progress!);
        // 自动触发节点点击
        _onNodeTap(i);
        break;
      }
    }
  }

  // ============================================================
  // ✅ 开始战斗
  // ============================================================
  void _startBattle(int index, TowerNodeType type) {
    if (_currentQuestion == null && _availableQuestions.isEmpty) {
      _loadQuestions().then((_) {
        if (_currentQuestion != null && mounted) {
          _startBattle(index, type);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有可用的题目！'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      return;
    }

    setState(() {
      _selectedNodeIndex = index;
      _selectedNodeType = type;
      _isInBattle = true;
      _isBossBattle = (type == TowerNodeType.boss);
      _isAnswered = false;
      _feedbackMessage = null;
      _showFloorComplete = false;
      _showFloorFailed = false;
      _progress!.correctCount = 0;
      _progress!.wrongCount = 0;
    });

    _towerRepo.saveProgress(_progress!);
  }

  // ============================================================
  // ✅ Boss战斗特殊逻辑
  // ============================================================
  void _handleBossAnswer(Question question, bool isCorrect) {
    final bossHp = _progress!.getBossHp();

    if (isCorrect) {
      _progress!.correctCount++;
      _progress!.totalCorrect++;
      _feedbackMessage = '💥 攻击魔王！(${_progress!.correctCount}/$bossHp)';
      _feedbackColor = Colors.orange;
    } else {
      _progress!.wrongCount++;
      _progress!.totalWrong++;
      _progress!.hp--;
      _feedbackMessage = '💔 被魔王反击了！\n🗡️ 正确答案：${_getCorrectAnswerText(question)}';
      _feedbackColor = Colors.red;

      if (_progress!.hp <= 0) {
        _showFloorFailed = true;
        _towerRepo.saveProgress(_progress!);
        setState(() {});
        return;
      }
    }

    if (!_progress!.usedQuestionIds.contains(question.id)) {
      _progress!.usedQuestionIds.add(question.id);
    }

    _towerRepo.saveProgress(_progress!);

    if (_progress!.correctCount >= bossHp) {
      // Boss击败！
      _progress!.completedNodeIndices.add(_selectedNodeIndex);
      _progress!.hp = (_progress!.hp + 2).clamp(0, _progress!.maxHp);
      _towerRepo.saveProgress(_progress!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👑 魔王被击败了！'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _showFloorComplete = true;
        _isInBattle = false;
        _isBossBattle = false;
        _isAnswered = false;
        _feedbackMessage = null;
      });
      // 延迟检查是否所有节点完成
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkAllNodesComplete();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  // ============================================================
  // ✅ 普通战斗逻辑
  // ============================================================
  void _handleNormalAnswer(Question question, bool isCorrect) {
    final requiredCorrect = (_selectedNodeType == TowerNodeType.elite) ? 2 : 2;

    if (isCorrect) {
      _progress!.correctCount++;
      _progress!.totalCorrect++;
      _feedbackMessage = '💥 击败了怪物！';
      _feedbackColor = Colors.green;
    } else {
      _progress!.wrongCount++;
      _progress!.totalWrong++;
      _progress!.hp--;
      _feedbackMessage = '💔 被怪物击中了！\n🗡️ 正确答案：${_getCorrectAnswerText(question)}';
      _feedbackColor = Colors.red;

      if (_progress!.hp <= 0) {
        _showFloorFailed = true;
        _towerRepo.saveProgress(_progress!);
        setState(() {});
        return;
      }
    }

    if (!_progress!.usedQuestionIds.contains(question.id)) {
      _progress!.usedQuestionIds.add(question.id);
    }

    _towerRepo.saveProgress(_progress!);

    if (_progress!.correctCount >= requiredCorrect) {
      // 战斗胜利
      _progress!.completedNodeIndices.add(_selectedNodeIndex);

      if (_selectedNodeType == TowerNodeType.elite) {
        _progress!.appleCount++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💀 精英奖励：获得一瓶生命药水！'),
            backgroundColor: Colors.purple,
            duration: Duration(seconds: 2),
          ),
        );
      }

      _towerRepo.saveProgress(_progress!);

      setState(() {
        _showFloorComplete = true;
        _isInBattle = false;
        _isAnswered = false;
        _feedbackMessage = null;
      });
      // 延迟检查
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkAllNodesComplete();
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  // ============================================================
  // ✅ 答题入口
  // ============================================================
  void _handleAnswer(Question question, bool isCorrect) {
    if (_isAnswered) return;
    if (_progress == null) return;
    if (_showFloorComplete || _showFloorFailed) return;

    setState(() {
      _isAnswered = true;
    });

    if (_isBossBattle) {
      _handleBossAnswer(question, isCorrect);
    } else {
      _handleNormalAnswer(question, isCorrect);
    }
  }

  // ============================================================
  // ✅ 下一题
  // ============================================================
  void _nextQuestion() {
    if (_progress == null) return;

    _progress!.currentQuestionIndex++;
    if (_progress!.currentQuestionIndex >= _availableQuestions.length) {
      _progress!.currentQuestionIndex = 0;
      _progress!.usedQuestionIds.clear();
    }

    if (_progress!.currentQuestionIndex < _availableQuestions.length) {
      _currentQuestion = _availableQuestions[_progress!.currentQuestionIndex];
    } else {
      _currentQuestion = null;
    }

    setState(() {
      _isAnswered = false;
      _feedbackMessage = null;
      _fillAnswers.clear();
    });

    _towerRepo.saveProgress(_progress!);
  }

  // ============================================================
  // ✅ 继续冒险（修复：直接推进到下一层）
  // ============================================================
  void _continueAfterComplete() {
    if (_progress == null) return;

    setState(() {
      _showFloorComplete = false;
      _isInBattle = false;
      _isBossBattle = false;
      _isAnswered = false;
      _feedbackMessage = null;
      _selectedNodeIndex = -1;
      _selectedNodeType = null;
      _currentQuestion = null;
    });

    _checkAllNodesComplete();
  }

  // ============================================================
  // ✅ 返回上一层
  // ============================================================
  void _goBackFloor() {
    if (_progress == null) return;

    if (_progress!.currentFloor > 1) {
      _progress!.currentFloor--;
      _progress!.resetFloor();
      _progress!.currentQuestionIndex = 0;
      _towerRepo.saveProgress(_progress!);
      _loadData();
    } else {
      _progress!.resetFloor();
      _progress!.currentQuestionIndex = 0;
      _towerRepo.saveProgress(_progress!);
      _loadData();
    }
  }

  // ============================================================
  // ✅ 辅助方法
  // ============================================================
  String _getCorrectAnswerText(Question question) {
    final isJudge = question.options.length == 2 &&
        question.options.contains('正确') &&
        question.options.contains('错误');
    if (isJudge) {
      return question.correctIndex == 0 ? '正确' : '错误';
    }

    final isFill = question.options.length == 1 &&
        question.options.first.contains('填空');
    if (isFill) {
      return question.answer ?? '（未设置答案）';
    }

    if (question.correctIndex < question.options.length) {
      return question.options[question.correctIndex];
    }

    return '（无法获取正确答案）';
  }

  // ============================================================
  // ✅ 重置、称号、背包
  // ============================================================
  void _resetTower() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.deepPurple[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              '🗑️ 重置冒险？',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: const Text(
          '⚠️ 冒险者，确定要重置所有进度吗？\n\n这将清空所有层数和道具！',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _towerRepo.resetProgress();
              _progress = TowerProgress();
              _fillAnswers.clear();
              await _towerRepo.saveProgress(_progress!);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗡️ 冒险已重置，从第1层开始！'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete),
            label: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog() {
    if (_progress == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.deepPurple[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text(
              '🏆 称号图鉴',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView(
            shrinkWrap: true,
            children: _getAllAchievements().map((ach) {
              final isUnlocked = ach['unlocked'] as bool;
              return ListTile(
                leading: Text(ach['icon'] as String, style: const TextStyle(fontSize: 28)),
                title: Text(
                  ach['name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                    color: isUnlocked ? Colors.green.shade300 : Colors.grey.shade500,
                  ),
                ),
                subtitle: Text(
                  ach['desc'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnlocked ? Colors.green.shade400 : Colors.grey.shade500,
                  ),
                ),
                trailing: isUnlocked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.lock_outline, color: Colors.grey.shade500),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
            child: const Text('关闭图鉴'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllAchievements() {
    final maxFloor = _progress?.maxFloor ?? 0;

    return [
      {'icon': '🗡️', 'name': '初心勇者', 'desc': '到达第 1 层', 'need': 1},
      {'icon': '🛡️', 'name': '基石护卫', 'desc': '到达第 5 层', 'need': 5},
      {'icon': '⚔️', 'name': '翡翠剑士', 'desc': '到达第 10 层', 'need': 10},
      {'icon': '💎', 'name': '钻石骑士', 'desc': '到达第 20 层', 'need': 20},
      {'icon': '🔥', 'name': '烈焰领主', 'desc': '到达第 40 层', 'need': 40},
      {'icon': '🧙', 'name': '博学法师', 'desc': '到达第 60 层', 'need': 60},
      {'icon': '🏅', 'name': '殿堂英雄', 'desc': '到达第 80 层', 'need': 80},
      {'icon': '👑', 'name': '传说勇者', 'desc': '到达第 100 层', 'need': 100},
    ].map((ach) {
      return {
        ...ach,
        'unlocked': maxFloor >= (ach['need'] as num).toInt(),
      };
    }).toList();
  }

  void _showItemDialog() {
    if (_progress == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.deepPurple.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎒 冒险背包',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildItemButton(
              icon: '🧪',
              name: '生命药水',
              count: _progress!.appleCount,
              desc: '恢复 1 点生命值',
              color: Colors.red,
              onTap: () {
                if (_progress!.useApple()) {
                  _towerRepo.saveProgress(_progress!);
                  Navigator.pop(bottomContext);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❤️ 生命药水已使用！'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('没有生命药水或生命已满！'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            _buildItemButton(
              icon: '🛡️',
              name: '护盾',
              count: _progress!.shieldCount,
              desc: '免疫下一次攻击',
              color: Colors.blue,
              onTap: () {
                if (_progress!.useShield()) {
                  _towerRepo.saveProgress(_progress!);
                  Navigator.pop(bottomContext);
                  _hasShield = true;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛡️ 护盾已激活！'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('没有护盾！'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            _buildItemButton(
              icon: '💥',
              name: '双倍攻击',
              count: _progress!.doubleExpCount,
              desc: '下次攻击造成 2 倍伤害',
              color: Colors.amber,
              onTap: () {
                if (_progress!.useDoubleExp()) {
                  _towerRepo.saveProgress(_progress!);
                  Navigator.pop(bottomContext);
                  _hasDoubleExpActive = true;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💥 双倍攻击已激活！'),
                      backgroundColor: Colors.amber,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('没有双倍攻击！'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(bottomContext),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text('关闭背包'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemButton({
    required String icon,
    required String name,
    required int count,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 32)),
      title: Text(
        '$name × $count',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: count > 0 ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
        ),
        child: Text(count > 0 ? '使用' : '无'),
      ),
    );
  }

  // ============================================================
  // ✅ 退出确认
  // ============================================================
  Future<bool> _onWillPop() async {
    if (_progress == null) return true;
    if (_showFloorComplete || _showFloorFailed) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.deepPurple[400]!, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              '⚔️ 离开冒险？',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 冒险者，你确定要离开吗？',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple[600]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📜 当前战报：',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('🏰 第 ${_progress!.currentFloor} 层', style: const TextStyle(color: Colors.white70)),
                  Text('💥 击败 ${_progress!.correctCount} 个怪物', style: const TextStyle(color: Colors.white70)),
                  Text('💔 被击中 ${_progress!.wrongCount} 次', style: const TextStyle(color: Colors.white70)),
                  Text('❤️ ${_progress!.hp}/${_progress!.maxHp}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择你的行动：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade300,
            ),
            child: const Text('⚔️ 继续战斗'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text('💾 保存退出'),
          ),
          TextButton(
            onPressed: () {
              _progress!.resetFloor();
              _towerRepo.saveProgress(_progress!);
              Navigator.pop(dialogContext, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade300,
            ),
            child: const Text('🗑️ 放弃本层'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ============================================================
  // ✅ Build（UI优化）
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (_progress != null && _availableQuestions.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadQuestions();
      });
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade900,
        appBar: AppBar(
          title: const Text('⚔️ 冒险之塔'),
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.deepPurple.shade900,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _onWillPop();
              if (shouldExit) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.backpack, color: Colors.amber),
              onPressed: _showItemDialog,
              tooltip: '🎒 背包',
            ),
            IconButton(
              icon: const Icon(Icons.emoji_events, color: Colors.amber),
              onPressed: _showAchievementsDialog,
              tooltip: '🏆 称号',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: '刷新',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _resetTower,
              tooltip: '🗑️ 重置冒险',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _availableQuestions.isEmpty || _currentQuestion == null
            ? _buildEmptyState(context)
            : _buildContent(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 64, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text(
              '没有怪物可打',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请先导入一些题目再挑战吧！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('🏠 回到营地'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final progress = _progress!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 顶部状态栏
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade600),
                ),
                child: Text(
                  '🏆 ${progress.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    ...List.generate(progress.maxHp, (index) {
                      return Icon(
                        index < progress.hp ? Icons.favorite : Icons.favorite_border,
                        color: index < progress.hp ? Colors.red : Colors.grey,
                        size: 16,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 地图
          TowerMapWidget(
            progress: progress,
            onNodeTap: _onNodeTap,
          ),
          const SizedBox(height: 10),

          // 战斗区域
          if (_isInBattle && _currentQuestion != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 战斗标题
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBattleColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getBattleColor(), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _getBattleColor().withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getBattleLabel(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getBattleColor(),
                            ),
                          ),
                          if (_isBossBattle) ...[
                            const SizedBox(width: 8),
                            Text(
                              '❤️ ${_progress!.correctCount}/${_progress!.getBossHp()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 题目卡片（毛玻璃效果）
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade800.withOpacity(0.8),
                            Colors.deepPurple.shade700.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.deepPurple.shade400.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.shade900.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TowerQuestionCard(
                          key: ValueKey(_currentQuestion!.id),
                          question: _currentQuestion!,
                          currentIndex: progress.currentQuestionIndex,
                          total: _availableQuestions.length,
                          fillAnswer: _fillAnswers[_currentQuestion!.id] ?? '',
                          onFillChanged: (value) {
                            setState(() {
                              _fillAnswers[_currentQuestion!.id] = value;
                            });
                          },
                          onAnswerSelected: (question, isCorrect) {
                            _handleAnswer(question, isCorrect);
                          },
                          isAnswered: _isAnswered,
                          selectedOption: _isAnswered ? _currentQuestion!.selectedOption : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 反馈信息
                    if (_feedbackMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _feedbackColor?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _feedbackColor ?? Colors.transparent, width: 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _feedbackMessage!.split('\n')[0],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _feedbackColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_feedbackMessage!.contains('\n'))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _feedbackMessage!.split('\n')[1],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _feedbackColor?.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // 战斗进度条（能量条风格）
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade800,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.shade600),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isBossBattle
                                ? '👑 魔王血量 ${_progress!.correctCount}/${_progress!.getBossHp()}'
                                : '🎯 需要击败 2 个怪物',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '⚔️ ${_progress!.correctCount}/${_isBossBattle ? _progress!.getBossHp() : 2}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_isInBattle && _currentQuestion == null) ...[
            const Expanded(
              child: Center(
                child: Text(
                  '⚔️ 加载题目中...',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],

          // 完成/失败弹窗
          if (_showFloorComplete)
            _buildCompleteDialog(),
          if (_showFloorFailed)
            _buildFailedDialog(),
        ],
      ),
    );
  }

  Color _getBattleColor() {
    if (_isBossBattle) return Colors.red;
    if (_selectedNodeType == TowerNodeType.elite) return Colors.deepPurple;
    return Colors.blue;
  }

  String _getBattleLabel() {
    if (_isBossBattle) return '👑 ${_progress!.getBossName()}';
    if (_selectedNodeType == TowerNodeType.elite) return '💀 精英战';
    return '⚔️ 普通战斗';
  }

  Widget _buildCompleteDialog() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.5),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            _isBossBattle ? '👑 魔王被击败了！' : '🎉 胜利！',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _continueAfterComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                ),
                child: const Text('继续冒险'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('回到营地'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedDialog() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            '💀 败北...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _progress!.currentFloor == 1
                ? '没关系，再来一次！'
                : '回到第 ${_progress!.currentFloor - 1} 层重新挑战',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _goBackFloor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                ),
                child: const Text('重新挑战'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('回到营地'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}