import 'package:flutter/material.dart';

class PasswordChangeValues {
  final String currentPassword;
  final String newPassword;
  const PasswordChangeValues(this.currentPassword, this.newPassword);
}

Future<PasswordChangeValues?> showPasswordChangeDialog(
  BuildContext context, {
  required String title,
}) =>
    showDialog<PasswordChangeValues>(
      context: context,
      builder: (_) => _PasswordChangeDialog(title: title),
    );

class _PasswordChangeDialog extends StatefulWidget {
  final String title;
  const _PasswordChangeDialog({required this.title});

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your current password' : null,
              ),
              TextFormField(
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => value == null || value.length < 6
                    ? 'Use at least 6 characters'
                    : null,
              ),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (value) => value != _new.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                PasswordChangeValues(_current.text, _new.text),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      );
}
