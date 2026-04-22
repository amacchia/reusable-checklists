import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/navigation/route_observer.dart';
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
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

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

  void _startSelection(String id) {
    setState(() {
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _deleteSelected(BuildContext context, ChecklistListViewModel vm) {
    final deletedChecklists = vm.checklists
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    final count = deletedChecklists.length;

    for (final checklist in deletedChecklists) {
      vm.deleteChecklist(checklist.id);
    }
    _clearSelection();

    final message = count == 1
        ? AppStrings.checklistDeleted
        : AppStrings.checklistsDeleted.replaceFirst('{count}', '$count');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            for (final checklist in deletedChecklists) {
              vm.saveChecklist(checklist);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _clearSelection();
        }
      },
      child: Consumer<ChecklistListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: _isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                    ),
                    title: Text(AppStrings.nSelected
                        .replaceFirst('{count}', '${_selectedIds.length}')),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteSelected(context, vm),
                      ),
                    ],
                  )
                : AppBar(
                    title: const Text(AppStrings.appTitle),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
            body: _buildBody(vm),
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton(
                    onPressed: () => _showNewChecklistDialog(context),
                    child: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ChecklistListViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
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
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedIds.contains(checklist.id),
          onTap: () {
            Navigator.pushNamed(context, '/detail', arguments: checklist.id);
          },
          onLongPress: () => _startSelection(checklist.id),
          onSelectionTap: () => _toggleSelection(checklist.id),
        );
      },
    );
  }

  Future<void> _showNewChecklistDialog(BuildContext context) async {
    final vm = context.read<ChecklistListViewModel>();
    final name = await showAdaptiveDialog<String>(
      context: context,
      builder: (_) => const NewChecklistDialog(),
    );
    if (name != null) {
      vm.createChecklist(name);
    }
  }
}
