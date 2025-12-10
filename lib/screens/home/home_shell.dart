import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_state.dart';
import '../../controllers/landmark_controller.dart';
import '../../models/landmark.dart';
import '../tabs/entry_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/records_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LandmarkController>().fetchLandmarks();
    });
  }

  void _openNewEntry([Landmark? landmark]) {
    final controller = context.read<LandmarkController>();
    if (landmark != null) {
      controller.startEditing(landmark);
    } else {
      controller.resetDraft();
    }
    setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmark Manager'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              appState.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: appState.toggleTheme,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => appState.signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          OverviewTab(onEdit: (landmark) => _openNewEntry(landmark)),
          RecordsTab(
            onEdit: (landmark) => _openNewEntry(landmark),
            onAddNew: () => _openNewEntry(null),
          ),
          EntryTab(onCompleted: () => setState(() => _index = 1)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'New Entry',
          ),
        ],
      ),
    );
  }
}
