import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/checklist.dart';
import '../../main.dart';
import '../../viewmodels/checklist_list_viewmodel.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/new_checklist_dialog.dart';

class ChecklistListScreen extends StatefulWidget {
  const ChecklistListScreen({super.key});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ChecklistListViewModel>().loadChecklists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<ChecklistListViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.checklists.isEmpty) {
            return const EmptyStateWidget(
              title: AppStrings.emptyChecklists,
              subtitle: AppStrings.emptyChecklistsSubtitle,
              icon: Icons.checklist_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: vm.checklists.length,
            itemBuilder: (context, index) {
              final checklist = vm.checklists[index];
              return ChecklistTile(
                checklist: checklist,
                onTap: () {
                  Navigator.pushNamed(context, '/detail',
                      arguments: checklist.id);
                },
                onDelete: () => _deleteChecklist(context, vm, checklist),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChecklistDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showNewChecklistDialog(BuildContext context) async {
    final vm = context.read<ChecklistListViewModel>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const NewChecklistDialog(),
    );
    if (name != null) {
      vm.createChecklist(name);
    }
  }

  void _deleteChecklist(
    BuildContext context,
    ChecklistListViewModel vm,
    Checklist checklist,
  ) {
    vm.deleteChecklist(checklist.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.checklistDeleted),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () => vm.saveChecklist(checklist),
        ),
      ),
    );
  }
}
