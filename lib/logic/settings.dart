import 'package:hive_ce_flutter/adapters.dart';

part 'settings.g.dart';

@HiveType(typeId: 0)
class Settings extends HiveObject {
  @HiveField(0)
  final double weeklyWorkHours;

  @HiveField(1)
  final double mondayWorkHours;

  @HiveField(2)
  final double tuesdayWorkHours;

  @HiveField(3)
  final double wednesdayWorkHours;

  @HiveField(4)
  final double thursdayWorkHours;

  @HiveField(5)
  final double fridayWorkHours;

  @HiveField(6)
  final double saturdayWorkHours;

  @HiveField(7)
  final double sundayWorkHours;

  @HiveField(8)
  final double maxDailyWorkHours;

  Settings({
    this.weeklyWorkHours = 40,
    this.mondayWorkHours = 8,
    this.tuesdayWorkHours = 8,
    this.wednesdayWorkHours = 8,
    this.thursdayWorkHours = 8,
    this.fridayWorkHours = 8,
    this.saturdayWorkHours = 0,
    this.sundayWorkHours = 0,
    this.maxDailyWorkHours = 10,
  });
}
