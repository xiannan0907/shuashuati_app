import 'package:flutter/material.dart';
import '../../data/models/tower_model.dart';

class TowerMapWidget extends StatelessWidget {
  final TowerProgress progress;
  final Function(int) onNodeTap;

  const TowerMapWidget({
    super.key,
    required this.progress,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodeCount = progress.floorNodeCount;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade900.withValues(alpha: 0.6), Colors.deepPurple.shade800.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade400.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade900.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏰 第 ${progress.currentFloor} 层',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.blue, blurRadius: 6),
                    ],
                  ),
                ),
                Text(
                  '🗡️ ${progress.completedNodeIndices.length}/$nodeCount',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // 连线
                    CustomPaint(
                      size: Size(constraints.maxWidth, 110),
                      painter: TowerLinePainter(
                        nodeCount: nodeCount,
                        completedIndices: progress.completedNodeIndices,
                        currentIndex: progress.currentNodeIndex,
                      ),
                    ),
                    // 节点
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(nodeCount, (index) {
                        final type = progress.getNodeType(index);
                        final isCompleted = progress.isNodeCompleted(index);
                        final isCurrent = progress.isCurrentNode(index);
                        final isAccessible = progress.isNodeAccessible(index);

                        return GestureDetector(
                          onTap: () {
                            if (isAccessible && !isCompleted) {
                              onNodeTap(index);
                            }
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isCurrent
                                      ? const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : (isCompleted
                                      ? LinearGradient(
                                    colors: [Colors.green.shade700, Colors.green.shade500],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : (isAccessible
                                      ? LinearGradient(
                                    colors: [
                                      progress.getNodeColor(type),
                                      progress.getNodeColor(type).withValues(alpha: 0.5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : LinearGradient(
                                    colors: [Colors.grey.shade700, Colors.grey.shade500],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ))),
                                  border: Border.all(
                                    color: isCurrent
                                        ? Colors.amber.shade700
                                        : (isCompleted
                                        ? Colors.green.shade300
                                        : (isAccessible
                                        ? Colors.white54
                                        : Colors.grey.shade600)),
                                    width: isCurrent ? 3 : 1.5,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                      : (isCompleted
                                      ? [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                      : []),
                                ),
                                child: Center(
                                  child: Text(
                                    progress.getNodeIcon(type),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getNodeLabel(type),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isAccessible
                                      ? (isCurrent ? Colors.amber : Colors.white70)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getNodeLabel(TowerNodeType type) {
    switch (type) {
      case TowerNodeType.normal: return '战斗';
      case TowerNodeType.elite: return '精英';
      case TowerNodeType.boss: return 'Boss';
      case TowerNodeType.rest: return '休息';
      case TowerNodeType.event: return '事件';
      case TowerNodeType.treasure: return '宝箱';
      case TowerNodeType.trap: return '陷阱';
      case TowerNodeType.shop: return '商店';
    }
  }
}

// ============================================================
// 路线连线绘制器（增强视觉效果）
// ============================================================

class TowerLinePainter extends CustomPainter {
  final int nodeCount;
  final List<int> completedIndices;
  final int currentIndex;

  TowerLinePainter({
    required this.nodeCount,
    required this.completedIndices,
    required this.currentIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final spacing = size.width / (nodeCount + 1);

    for (int i = 0; i < nodeCount - 1; i++) {
      final x1 = spacing * (i + 1);
      final x2 = spacing * (i + 2);

      final bool isCompleted = completedIndices.contains(i) && completedIndices.contains(i + 1);
      final bool isActive = (i == currentIndex - 1 && completedIndices.contains(i)) ||
          (i == currentIndex && completedIndices.contains(i - 1));

      // 绘制发光连线
      if (isCompleted || isActive) {
        // 外层发光
        paint.color = (isCompleted ? Colors.green : Colors.amber).withValues(alpha: 0.3);
        paint.strokeWidth = 6;
        canvas.drawLine(Offset(x1, centerY), Offset(x2, centerY), paint);

        // 主线
        paint.color = isCompleted ? Colors.green.shade400 : Colors.amber.shade400;
        paint.strokeWidth = 3;
        canvas.drawLine(Offset(x1, centerY), Offset(x2, centerY), paint);
      } else {
        // 未完成路线
        paint.color = Colors.grey.shade700;
        paint.strokeWidth = 2;
        canvas.drawLine(Offset(x1, centerY), Offset(x2, centerY), paint);

        // 虚线效果
        const dashWidth = 4;
        const dashSpace = 4;
        double startX = x1;
        while (startX < x2) {
          canvas.drawLine(
            Offset(startX, centerY),
            Offset(startX + dashWidth, centerY),
            paint,
          );
          startX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}