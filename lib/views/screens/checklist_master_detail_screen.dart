import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../viewmodels/checklist_detail_viewmodel.dart';
import '../../viewmodels/checklist_list_viewmodel.dart';
import '../../viewmodels/selection_viewmodel.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/new_checklist_dialog.dart';
import 'checklist_detail_screen.dart';
import 'checklist_list_screen.dart';

class ChecklistMasterDetailScreen extends StatefulWidget {
  const ChecklistMasterDetailScreen({super.key});

  @override
  State<ChecklistMasterDetailScreen> createState() =>
      _ChecklistMasterDetailScreenState();
}

class _ChecklistMasterDetailScreenState
    extends State<ChecklistMasterDetailScreen> {
  String? _selectedChecklistId;
  ChecklistDetailViewModel? _detailVm;

  @override
  void dispose() {
    _detailVm?.removeListener(_onDetailVmChanged);
    _detailVm?.dispose();
    super.dispose();
  }

  void _selectChecklist(String id) {
    if (_selectedChecklistId == id) return;
    _detailVm?.dispose();
    final repo = context.read<ChecklistRepository>();
    _detailVm = ChecklistDetailViewModel(repo);
    _detailVm!.addListener(_onDetailVmChanged);
    unawaited(_detailVm!.loadChecklist(id));
    setState(() {
      _selectedChecklistId = id;
    });
  }

  void _onDetailVmChanged() {
    final listVm = context.read<ChecklistListViewModel>();
    final detailVm = _detailVm;
    if (detailVm == null || detailVm.checklist == null) return;
    final id = detailVm.checklist!.id;
    final index = listVm.checklists.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final updated = detailVm.checklist!.copyWith();
    final list = List.of(listVm.checklists);
    list[index] = updated;
    listVm.updateChecklistInList(updated);
  }

  void _deselectChecklist() {
    if (_selectedChecklistId == null) return;
    _detailVm?.removeListener(_onDetailVmChanged);
    _detailVm?.dispose();
    _detailVm = null;
    setState(() {
      _selectedChecklistId = null;
    });
  }

  void _resetSelected(
    BuildContext scaffoldContext,
    ChecklistListViewModel listVm,
  ) {
    final selection = context.read<SelectionNotifier>();
    final originalChecklists = listVm.checklists
        .where((c) => selection.selectedIds.contains(c.id))
        .toList();
    final count = originalChecklists.length;
    for (final checklist in originalChecklists) {
      unawaited(listVm.resetChecklist(checklist.id));
    }
    selection.clearSelection();
    final message = count == 1
        ? AppStrings.checklistReset
        : AppStrings.checklistsReset.replaceFirst('{count}', '$count');
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            for (final checklist in originalChecklists) {
              unawaited(listVm.saveChecklist(checklist));
            }
          },
        ),
      ),
    );
  }

  void _deleteSelected(
    BuildContext scaffoldContext,
    ChecklistListViewModel listVm,
  ) {
    final selection = context.read<SelectionNotifier>();
    final deletedChecklists = listVm.checklists
        .where((c) => selection.selectedIds.contains(c.id))
        .toList();
    final count = deletedChecklists.length;
    for (final checklist in deletedChecklists) {
      unawaited(listVm.deleteChecklist(checklist.id));
    }
    if (selection.selectedIds.contains(_selectedChecklistId)) {
      _deselectChecklist();
    }
    selection.clearSelection();
    final message = count == 1
        ? AppStrings.checklistDeleted
        : AppStrings.checklistsDeleted.replaceFirst('{count}', '$count');
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () {
            for (final checklist in deletedChecklists) {
              unawaited(listVm.saveChecklist(checklist));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveUtils.isCompact(context);

    if (isCompact) {
      return const ChecklistListScreen();
    }

    return Consumer<SelectionNotifier>(
      builder: (context, selection, _) {
        return Consumer<ChecklistListViewModel>(
          builder: (context, listVm, _) {
            final splitRatio = ResponsiveUtils.isExpanded(context) ? 0.35 : 0.4;

            return PopScope(
              canPop:
                  _selectedChecklistId == null && !selection.isSelectionMode,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (selection.isSelectionMode) {
                  selection.clearSelection();
                  return;
                }
                if (_selectedChecklistId != null) {
                  _deselectChecklist();
                }
              },
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * splitRatio,
                    child: _buildListPanel(listVm, selection),
                  ),
                  Expanded(child: _buildDetailPanel()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListPanel(
    ChecklistListViewModel listVm,
    SelectionNotifier selection,
  ) {
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
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.restart_alt),
                      tooltip: AppStrings.reset,
                      onPressed: () => _resetSelected(context, listVm),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: AppStrings.delete,
                      onPressed: () => _deleteSelected(context, listVm),
                    );
                  },
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
              ],
            ),
      body: ChecklistListBody(
        vm: listVm,
        selection: selection,
        onStartSelection: selection.startSelection,
        onChecklistTap: _selectChecklist,
      ),
      floatingActionButton: selection.isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showNewChecklistDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildDetailPanel() {
    final detailVm = _detailVm;
    if (detailVm == null || _selectedChecklistId == null) {
      return const Scaffold(
        body: EmptyStateWidget(
          title: AppStrings.selectChecklist,
          subtitle: AppStrings.selectChecklistSubtitle,
          icon: Icons.checklist_outlined,
        ),
      );
    }
    return ChangeNotifierProvider<ChecklistDetailViewModel>.value(
      value: detailVm,
      child: const Scaffold(
        appBar: ChecklistDetailAppBar(),
        body: ChecklistDetailBody(),
      ),
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
