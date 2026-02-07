String getCurrentDay() {
  final now = DateTime.now();

  final dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final dayName = dayNames[now.weekday - 1];

  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = now.year.toString().substring(2);

  return '$dayName, $day.$month.$year';
}

List<String> getCurrentWeek() {
  final now = DateTime.now();

  final daysFromMonday = now.weekday - 1;
  final monday = now.subtract(Duration(days: daysFromMonday));

  final dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final week = <String>[];

  for (int i = 0; i < 7; i++) {
    final day = monday.add(Duration(days: i));
    final dayName = dayNames[i];
    final dayNum = day.day.toString().padLeft(2, '0');
    final month = day.month.toString().padLeft(2, '0');
    final year = day.year.toString().substring(2);

    week.add('$dayName, $dayNum.$month.$year');
  }

  return week;
}
