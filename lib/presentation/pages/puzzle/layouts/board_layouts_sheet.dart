import 'package:caesar_puzzle/application/models/board_layout.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/services/calendar_cells.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/board_layouts_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

Future<void> showBoardLayoutsSheet(final BuildContext context) {
  final spec = ScreenSpec.of(context);
  final puzzleBloc = context.read<PuzzleBloc>();
  final layoutsCubit = context.read<BoardLayoutsCubit>();
  final settingsCubit = context.read<SettingsCubit>();
  Widget panel({required final bool isSheet}) => MultiBlocProvider(
    providers: [
      BlocProvider<PuzzleBloc>.value(value: puzzleBloc),
      BlocProvider<BoardLayoutsCubit>.value(value: layoutsCubit),
      BlocProvider<SettingsCubit>.value(value: settingsCubit),
    ],
    child: _BoardLayoutsPanel(isSheet: isSheet),
  );

  if (spec.window == WindowClass.compact && !spec.isLandscape) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => panel(isSheet: true),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: panel(isSheet: false),
      ),
    ),
  );
}

Future<String?> showLayoutNameDialog(final BuildContext context, final String title, final String initial) =>
    showDialog<String>(context: context, builder: (_) => _NameDialog(title: title, initial: initial));

class _BoardLayoutsPanel extends StatefulWidget {
  const _BoardLayoutsPanel({required this.isSheet});

  final bool isSheet;

  @override
  State<_BoardLayoutsPanel> createState() => _BoardLayoutsPanelState();
}

class _BoardLayoutsPanelState extends State<_BoardLayoutsPanel> {
  String? _countedFor;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final layouts = context.watch<BoardLayoutsCubit>().state;
    final indicator = context.select<SettingsCubit, SolutionIndicator>((final c) => c.state.solutionIndicator);
    final currentKey = context.select<PuzzleBloc, String>((final b) => cellsKey(b.state.blockedCells));
    final canEdit = context.select<PuzzleBloc, bool>((final b) => !b.state.isShowSolutions);
    final current = layouts.entryWithKey(currentKey);
    final unsaved = current == null
        ? LayoutEntry(
            BoardLayout(
              id: '',
              name: S.current.historyConfigCustom,
              placements: context.read<PuzzleBloc>().state.configPlacements,
            ),
          )
        : null;
    final entries = [...layouts.entries, if (unsaved != null) unsaved];
    _countSolutions(entries, today);

    final radius = widget.isSheet
        ? const BorderRadius.vertical(top: Radius.circular(30))
        : const BorderRadius.all(Radius.circular(24));
    return GlassSurface(
      borderRadius: radius,
      color: colors.menu,
      allowLiquid: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isSheet)
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.current.headerLayoutsTooltip,
                          style: TextStyle(fontSize: 20, height: 25 / 20, fontWeight: FontWeight.w600, color: colors.text),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: canEdit ? () => _startEdit(null) : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(S.current.layoutsNew),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.accent,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: colors.gridLine),
                    itemBuilder: (final context, final index) {
                      final entry = entries[index];
                      final isCurrent = entry == current || entry == unsaved;
                      return _LayoutRow(
                        entry: entry,
                        targets: targetCells(
                          rows: PuzzleBloc.gridRows,
                          columns: PuzzleBloc.gridColumns,
                          blocked: entry.blocked,
                          date: today,
                        ),
                        meta: _meta(colors, indicator, entry, layouts.solutionsFor(entry, today)),
                        isCurrent: isCurrent,
                        onTap: isCurrent ? null : () => _switchTo(entry),
                        onRename: entry.layout.isStandard || entry == unsaved ? null : () => _rename(entry.layout),
                        onDelete: entry.layout.isStandard || entry == unsaved ? null : () => _delete(entry.layout),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.gridLine),
                const _PieceSetRow(),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: canEdit ? () => _startEdit(current?.layout) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.active,
                    foregroundColor: colors.onActive,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Text(S.current.layoutsEditCurrent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _countSolutions(final List<LayoutEntry> entries, final DateTime date) {
    final signature = '$date|${entries.map((final e) => e.key).join(';')}';
    if (signature == _countedFor) {
      return;
    }
    _countedFor = signature;
    final cubit = context.read<BoardLayoutsCubit>();
    final bloc = context.read<PuzzleBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        cubit.countSolutions(entries, date, bloc.countSolutionsFor);
      }
    });
  }

  Widget _meta(final GameColors colors, final SolutionIndicator indicator, final LayoutEntry entry, final int? count) {
    final style = TextStyle(fontSize: 13, height: 17 / 13, color: colors.textSecondary);
    if (count == 0) {
      return Text(S.current.layoutsNoSolutionToday, style: style.copyWith(color: colors.bad));
    }
    final text = switch (indicator) {
      SolutionIndicator.countSolutions => count == null ? '…' : S.current.layoutsSolutionsToday(count),
      SolutionIndicator.solvability => count == null ? '…' : S.current.layoutsSolvableToday,
      SolutionIndicator.none => entry.layout.isStandard ? S.current.layoutsClassicBoard : S.current.layoutsCustomBoard,
    };
    return Text(text, style: style);
  }

  Future<void> _switchTo(final LayoutEntry entry) async {
    final bloc = context.read<PuzzleBloc>();
    final inProgress = bloc.state.firstMoveAt != null && !bloc.state.isSolved;
    if (inProgress &&
        !await _confirm(
          title: S.current.layoutsSwitchTitle,
          message: S.current.layoutsSwitchMessage,
          action: S.current.layoutsSwitch,
        )) {
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    bloc.add(PuzzleEvent.applyLayout(entry.layout.placements));
  }

  /// Standard is read-only: its edit saves a new layout.
  void _startEdit(final BoardLayout? layout) {
    final saved = layout == null || layout.isStandard ? null : layout;
    final bloc = context.read<PuzzleBloc>();
    Navigator.of(context).pop();
    bloc.add(PuzzleEvent.startLayoutEdit(layoutId: saved?.id, name: saved?.name));
  }

  Future<void> _rename(final BoardLayout layout) async {
    final name = await showLayoutNameDialog(context, S.current.layoutsRenameTitle, layout.name);
    if (name != null && mounted) {
      await context.read<BoardLayoutsCubit>().rename(layout, name);
    }
  }

  Future<void> _delete(final BoardLayout layout) async {
    final confirmed = await _confirm(
      title: S.current.layoutsDeleteTitle(layout.name),
      message: S.current.layoutsDeleteMessage,
      action: S.current.layoutsDelete,
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<BoardLayoutsCubit>().delete(layout);
    }
  }

  Future<bool> _confirm({
    required final String title,
    required final String message,
    required final String action,
    final bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (final dialogContext) => PlatformAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.current.layoutsCancel),
            ),
            PlatformDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              cupertino: (_, _) => CupertinoDialogActionData(isDestructiveAction: destructive),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

}

class _LayoutRow extends StatelessWidget {
  const _LayoutRow({
    required this.entry,
    required this.targets,
    required this.meta,
    required this.isCurrent,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final LayoutEntry entry;
  final Set<Cell> targets;
  final Widget meta;
  final bool isCurrent;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final layout = entry.layout;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            spacing: 14,
            children: [
              _BoardThumbnail(blocked: entry.blocked, targets: targets),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 16, height: 21 / 16, fontWeight: FontWeight.w500, color: colors.text),
                        children: [
                          TextSpan(text: layout.isStandard ? S.current.historyConfigStandard : layout.name),
                          if (layout.isStandard) WidgetSpan(alignment: PlaceholderAlignment.middle, child: _BuiltInChip(colors: colors)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    meta,
                  ],
                ),
              ),
              if (isCurrent) Icon(Icons.check, size: 22, color: colors.accent),
              if (onRename != null && onDelete != null)
                PopupMenuButton<VoidCallback>(
                  icon: Icon(Icons.more_horiz, size: 22, color: colors.textSecondary),
                  onSelected: (final action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem<VoidCallback>(value: onRename, child: Text(S.current.layoutsRename)),
                    PopupMenuItem<VoidCallback>(
                      value: onDelete,
                      child: Text(S.current.layoutsDelete, style: TextStyle(color: colors.bad)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuiltInChip extends StatelessWidget {
  const _BuiltInChip({required this.colors});

  final GameColors colors;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: colors.gridLine),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      S.current.layoutsBuiltIn,
      style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w500, color: colors.textSecondary),
    ),
  );
}

class _PieceSetRow extends StatelessWidget {
  const _PieceSetRow();

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: _BoardThumbnail.size,
            height: _BoardThumbnail.size,
            decoration: BoxDecoration(
              color: colors.board,
              border: Border.all(color: colors.boardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.extension_outlined, size: 20, color: colors.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.layoutsPieceSet,
                  style: TextStyle(fontSize: 16, height: 21 / 16, fontWeight: FontWeight.w500, color: colors.text),
                ),
                Text(
                  S.current.layoutsPieceSetClassic,
                  style: TextStyle(fontSize: 13, height: 17 / 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardThumbnail extends StatelessWidget {
  const _BoardThumbnail({required this.blocked, required this.targets});

  static const double cell = 7;
  static const double size = cell * PuzzleBloc.gridColumns + 2;

  final Set<Cell> blocked;
  final Set<Cell> targets;

  @override
  Widget build(final BuildContext context) => CustomPaint(
    size: const Size.square(size),
    painter: _ThumbnailPainter(blocked: blocked, targets: targets, colors: GameColors.of(context)),
  );
}

class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter({required this.blocked, required this.targets, required this.colors});

  final Set<Cell> blocked;
  final Set<Cell> targets;
  final GameColors colors;

  @override
  void paint(final Canvas canvas, final Size size) {
    const cell = _BoardThumbnail.cell;
    final board = RRect.fromRectAndRadius(Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1), const Radius.circular(4));
    canvas
      ..drawRRect(board, Paint()..color = colors.board)
      ..drawRRect(
        board,
        Paint()
          ..color = colors.boardBorder
          ..style = PaintingStyle.stroke,
      );
    final blockedPaint = Paint()..color = colors.textSecondary.withValues(alpha: 0.55);
    for (final c in blocked) {
      canvas.drawRect(Rect.fromLTWH(1 + c.col * cell, 1 + c.row * cell, cell, cell), blockedPaint);
    }
    final targetPaint = Paint()..color = colors.targetLine;
    for (final c in targets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(2 + c.col * cell, 2 + c.row * cell, cell - 2, cell - 2), const Radius.circular(1.5)),
        targetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(final _ThumbnailPainter old) =>
      old.blocked != blocked || old.targets != targets || old.colors != colors;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => PlatformAlertDialog(
    title: Text(widget.title),
    content: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PlatformTextField(
        controller: _controller,
        autofocus: true,
        hintText: S.current.layoutsNameHint,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      PlatformDialogAction(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.layoutsCancel)),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (final context, final value, _) => PlatformDialogAction(
          onPressed: value.text.trim().isEmpty ? null : _submit,
          child: Text(S.current.layoutsSave),
        ),
      ),
    ],
  );

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      Navigator.of(context).pop(name);
    }
  }
}
