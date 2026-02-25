import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/workout_repository.dart';

/// 历史记录页面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _repository = WorkoutRepository();

  DateTime _selectedDate = DateTime.now();
  List<WorkoutRecord> _records = [];
  List<Map<String, dynamic>> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _repository.getWorkoutRecordsByDate(_selectedDate);
    final stats = await _repository.getWeeklyStats();

    if (mounted) {
      setState(() {
        _records = records;
        _weeklyStats = stats;
      });
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _nextDay() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return;
    }
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadData();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 日期选择器
          _buildDateSelector(),

          // 日统计卡片
          _buildDaySummaryCard(),

          // 周统计图表
          if (_weeklyStats.isNotEmpty) _buildWeeklyChart(),

          // 记录列表
          Expanded(
            child: _records.isNotEmpty
                ? _buildRecordsList()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    final dateFormat = DateFormat('MM月dd日', 'zh_CN');
    final weekDay = _getWeekDay(_selectedDate.weekday);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousDay,
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    dateFormat.format(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? '今天' : weekDay,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : _nextDay,
          ),
        ],
      ),
    );
  }

  String _getWeekDay(int weekday) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${days[weekday - 1]}';
  }

  Widget _buildDaySummaryCard() {
    double totalDistance = 0;
    int totalDuration = 0;
    double totalCalories = 0;

    for (final record in _records) {
      totalDistance += record.distance;
      totalDuration += record.duration;
      totalCalories += record.calories;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.route,
            value: DistanceUtils.formatDistance(totalDistance),
            label: '总里程',
          ),
          _buildSummaryItem(
            icon: Icons.timer,
            value: DistanceUtils.formatDuration(totalDuration),
            label: '总时长',
          ),
          _buildSummaryItem(
            icon: Icons.local_fire_department,
            value: totalCalories.toStringAsFixed(0),
            label: '卡路里',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildWeeklyChart() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本周运动',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildBarChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // 准备本周数据
    final Map<int, double> distanceByDay = {};
    for (int i = 0; i < 7; i++) {
      distanceByDay[i] = 0;
    }

    for (final stat in _weeklyStats) {
      final dateStr = stat['date'] as String?;
      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final dayIndex = date.weekday - 1;
          distanceByDay[dayIndex] = (stat['total_distance'] as double?) ?? 0;
        } catch (e) {
          // 忽略解析错误
        }
      }
    }

    // 找最大值用于Y轴
    double maxDistance = 0;
    for (final value in distanceByDay.values) {
      if (value > maxDistance) maxDistance = value;
    }
    if (maxDistance == 0) maxDistance = 5000; // 默认5km

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxDistance / 1000 * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['一', '二', '三', '四', '五', '六', '日'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${value.toInt()}km',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxDistance / 1000 / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.textHint.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: List.generate(7, (index) {
          final distance = distanceByDay[index] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: distance / 1000,
                color: AppTheme.primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(WorkoutRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 图标
            Container(
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

            const SizedBox(width: 16),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.typeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')} - ${record.endTime.hour.toString().padLeft(2, '0')}:${record.endTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 数据
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DistanceUtils.formatDistance(record.distance),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DistanceUtils.formatDuration(record.duration),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '这一天没有运动记录',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}