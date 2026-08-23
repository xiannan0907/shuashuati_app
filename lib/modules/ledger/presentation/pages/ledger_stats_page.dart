import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ledger_bloc.dart';

/// 收支统计页：月度总览 + 支出/收入构成饼图 + 每日支出趋势折线
class LedgerStatsPage extends StatelessWidget {
  const LedgerStatsPage({super.key});

  static const brandBlue = Color(0xFF1565C0);

  /// 分类 colorKey → 颜色
  static const Map<String, Color> _keyColors = {
    'orange': Colors.orange,
    'blue': Colors.blue,
    'purple': Colors.purple,
    'deepPurple': Colors.deepPurple,
    'teal': Colors.teal,
    'red': Colors.red,
    'green': Colors.green,
    'pink': Colors.pink,
    'brown': Colors.brown,
    'grey': Colors.grey,
  };

  /// 无 colorKey 分类时的调色板
  static const List<Color> _palette = [
    Color(0xFF1565C0), Color(0xFFEF6C00), Color(0xFF2E7D32),
    Color(0xFF6A1B9A), Color(0xFF00838F), Color(0xFFC62828),
    Color(0xFFF9A825), Color(0xFF4527A0), Color(0xFFAD1457),
    Color(0xFF5D4037),
  ];

  static Color _colorOf(int index, String? colorKey) {
    if (colorKey != null && _keyColors.containsKey(colorKey)) {
      return _keyColors[colorKey]!;
    }
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('📊 收支统计'),
      ),
      body: BlocBuilder<LedgerBloc, LedgerLoaded?>(
        builder: (context, state) {
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _monthSwitcher(context, isDark, state.month),
              const SizedBox(height: 12),
              _summaryCard(isDark, state),
              const SizedBox(height: 14),
              if (state.expenseByCategory.isNotEmpty) ...[
                _pieCard(
                  context,
                  isDark,
                  title: '支出构成',
                  items: state.expenseByCategory,
                  total: state.expenseCents,
                ),
                const SizedBox(height: 14),
              ],
              if (state.incomeByCategory.isNotEmpty) ...[
                _pieCard(
                  context,
                  isDark,
                  title: '收入构成',
                  items: state.incomeByCategory,
                  total: state.incomeCents,
                ),
                const SizedBox(height: 14),
              ],
              _dailyTrendCard(isDark, state),
            ],
          );
        },
      ),
    );
  }

  // ── 月份切换 ──
  Widget _monthSwitcher(BuildContext context, bool isDark, String month) {
    void shift(int delta) {
      final parts = month.split('-');
      var y = int.parse(parts[0]);
      var m = int.parse(parts[1]) + delta;
      while (m > 12) { m -= 12; y++; }
      while (m < 1) { m += 12; y--; }
      context.read<LedgerBloc>().add(LedgerMonthChanged('$y-${m.toString().padLeft(2, '0')}'));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => shift(-1),
          icon: Icon(Icons.chevron_left,
              color: isDark ? Colors.white70 : Colors.grey.shade700),
        ),
        Text(month,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800)),
        IconButton(
          onPressed: () => shift(1),
          icon: Icon(Icons.chevron_right,
              color: isDark ? Colors.white70 : Colors.grey.shade700),
        ),
      ],
    );
  }

  // ── 月度总览 ──
  Widget _summaryCard(bool isDark, LedgerLoaded s) {
    String yuan(int cents) => (cents / 100).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade900, Colors.indigo.shade900]
              : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _statCol('收入', '¥${yuan(s.incomeCents)}')),
          Expanded(child: _statCol('支出', '¥${yuan(s.expenseCents)}')),
          Expanded(
              child: _statCol('结余', '¥${yuan(s.incomeCents - s.expenseCents)}',
                  valueColor: s.incomeCents - s.expenseCents < 0
                      ? Colors.orangeAccent.shade100
                      : Colors.yellowAccent.shade100)),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
      ],
    );
  }

  // ── 构成饼图卡 ──
  Widget _pieCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required List<LedgerSummaryItem> items,
    required int total,
  }) {
    final shown = items.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 54,
                    sections: [
                      for (var i = 0; i < shown.length; i++)
                        PieChartSectionData(
                          value: shown[i].totalCents.toDouble(),
                          color: _colorOf(i, null),
                          radius: 36,
                          title: (shown[i].percent * 100) >= 5
                              ? '${(shown[i].percent * 100).toStringAsFixed(0)}%'
                              : '',
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('总计',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500)),
                    Text('¥${(total / 100).toStringAsFixed(total % 100 == 0 ? 0 : 2)}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : Colors.grey.shade800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...shown.take(5).map((s) {
            final idx = shown.indexOf(s);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: _colorOf(idx, null), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${s.icon} ${s.name.contains(' ') ? s.name.substring(s.name.indexOf(' ') + 1) : s.name}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700)),
                  ),
                  Text(
                      '¥${(s.totalCents / 100).toStringAsFixed(2)}'
                      ' · ${(s.percent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white70 : Colors.grey.shade800)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 每日支出趋势折线 ──
  Widget _dailyTrendCard(bool isDark, LedgerLoaded s) {
    final parts = s.month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final daysInMonth = DateTime(year, monthNum + 1, 0).day;

    final daily = List<double>.filled(daysInMonth + 1, 0);
    for (final t in s.transactions) {
      if (t.type == 'expense') {
        daily[t.date.day] += t.amountCents / 100;
      }
    }
    final spots = [
      for (var d = 1; d <= daysInMonth; d++) FlSpot(d.toDouble(), daily[d]),
    ];
    final maxVal = daily.reduce((a, b) => a > b ? a : b);

    Color axisColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每日支出趋势（元）',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800)),
          const SizedBox(height: 6),
          if (s.expenseCents == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('本月暂无支出记录',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 3 : 1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: axisColor.withValues(alpha: 0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) => Text(
                          v >= 1000
                              ? '${(v / 1000).toStringAsFixed(1)}k'
                              : v.toStringAsFixed(0),
                          style: TextStyle(fontSize: 10, color: axisColor),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final day = v.toInt();
                          const marks = [1, 5, 10, 15, 20, 25];
                          if (!marks.contains(day) && day != daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$day',
                                style: TextStyle(
                                    fontSize: 10, color: axisColor)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((sp) => LineTooltipItem(
                                '${sp.x.toInt()}日 ¥${sp.y.toStringAsFixed(2)}',
                                const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: brandBlue,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: brandBlue.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
