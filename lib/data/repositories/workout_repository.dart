import '../models/workout_record.dart';
import '../models/daily_goal.dart';
import '../models/user_stats.dart';
import '../database/database_service.dart';

/// 运动数据仓库
class WorkoutRepository {
  final DatabaseService _db = DatabaseService();

  // ==================== 运动记录操作 ====================

  /// 保存运动记录
  Future<int> saveWorkoutRecord(WorkoutRecord record) async {
    return await _db.insertWorkoutRecord(record);
  }

  /// 获取所有运动记录
  Future<List<WorkoutRecord>> getAllWorkoutRecords() async {
    return await _db.getAllWorkoutRecords();
  }

  /// 获取指定日期的运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDate(DateTime date) async {
    return await _db.getWorkoutRecordsByDate(date);
  }

  /// 获取指定日期范围的运动记录
  Future<List<WorkoutRecord>> getWorkoutRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _db.getWorkoutRecordsByDateRange(startDate, endDate);
  }

  /// 获取最近的运动记录
  Future<WorkoutRecord?> getLatestWorkoutRecord() async {
    return await _db.getLatestWorkoutRecord();
  }

  /// 删除运动记录
  Future<int> deleteWorkoutRecord(int id) async {
    return await _db.deleteWorkoutRecord(id);
  }

  // ==================== 每日目标操作 ====================

  /// 保存每日目标
  Future<int> saveDailyGoal(DailyGoal goal) async {
    return await _db.insertOrUpdateDailyGoal(goal);
  }

  /// 获取指定日期的目标
  Future<DailyGoal?> getDailyGoalByDate(DateTime date) async {
    return await _db.getDailyGoalByDate(date);
  }

  /// 获取或创建今日目标
  Future<DailyGoal> getOrCreateTodayGoal({
    double defaultDistance = 5000, // 默认5公里
    int defaultDuration = 1800, // 默认30分钟
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DailyGoal? goal = await getDailyGoalByDate(today);
    if (goal == null) {
      goal = DailyGoal(
        date: today,
        targetDistance: defaultDistance,
        targetDuration: defaultDuration,
      );
      await saveDailyGoal(goal);
    }
    return goal;
  }

  /// 更新目标完成状态
  Future<void> updateGoalCompletion(int id, bool isCompleted) async {
    await _db.updateGoalCompletionStatus(id, isCompleted);
  }

  // ==================== 统计操作 ====================

  /// 获取今日统计
  Future<Map<String, dynamic>> getTodayStats() async {
    return await _db.getTodayStats();
  }

  /// 获取总计统计
  Future<UserStats> getTotalStats() async {
    final stats = await _db.getTotalStats();
    return UserStats(
      totalWorkouts: (stats['count'] as int?) ?? 0,
      totalDistance: (stats['total_distance'] as double?) ?? 0,
      totalDuration: (stats['total_duration'] as int?) ?? 0,
      totalCalories: (stats['total_calories'] as double?) ?? 0,
    );
  }

  /// 获取周统计数据
  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    return await _db.getWeeklyStats();
  }

  /// 检查今日目标完成情况
  Future<bool> checkTodayGoalCompletion() async {
    final goal = await getDailyGoalByDate(DateTime.now());
    if (goal == null) return false;

    final stats = await getTodayStats();
    final totalDistance = (stats['total_distance'] as double?) ?? 0;
    final totalDuration = (stats['total_duration'] as int?) ?? 0;

    final distanceCompleted = totalDistance >= goal.targetDistance;
    final durationCompleted = totalDuration >= goal.targetDuration;

    if ((distanceCompleted || durationCompleted) && !goal.isCompleted) {
      await updateGoalCompletion(goal.id!, true);
      return true;
    }

    return goal.isCompleted;
  }
}