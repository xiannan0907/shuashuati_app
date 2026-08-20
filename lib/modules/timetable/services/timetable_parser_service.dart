import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../data/models/course_model.dart';
import 'xlsx_parser.dart';

class TimetableParserService {
  final XlsxParser _xlsxParser = XlsxParser();

  // ============================================================
  // 1. 导入（自动识别格式）
  // ============================================================

  Future<List<Course>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'json':
        return await _parseJson(file);
      case 'xlsx':
      case 'xls':
        debugPrint('📊 开始解析 Excel...');
        final isMatrix = await _isMatrixFormat(file);
        if (isMatrix) {
          debugPrint('📊 检测到矩阵式课表格式（含"星期一"表头）');
          return await _xlsxParser.parse(file);
        } else {
          debugPrint('📊 检测到课程列表格式（导出文件）');
          return await _parseExportFile(file);
        }
      default:
        throw Exception('不支持的文件格式: $extension');
    }
  }

  // ============================================================
  // 1.1 检测文件类型
  // ============================================================

  Future<bool> _isMatrixFormat(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final sharedStrings = _readSharedStringsFromArchive(archive);
      final rows = _readSheetFromArchive(archive, sharedStrings);

      if (rows.isEmpty) return false;

      for (int i = 0; i < rows.length && i < 20; i++) {
        final row = rows[i];
        int weekdayCount = 0;
        for (var cell in row) {
          if (cell.contains('星期一') ||
              cell.contains('星期二') ||
              cell.contains('星期三') ||
              cell.contains('星期四') ||
              cell.contains('星期五') ||
              cell.contains('星期六') ||
              cell.contains('星期日')) {
            weekdayCount++;
          }
        }
        if (weekdayCount >= 2) {
          return true;
        }
      }

      for (int i = 0; i < rows.length && i < 10; i++) {
        final rowText = rows[i].join('');
        if (rowText.contains('课程名称') && rowText.contains('教师')) {
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ 格式检测失败: $e，默认使用矩阵式解析器');
      return true;
    }
  }

  List<String> _readSharedStringsFromArchive(Archive archive) {
    try {
      final file = archive.findFile('xl/sharedStrings.xml');
      if (file == null) return [];
      final content = utf8.decode(file.content as List<int>);
      final document = XmlDocument.parse(content);
      final strings = <String>[];
      for (var element in document.findAllElements('si')) {
        final text = element.findElements('t').map((e) => e.innerText).join('');
        strings.add(text);
      }
      return strings;
    } catch (e) {
      return [];
    }
  }

  List<List<String>> _readSheetFromArchive(Archive archive, List<String> sharedStrings) {
    try {
      ArchiveFile? sheetFile;
      for (var file in archive.files) {
        if (file.name.contains('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
          sheetFile = file;
          break;
        }
      }
      if (sheetFile == null) return [];

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
          final cellValue = cellElement.findElements('v').firstOrNull;
          if (cellValue != null) {
            if (type == 's') {
              final index = int.tryParse(cellValue.innerText) ?? -1;
              if (index >= 0 && index < sharedStrings.length) {
                value = sharedStrings[index];
              }
            } else {
              value = cellValue.innerText;
            }
          }
          rowData.add(value.trim());
          lastColIndex = colIndex;
          if (colIndex > maxCols) maxCols = colIndex;
        }

        while (rowData.length <= maxCols) {
          rowData.add('');
        }

        if (rowData.isNotEmpty && rowData.any((s) => s.isNotEmpty)) {
          rows.add(rowData);
        }
      }

      for (var row in rows) {
        while (row.length < maxCols + 1) {
          row.add('');
        }
      }

      return rows;
    } catch (e) {
      return [];
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
  // 1.2 解析导出文件（课程列表格式）
  // ============================================================

  Future<List<Course>> _parseExportFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final sharedStrings = _readSharedStringsFromArchive(archive);
      final rows = _readSheetFromArchive(archive, sharedStrings);

      if (rows.isEmpty) {
        throw Exception('文件为空或无法读取');
      }

      int headerRowIndex = -1;
      for (int i = 0; i < rows.length && i < 20; i++) {
        final rowText = rows[i].join('');
        if (rowText.contains('课程名称') || rowText.contains('名称')) {
          headerRowIndex = i;
          break;
        }
      }

      if (headerRowIndex == -1) {
        throw Exception('未找到表头行（应包含"课程名称"）');
      }

      final header = rows[headerRowIndex];
      debugPrint('📋 表头: ${header.take(10).join(' | ')}');

      int nameCol = -1, teacherCol = -1, classroomCol = -1,
          weekdayCol = -1, startSlotCol = -1, endSlotCol = -1,
          weekStartCol = -1, weekEndCol = -1, colorCol = -1, noteCol = -1;

      for (int i = 0; i < header.length; i++) {
        final val = header[i].trim();
        if (val.contains('课程名称') || val.contains('名称')) {
          nameCol = i;
        } else if (val.contains('教师') || val.contains('老师')) {
          teacherCol = i;
        } else if (val.contains('教室') || val.contains('地点')) {
          classroomCol = i;
        } else if (val.contains('星期') || val.contains('周几')) {
          weekdayCol = i;
        } else if (val.contains('开始节') || val.contains('开始')) {
          startSlotCol = i;
        } else if (val.contains('结束节') || val.contains('结束')) {
          endSlotCol = i;
        } else if (val.contains('开始周') || val.contains('起始周')) {
          weekStartCol = i;
        } else if (val.contains('结束周') || val.contains('终止周')) {
          weekEndCol = i;
        } else if (val.contains('颜色')) {
          colorCol = i;
        } else if (val.contains('备注') || val.contains('说明')) {
          noteCol = i;
        }
      }

      debugPrint('📋 列索引 -> 课程名称:$nameCol, 教师:$teacherCol, 教室:$classroomCol, 星期:$weekdayCol, 开始节:$startSlotCol, 结束节:$endSlotCol, 开始周:$weekStartCol, 结束周:$weekEndCol');

      if (nameCol == -1) {
        throw Exception('未找到"课程名称"列');
      }

      final courses = <Course>[];

      for (int i = headerRowIndex + 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((s) => s.isEmpty)) continue;

        String getVal(int col) => (col != -1 && col < row.length) ? row[col] : '';

        String rawName = getVal(nameCol);
        if (rawName.isEmpty) continue;

        String rawTeacher = getVal(teacherCol);
        String rawClassroom = getVal(classroomCol);
        String rawWeekday = getVal(weekdayCol);
        String rawStartSlot = getVal(startSlotCol);
        String rawEndSlot = getVal(endSlotCol);
        String rawWeekStart = getVal(weekStartCol);
        String rawWeekEnd = getVal(weekEndCol);
        String rawColor = getVal(colorCol);
        String rawNote = getVal(noteCol);

        // ✅ 增强提取（使用统一函数，传入原始数据）
        String teacher = _extractTeacher(rawName, rawTeacher);
        String classroom = _extractClassroom(rawName, rawClassroom);
        String name = _cleanCourseName(rawName, teacher, classroom);
        int weekday = _extractWeekday(rawWeekday, rawName);
        Map<String, int> weeks = _extractWeeks(rawName, rawWeekStart, rawWeekEnd);
        Map<String, int> slots = _extractSlots(rawName, rawStartSlot, rawEndSlot, rawNote);

        int weekStart = weeks['start']!;
        int weekEnd = weeks['end']!;
        int startSlot = slots['start']!;
        int endSlot = slots['end']!;

        final course = Course(
          id: 'course_${DateTime.now().millisecondsSinceEpoch}_${courses.length}',
          name: name.isNotEmpty ? name : rawName,
          teacher: teacher,
          classroom: classroom,
          weekday: weekday,
          startSlot: startSlot.clamp(1, 12),
          endSlot: endSlot.clamp(startSlot, 12),
          weekStart: weekStart.clamp(1, 20),
          weekEnd: weekEnd.clamp(weekStart, 20),
          color: rawColor.isNotEmpty ? rawColor : 'blue',
          note: rawNote,
        );
        courses.add(course);
        debugPrint('  ✅ 课程: ${course.name} | 周${course.weekday} | ${course.startSlot}-${course.endSlot}节 | 教师:$teacher | 教室:$classroom | 周${course.weekStart}-${course.weekEnd}');
      }

      debugPrint('✅ 解析完成，共 ${courses.length} 门课程');
      return courses;

    } catch (e) {
      debugPrint('❌ 解析导出文件失败: $e');
      throw Exception('解析导出文件失败: $e');
    }
  }

  // ============================================================
  // 1.3 统一增强提取函数（供导出文件解析和矩阵解析器共用）
  // ============================================================

  /// 从文本中提取教师（供矩阵解析器使用）
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

  /// 从文本中提取教室（供矩阵解析器使用）
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

  /// 提取教师（导出文件专用，优先使用独立列数据）
  String _extractTeacher(String rawName, String rawTeacher) {
    if (rawTeacher.isNotEmpty) return rawTeacher.trim();
    return _extractTeacherFromText(rawName);
  }

  /// 提取教室（导出文件专用，优先使用独立列数据）
  String _extractClassroom(String rawName, String rawClassroom) {
    if (rawClassroom.isNotEmpty) return rawClassroom.trim();
    return _extractClassroomFromText(rawName);
  }

  /// 清理课程名称
  String _cleanCourseName(String rawName, String teacher, String classroom) {
    String name = rawName;
    if (teacher.isNotEmpty) {
      name = name.replaceAll(RegExp(r'[\[（(]\s*' + RegExp.escape(teacher) + r'\s*[\]）)]'), '');
      name = name.replaceAll(RegExp(r'(?:教师|授课教师)[：:]\s*' + RegExp.escape(teacher)), '');
      name = name.replaceAll(RegExp(RegExp.escape(teacher) + r'\s*老师'), '');
    }
    if (classroom.isNotEmpty) {
      name = name.replaceAll(RegExp(RegExp.escape(classroom)), '');
    }
    name = name.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
    name = name.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    name = name.replaceAll(RegExp(r'\d{1,2}\s*[-~到至]\s*\d{1,2}\s*周?'), '');
    name = name.replaceAll(RegExp(r'\d{1,2}\s*节'), '');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name;
  }

  /// 提取星期
  int _extractWeekday(String rawWeekday, String rawName) {
    if (rawWeekday.isNotEmpty) {
      final cleaned = rawWeekday.replaceAll('星期', '').replaceAll('周', '').trim();
      final map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
      for (var entry in map.entries) {
        if (cleaned.contains(entry.key)) return entry.value;
      }
      final num = int.tryParse(cleaned);
      if (num != null && num >= 1 && num <= 7) return num;
    }
    // 从课程名提取
    final map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
    for (var entry in map.entries) {
      if (rawName.contains('星期${entry.key}') || rawName.contains('周${entry.key}')) {
        return entry.value;
      }
    }
    return 1;
  }

  /// 提取周次
  Map<String, int> _extractWeeks(String rawName, String rawWeekStart, String rawWeekEnd) {
    int start = 1, end = 20;
    if (rawWeekStart.isNotEmpty) {
      final parsed = int.tryParse(rawWeekStart);
      if (parsed != null) start = parsed;
    }
    if (rawWeekEnd.isNotEmpty) {
      final parsed = int.tryParse(rawWeekEnd);
      if (parsed != null) end = parsed;
    }
    if (start == 1 && end == 20) {
      final matches = RegExp(r'(\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*周?').allMatches(rawName);
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
        final single = RegExp(r'第?(\d{1,2})\s*周').firstMatch(rawName);
        if (single != null) {
          start = int.parse(single.group(1)!);
          end = start;
        }
      }
    }
    return {'start': start, 'end': end};
  }

  /// 提取节次
  Map<String, int> _extractSlots(String rawName, String rawStartSlot, String rawEndSlot, String rawNote) {
    int start = 1, end = 2;
    if (rawStartSlot.isNotEmpty) {
      final parsed = int.tryParse(rawStartSlot);
      if (parsed != null) start = parsed;
    }
    if (rawEndSlot.isNotEmpty) {
      final parsed = int.tryParse(rawEndSlot);
      if (parsed != null) end = parsed;
    }
    if (start == 1 && end == 2) {
      final text = '$rawName $rawNote';
      final match1 = RegExp(r'[\[（(](\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*节?[\]）)]').firstMatch(text);
      if (match1 != null) {
        start = int.parse(match1.group(1)!);
        end = int.parse(match1.group(2)!);
      } else {
        final match2 = RegExp(r'第?(\d{1,2})\s*[-~到至]\s*(\d{1,2})\s*节?').firstMatch(text);
        if (match2 != null) {
          start = int.parse(match2.group(1)!);
          end = int.parse(match2.group(2)!);
        }
      }
    }
    return {'start': start, 'end': end};
  }

  // ============================================================
  // 1.4 解析 JSON 文件
  // ============================================================

  Future<List<Course>> _parseJson(File file) async {
    final content = await file.readAsString();
    final jsonData = jsonDecode(content);

    List<dynamic> data;
    if (jsonData is List) {
      data = jsonData;
    } else if (jsonData is Map && jsonData.containsKey('courses')) {
      data = jsonData['courses'] as List;
    } else {
      throw Exception('JSON格式不支持，请确保格式为 {"courses": [...]} 或直接为数组');
    }

    final courses = <Course>[];
    for (var item in data) {
      try {
        final course = Course(
          id: 'course_${DateTime.now().millisecondsSinceEpoch}_${courses.length}',
          name: _getString(item, ['name', '课程', '课程名称']),
          teacher: _getString(item, ['teacher', '教师', '老师']),
          classroom: _getString(item, ['classroom', '教室', '地点']),
          weekday: _parseInt(_getString(item, ['weekday', '星期', '星期几'])),
          startSlot: _parseInt(_getString(item, ['startSlot', '开始节', '开始'])),
          endSlot: _parseInt(_getString(item, ['endSlot', '结束节', '结束'])),
          weekStart: _parseInt(_getString(item, ['weekStart', '开始周']), 1),
          weekEnd: _parseInt(_getString(item, ['weekEnd', '结束周']), 20),
          color: _getString(item, ['color', '颜色']),
          note: _getString(item, ['note', '备注']),
        );
        if (course.name.isNotEmpty) {
          courses.add(course);
        }
      } catch (e) {
        debugPrint('⚠️ 跳过一条无效课程: $e');
      }
    }

    return courses;
  }

  String _getString(Map<String, dynamic> item, List<String> keys) {
    for (var key in keys) {
      if (item.containsKey(key) && item[key] != null) {
        return item[key].toString().trim();
      }
    }
    return '';
  }

  int _parseInt(String? value, [int defaultValue = 1]) {
    if (value == null || value.isEmpty) return defaultValue;
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(cleaned);
    return parsed ?? defaultValue;
  }

  // ============================================================
  // 2. 导出
  // ============================================================

  String exportToJson(List<Course> courses) {
    final jsonList = courses.map((c) => {
      'name': c.name,
      'teacher': c.teacher,
      'classroom': c.classroom,
      'weekday': c.weekday,
      'startSlot': c.startSlot,
      'endSlot': c.endSlot,
      'weekStart': c.weekStart,
      'weekEnd': c.weekEnd,
      'color': c.color,
      'note': c.note ?? '',
    }).toList();

    return jsonEncode({
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'courseCount': courses.length,
      'courses': jsonList,
    });
  }

  Future<File> exportToJsonFile(List<Course> courses, String filePath) async {
    final jsonStr = exportToJson(courses);
    final file = File(filePath);
    await file.writeAsString(jsonStr, encoding: utf8);
    return file;
  }

  Future<File> exportToExcelFile(List<Course> courses, String filePath) async {
    try {
      final archive = Archive();

      final contentTypes = _buildContentTypes();
      archive.addFile(ArchiveFile(
        '[Content_Types].xml',
        utf8.encode(contentTypes).length,
        utf8.encode(contentTypes),
      ));

      final rels = _buildRels();
      archive.addFile(ArchiveFile(
        '_rels/.rels',
        utf8.encode(rels).length,
        utf8.encode(rels),
      ));

      final workbookRels = _buildWorkbookRels();
      archive.addFile(ArchiveFile(
        'xl/_rels/workbook.xml.rels',
        utf8.encode(workbookRels).length,
        utf8.encode(workbookRels),
      ));

      final workbook = _buildWorkbook();
      archive.addFile(ArchiveFile(
        'xl/workbook.xml',
        utf8.encode(workbook).length,
        utf8.encode(workbook),
      ));

      final sharedStrings = _buildSharedStrings(courses);
      archive.addFile(ArchiveFile(
        'xl/sharedStrings.xml',
        utf8.encode(sharedStrings).length,
        utf8.encode(sharedStrings),
      ));

      final styles = _buildStyles();
      archive.addFile(ArchiveFile(
        'xl/styles.xml',
        utf8.encode(styles).length,
        utf8.encode(styles),
      ));

      final sheet = _buildSheet(courses);
      archive.addFile(ArchiveFile(
        'xl/worksheets/sheet1.xml',
        utf8.encode(sheet).length,
        utf8.encode(sheet),
      ));

      final zipData = ZipEncoder().encode(archive);

      final file = File(filePath);
      await file.writeAsBytes(zipData);
      debugPrint('✅ Excel 导出成功: $filePath');
      return file;

    } catch (e) {
      debugPrint('❌ Excel 导出失败: $e');
      final jsonPath = filePath.replaceAll('.xlsx', '.json');
      debugPrint('⚠️ 降级为 JSON 导出: $jsonPath');
      return await exportToJsonFile(courses, jsonPath);
    }
  }

  String _buildContentTypes() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
  }

  String _buildRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
  }

  String _buildWorkbookRels() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
  }

  String _buildWorkbook() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheets>
    <sheet name="课表" sheetId="1" r:id="rId1" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
  </sheets>
</workbook>''';
  }

  String _buildStyles() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1">
    <font>
      <sz val="11"/>
      <color theme="1"/>
      <name val="Calibri"/>
      <family val="2"/>
      <scheme val="minor"/>
    </font>
  </fonts>
  <fills count="2">
    <fill/>
    <fill>
      <patternFill patternType="none"/>
    </fill>
  </fills>
  <borders count="1">
    <border>
      <left/>
      <right/>
      <top/>
      <bottom/>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
  </cellXfs>
</styleSheet>''';
  }

  String _buildSharedStrings(List<Course> courses) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${10 + courses.length * 10}">');

    final strings = <String>[
      '课程名称', '教师', '教室', '星期', '开始节', '结束节', '开始周', '结束周', '颜色', '备注'
    ];
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

    for (var c in courses) {
      strings.add(c.name);
      strings.add(c.teacher);
      strings.add(c.classroom);
      strings.add('星期${weekdayNames[c.weekday - 1]}');
      strings.add(c.startSlot.toString());
      strings.add(c.endSlot.toString());
      strings.add(c.weekStart.toString());
      strings.add(c.weekEnd.toString());
      strings.add(c.color);
      strings.add(c.note ?? '');
    }

    for (var s in strings) {
      buffer.writeln('  <si><t xml:space="preserve">${_escapeXml(s)}</t></si>');
    }

    buffer.writeln('</sst>');
    return buffer.toString();
  }

  String _buildSheet(List<Course> courses) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    buffer.writeln('  <dimension ref="A1:J${courses.length + 1}"/>');
    buffer.writeln('  <sheetData>');

    // 表头
    buffer.writeln('    <row r="1">');
    final headers = ['课程名称', '教师', '教室', '星期', '开始节', '结束节', '开始周', '结束周', '颜色', '备注'];
    for (int i = 0; i < headers.length; i++) {
      buffer.writeln('      <c r="${_colLetter(i)}1" t="s"><v>$i</v></c>');
    }
    buffer.writeln('    </row>');

    // 数据行
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    int stringIndex = 10;

    for (int row = 0; row < courses.length; row++) {
      final c = courses[row];
      final rowNum = row + 2;
      buffer.writeln('    <row r="$rowNum">');

      final rowData = [
        c.name,
        c.teacher,
        c.classroom,
        '星期${weekdayNames[c.weekday - 1]}',
        c.startSlot.toString(),
        c.endSlot.toString(),
        c.weekStart.toString(),
        c.weekEnd.toString(),
        c.color,
        c.note ?? '',
      ];

      for (int col = 0; col < rowData.length; col++) {
        buffer.writeln('      <c r="${_colLetter(col)}$rowNum" t="s"><v>${stringIndex + col}</v></c>');
      }
      buffer.writeln('    </row>');
      stringIndex += rowData.length;
    }

    buffer.writeln('  </sheetData>');
    buffer.writeln('</worksheet>');
    return buffer.toString();
  }

  String _colLetter(int index) {
    return String.fromCharCode(65 + index);
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<File> exportCourses(List<Course> courses, String filePath, String format) async {
    if (format == 'json') {
      return await exportToJsonFile(courses, filePath);
    } else if (format == 'xlsx') {
      return await exportToExcelFile(courses, filePath);
    } else {
      throw Exception('不支持的导出格式: $format');
    }
  }

  String getSuggestedFileName(String format) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final ext = format == 'json' ? 'json' : 'xlsx';
    return '课表_$dateStr.$ext';
  }
}