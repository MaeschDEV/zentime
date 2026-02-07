import 'package:flutter/material.dart';
import 'package:zentime/logic/week.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTab();
}

class _OverviewTab extends State<OverviewTab> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                                    "40.00",
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
                              Text("40.00", style: theme.textTheme.bodyMedium),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: 1),
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
