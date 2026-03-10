import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:zentime/logic/settings.dart';
import 'package:zentime/logic/workday.dart';
import 'package:zentime/screens/home_screen.dart';

// Notification stuff
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background Action: ${notificationResponse.actionId}');
  print('Payload: ${notificationResponse.payload}');
}

void main() async {
  // Initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  await initNotifications();

  // Hive
  await Hive.initFlutter();

  Hive.registerAdapter(DayTypeAdapter());
  Hive.registerAdapter(EntryTypeAdapter());
  Hive.registerAdapter(TimeEntryAdapter());
  Hive.registerAdapter(WorkDayAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox<Settings>('settingsBox');

  runApp(const MyApp());
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('Foreground Action: ${response.actionId}');
      print('Payload: ${response.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

Future<void> showNotificationWithButtons() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'button_channel',
    'Button Notifications',
    importance: Importance.max,
    priority: Priority.high,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction('accept', "Annehmen ✅"),
      AndroidNotificationAction('decline', "Ablehnen ❌"),
    ],
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: 'Neue Nachricht',
    notificationDetails: details,
    payload: 'meine_daten',
  );
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
