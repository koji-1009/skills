import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = SharedPreferencesAsync();
  final count = (await prefs.getInt('count') ?? 0) + 1;
  await prefs.setInt('count', count);
  runApp(MaterialApp(home: Text('Launched $count times')));
}
