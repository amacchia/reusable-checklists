import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String submitLabel;
  final String initialValue;
  final TextCapitalization textCapitalization;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.submitLabel,
    this.initialValue = '',
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
        textCapitalization: widget.textCapitalization,
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
          child: Text(widget.submitLabel),
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
