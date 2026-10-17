import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/cupertino_settings_panel.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/material_settings_panel.dart';
import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(final BuildContext context) => ScreenSpec.of(context).family == ChromeFamily.glass
      ? const CupertinoSettingsPanel()
      : const MaterialSettingsPanel();
}
