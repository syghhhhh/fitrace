import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_record.dart';
import '../models/daily_goal.dart';
import '../../core/constants/app_constants.dart';

/// 数据库服务
class DatabaseService {
  DatabaseService._();
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;

  static Database? _database;
  static bool _initialized = false;

  /// 初始化数据库工厂（支持桌面平台）
  static Future<void> initialize() async {
    if (_initialized) return;

    // 在Windows/Linux/macOS桌面平台使用sqflite_common_ffi
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _initialized = true;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    if (!_initialized) {
      await initialize();
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 获取数据库路径
  Future<String> _getDatabasePath() async {
    // 使用path_provider获取跨平台的应用文档目录
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return join(appDocDir.path, AppConstants.databaseName);
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final String path = await _getDatabasePath();
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 运动记录表
    await db.execute('''
      CREATE TABLE workout_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        distance REAL NOT NULL,
        avg_speed REAL NOT NULL,
        calories REAL NOT NULL,
        route_points TEXT
      )
    ''');

    // 每日目标表
    await db.execute('''
      CREATE TABLE daily_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL UNIQUE,
        target_distance REAL NOT NULL,
        target_duration INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ==================== 运动记录相关操作 ====================

  /// 插入运动记录
  Future<int> insertWorkoutRecord(WorkoutRecord record) async {
    final db = await database;
    return await db.insert('workout_records', record.toMap());
  }

  /// 获取所有运动记录
  Future<List<WorkoutRecord>> getAllWorkoutRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  /// 获取指定日期的运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  /// 获取指定日期范围的运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => WorkoutRecord.fromMap(map)).toList();
  }

  /// 获取最近的运动记录
  Future<WorkoutRecord?> getLatestWorkoutRecord() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_records',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutRecord.fromMap(maps.first);
  }

  /// 删除运动记录
  Future<int> deleteWorkoutRecord(int id) async {
    final db = await database;
    return await db.delete('workout_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 每日目标相关操作 ====================

  /// 插入或更新每日目标
  Future<int> insertOrUpdateDailyGoal(DailyGoal goal) async {
    final db = await database;
    return await db.insert(
      'daily_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取指定日期的目标
  Future<DailyGoal?> getDailyGoalByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);

    final List<Map<String, dynamic>> maps = await db.query(
      'daily_goals',
      where: 'date = ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch],
    );
    if (maps.isEmpty) return null;
    return DailyGoal.fromMap(maps.first);
  }

  /// 更新目标完成状态
  Future<int> updateGoalCompletionStatus(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'daily_goals',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 统计相关操作 ====================

  /// 获取今日统计数据
  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(distance), 0) as total_distance,
        COALESCE(SUM(duration), 0) as total_duration,
        COALESCE(SUM(calories), 0) as total_calories
      FROM workout_records
      WHERE start_time >= ? AND start_time < ?
    ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

    return result.first;
  }

  /// 获取总计统计数据
  Future<Map<String, dynamic>> getTotalStats() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(distance), 0) as total_distance,
        COALESCE(SUM(duration), 0) as total_duration,
        COALESCE(SUM(calories), 0) as total_calories
      FROM workout_records
    ''');

    return result.first;
  }

  /// 获取周统计数据（按天分组）
  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final result = await db.rawQuery('''
      SELECT
        date(start_time / 1000, 'unixepoch', 'localtime') as date,
        COUNT(*) as count,
        SUM(distance) as total_distance,
        SUM(duration) as total_duration,
        SUM(calories) as total_calories
      FROM workout_records
      WHERE start_time >= ?
      GROUP BY date(start_time / 1000, 'unixepoch', 'localtime')
      ORDER BY date
    ''', [startOfDay.millisecondsSinceEpoch]);

    return result;
  }
}