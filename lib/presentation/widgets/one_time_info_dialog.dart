import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OneTimeInfoDialog {
  const OneTimeInfoDialog._();

  static Future<bool> show({
    required final BuildContext context,
    required final String storageKey,
    required final String title,
    required final String message,
    required final String actionLabel,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(storageKey) ?? false) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final acknowledged = await showPlatformDialog<bool>(
      context: context,
      material: MaterialDialogData(
        builder: (final context) => PlatformAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            PlatformDialogAction(onPressed: () => Navigator.of(context).pop(false), child: Text(S.current.onboardingClose)),
            PlatformDialogAction(onPressed: () => Navigator.of(context).pop(true), child: Text(actionLabel)),
          ],
        ),
      ),
      cupertino: CupertinoDialogData(
        builder: (final context) => PlatformAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
              child: Text(S.current.onboardingClose),
            ),
            PlatformDialogAction(onPressed: () => Navigator.of(context, rootNavigator: true).pop(true), child: Text(actionLabel)),
          ],
        ),
      ),
    );
    if (acknowledged != true) {
      return false;
    }
    await preferences.setBool(storageKey, true);
    return context.mounted;
  }
}
