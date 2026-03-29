import 'package:flutter/material.dart';

import '../../data/models/checklist_item.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          onTap: onToggle,
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            item.title,
            style: item.isChecked
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.outline,
                  )
                : null,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: onDelete,
              ),
              ReorderableDragStartListener(
                index: item.sortIndex,
                child: Icon(Icons.drag_handle, color: colorScheme.outline),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
