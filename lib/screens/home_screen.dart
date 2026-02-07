import 'package:flutter/material.dart';
import 'package:zentime/tabs/day_tab.dart';
import 'package:zentime/tabs/overview_tab.dart';
import 'package:zentime/tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontWeight: FontWeight.bold, // Bold wenn ausgewählt
              fontSize: 12,
              color: theme.colorScheme.primary,
            );
          }
          return const TextStyle(fontWeight: FontWeight.normal, fontSize: 12);
        }),

        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: theme.colorScheme.primaryContainer,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.home_rounded,
              size: 26,
              color: theme.colorScheme.primary,
            ),
            icon: Icon(Icons.home_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.calendar_today_rounded,
              size: 26,
              color: theme.colorScheme.primary,
            ),
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.settings_rounded,
              size: 26,
              color: theme.colorScheme.primary,
            ),
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: <Widget>[OverviewTab(), DayTab(), SettingsTab()][currentPageIndex],
    );
  }
}
