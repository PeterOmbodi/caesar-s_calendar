import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    this.destructive = false,
    this.isDefault = false,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final bool isDefault;

  static Future<bool> show(
    final BuildContext context, {
    required final String title,
    required final String message,
    required final String cancelLabel,
    required final String confirmLabel,
    final bool destructive = false,
    final bool isDefault = false,
  }) async =>
      await showAdaptiveDialog<bool>(
        context: context,
        builder: (_) => ConfirmDialog(
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          destructive: destructive,
          isDefault: isDefault,
        ),
      ) ??
      false;

  @override
  Widget build(final BuildContext context) => PlatformAlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      PlatformDialogAction(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
      PlatformDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        cupertino: (_, _) => CupertinoDialogActionData(isDefaultAction: isDefault, isDestructiveAction: destructive),
        child: Text(confirmLabel),
      ),
    ],
  );
}
