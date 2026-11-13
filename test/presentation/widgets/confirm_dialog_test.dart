import 'package:caesar_puzzle/presentation/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Future<bool>> open(final WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (final c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final result = ConfirmDialog.show(
      context,
      title: 'Title',
      message: 'Message',
      cancelLabel: 'Cancel',
      confirmLabel: 'Go',
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('confirm gives true', (final tester) async {
    final result = await open(tester);
    expect(find.text('Message'), findsOneWidget);
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('cancel gives false', (final tester) async {
    final result = await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('a tap outside gives false', (final tester) async {
    final result = await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsNothing);
    expect(await result, isFalse);
  });
}
