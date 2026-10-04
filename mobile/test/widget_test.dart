import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatverse_mobile/config/api_config.dart';
import 'package:chatverse_mobile/widgets/password_prompt_dialog.dart';

void main() {
  test('mobile app defaults to the shared ChatVerse backend', () {
    expect(ApiConfig.baseUrl, 'https://chatverse-server-eoma.onrender.com');
    expect(ApiConfig.sendMessage(), '${ApiConfig.baseUrl}/api/messages');
  });

  testWidgets('password dialog cancels without a framework error',
      (tester) async {
    await _pumpPasswordDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('password dialog submits without a framework error',
      (tester) async {
    await _pumpPasswordDialog(tester);
    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPasswordDialog(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showDialog<String>(
            context: context,
            builder: (_) => const PasswordPromptDialog(
              title: 'Set chat password',
              hint: 'Enter password',
              confirmLabel: 'Save',
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
