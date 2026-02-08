import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
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

    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysFromMonday));

    Duration totalWorkedDuration = Duration.zero;
    double targetHours = 40.0;
    List<Duration> dailyDurations = List.filled(7, Duration.zero);
    List<double> dailyHours = List.filled(7, 0.0);
    List<DayType> dayTypes = List.filled(7, DayType.work);

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

      switch (workDay?.dayType) {
        case DayType.publicHoliday:
          dayTypes[i] = DayType.publicHoliday;

          if (i < 5) {
            targetHours -= 8.0;
          }
          break;
        case DayType.holiday:
          dayTypes[i] = DayType.holiday;
          if (i < 5) {
            targetHours -= 8.0;
          }
          break;
        case DayType.sick:
          if (i < 5) {
            targetHours -= 8.0;
          }
          dayTypes[i] = DayType.sick;
          break;
        default:
          dayTypes[i] = DayType.work;
      }
    }

    final workedHours = totalWorkedDuration.inMinutes / 60.0;

    for (int i = 0; i < dailyDurations.length; i++) {
      dailyHours[i] = dailyDurations[i].inMinutes / 60.0;
    }

    final remainingHours = (targetHours - workedHours).clamp(0.0, targetHours);
    final progress = (workedHours / targetHours).clamp(0.0, 1.0);

    return {
      'workedHours': workedHours,
      'dailyHours': dailyHours,
      'targetHours': targetHours,
      'dayTypes': dayTypes,
      'remainingHours': remainingHours,
      'progress': progress,
    };
  }

  String _formatHours(double hours) {
    return hours.toStringAsFixed(2);
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
                                      data['workedHours'] as double;
                                  final remainingHours =
                                      data['remainingHours'] as double;
                                  final progress = data['progress'] as double;
                                  final targetHours =
                                      data['targetHours'] as double;

                                  return Column(
                                    spacing: 8,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            _formatHours(workedHours),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          Text(
                                            "/",
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                          Text(
                                            _formatHours(targetHours),
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                      LinearProgressIndicator(value: progress),
                                      Row(
                                        children: [
                                          Text(
                                            _formatHours(remainingHours),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          Text(
                                            " hours remaining",
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[0]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "8.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[1]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "8.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[2]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "8.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[3]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "8.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[4]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "8.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[5]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "0.00",
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
                                            data['dailyHours'] as List<double>;

                                        return Row(
                                          spacing: 8,
                                          children: [
                                            Text(
                                              _formatHours(dailyHours[6]),
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "/",
                                              style: theme.textTheme.bodyLarge,
                                            ),
                                            Text(
                                              "0.00",
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
