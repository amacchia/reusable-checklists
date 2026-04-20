import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class NewChecklistDialog extends StatefulWidget {
  const NewChecklistDialog({super.key});

  @override
  State<NewChecklistDialog> createState() => _NewChecklistDialogState();
}

class _NewChecklistDialogState extends State<NewChecklistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text(AppStrings.newChecklist),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.checklistName,
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: const Text(AppStrings.create),
        ),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(context, text);
    }
  }
}
