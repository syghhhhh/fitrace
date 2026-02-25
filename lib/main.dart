import 'package:flutter/material.dart';
import 'app.dart';
import 'data/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库（支持桌面平台）
  await DatabaseService.initialize();

  runApp(const FitraceApp());
}