import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/workout_repository.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../core/utils/distance_utils.dart';
import '../workout/workout_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final WorkoutRepository _repository = WorkoutRepository();

  // 今日数据
  double _todayDistance = 0;
  int _todayDuration = 0;
  double _todayCalories = 0;
  double _targetDistance = 5000;

  // 最近记录
  WorkoutRecord? _latestRecord;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 加载今日统计
    final todayStats = await _repository.getTodayStats();
    // 加载目标
    final goal = await _repository.getOrCreateTodayGoal();
    // 加载最近记录
    final latest = await _repository.getLatestWorkoutRecord();

    if (mounted) {
      setState(() {
        _todayDistance = (todayStats['total_distance'] as double?) ?? 0;
        _todayDuration = (todayStats['total_duration'] as int?) ?? 0;
        _todayCalories = (todayStats['total_calories'] as double?) ?? 0;
        _targetDistance = goal.targetDistance;
        _latestRecord = latest;
      });
    }
  }

  double get _progress {
    if (_targetDistance <= 0) return 0;
    return (_todayDistance / _targetDistance).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const WorkoutScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // 切换到首页时刷新数据
          if (index == 0) {
            _loadData();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: '运动',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '历史',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitrace'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日概览卡片
              _buildTodayCard(),
              const SizedBox(height: 24),

              // 快速统计
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: '今日里程',
                      value: DistanceUtils.formatDistance(_todayDistance),
                      icon: Icons.route,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: '今日时长',
                      value: DistanceUtils.formatDuration(_todayDuration),
                      icon: Icons.timer,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                title: '消耗卡路里',
                value: '${_todayCalories.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),

              const SizedBox(height: 24),

              // 最近运动记录
              Text(
                '最近运动',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _latestRecord != null
                  ? _buildLatestRecordCard()
                  : _buildEmptyRecordCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始运动'),
      ),
    );
  }

  Widget _buildTodayCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日目标',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_targetDistance / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已完成 ${(_todayDistance / 1000).toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ProgressRing(
                  progress: _progress,
                  size: 80,
                  strokeWidth: 8,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  child: Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestRecordCard() {
    if (_latestRecord == null) return const SizedBox.shrink();

    final record = _latestRecord!;
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: record.type == 0
                ? AppTheme.runningColor.withValues(alpha: 0.1)
                : AppTheme.cyclingColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            record.type == 0 ? Icons.directions_run : Icons.directions_bike,
            color: record.type == 0
                ? AppTheme.runningColor
                : AppTheme.cyclingColor,
          ),
        ),
        title: Text(record.typeName),
        subtitle: Text(
          '${record.startTime.month}月${record.startTime.day}日 ${record.startTime.hour}:${record.startTime.minute.toString().padLeft(2, '0')}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DistanceUtils.formatDistance(record.distance),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              DistanceUtils.formatDuration(record.duration),
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.directions_run,
                size: 48,
                color: AppTheme.textHint,
              ),
              const SizedBox(height: 12),
              Text(
                '还没有运动记录',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击下方按钮开始第一次运动吧',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}