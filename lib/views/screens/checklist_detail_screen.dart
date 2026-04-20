import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../viewmodels/checklist_detail_viewmodel.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/empty_state_widget.dart';

class ChecklistDetailScreen extends StatefulWidget {
  const ChecklistDetailScreen({super.key});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChecklistDetailViewModel>(
      builder: (context, vm, _) {
        final checklist = vm.checklist;
        final items = vm.sortedItems;

        return Scaffold(
          appBar: AppBar(
            title: Text(checklist?.name ?? ''),
            actions: [
              TextButton(
                onPressed: items.isEmpty ? null : () => vm.checkAll(),
                child: const Text(AppStrings.checkAll),
              ),
              TextButton(
                onPressed: items.isEmpty ? null : () => vm.uncheckAll(),
                child: const Text(AppStrings.uncheckAll),
              ),
            ],
          ),
          body: checklist == null
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Column(
                  children: [
                    Expanded(
                      child: items.isEmpty
                          ? const EmptyStateWidget(
                              title: AppStrings.emptyItems,
                              subtitle: AppStrings.emptyItemsSubtitle,
                              icon: Icons.playlist_add,
                            )
                          : _buildItemLists(context, vm),
                    ),
                    _buildAddItemBar(context, vm),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAddItemBar(
      BuildContext context, ChecklistDetailViewModel vm) {
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
                controller: _itemController,
                decoration: const InputDecoration(
                  hintText: AppStrings.addItem,
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addItem(vm),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addItem(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemLists(
      BuildContext context, ChecklistDetailViewModel vm) {
    final unchecked = vm.uncheckedItems;
    final checked = vm.checkedItems;
    final colorScheme = Theme.of(context).colorScheme;

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
                'Completed',
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

  void _addItem(ChecklistDetailViewModel vm) {
    final text = _itemController.text.trim();
    if (text.isNotEmpty) {
      vm.addItem(text);
      _itemController.clear();
    }
  }

  void _deleteItem(
      BuildContext context, ChecklistDetailViewModel vm, String itemId) {
    vm.removeItem(itemId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.itemDeleted)),
    );
  }
}
