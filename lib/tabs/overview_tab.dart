import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:zentime/logic/settings.dart';
import 'package:zentime/logic/week.dart';
import 'package:zentime/logic/workday.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTab();
}

class _OverviewTab extends State<OverviewTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // start periodic refresh so UI updates automatically (every second)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getWeeklyWorkedHours() async {
    final box = await Hive.openBox<WorkDay>('workdays');
    final settingsBox = await Hive.openBox<Settings>('settingsBox');

    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysFromMonday));

    Duration totalWorkedDuration = Duration.zero;
    double targetHours = settingsBox.get('current')?.weeklyWorkHours ?? 40.0;
    List<Duration> dailyDurations = List.filled(7, Duration.zero);
    List<String> dailyHours = List.filled(7, "");
    List<DayType> dayTypes = List.filled(7, DayType.work);
    List<double> dailyTargetHours = List.filled(7, 8.0);
    List<String> dailyTargetHoursString = List.filled(7, "");

    // Loop through each day of the week (Monday to Sunday)
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayKey = "${day.year}-${day.month}-${day.day}";
      final workDay = box.get(dayKey);

      if (workDay != null && workDay.dayType == DayType.work) {
        for (final entry in workDay.entries) {
          if (entry.type == EntryType.work) {
            final start = entry.start;
            var end = entry.end;
            // If entry appears to be ongoing (end == start), treat end as now
            if (end.isAtSameMomentAs(start)) {
              end = DateTime.now();
            }
            final duration = end.difference(start);
            totalWorkedDuration += duration;
            dailyDurations[i] += duration;
          }
        }
      }

      dailyTargetHours[0] = settingsBox.get('current')?.mondayWorkHours ?? 8.0;
      dailyTargetHours[1] = settingsBox.get('current')?.tuesdayWorkHours ?? 8.0;
      dailyTargetHours[2] =
          settingsBox.get('current')?.wednesdayWorkHours ?? 8.0;
      dailyTargetHours[3] =
          settingsBox.get('current')?.thursdayWorkHours ?? 8.0;
      dailyTargetHours[4] = settingsBox.get('current')?.fridayWorkHours ?? 8.0;
      dailyTargetHours[5] =
          settingsBox.get('current')?.saturdayWorkHours ?? 0.0;
      dailyTargetHours[6] = settingsBox.get('current')?.sundayWorkHours ?? 0.0;

      switch (workDay?.dayType) {
        case DayType.publicHoliday:
          dayTypes[i] = DayType.publicHoliday;

          targetHours -= dailyTargetHours[i];
          break;
        case DayType.holiday:
          dayTypes[i] = DayType.holiday;
          targetHours -= dailyTargetHours[i];
          break;
        case DayType.sick:
          targetHours -= dailyTargetHours[i];
          dayTypes[i] = DayType.sick;
          break;
        default:
          dayTypes[i] = DayType.work;
      }
    }

    // Worked Hours
    final workedHours = _formatDurationHHmm(totalWorkedDuration);

    // Target Hours
    final targetHoursDuration = Duration(minutes: (targetHours * 60).round());
    final targetHoursString = _formatDurationHHmm(targetHoursDuration);

    // Progress
    double progress = 0.0;
    if (targetHours != 0) {
      progress = (totalWorkedDuration.inMinutes / 60.0 / targetHours).clamp(
        0.0,
        1.0,
      );
    }

    // Remaining Hours
    final remainingHours =
        (targetHoursDuration - totalWorkedDuration) < Duration.zero
        ? Duration.zero
        : targetHoursDuration - totalWorkedDuration;
    final remainingHoursString = _formatDurationHHmm(remainingHours);

    // Daily Hours
    for (int i = 0; i < dailyDurations.length; i++) {
      dailyHours[i] = _formatDurationHHmm(dailyDurations[i]);
    }

    // Daily target Hours
    for (int i = 0; i < dailyTargetHours.length; i++) {
      dailyTargetHoursString[i] = _formatDurationHHmm(
        Duration(minutes: (dailyTargetHours[i] * 60).round()),
      );
    }

    return {
      'workedHours': workedHours,
      'targetHours': targetHoursString,
      'progress': progress,
      'remainingHours': remainingHoursString,
      'dailyHours': dailyHours,
      'dailyTargetHours': dailyTargetHoursString,
      'dayTypes': dayTypes,
    };
  }

  String _formatDurationHHmm(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final weeklyFuture = _getWeeklyWorkedHours();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Overview", style: theme.textTheme.titleLarge),
                  Card.outlined(
                    elevation: 2,
                    child: SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 16,
                              children: [
                                Icon(Icons.schedule_rounded),
                                Text(
                                  "Recorded this week",
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: weeklyFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  final workedHours =
                                      data['workedHours'] as String;
                                  final remainingHours =
                                      data['remainingHours'] as String;
                                  final progress = data['progress'] as double;
                                  final targetHours =
                                      data['targetHours'] as String;

                                  return Column(
                                    spacing: 8,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            workedHours,
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          Text(
                                            "/",
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          Text(
                                            targetHours,
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                      LinearProgressIndicator(value: progress),
                                      (remainingHours != "0.0")
                                          ? Row(
                                              children: [
                                                Text(
                                                  remainingHours,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                Text(
                                                  " hours remaining",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            )
                                          : Text(
                                              "Finished Work for this week!",
                                            ),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error loading weekly hours');
                                } else {
                                  return Column(
                                    spacing: 8,
                                    children: [
                                      LinearProgressIndicator(),
                                      Text(
                                        "Loading...",
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[0],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][0] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[0],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[0],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[1],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][1] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[1],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[1],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[2],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][2] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[2],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[2],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[3],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][3] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[3],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[3],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[4],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][4] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[4],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[4],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[5],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][5] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[5],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[5],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Card.outlined(
                          elevation: 2,
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                spacing: 16,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getCurrentWeek()[6],
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: weeklyFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final data = snapshot.data!;
                                        final dayType =
                                            data['dayTypes'][6] as DayType;

                                        if (dayType != DayType.work) {
                                          // show only the status text for non-work days
                                          String label;
                                          switch (dayType) {
                                            case DayType.sick:
                                              label = 'Sick';
                                              break;
                                            case DayType.holiday:
                                              label = 'Holiday';
                                              break;
                                            case DayType.publicHoliday:
                                              label = 'Public Holiday';
                                              break;
                                            default:
                                              label = '';
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Text(
                                              label,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          );
                                        }

                                        final dailyHours =
                                            data['dailyHours'] as List<String>;
                                        final targetHours =
                                            data['dailyTargetHours']
                                                as List<String>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              dailyHours[6],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              targetHours[6],
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                          ],
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error loading weekly hours',
                                        );
                                      } else {
                                        return Column(
                                          spacing: 8,
                                          children: [
                                            LinearProgressIndicator(),
                                            Text(
                                              "Loading...",
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
