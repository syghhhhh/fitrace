import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/workout_repository.dart';

/// 运动页面
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // 运动状态
  bool _isRunning = false;
  bool _isPaused = false;
  int _selectedType = 0; // 0: 跑步, 1: 骑行

  // 运动数据
  int _duration = 0; // 秒
  double _distance = 0; // 米
  double _currentSpeed = 0; // 米/秒
  double _calories = 0;

  // 位置数据
  Position? _lastPosition;
  final List<Map<String, double>> _routePoints = [];

  // 计时器
  Timer? _timer;
  DateTime? _startTime;

  // 数据仓库
  final WorkoutRepository _repository = WorkoutRepository();

  // GPS状态
  bool _gpsEnabled = false;
  String _gpsStatus = '检查中...';

  @override
  void initState() {
    super.initState();
    _checkGpsStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkGpsStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _gpsEnabled = false;
        _gpsStatus = 'GPS未开启，请在设置中开启';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _gpsEnabled = false;
          _gpsStatus = '位置权限被拒绝';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _gpsEnabled = false;
        _gpsStatus = '位置权限被永久拒绝，请在设置中开启';
      });
      return;
    }

    setState(() {
      _gpsEnabled = true;
      _gpsStatus = 'GPS已就绪';
    });
  }

  void _startWorkout() {
    if (!_gpsEnabled) {
      _checkGpsStatus();
      return;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _duration = 0;
      _distance = 0;
      _calories = 0;
      _routePoints.clear();
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _duration++;
        });
        _updateLocation();
      }
    });
  }

  void _pauseWorkout() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeWorkout() {
    setState(() {
      _isPaused = false;
      _lastPosition = null; // 重置位置避免暂停后计算大距离
    });
  }

  Future<void> _stopWorkout() async {
    _timer?.cancel();
    _timer = null;

    if (_duration < 10) {
      // 运动时间太短，不保存
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('运动时间太短，不保存记录')),
        );
      }
      _resetWorkout();
      return;
    }

    // 保存运动记录
    final record = WorkoutRecord(
      type: _selectedType,
      startTime: _startTime!,
      endTime: DateTime.now(),
      duration: _duration,
      distance: _distance,
      avgSpeed: _duration > 0 ? _distance / _duration : 0,
      calories: _calories,
      routePoints: _routePoints.isNotEmpty ? jsonEncode(_routePoints) : null,
    );

    await _repository.saveWorkoutRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('运动记录已保存：${DistanceUtils.formatDistance(_distance)}')),
      );
    }

    _resetWorkout();
  }

  void _resetWorkout() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _duration = 0;
      _distance = 0;
      _currentSpeed = 0;
      _calories = 0;
      _lastPosition = null;
      _startTime = null;
    });
  }

  Future<void> _updateLocation() async {
    if (!_isRunning || _isPaused) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_lastPosition != null) {
        final double lat1 = _lastPosition!.latitude;
        final double lon1 = _lastPosition!.longitude;
        final double lat2 = position.latitude;
        final double lon2 = position.longitude;

        final double deltaDistance = DistanceUtils.calculateDistance(
          lat1, lon1, lat2, lon2,
        );

        // 过滤掉异常的距离跳跃（超过100米/秒）
        if (deltaDistance < 100) {
          setState(() {
            _distance += deltaDistance;
            _currentSpeed = position.speed > 0 ? position.speed : deltaDistance;

            // 计算卡路里
            final double km = _distance / 1000;
            _calories = km * (_selectedType == 0
                ? AppConstants.caloriesPerKmRunning
                : AppConstants.caloriesPerKmCycling);
          });
        }
      }

      _lastPosition = position;

      // 记录路线点（每10秒记录一次）
      if (_duration % 10 == 0) {
        _routePoints.add({
          'lat': position.latitude,
          'lon': position.longitude,
        });
      }
    } catch (e) {
      // GPS获取失败，忽略
    }
  }

  String get _formattedDuration {
    return DistanceUtils.formatDuration(_duration);
  }

  String get _formattedPace {
    if (_distance < 100) return "--'--\"";
    final secondsPerKm = _duration / (_distance / 1000);
    return DistanceUtils.formatPace(secondsPerKm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动'),
        automaticallyImplyLeading: false,
      ),
      body: _isRunning ? _buildRunningView() : _buildStartView(),
    );
  }

  Widget _buildStartView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // GPS状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _gpsEnabled
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _gpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: _gpsEnabled ? AppTheme.primaryColor : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _gpsStatus,
                  style: TextStyle(
                    color: _gpsEnabled ? AppTheme.primaryColor : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 运动类型选择
          Text(
            '选择运动类型',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTypeCard(
                type: 0,
                icon: Icons.directions_run,
                label: '跑步',
                color: AppTheme.runningColor,
              ),
              _buildTypeCard(
                type: 1,
                icon: Icons.directions_bike,
                label: '骑行',
                color: AppTheme.cyclingColor,
              ),
            ],
          ),

          const Spacer(),

          // 开始按钮
          GestureDetector(
            onTap: _gpsEnabled ? _startWorkout : _checkGpsStatus,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '开始',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required int type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 运动类型标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedType == 0
                  ? AppTheme.runningColor.withValues(alpha: 0.1)
                  : AppTheme.cyclingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedType == 0 ? '跑步中' : '骑行中',
              style: TextStyle(
                color: _selectedType == 0
                    ? AppTheme.runningColor
                    : AppTheme.cyclingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 用时
          Text(
            '用时',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formattedDuration,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const Spacer(),

          // 数据展示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDataItem(
                label: '距离',
                value: DistanceUtils.formatDistance(_distance),
              ),
              _buildDataItem(
                label: _selectedType == 0 ? '配速' : '时速',
                value: _selectedType == 0
                    ? _formattedPace
                    : DistanceUtils.formatSpeed(_currentSpeed),
              ),
              _buildDataItem(
                label: '卡路里',
                value: '${_calories.toStringAsFixed(0)} kcal',
              ),
            ],
          ),

          const Spacer(),

          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 暂停/继续按钮
              GestureDetector(
                onTap: _isPaused ? _resumeWorkout : _pauseWorkout,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

              // 结束按钮
              GestureDetector(
                onTap: _stopWorkout,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_isPaused)
            Text(
              '已暂停',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}