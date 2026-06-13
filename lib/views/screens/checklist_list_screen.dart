import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/navigation/route_observer.dart';
import '../../viewmodels/checklist_list_viewmodel.dart';
import '../../viewmodels/selection_viewmodel.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/new_checklist_dialog.dart';

class ChecklistListScreen extends StatefulWidget {
  final bool showSettingsAction;

  const ChecklistListScreen({super.key, this.showSettingsAction = true});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen>
    with RouteAware {
  ChecklistListViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    final vm = context.read<ChecklistListViewModel>();
    if (vm != _vm) {
      _vm?.removeListener(_onVmChanged);
      _vm = vm;
      _vm!.addListener(_onVmChanged);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    final vm = _vm;
    if (vm == null || !mounted) return;
    final error = vm.errorMessage;
    if (error == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      vm.clearError();
    });
  }

  @override
  void didPopNext() {
    unawaited(context.read<ChecklistListViewModel>().loadChecklists());
  }

  void _resetSelected(BuildContext context, ChecklistListViewModel vm) {
    final selection = context.read<SelectionNotifier>();
    final originalChecklists = vm.checklists
        .where((c) => selection.selectedIds.contains(c.id))
        .toList();
    final count = originalChecklists.length;

    for (final checklist in originalChecklists) {
      unawaited(vm.resetChecklist(checklist.id));
    }
    selection.clearSelection();

    final message = count == 1
        ? AppStrings.checklistReset
        : AppStrings.checklistsReset.replaceFirst('{count}', '$count');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            for (final checklist in originalChecklists) {
              unawaited(vm.saveChecklist(checklist));
            }
          },
        ),
      ),
    );
  }

  void _deleteSelected(BuildContext context, ChecklistListViewModel vm) {
    final selection = context.read<SelectionNotifier>();
    final deletedChecklists = vm.checklists
        .where((c) => selection.selectedIds.contains(c.id))
        .toList();
    final count = deletedChecklists.length;

    for (final checklist in deletedChecklists) {
      unawaited(vm.deleteChecklist(checklist.id));
    }
    selection.clearSelection();

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
              unawaited(vm.saveChecklist(checklist));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionNotifier>(
      builder: (context, selection, _) {
        return PopScope(
          canPop: !selection.isSelectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              selection.clearSelection();
            }
          },
          child: Consumer<ChecklistListViewModel>(
            builder: (context, vm, _) {
              return Scaffold(
                appBar: selection.isSelectionMode
                    ? AppBar(
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: selection.clearSelection,
                        ),
                        title: Text(
                          AppStrings.nSelected.replaceFirst(
                            '{count}',
                            '${selection.selectedIds.length}',
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.restart_alt),
                            tooltip: AppStrings.reset,
                            onPressed: () => _resetSelected(context, vm),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: AppStrings.delete,
                            onPressed: () => _deleteSelected(context, vm),
                          ),
                        ],
                      )
                    : AppBar(
                        title: const Text(AppStrings.appTitle),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.select_all),
                            tooltip: AppStrings.select,
                            onPressed: selection.enterSelectionMode,
                          ),
                          if (widget.showSettingsAction)
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/settings'),
                            ),
                        ],
                      ),
                body: ChecklistListBody(
                  vm: vm,
                  selection: selection,
                  onStartSelection: selection.startSelection,
                ),
                floatingActionButton: selection.isSelectionMode
                    ? null
                    : FloatingActionButton(
                        onPressed: () => _showNewChecklistDialog(context),
                        child: const Icon(Icons.add),
                      ),
              );
            },
          ),
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
      await vm.createChecklist(name);
    }
  }
}

class ChecklistListBody extends StatelessWidget {
  final ChecklistListViewModel vm;
  final SelectionNotifier selection;
  final ValueChanged<String>? onChecklistTap;
  final ValueChanged<String> onStartSelection;

  const ChecklistListBody({
    super.key,
    required this.vm,
    required this.selection,
    required this.onStartSelection,
    this.onChecklistTap,
  });

  @override
  Widget build(BuildContext context) {
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
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vm.checklists.length,
      buildDefaultDragHandles: false,
      onReorderItem: vm.reorderChecklists,
      itemBuilder: (context, index) {
        final checklist = vm.checklists[index];
        return ChecklistTile(
          key: ValueKey(checklist.id),
          checklist: checklist,
          reorderIndex: index,
          isSelectionMode: selection.isSelectionMode,
          isSelected: selection.isSelected(checklist.id),
          onTap: () {
            final customTap = onChecklistTap;
            if (customTap != null) {
              customTap(checklist.id);
            } else {
              unawaited(
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: checklist.id,
                ),
              );
            }
          },
          onLongPress: () => onStartSelection(checklist.id),
          onSelectionTap: () => selection.toggleSelection(checklist.id),
        );
      },
    );
  }
}
