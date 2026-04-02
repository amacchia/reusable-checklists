import 'package:flutter/material.dart';

import '../../data/models/checklist.dart';

class ChecklistTile extends StatelessWidget {
  final Checklist checklist;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionTap;

  const ChecklistTile({
    super.key,
    required this.checklist,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = checklist.items.length;
    final checked = checklist.checkedCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onSelectionTap?.call(),
              )
            : null,
        title: Text(checklist.name),
        subtitle: total > 0
            ? Text(
                '$checked / $total checked',
                style: TextStyle(color: colorScheme.outline),
              )
            : null,
        onTap: isSelectionMode ? onSelectionTap : onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
