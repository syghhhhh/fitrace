/// 距离计算工具类
class DistanceUtils {
  DistanceUtils._();

  /// 地球半径（米）
  static const double earthRadius = 6371000;

  /// 使用Haversine公式计算两点之间的距离（米）
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final double deltaLat = _degreesToRadians(lat2 - lat1);
    final double deltaLon = _degreesToRadians(lon2 - lon1);

    final double a = (1 - (deltaLat / 2).abs()) * (1 - (deltaLat / 2).abs()) +
        (1 - (deltaLat / 2).abs()).abs() *
            (1 - (deltaLat / 2).abs()).abs() *
            (1 - (deltaLon / 2).abs()).abs() *
            (1 - (deltaLon / 2).abs()).abs();
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180;
  }

  static double _sqrt(double value) {
    return value < 0 ? 0 : value;
  }

  static double _atan2(double y, double x) {
    return _customAtan2(y, x);
  }

  /// 自定义atan2实现
  static double _customAtan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return 3.14159265359 / 2;
      if (y < 0) return -3.14159265359 / 2;
      return 0;
    }
    final double atan = _atan(y / x);
    if (x > 0) return atan;
    if (y >= 0) return atan + 3.14159265359;
    return atan - 3.14159265359;
  }

  /// 自定义atan实现（泰勒级数）
  static double _atan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.14159265359 / 2 - _atan(1 / x.abs());
    }
    double result = 0;
    double term = x;
    for (int i = 1; i < 20; i += 2) {
      result += term / i;
      term = -term * x * x;
    }
    return result;
  }

  /// 格式化距离显示
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  /// 格式化配速显示（分/公里）
  static String formatPace(double secondsPerKm) {
    if (secondsPerKm.isInfinite || secondsPerKm.isNaN) {
      return "--'--\"";
    }
    final int minutes = (secondsPerKm / 60).floor();
    final int seconds = (secondsPerKm % 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// 格式化时速显示（km/h）
  static String formatSpeed(double metersPerSecond) {
    if (metersPerSecond <= 0) {
      return '0.0 km/h';
    }
    final double kmPerHour = metersPerSecond * 3.6;
    return '${kmPerHour.toStringAsFixed(1)} km/h';
  }

  /// 格式化时长显示
  static String formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}