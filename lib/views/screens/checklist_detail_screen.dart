import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/checklist_item.dart';
import '../../viewmodels/checklist_detail_viewmodel.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/text_input_dialog.dart';

class ChecklistDetailScreen extends StatefulWidget {
  const ChecklistDetailScreen({super.key});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  ChecklistDetailViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<ChecklistDetailViewModel>();
    if (vm != _vm) {
      _vm?.removeListener(_onVmChanged);
      _vm = vm;
      _vm!.addListener(_onVmChanged);
    }
  }

  @override
  void dispose() {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      vm.clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ChecklistAppBar(),
      body: _ChecklistBody(),
    );
  }
}

class _ChecklistAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChecklistAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Selector<ChecklistDetailViewModel,
        ({String name, bool isEmpty, bool hasChecklist})>(
      selector: (_, vm) => (
        name: vm.checklist?.name ?? '',
        isEmpty: vm.sortedItems.isEmpty,
        hasChecklist: vm.checklist != null,
      ),
      builder: (context, data, _) {
        final vm = context.read<ChecklistDetailViewModel>();
        return AppBar(
          title: InkWell(
            onTap: data.hasChecklist
                ? () => _showRenameDialog(context, vm, data.name)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Tooltip(
              message: AppStrings.renameChecklist,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Text(data.name),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: data.isEmpty ? null : vm.checkAll,
              child: const Text(AppStrings.checkAll),
            ),
            TextButton(
              onPressed: data.isEmpty ? null : vm.uncheckAll,
              child: const Text(AppStrings.uncheckAll),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    ChecklistDetailViewModel vm,
    String currentName,
  ) async {
    final newName = await showAdaptiveDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: AppStrings.renameChecklist,
        hint: AppStrings.checklistName,
        submitLabel: AppStrings.save,
        initialValue: currentName,
        textCapitalization: TextCapitalization.words,
      ),
    );
    if (newName != null) {
      await vm.renameChecklist(newName);
    }
  }
}

class _ChecklistBody extends StatelessWidget {
  const _ChecklistBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChecklistDetailViewModel>();
    if (vm.checklist == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Column(
      children: [
        Expanded(
          child: vm.sortedItems.isEmpty
              ? const EmptyStateWidget(
                  title: AppStrings.emptyItems,
                  subtitle: AppStrings.emptyItemsSubtitle,
                  icon: Icons.playlist_add,
                )
              : const _ItemLists(),
        ),
        const _AddItemBar(),
      ],
    );
  }
}

class _ItemLists extends StatelessWidget {
  const _ItemLists();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChecklistDetailViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final unchecked = vm.uncheckedItems;
    final checked = vm.checkedItems;

    return CustomScrollView(
      slivers: [
        SliverReorderableList(
          itemCount: unchecked.length,
          onReorder: vm.reorderItems,
          itemBuilder: (context, index) {
            final item = unchecked[index];
            return ChecklistItemTile(
              key: ValueKey(item.id),
              item: item,
              reorderIndex: index,
              onToggle: () => vm.toggleItem(item.id),
              onEdit: () => _editItem(context, vm, item),
              onDelete: () => _deleteItem(context, vm, item.id),
            );
          },
        ),
        if (checked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                AppStrings.completed,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.outline,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = checked[index];
                return ChecklistItemTile(
                  key: ValueKey(item.id),
                  item: item,
                  onToggle: () => vm.toggleItem(item.id),
                  onEdit: () => _editItem(context, vm, item),
                  onDelete: () => _deleteItem(context, vm, item.id),
                );
              },
              childCount: checked.length,
            ),
          ),
        ],
      ],
    );
  }

  void _deleteItem(
      BuildContext context, ChecklistDetailViewModel vm, String itemId) {
    final messenger = ScaffoldMessenger.of(context);
    final item = vm.checklist?.items.firstWhere((i) => i.id == itemId);
    if (item == null) return;
    unawaited(vm.removeItem(itemId));
    messenger.showSnackBar(
      SnackBar(
        content: const Text(AppStrings.itemDeleted),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () => vm.restoreItem(item),
        ),
      ),
    );
  }

  Future<void> _editItem(
    BuildContext context,
    ChecklistDetailViewModel vm,
    ChecklistItem item,
  ) async {
    final newTitle = await showAdaptiveDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: AppStrings.editItem,
        hint: AppStrings.itemText,
        submitLabel: AppStrings.save,
        initialValue: item.title,
      ),
    );
    if (newTitle != null) {
      await vm.editItem(item.id, newTitle);
    }
  }
}

class _AddItemBar extends StatefulWidget {
  const _AddItemBar();

  @override
  State<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<_AddItemBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    unawaited(context.read<ChecklistDetailViewModel>().addItem(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: AppStrings.addItem,
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addItem(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
            ),
          ],
        ),
      ),
    );
  }
}
