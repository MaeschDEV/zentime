import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTab();
}

class _SettingsTab extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                spacing: 32,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Settings", style: theme.textTheme.titleLarge),
                  Column(
                    spacing: 8,
                    children: [
                      Icon(Icons.sentiment_very_dissatisfied_rounded, size: 64),
                      Text(
                        "This site is still under construction.",
                        style: theme.textTheme.bodyMedium,
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
