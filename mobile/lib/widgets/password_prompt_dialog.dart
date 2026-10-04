import 'package:flutter/material.dart';

/// Owns its input controller for the full dialog route lifecycle. The dialog
/// route may continue its exit animation after Navigator.pop returns a result.
class PasswordPromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String confirmLabel;

  const PasswordPromptDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
