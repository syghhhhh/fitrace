import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/models/user_stats.dart';
import '../../data/models/daily_goal.dart';
import '../../data/repositories/workout_repository.dart';

/// 个人中心页面
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WorkoutRepository _repository = WorkoutRepository();

  UserStats? _userStats;
  DailyGoal? _todayGoal;
  bool _isLoading = true;

  // 目标设置
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final stats = await _repository.getTotalStats();
    final goal = await _repository.getOrCreateTodayGoal();

    if (mounted) {
      setState(() {
        _userStats = stats;
        _todayGoal = goal;
        _distanceController.text = (goal.targetDistance / 1000).toStringAsFixed(1);
        _durationController.text = (goal.targetDuration / 60).toStringAsFixed(0);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    final distance = double.tryParse(_distanceController.text) ?? 5.0;
    final duration = int.tryParse(_durationController.text) ?? 30;

    final goal = DailyGoal(
      date: DateTime.now(),
      targetDistance: distance * 1000, // km -> m
      targetDuration: duration * 60, // min -> s
    );

    await _repository.saveDailyGoal(goal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标已保存')),
      );
      _loadData();
    }
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置每日目标'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '目标里程 (km)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '目标时长 (分钟)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveGoals();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 累计数据卡片
                    _buildStatsCard(),

                    const SizedBox(height: 24),

                    // 今日目标
                    _buildGoalCard(),

                    const SizedBox(height: 24),

                    // 设置选项
                    Text(
                      '设置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    _buildSettingsItem(
                      icon: Icons.flag,
                      title: '目标设置',
                      subtitle: '设置每日运动目标',
                      onTap: _showGoalDialog,
                    ),

                    const SizedBox(height: 12),

                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: '关于',
                      subtitle: 'Fitrace v1.0.0',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Fitrace',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2024 Fitrace',
                          children: [
                            const SizedBox(height: 16),
                            const Text('一款简洁的运动健身记录应用'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '累计运动数据',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                value: _userStats?.totalWorkouts.toString() ?? '0',
                label: '运动次数',
              ),
              _buildStatItem(
                value: _userStats != null
                    ? (_userStats!.totalDistanceInKm).toStringAsFixed(1)
                    : '0',
                label: '总里程(km)',
              ),
              _buildStatItem(
                value: _userStats?.formattedTotalDuration ?? '0分钟',
                label: '总时长',
              ),
              _buildStatItem(
                value: _userStats?.totalCalories.toStringAsFixed(0) ?? '0',
                label: '消耗(kcal)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    if (_todayGoal == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日目标',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_todayGoal!.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '已完成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGoalItem(
                    icon: Icons.route,
                    value: DistanceUtils.formatDistance(_todayGoal!.targetDistance),
                    label: '目标里程',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGoalItem(
                    icon: Icons.timer,
                    value: DistanceUtils.formatDuration(_todayGoal!.targetDuration),
                    label: '目标时长',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}