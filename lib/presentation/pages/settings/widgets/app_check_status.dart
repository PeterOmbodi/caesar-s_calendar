import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firebase_bootstrap.dart';
import 'package:caesar_puzzle/presentation/widgets/adaptive_dialog.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showAppCheckStatus(final BuildContext context) =>
    showAdaptiveDialog<void>(context: context, builder: (_) => const _AppCheckStatusDialog());

class _AppCheckStatusDialog extends StatefulWidget {
  const _AppCheckStatusDialog();

  @override
  State<_AppCheckStatusDialog> createState() => _AppCheckStatusDialogState();
}

class _AppCheckStatusDialogState extends State<_AppCheckStatusDialog> {
  final Future<String> _status = FirebaseBootstrap.appCheckStatus();

  @override
  Widget build(final BuildContext context) => AlertDialog.adaptive(
    title: const Text('App Check'),
    content: FutureBuilder(
      future: _status,
      builder: (final context, final snapshot) =>
          snapshot.hasData ? SelectableText(snapshot.data!) : const Center(child: CircularProgressIndicator.adaptive()),
    ),
    actions: [AdaptiveDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok))],
  );
}

/// Opens the App Check status after [taps] quick taps on [child]: the only way to reach it in a release build.
class AppCheckSecretTap extends StatefulWidget {
  const AppCheckSecretTap({super.key, required this.child, this.taps = 7});

  final Widget child;
  final int taps;

  @override
  State<AppCheckSecretTap> createState() => _AppCheckSecretTapState();
}

class _AppCheckSecretTapState extends State<AppCheckSecretTap> {
  static const _maxGap = Duration(seconds: 1);

  int _count = 0;
  DateTime? _lastTap;

  void _onTap() {
    final now = DateTime.now();
    final last = _lastTap;
    _count = last != null && now.difference(last) <= _maxGap ? _count + 1 : 1;
    _lastTap = now;
    if (_count < widget.taps) return;
    _count = 0;
    showAppCheckStatus(context);
  }

  @override
  Widget build(final BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: _onTap,
    child: widget.child,
  );
}
