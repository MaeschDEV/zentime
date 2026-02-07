import 'package:flutter/material.dart';

class DayTab extends StatefulWidget {
  const DayTab({super.key});

  @override
  State<DayTab> createState() => _DayTab();
}

class _DayTab extends State<DayTab> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    var checkInEnabled = true;
    var checkOutEnabled = false;
    var breakEnabled = false;
    var workEnabled = false;

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
                Text("Monday, 27.01.26", style: theme.textTheme.titleSmall),
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
                          Column(
                            spacing: 8,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                  Text(
                                    "0.00",
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Text("/", style: theme.textTheme.bodyLarge),
                                  Text(
                                    "8.00",
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              LinearProgressIndicator(
                                year2023: false,
                                value: 0.25,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("8.00", style: theme.textTheme.bodyMedium),
                              Text(
                                " hours remaining",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.work_rounded, size: 48),
                    Row(
                      children: [
                        Text("00", style: theme.textTheme.displayLarge),
                        Text(":", style: theme.textTheme.displayLarge),
                        Text("00", style: theme.textTheme.displayLarge),
                        Text(":", style: theme.textTheme.displayLarge),
                        Text("00", style: theme.textTheme.displayLarge),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.coffee_rounded, size: 30),
                    Row(
                      children: [
                        Text("00", style: theme.textTheme.displaySmall),
                        Text(":", style: theme.textTheme.displaySmall),
                        Text("00", style: theme.textTheme.displaySmall),
                        Text(":", style: theme.textTheme.displaySmall),
                        Text("00", style: theme.textTheme.displaySmall),
                      ],
                    ),
                  ],
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
                        onPressed: checkInEnabled ? () {} : null,
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
                        onPressed: checkOutEnabled ? () {} : null,
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
                        onPressed: breakEnabled ? () {} : null,
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
                        onPressed: workEnabled ? () {} : null,
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
