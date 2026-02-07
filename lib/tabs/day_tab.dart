import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:zentime/logic/week.dart';
import 'package:zentime/logic/workday.dart';

class DayTab extends StatefulWidget {
  const DayTab({super.key});

  @override
  State<DayTab> createState() => _DayTab();
}

class _DayTab extends State<DayTab> {
  late bool checkInEnabled;
  late bool checkOutEnabled;
  late bool breakEnabled;
  late bool workEnabled;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    checkInEnabled = false;
    checkOutEnabled = false;
    breakEnabled = false;
    workEnabled = false;
    // start periodic refresh so UI updates automatically (every second)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // load persisted button state based on today's entries
    _loadButtonState();
  }

  Future<void> _loadButtonState() async {
    final box = await Hive.openBox<WorkDay>('workdays');
    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    final workDay = box.get(todayKey);

    if (workDay == null || workDay.entries.isEmpty) {
      // no entries: only Check-In (and More) available
      if (mounted) {
        setState(() {
          checkInEnabled = true;
          checkOutEnabled = false;
          breakEnabled = false;
          workEnabled = false;
        });
      }
      return;
    }

    // there is at least one entry
    final entries = workDay.entries;
    final last = entries.isNotEmpty ? entries.last : null;

    bool lastIsOngoing = false;
    if (last != null) {
      lastIsOngoing = last.end.isAtSameMomentAs(last.start);
    }

    if (mounted) {
      if (lastIsOngoing) {
        // an entry is ongoing: allow checkout and toggling between work/break
        setState(() {
          checkInEnabled = false;
          checkOutEnabled = true;
          breakEnabled = last != null && last.type == EntryType.work;
          workEnabled = last != null && last.type == EntryType.coffeeBreak;
        });
      } else {
        // last entry already closed: no action buttons (only More)
        setState(() {
          checkInEnabled = false;
          checkOutEnabled = false;
          breakEnabled = false;
          workEnabled = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final box = await Hive.openBox<WorkDay>('workdays');

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

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

  Future<void> _handleBreak() async {
    final box = await Hive.openBox<WorkDay>('workdays');

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    final workDay = box.get(todayKey);

    // If no workday exists, create one with a break entry
    if (workDay == null) {
      final newWorkDay = WorkDay(
        date: now,
        dayType: DayType.work,
        entries: [TimeEntry(type: EntryType.coffeeBreak, start: now, end: now)],
      );
      await box.put(todayKey, newWorkDay);
    } else {
      final entries = List<TimeEntry>.from(workDay.entries);

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
        date: workDay.date,
        dayType: workDay.dayType,
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

  Future<void> _handleWork() async {
    final box = await Hive.openBox<WorkDay>('workdays');

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    final workDay = box.get(todayKey);

    // If no workday exists, create one with a work entry
    if (workDay == null) {
      final newWorkDay = WorkDay(
        date: now,
        dayType: DayType.work,
        entries: [TimeEntry(type: EntryType.work, start: now, end: now)],
      );
      await box.put(todayKey, newWorkDay);
    } else {
      final entries = List<TimeEntry>.from(workDay.entries);

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
        date: workDay.date,
        dayType: workDay.dayType,
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

  Future<void> _handleCheckOut() async {
    final box = await Hive.openBox<WorkDay>('workdays');

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    final workDay = box.get(todayKey);

    if (workDay != null && workDay.entries.isNotEmpty) {
      final entries = List<TimeEntry>.from(workDay.entries);
      final lastIndex = entries.length - 1;
      final last = entries[lastIndex];

      // close the last entry by setting its end to now
      entries[lastIndex] = TimeEntry(
        type: last.type,
        start: last.start,
        end: now,
      );

      final updated = WorkDay(
        date: workDay.date,
        dayType: workDay.dayType,
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

  Future<Map<String, dynamic>> _getWorkedHours() async {
    final box = await Hive.openBox<WorkDay>('workdays');

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    final workDay = box.get(todayKey);

    Duration workedDuration = Duration.zero;
    Duration breakDuration = Duration.zero;

    if (workDay != null) {
      for (final entry in workDay.entries) {
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

    final workedHours = workedDuration.inMinutes / 60.0;
    const targetHours = 8.0;
    final remainingHours = (targetHours - workedHours).clamp(0.0, targetHours);
    final progress = (workedHours / targetHours).clamp(0.0, 1.0);

    return {
      'workedHours': workedHours,
      'remainingHours': remainingHours,
      'progress': progress,
      'workedDuration': workedDuration,
      'breakDuration': breakDuration,
    };
  }

  String _formatHours(double hours) {
    return hours.toStringAsFixed(2);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                                final workedHours =
                                    data['workedHours'] as double;
                                final remainingHours =
                                    data['remainingHours'] as double;
                                final progress = data['progress'] as double;

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
                                          "8.00",
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
                                return Text('Error loading work hours');
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                    final duration = snapshot.hasData
                        ? snapshot.data!['workedDuration'] as Duration
                        : Duration.zero;
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
                    final duration = snapshot.hasData
                        ? snapshot.data!['breakDuration'] as Duration
                        : Duration.zero;
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
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
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
                          backgroundColor: theme.colorScheme.secondaryContainer,
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
                          children: [Icon(Icons.coffee_rounded), Text("Break")],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          textStyle: theme.textTheme.bodyLarge,
                          backgroundColor: theme.colorScheme.secondaryContainer,
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
                          backgroundColor: theme.colorScheme.secondaryContainer,
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
                        onPressed: () {},
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
    );
  }
}
