import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/actions/game_action.dart';
import 'package:caesar_puzzle/presentation/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

Future<bool> confirmAssist(
  final BuildContext context, {
  required final AssistGate gate,
  required final Future<bool> Function() countsForRecords,
}) async {
  if (gate == AssistGate.open || !await countsForRecords()) return true;
  if (!context.mounted) return false;
  return ConfirmDialog.show(
    context,
    title: S.current.assistNoRecordsTitle,
    message: S.current.assistNoRecordsMessage,
    cancelLabel: S.current.solutionsFoundDialogCancel,
    confirmLabel: S.current.assistNoRecordsContinue,
  );
}

Future<void> showDeadEndNotice(final BuildContext context) => showAdaptiveDialog<void>(
  context: context,
  builder: (final context) => PlatformAlertDialog(
    title: Text(S.current.searchCompletedDialogTitle),
    content: Text(S.current.solutionsNotFoundDialogMessage),
    actions: [PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok))],
  ),
);
