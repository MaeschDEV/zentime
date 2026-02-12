import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:zentime/logic/settings.dart';
import 'package:zentime/logic/week.dart';
import 'package:zentime/logic/workday.dart';

class DayTab extends StatefulWidget {
  const DayTab({super.key});

  @override
  State<DayTab> createState() => _DayTab();
}

class _DayTab extends State<DayTab> {
  Timer? timer;

  late bool breakEnabled;
  late Box<WorkDay> box;
  late bool checkInEnabled;
  late bool checkOutEnabled;
  late DayType currentDayType;
  late DateTime now;
  late String todayKey;
  late WorkDay? workDay;
  late bool workEnabled;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // initialize button states
    checkInEnabled = false;
    checkOutEnabled = false;
    breakEnabled = false;
    workEnabled = false;
    currentDayType = DayType.work;

    // start periodic refresh so UI updates automatically (every second)
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // load persisted button state based on today's entries
    _loadButtonState();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatHours(double hours) {
    return hours.toStringAsFixed(2);
  }

  Future<void> _getBox() async {
    box = await Hive.openBox<WorkDay>('workdays');
    now = DateTime.now();
    todayKey = "${now.year}-${now.month}-${now.day}";

    workDay = box.get(todayKey);
  }

  Future<Map<String, dynamic>> _getWorkedHours() async {
    await _getBox();
    final settingsBox = await Hive.openBox<Settings>('settingsBox');

    Duration workedDuration = Duration.zero;
    Duration breakDuration = Duration.zero;
    double targetHours = 8.0;

    if (workDay != null) {
      for (final entry in workDay!.entries) {
        final start = entry.start;
        var end = entry.end;
        // If entry appears to be ongoing (end == start), treat end as now
        if (end.isAtSameMomentAs(start)) {
          end = DateTime.now();
        }

        final duration = end.difference(start);

        if (entry.type == EntryType.work) {
          workedDuration += duration;
        } else if (entry.type == EntryType.coffeeBreak) {
          breakDuration += duration;
        }
      }
    }

    switch (DateTime.now().weekday) {
      case 1:
        targetHours = settingsBox.get('current')?.mondayWorkHours ?? 8.0;
        break;
      case 2:
        targetHours = settingsBox.get('current')?.tuesdayWorkHours ?? 8.0;
        break;
      case 3:
        targetHours = settingsBox.get('current')?.wednesdayWorkHours ?? 8.0;
        break;
      case 4:
        targetHours = settingsBox.get('current')?.thursdayWorkHours ?? 8.0;
        break;
      case 5:
        targetHours = settingsBox.get('current')?.fridayWorkHours ?? 8.0;
        break;
      case 6:
        targetHours = settingsBox.get('current')?.saturdayWorkHours ?? 0.0;
        break;
      case 7:
        targetHours = settingsBox.get('current')?.sundayWorkHours ?? 0.0;
        break;
      default:
        targetHours = 100;
        break;
    }

    final workedHours = workedDuration.inMinutes / 60.0;
    final remainingHours = (targetHours - workedHours).clamp(0.0, targetHours);

    final clockOutTime = DateTime.now().add(
      Duration(minutes: (remainingHours * 60).round()),
    );

    final clockOutTimeString = DateFormat('HH:mm').format(clockOutTime);

    double progress = 0.0;

    if (targetHours != 0) {
      progress = (workedHours / targetHours).clamp(0.0, 1.0);
    }

    if (workedHours >= (settingsBox.get('current')?.maxDailyWorkHours ?? 10) &&
        checkInEnabled) {
      _handleCheckOut();
    }

    return {
      'workedHours': workedHours,
      'remainingHours': remainingHours,
      'progress': progress,
      'workedDuration': workedDuration,
      'breakDuration': breakDuration,
      'dayType': workDay?.dayType ?? DayType.work,
      'targetHours': targetHours,
      'clockOutTime': clockOutTimeString,
    };
  }

  Future<void> _handleBreak() async {
    await _getBox();

    // If no workday exists, create one with a break entry
    if (workDay == null) {
      final newWorkDay = WorkDay(
        date: now,
        dayType: DayType.work,
        entries: [TimeEntry(type: EntryType.coffeeBreak, start: now, end: now)],
      );
      await box.put(todayKey, newWorkDay);
    } else {
      final entries = List<TimeEntry>.from(workDay!.entries);

      // find last work entry index
      int lastWorkIndex = -1;
      for (int i = entries.length - 1; i >= 0; i--) {
        if (entries[i].type == EntryType.work) {
          lastWorkIndex = i;
          break;
        }
      }

      if (lastWorkIndex != -1) {
        final last = entries[lastWorkIndex];
        // replace last work entry with updated end = now
        entries[lastWorkIndex] = TimeEntry(
          type: last.type,
          start: last.start,
          end: now,
        );
      }

      // append new break entry (start=end=now)
      entries.add(TimeEntry(type: EntryType.coffeeBreak, start: now, end: now));

      final updated = WorkDay(
        date: workDay!.date,
        dayType: workDay!.dayType,
        entries: entries,
      );

      await box.put(todayKey, updated);
    }

    setState(() {
      // after starting break, allow ending break via Work, keep checkout enabled
      checkInEnabled = false;
      checkOutEnabled = true;
      breakEnabled = false;
      workEnabled = true;
    });
  }

  Future<void> _handleCheckIn() async {
    await _getBox();

    // Delete existing WorkDay for today
    await box.delete(todayKey);

    // Create new WorkDay with a Work entry starting now
    final newWorkDay = WorkDay(
      date: now,
      dayType: DayType.work,
      entries: [TimeEntry(type: EntryType.work, start: now, end: now)],
    );

    // Save the new WorkDay
    await box.put(todayKey, newWorkDay);

    // Update button states
    setState(() {
      checkInEnabled = false;
      checkOutEnabled = true;
      breakEnabled = true;
      workEnabled = false;
    });
  }

  Future<void> _handleCheckOut() async {
    await _getBox();

    if (workDay != null && workDay!.entries.isNotEmpty) {
      final entries = List<TimeEntry>.from(workDay!.entries);
      final lastIndex = entries.length - 1;
      final last = entries[lastIndex];

      // close the last entry by setting its end to now
      entries[lastIndex] = TimeEntry(
        type: last.type,
        start: last.start,
        end: now,
      );

      final updated = WorkDay(
        date: workDay!.date,
        dayType: workDay!.dayType,
        entries: entries,
      );

      await box.put(todayKey, updated);
    }

    // after check-out, no action buttons except More should be available
    setState(() {
      checkInEnabled = false;
      checkOutEnabled = false;
      breakEnabled = false;
      workEnabled = false;
    });
  }

  Future<void> _handleWork() async {
    await _getBox();

    // If no workday exists, create one with a work entry
    if (workDay == null) {
      final newWorkDay = WorkDay(
        date: now,
        dayType: DayType.work,
        entries: [TimeEntry(type: EntryType.work, start: now, end: now)],
      );
      await box.put(todayKey, newWorkDay);
    } else {
      final entries = List<TimeEntry>.from(workDay!.entries);

      // find last break entry index
      int lastBreakIndex = -1;
      for (int i = entries.length - 1; i >= 0; i--) {
        if (entries[i].type == EntryType.coffeeBreak) {
          lastBreakIndex = i;
          break;
        }
      }

      if (lastBreakIndex != -1) {
        final last = entries[lastBreakIndex];
        // replace last break entry with updated end = now
        entries[lastBreakIndex] = TimeEntry(
          type: last.type,
          start: last.start,
          end: now,
        );
      }

      // append new work entry (start=end=now)
      entries.add(TimeEntry(type: EntryType.work, start: now, end: now));

      final updated = WorkDay(
        date: workDay!.date,
        dayType: workDay!.dayType,
        entries: entries,
      );

      await box.put(todayKey, updated);
    }

    setState(() {
      checkInEnabled = false;
      checkOutEnabled = true;
      breakEnabled = true;
      workEnabled = false;
    });
  }

  Future<void> _loadButtonState() async {
    await _getBox();

    currentDayType = workDay?.dayType ?? DayType.work;

    if (workDay == null || workDay!.entries.isEmpty) {
      // no entries -> Only Check-In enabled
      if (mounted) {
        setState(() {
          // if day type is not work, disable all action buttons
          if (currentDayType != DayType.work) {
            checkInEnabled = false;
            checkOutEnabled = false;
            breakEnabled = false;
            workEnabled = false;
          } else {
            checkInEnabled = true;
            checkOutEnabled = false;
            breakEnabled = false;
            workEnabled = false;
          }
        });
      }
      return;
    }

    // there is at least one entry
    final entries = workDay!.entries;
    final last = entries.isNotEmpty ? entries.last : null;

    bool lastIsOngoing = false;
    if (last != null) {
      lastIsOngoing = last.end.isAtSameMomentAs(last.start);
    }

    if (mounted) {
      if (currentDayType != DayType.work) {
        // day type is not work, disable all action buttons
        setState(() {
          checkInEnabled = false;
          checkOutEnabled = false;
          breakEnabled = false;
          workEnabled = false;
        });
      } else if (lastIsOngoing) {
        // an entry is ongoing: allow checkout and toggling between work/break
        setState(() {
          checkInEnabled = false;
          checkOutEnabled = true;
          breakEnabled = last != null && last.type == EntryType.work;
          workEnabled = last != null && last.type == EntryType.coffeeBreak;
        });
      } else {
        // last entry already closed: no action buttons
        setState(() {
          checkInEnabled = false;
          checkOutEnabled = false;
          breakEnabled = false;
          workEnabled = false;
        });
      }
    }
  }

  Future<void> _showEditDayDialog() async {
    await _getBox();

    DayType current = workDay?.dayType ?? DayType.work;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Future<void> setDayType(DayType t) async {
              // update or create WorkDay with new dayType
              final updated = workDay != null
                  ? WorkDay(
                      date: workDay!.date,
                      dayType: t,
                      entries: workDay!.entries,
                    )
                  : WorkDay(date: now, dayType: t, entries: []);
              await box.put(todayKey, updated);
              workDay = updated;
              dialogSetState(() {
                current = t;
              });
              if (mounted) {
                // refresh button states
                _loadButtonState();
                setState(() {});
              }
            }

            Widget statusButton(IconData icon, String label, DayType t) {
              final isDisabled = current == t;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton.icon(
                  onPressed: isDisabled ? null : () => setDayType(t),
                  icon: Icon(icon),
                  label: Text(label),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: const Text('Edit this day'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    statusButton(Icons.work_rounded, 'Work', DayType.work),
                    statusButton(Icons.sick_rounded, 'Sick', DayType.sick),
                    statusButton(
                      Icons.beach_access_rounded,
                      'Holiday',
                      DayType.holiday,
                    ),
                    statusButton(
                      Icons.gavel_rounded,
                      'Public Holiday',
                      DayType.publicHoliday,
                    ),
                    const Divider(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await box.delete(todayKey);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (mounted) {
                            _loadButtonState();
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Reset this day'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final hoursFuture = _getWorkedHours();

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
                  Text("Today", style: theme.textTheme.titleLarge),
                  Text(getCurrentDay(), style: theme.textTheme.titleSmall),
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
                                  "Worked today",
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: hoursFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  final dayType = data['dayType'] as DayType;

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
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    );
                                  }

                                  final workedHours =
                                      data['workedHours'] as double;
                                  final remainingHours =
                                      data['remainingHours'] as double;
                                  final clockOutTime =
                                      data['clockOutTime'] as String;
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
                                      (remainingHours != 0.0)
                                          ? Row(
                                              children: [
                                                Text(
                                                  _formatHours(remainingHours),
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                Text(
                                                  " hours remaining - working until ",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                Text(
                                                  clockOutTime,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                Text(
                                                  ".",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ],
                                            )
                                          : Text("Finished Work for today!"),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(snapshot.stackTrace.toString());
                                } else {
                                  return Column(
                                    spacing: 8,
                                    children: [
                                      Row(
                                        spacing: 8,
                                        children: [
                                          SizedBox(
                                            width: 50,
                                            height: 20,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                  SizedBox(height: 8),
                  FutureBuilder<Map<String, dynamic>>(
                    future: hoursFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      final data = snapshot.data!;
                      final dayType = data['dayType'] as DayType;
                      if (dayType != DayType.work) return SizedBox.shrink();
                      final duration = data['workedDuration'] as Duration;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(Icons.work_rounded, size: 48),
                          Row(
                            children: [
                              Text(
                                _formatDuration(duration),
                                style: theme.textTheme.displayLarge,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: hoursFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox.shrink();
                      }
                      final data = snapshot.data!;
                      final dayType = data['dayType'] as DayType;
                      if (dayType != DayType.work) return SizedBox.shrink();
                      final duration = data['breakDuration'] as Duration;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(Icons.coffee_rounded, size: 30),
                          Row(
                            children: [
                              Text(
                                _formatDuration(duration),
                                style: theme.textTheme.displaySmall,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyLarge,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: checkInEnabled ? 2 : 0,
                          ),
                          onPressed: checkInEnabled ? _handleCheckIn : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(Icons.login_rounded),
                              Text("Check-In"),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyLarge,
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: checkOutEnabled ? 2 : 0,
                          ),
                          onPressed: checkOutEnabled ? _handleCheckOut : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(Icons.logout_rounded),
                              Text("Check-Out"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyLarge,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            foregroundColor:
                                theme.colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: breakEnabled ? 2 : 0,
                          ),
                          onPressed: breakEnabled ? _handleBreak : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(Icons.coffee_rounded),
                              Text("Break"),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyLarge,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            foregroundColor:
                                theme.colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: workEnabled ? 2 : 0,
                          ),
                          onPressed: workEnabled ? _handleWork : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [Icon(Icons.work_rounded), Text("Work")],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyLarge,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            foregroundColor:
                                theme.colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => _showEditDayDialog(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(Icons.more_horiz_rounded),
                              Text("More"),
                            ],
                          ),
                        ),
                      ),
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
