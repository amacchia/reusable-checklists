import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../viewmodels/checklist_detail_viewmodel.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/empty_state_widget.dart';

class ChecklistDetailScreen extends StatelessWidget {
  const ChecklistDetailScreen({super.key});

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
    return Selector<ChecklistDetailViewModel, ({String name, bool isEmpty})>(
      selector: (_, vm) => (
        name: vm.checklist?.name ?? '',
        isEmpty: vm.sortedItems.isEmpty,
      ),
      builder: (context, data, _) {
        final vm = context.read<ChecklistDetailViewModel>();
        return AppBar(
          title: Text(data.name),
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
              onToggle: () => vm.toggleItem(item.id),
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
    vm.removeItem(itemId);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.itemDeleted)),
    );
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
    context.read<ChecklistDetailViewModel>().addItem(text);
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
