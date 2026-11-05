import 'package:caesar_puzzle/presentation/widgets/app_switch.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(final Widget child) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.android),
  home: Scaffold(body: InsetSection(children: [InsetRow(title: 'Show my name', trailing: child)])),
);

void main() {
  testWidgets('Material switch is announced with its label', (final tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(AppSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Show my name')));

    expect(find.byType(Switch), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(Switch)),
      containsSemantics(label: 'Show my name', isToggled: true, isEnabled: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('without onChanged the switch is disabled and announced so', (final tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const AppSwitch(value: false, onChanged: null, semanticLabel: 'Show my name')));

    expect(
      tester.getSemantics(find.byType(Switch)),
      containsSemantics(label: 'Show my name', isEnabled: false, hasTapAction: false),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    handle.dispose();
  });

  testWidgets('enabled switch reports changes', (final tester) async {
    bool? changed;
    await tester.pumpWidget(_app(AppSwitch(value: false, onChanged: (final v) => changed = v, semanticLabel: 'X')));

    await tester.tap(find.byType(Switch));
    expect(changed, isTrue);
  });
}
