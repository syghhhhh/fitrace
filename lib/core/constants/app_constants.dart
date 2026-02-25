/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用名称
  static const String appName = 'Fitrace';

  // 运动类型
  static const int workoutTypeRunning = 0;
  static const int workoutTypeCycling = 1;

  static const Map<int, String> workoutTypeNames = {
    workoutTypeRunning: '跑步',
    workoutTypeCycling: '骑行',
  };

  // 默认目标
  static const double defaultDailyDistanceGoal = 5.0; // km
  static const int defaultDailyDurationGoal = 30; // minutes

  // 卡路里计算系数（简化计算）
  // 跑步: ~60 cal/km，骑行: ~30 cal/km
  static const double caloriesPerKmRunning = 60.0;
  static const double caloriesPerKmCycling = 30.0;

  // 数据库
  static const String databaseName = 'fitrace.db';
  static const int databaseVersion = 1;
}