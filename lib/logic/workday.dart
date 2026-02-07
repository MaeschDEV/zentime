import 'package:hive_ce/hive.dart';

part 'workday.g.dart';

@HiveType(typeId: 0)
enum DayType {
  @HiveField(0)
  work,
  @HiveField(1)
  sick,
  @HiveField(2)
  holiday,
  @HiveField(3)
  publicHoliday,
}

@HiveType(typeId: 1)
enum EntryType {
  @HiveField(0)
  work,
  @HiveField(1)
  coffeeBreak,
}

@HiveType(typeId: 2)
class TimeEntry {
  @HiveField(0)
  final EntryType type;
  @HiveField(1)
  final DateTime start;
  @HiveField(2)
  final DateTime end;

  TimeEntry({required this.type, required this.start, required this.end});
}

@HiveType(typeId: 3)
class WorkDay extends HiveObject {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final DayType dayType;
  @HiveField(2)
  final List<TimeEntry> entries;

  WorkDay({
    required this.date,
    this.dayType = DayType.work,
    this.entries = const [],
  });

  String get dayKey => "${date.year}-${date.month}-${date.day}";
}
