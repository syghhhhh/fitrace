/// 用户统计数据模型
class UserStats {
  final int totalWorkouts; // 总运动次数
  final double totalDistance; // 总里程（米）
  final int totalDuration; // 总时长（秒）
  final double totalCalories; // 总消耗卡路里

  const UserStats({
    this.totalWorkouts = 0,
    this.totalDistance = 0,
    this.totalDuration = 0,
    this.totalCalories = 0,
  });

  /// 从运动记录列表计算统计
  factory UserStats.fromRecords(List<dynamic> records) {
    int workouts = 0;
    double distance = 0;
    int duration = 0;
    double calories = 0;

    for (final record in records) {
      workouts++;
      distance += (record as dynamic).distance as double;
      duration += (record as dynamic).duration as int;
      calories += (record as dynamic).calories as double;
    }

    return UserStats(
      totalWorkouts: workouts,
      totalDistance: distance,
      totalDuration: duration,
      totalCalories: calories,
    );
  }

  /// 获取总里程（公里）
  double get totalDistanceInKm => totalDistance / 1000;

  /// 获取总时长（小时）
  double get totalDurationInHours => totalDuration / 3600;

  /// 格式化总时长
  String get formattedTotalDuration {
    final int hours = totalDuration ~/ 3600;
    final int minutes = (totalDuration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  /// 复制并修改
  UserStats copyWith({
    int? totalWorkouts,
    double? totalDistance,
    int? totalDuration,
    double? totalCalories,
  }) {
    return UserStats(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalDistance: totalDistance ?? this.totalDistance,
      totalDuration: totalDuration ?? this.totalDuration,
      totalCalories: totalCalories ?? this.totalCalories,
    );
  }
}