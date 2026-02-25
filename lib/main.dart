import 'package:flutter/material.dart';

void main() {
  runApp(const FitraceApp());
}

class FitraceApp extends StatelessWidget {
  const FitraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitrace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _runCount = 0;
  double _totalKm = 0.0;

  void _addRun() {
    setState(() {
      _runCount++;
      _totalKm += 5.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Fitrace'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text('运动次数: $_runCount', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text('累计里程: ${_totalKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRun,
        tooltip: '记录一次跑步',
        child: const Icon(Icons.add),
      ),
    );
  }
}