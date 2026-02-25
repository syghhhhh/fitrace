/// 运动记录数据模型
class WorkoutRecord {
  final int? id;
  final int type; // 0: 跑步, 1: 骑行
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // 秒
  final double distance; // 米
  final double avgSpeed; // 米/秒
  final double calories;
  final String? routePoints; // JSON格式的路线点

  const WorkoutRecord({
    this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.avgSpeed,
    required this.calories,
    this.routePoints,
  });

  /// 从数据库Map创建
  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutRecord(
      id: map['id'] as int?,
      type: map['type'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      duration: map['duration'] as int,
      distance: map['distance'] as double,
      avgSpeed: map['avg_speed'] as double,
      calories: map['calories'] as double,
      routePoints: map['route_points'] as String?,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'duration': duration,
      'distance': distance,
      'avg_speed': avgSpeed,
      'calories': calories,
      'route_points': routePoints,
    };
  }

  /// 复制并修改
  WorkoutRecord copyWith({
    int? id,
    int? type,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    double? distance,
    double? avgSpeed,
    double? calories,
    String? routePoints,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      calories: calories ?? this.calories,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  /// 获取运动类型名称
  String get typeName => type == 0 ? '跑步' : '骑行';

  /// 获取距离（公里）
  double get distanceInKm => distance / 1000;

  /// 获取平均配速（秒/公里），仅跑步
  double get avgPace => distance > 0 ? duration / (distance / 1000) : 0;
}