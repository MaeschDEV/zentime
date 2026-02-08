import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:zentime/logic/settings.dart';
import 'package:zentime/logic/workday.dart';
import 'package:zentime/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(DayTypeAdapter());
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(TimeEntryAdapter());
  Hive.registerAdapter(WorkDayAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox<Settings>('settingsBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zentime',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
