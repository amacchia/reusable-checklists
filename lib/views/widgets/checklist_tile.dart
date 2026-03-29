import 'package:flutter/material.dart';

import '../../data/models/checklist.dart';

class ChecklistTile extends StatelessWidget {
  final Checklist checklist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ChecklistTile({
    super.key,
    required this.checklist,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = checklist.items.length;
    final checked = checklist.checkedCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(checklist.name),
        subtitle: total > 0
            ? Text(
                '$checked / $total checked',
                style: TextStyle(color: colorScheme.outline),
              )
            : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
