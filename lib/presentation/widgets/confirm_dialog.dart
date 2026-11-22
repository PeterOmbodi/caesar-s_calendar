import 'package:caesar_puzzle/presentation/widgets/adaptive_dialog.dart';
import 'package:material_ui/material_ui.dart';

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
  Widget build(final BuildContext context) => AlertDialog.adaptive(
    title: Text(title),
    content: Text(message),
    actions: [
      AdaptiveDialogAction(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
      AdaptiveDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDefault: isDefault,
        destructive: destructive,
        child: Text(confirmLabel),
      ),
    ],
  );
}
