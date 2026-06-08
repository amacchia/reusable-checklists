import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive_utils.dart';
import 'checklist_master_detail_screen.dart';
import 'settings_screen.dart';

class AdaptiveLayoutShell extends StatefulWidget {
  const AdaptiveLayoutShell({super.key});

  @override
  State<AdaptiveLayoutShell> createState() => _AdaptiveLayoutShellState();
}

class _AdaptiveLayoutShellState extends State<AdaptiveLayoutShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isCompact(context)) {
      return _buildCompactLayout();
    }
    return _buildWideLayout();
  }

  Widget _buildCompactLayout() {
    return const ChecklistMasterDetailScreen();
  }

  Widget _buildWideLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: colorScheme.surface,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: Text(AppStrings.checklists),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text(AppStrings.settings),
              ),
            ],
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const ChecklistMasterDetailScreen()
                : const SettingsScreen(showAppBar: false),
          ),
        ],
      ),
    );
  }
}
