/// 每日目标数据模型
class DailyGoal {
  final int? id;
  final DateTime date;
  final double targetDistance; // 目标距离（米）
  final int targetDuration; // 目标时长（秒）
  final bool isCompleted;

  const DailyGoal({
    this.id,
    required this.date,
    required this.targetDistance,
    required this.targetDuration,
    this.isCompleted = false,
  });

  /// 从数据库Map创建
  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      targetDistance: map['target_distance'] as double,
      targetDuration: map['target_duration'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'target_distance': targetDistance,
      'target_duration': targetDuration,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  /// 复制并修改
  DailyGoal copyWith({
    int? id,
    DateTime? date,
    double? targetDistance,
    int? targetDuration,
    bool? isCompleted,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      date: date ?? this.date,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDuration: targetDuration ?? this.targetDuration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 获取日期字符串（YYYY-MM-DD）
  String get dateString {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}