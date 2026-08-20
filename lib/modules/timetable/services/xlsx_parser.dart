import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../data/models/course_model.dart';
import '../utils/color_manager.dart';

/// 手动解析 xlsx 文件（支持矩阵式课表）
class XlsxParser {
  Future<List<Course>> parse(File file) async {
    debugPrint('📂 开始手动解析 xlsx...');

    final bytes = await file.readAsBytes();
    debugPrint('📖 文件大小: ${bytes.length} 字节');

    final archive = ZipDecoder().decodeBytes(bytes);
    debugPrint('📦 解压成功，文件数: ${archive.files.length}');

    final sharedStrings = _readSharedStrings(archive);
    final rows = _readSheet(archive, sharedStrings);

    if (rows.isEmpty) {
      throw Exception('没有数据行');
    }

    debugPrint('📊 读取到 ${rows.length} 行数据');

    // 重置颜色索引
    ColorManager.resetIndex();

    return _parseMatrixRows(rows);
  }

  List<String> _readSharedStrings(Archive archive) {
    try {
      final file = archive.findFile('xl/sharedStrings.xml');
      if (file == null) {
        debugPrint('⚠️ 未找到 sharedStrings.xml，使用空列表');
        return [];
      }

      final content = utf8.decode(file.content as List<int>);
      final document = XmlDocument.parse(content);

      final strings = <String>[];
      for (var element in document.findAllElements('si')) {
        final text = element.findElements('t').map((e) => e.innerText).join('');
        strings.add(text);
      }

      debugPrint('📋 共享字符串数: ${strings.length}');
      return strings;
    } catch (e) {
      debugPrint('⚠️ 读取共享字符串失败: $e');
      return [];
    }
  }

  List<List<String>> _readSheet(Archive archive, List<String> sharedStrings) {
    try {
      ArchiveFile? sheetFile;
      for (var file in archive.files) {
        if (file.name.contains('xl/worksheets/sheet') &&
            file.name.endsWith('.xml')) {
          sheetFile = file;
          break;
        }
      }

      if (sheetFile == null) {
        throw Exception('未找到工作表文件');
      }

      debugPrint('📄 找到工作表: ${sheetFile.name}');

      final content = utf8.decode(sheetFile.content as List<int>);
      final document = XmlDocument.parse(content);

      final rows = <List<String>>[];
      int maxCols = 0;

      for (var rowElement in document.findAllElements('row')) {
        final rowData = <String>[];
        int? lastColIndex;

        for (var cellElement in rowElement.findElements('c')) {
          final ref = cellElement.getAttribute('r') ?? '';
          final colIndex = _colIndexFromRef(ref);

          if (lastColIndex != null) {
            for (int i = lastColIndex + 1; i < colIndex; i++) {
              rowData.add('');
            }
          }

          String value = '';
          final type = cellElement.getAttribute('t');

          final inlineStr = cellElement.findElements('is');
          if (inlineStr.isNotEmpty) {
            final text = inlineStr.first.findElements('t').map((e) => e.innerText).join('');
            value = text;
          } else {
            final cellValue = cellElement.findElements('v').firstOrNull;
            if (cellValue != null) {
              if (type == 's') {
                final index = int.tryParse(cellValue.innerText) ?? -1;
                if (index >= 0 && index < sharedStrings.length) {
                  value = sharedStrings[index];
                } else {
                  value = cellValue.innerText;
                }
              } else {
                value = cellValue.innerText;
              }
            }
          }

          rowData.add(value.trim());
          lastColIndex = colIndex;
          if (colIndex > maxCols) maxCols = colIndex;
        }

        if (rowData.isNotEmpty && rowData.any((s) => s.isNotEmpty)) {
          while (rowData.length <= maxCols) {
            rowData.add('');
          }
          rows.add(rowData);
        }
      }

      for (var row in rows) {
        while (row.length < maxCols + 1) {
          row.add('');
        }
      }

      debugPrint('📊 读取到 ${rows.length} 行，${maxCols + 1} 列');
      return rows;

    } catch (e, stack) {
      debugPrint('❌ 读取工作表失败: $e');
      debugPrint(stack.toString());
      throw Exception('读取工作表失败: $e');
    }
  }

  int _colIndexFromRef(String ref) {
    if (ref.isEmpty) return 0;
    final match = RegExp(r'^([A-Z]+)').firstMatch(ref);
    if (match == null) return 0;

    final letters = match.group(1)!;
    int index = 0;
    for (int i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 64);
    }
    return index - 1;
  }

  // ============================================================
  // 矩阵式课表解析核心
  // ============================================================

  List<Course> _parseMatrixRows(List<List<String>> rows) {
    if (rows.length < 3) {
      throw Exception('数据行不足');
    }

    // 打印前5行
    debugPrint('📋 前5行数据:');
    for (int i = 0; i < rows.length && i < 5; i++) {
      debugPrint('  行 $i: ${rows[i].take(10).join(' | ')}');
    }

    // ============================================================
    // 第一步：找到表头行（包含"星期一"的行）
    // ============================================================
    int headerRowIndex = -1;
    for (int i = 0; i < rows.length && i < 20; i++) {
      final rowText = rows[i].join('');
      if (rowText.contains('星期一')) {
        headerRowIndex = i;
        debugPrint('✅ 找到表头行: 第 ${i + 1} 行');
        break;
      }
    }

    if (headerRowIndex == -1) {
      for (int i = 0; i < rows.length && i < 20; i++) {
        final rowText = rows[i].join('');
        if (rowText.contains('周') && rowText.contains('节')) {
          headerRowIndex = i;
          debugPrint('✅ 找到表头行(备用): 第 ${i + 1} 行');
          break;
        }
      }
    }

    if (headerRowIndex == -1) {
      throw Exception('未找到表头行（应包含"星期一"）');
    }

    final header = rows[headerRowIndex];
    debugPrint('📋 表头: ${header.take(10).join(' | ')}');

    // ============================================================
    // 第二步：找到星期列
    // ============================================================
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final Map<int, int> weekdayColMap = {};

    for (int col = 0; col < header.length; col++) {
      final val = header[col];
      for (int i = 0; i < weekdays.length; i++) {
        if (val.contains(weekdays[i])) {
          weekdayColMap[col] = i + 1;
          debugPrint('  列 $col -> ${weekdays[i]}');
          break;
        }
      }
    }

    if (weekdayColMap.isEmpty) {
      throw Exception('未找到星期列');
    }

    // ============================================================
    // 第三步：找到"节"列
    // ============================================================
    int slotCol = -1;
    for (int col = 0; col < header.length; col++) {
      final val = header[col];
      if (val.contains('节') || val.contains('时间') || val.contains('第')) {
        slotCol = col;
        debugPrint('✅ 节次列: 列 $col');
        break;
      }
    }
    if (slotCol == -1) {
      slotCol = 0;
      debugPrint('⚠️ 未找到节次列，使用第0列');
    }

    // ============================================================
    // 第四步：解析课程（按课程块分组，一个单元格可能包含多个课程）
    // ============================================================
    final courses = <Course>[];

    for (int i = headerRowIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.isEmpty)) continue;

      // 获取节次
      String slotText = row.length > slotCol ? row[slotCol] : '';
      if (slotText.isEmpty) continue;

      // 解析节次
      int startSlot = 1;
      int endSlot = 2;
      final match = RegExp(r'第?(\d+)\s*[-~到至]\s*(\d+)\s*节?').firstMatch(slotText);
      if (match != null) {
        startSlot = int.parse(match.group(1)!);
        endSlot = int.parse(match.group(2)!);
      } else {
        final singleMatch = RegExp(r'第?(\d+)\s*节?').firstMatch(slotText);
        if (singleMatch != null) {
          startSlot = int.parse(singleMatch.group(1)!);
          endSlot = startSlot + 1;
        } else {
          final numMatch = RegExp(r'(\d+)').firstMatch(slotText);
          if (numMatch != null) {
            startSlot = int.parse(numMatch.group(1)!);
            endSlot = startSlot + 1;
          }
        }
      }

      // 遍历各星期列
      for (var entry in weekdayColMap.entries) {
        final col = entry.key;
        final weekday = entry.value;

        final cellContent = col < row.length ? row[col] : '';
        if (cellContent.isEmpty) continue;

        // 按换行拆分成行数组
        final lines = cellContent.split(RegExp(r'\n|\r\n')).where((s) => s.trim().isNotEmpty).toList();
        if (lines.isEmpty) continue;

        // 按课程块分组：连续的几行属于同一课程
        final courseBlocks = <List<String>>[];
        List<String> currentBlock = [];

        for (var line in lines) {
          final trimmed = line.trim();

          // 判断是否为新课程的开始：课程名特征（不含括号、不含教师、不含周次、不含节次、不含教室）
          final isCourseName = trimmed.isNotEmpty &&
              !trimmed.contains('[') &&
              !trimmed.contains('（') &&
              !trimmed.contains('(') &&
              !trimmed.contains('周') &&
              !trimmed.contains('节') &&
              !RegExp(r'[A-Z]-\d+').hasMatch(trimmed);

          if (isCourseName && currentBlock.isNotEmpty) {
            courseBlocks.add(currentBlock);
            currentBlock = [];
          }
          currentBlock.add(trimmed);
        }
        if (currentBlock.isNotEmpty) {
          courseBlocks.add(currentBlock);
        }

        // 解析每个课程块
        for (var block in courseBlocks) {
          if (block.isEmpty) continue;
          final fullText = block.join(' ');

          // 提取教师 (支持 [教师]、教师：xxx、xxx老师等)
          String teacher = _extractTeacherFromText(fullText);

          // 提取教室 (支持 D-202、教学楼A-101等)
          String classroom = _extractClassroomFromText(fullText);

          // 提取周次 (支持 1-16周、1,3,5周等)
          Map<String, int> weeks = _extractWeeksFromText(fullText);
          int weekStart = weeks['start']!;
          int weekEnd = weeks['end']!;

          // 提取节次 (支持 [01-02节]、1-2节等)
          Map<String, int> slots = _extractSlotsFromText(fullText);
          // 如果从块中提取到节次，覆盖从行解析的节次（块内的节次更准确）
          if (slots['start'] != 1 || slots['end'] != 2) {
            startSlot = slots['start']!;
            endSlot = slots['end']!;
          }

          // 课程名称：取块中第一行，并移除所有标记
          String courseName = block[0].trim();
          // 移除教师标记
          if (teacher.isNotEmpty) {
            courseName = courseName.replaceAll(RegExp(r'[\[（(]\s*' + RegExp.escape(teacher) + r'\s*[\]）)]'), '');
            courseName = courseName.replaceAll(RegExp(r'(?:教师|授课教师)[：:]\s*' + RegExp.escape(teacher)), '');
            courseName = courseName.replaceAll(RegExp(RegExp.escape(teacher) + r'\s*老师'), '');
          }
          // 移除教室
          if (classroom.isNotEmpty) {
            courseName = courseName.replaceAll(RegExp(RegExp.escape(classroom)), '');
          }
          // 移除所有括号内容
          courseName = courseName.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
          courseName = courseName.replaceAll(RegExp(r'\[[^\]]*\]'), '');
          // 移除周次和节次信息
          courseName = courseName.replaceAll(RegExp(r'\d{1,2}\s*[-~到至]\s*\d{1,2}\s*周?'), '');
          courseName = courseName.replaceAll(RegExp(r'\d{1,2}\s*节'), '');
          courseName = courseName.replaceAll(RegExp(r'\s+'), ' ').trim();

          // 如果课程名为空，使用块中非空行
          if (courseName.isEmpty) {
            for (var line in block) {
              if (line.isNotEmpty && !line.contains('[') && !line.contains('）') && !line.contains(')') && !RegExp(r'[A-Z]-\d+').hasMatch(line)) {
                courseName = line.trim();
                break;
              }
            }
          }

          if (courseName.isNotEmpty) {
            final colorHex = ColorManager.colorToHex(ColorManager.getNextColor());
            final course = Course(
              id: 'course_${DateTime.now().millisecondsSinceEpoch}_${i}_${col}_${courses.length}',
              name: courseName,
              teacher: teacher,
              classroom: classroom,
              weekday: weekday,
              startSlot: startSlot.clamp(1, 12),
              endSlot: endSlot.clamp(startSlot, 12),
              weekStart: weekStart.clamp(1, 20),
              weekEnd: weekEnd.clamp(weekStart, 20),
              color: colorHex,
            );
            courses.add(course);
            debugPrint('  ✅ 课程: $courseName | 周$weekday | $startSlot-$endSlot节 | 教师:$teacher | 教室:$classroom | 周$weekStart-$weekEnd');
          } else {
            debugPrint('  ⚠️ 跳过空课程块: ${block.join(' ')}');
          }
        }
      }
    }

    debugPrint('✅ 解析完成，共 ${courses.length} 门课程');
    return courses;
  }

  // ============================================================
  // 辅助提取函数（增强版）
  // ============================================================

  String _extractTeacherFromText(String text) {
    // 1. [教师] 或 （教师） 或 (教师)
    final match1 = RegExp(r'[\[（(]\s*([^\s\]）)]+)\s*[\]）)]').firstMatch(text);
    if (match1 != null) return match1.group(1)!.trim();

    // 2. 教师：xxx 或 教师:xxx
    final match2 = RegExp(r'(?:教师|授课教师|任课教师)[：:]\s*([^\s，,、;；]+)').firstMatch(text);
    if (match2 != null) return match2.group(1)!.trim();

    // 3. xxx 老师
    final match3 = RegExp(r'([^\s，,、]+)\s*老师').firstMatch(text);
    if (match3 != null) return match3.group(1)!.trim();

    // 4. 括号内2-4字姓名
    final match4 = RegExp(r'[（(]([^）)]{2,4})[）)]').firstMatch(text);
    if (match4 != null) {
      final candidate = match4.group(1)!.trim();
      if (RegExp(r'^[\u4e00-\u9fa5]{2,4}$').hasMatch(candidate)) return candidate;
    }
    return '';
  }

  String _extractClassroomFromText(String text) {
    // 1. D-202, 教1-201, 教学楼A-101
    final match1 = RegExp(r'[A-Za-z]-\d+|[教学楼][A-Za-z]?[-]?\d+[-]?\d*').firstMatch(text);
    if (match1 != null) return match1.group(0)!;

    // 2. 实验楼101, 主教楼305
    final match2 = RegExp(r'(?:主教楼|实验楼|信息中心楼|综合楼|文科楼|理科楼)[A-Za-z]?[-]?\d+').firstMatch(text);
    if (match2 != null) return match2.group(0)!;

    // 3. A101, B206
    final match3 = RegExp(r'\b[A-Za-z]\d{2,3}\b').firstMatch(text);
    if (match3 != null) return match3.group(0)!;

    // 4. 纯数字教室 (101, 301)
    final match4 = RegExp(r'\b(\d{3,4})\b').firstMatch(text);
    if (match4 != null) return match4.group(0)!;

    return '';
  }

  Map<String, int> _extractWeeksFromText(String text) {
    int start = 1, end = 20;
    // 匹配所有 "1-16周" 或 "1~16周"
    final matches = RegExp(r'(\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*周?').allMatches(text);
    if (matches.isNotEmpty) {
      int minStart = 999, maxEnd = 0;
      for (var m in matches) {
        final s = int.parse(m.group(1)!);
        final e = int.parse(m.group(2)!);
        if (s < minStart) minStart = s;
        if (e > maxEnd) maxEnd = e;
      }
      if (minStart != 999) start = minStart;
      if (maxEnd != 0) end = maxEnd;
    } else {
      // 匹配单周 "第3周" 或 "3周"
      final single = RegExp(r'第?(\d{1,2})\s*周').firstMatch(text);
      if (single != null) {
        start = int.parse(single.group(1)!);
        end = start;
      }
    }
    return {'start': start, 'end': end};
  }

  Map<String, int> _extractSlotsFromText(String text) {
    int start = 1, end = 2;
    // 1. [01-02节] 或 （01-02节）
    final match1 = RegExp(r'[\[（(](\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*节?[\]）)]').firstMatch(text);
    if (match1 != null) {
      start = int.parse(match1.group(1)!);
      end = int.parse(match1.group(2)!);
    } else {
      // 2. 第1-2节 或 1-2节
      final match2 = RegExp(r'第?(\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*节?').firstMatch(text);
      if (match2 != null) {
        start = int.parse(match2.group(1)!);
        end = int.parse(match2.group(2)!);
      }
    }
    return {'start': start, 'end': end};
  }
}