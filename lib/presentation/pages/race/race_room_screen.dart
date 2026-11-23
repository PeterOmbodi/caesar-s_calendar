import 'dart:async';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/race/solver_race_repository.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/race/bloc/race_room_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_failure_text.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_game_screen.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_level_name.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_pieces.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_scaffold.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_store_links.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/room_code_card.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/controls/app_button.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Pops with a message when the room could not be entered or is gone.
class RaceRoomScreen extends StatefulWidget {
  const RaceRoomScreen({super.key, required this.profile, this.code, this.solverLevel});

  final RaceProfile profile;

  /// Null to create a room.
  final String? code;

  /// A race against the solver on this device; it starts by itself, without the lobby.
  final SolverLevel? solverLevel;

  @override
  State<RaceRoomScreen> createState() => _RaceRoomScreenState();
}

class _RaceRoomScreenState extends State<RaceRoomScreen> {
  late final RaceRoomCubit _cubit = RaceRoomCubit(switch (widget.solverLevel) {
    final level? => SolverRaceRepository(
      pieces: standardSolverPieces(),
      grid: solverGrid,
      level: level,
      solverNickname: level.label,
    ),
    null => getIt<RaceRoomRepository>(),
  });

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.enter(profile: widget.profile, code: widget.code));
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _onState(final BuildContext context, final RaceRoomState state) {
    switch (state.phase) {
      case RaceRoomPhase.failed:
        Navigator.of(context).pop((state.failure ?? RaceRoomFailure.unknown).text);
      case RaceRoomPhase.closed:
        Navigator.of(context).pop(S.current.raceRoomClosed);
      case RaceRoomPhase.entering:
      case RaceRoomPhase.open:
        final room = state.room;
        if (widget.solverLevel != null && room != null && room.status == RaceRoomStatus.lobby && room.canStart) {
          unawaited(_cubit.start());
        }
        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failure.text)));
        }
    }
  }

  @override
  Widget build(final BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocConsumer<RaceRoomCubit, RaceRoomState>(
      listener: _onState,
      builder: (final context, final state) {
        final room = state.room;
        final me = room?.player(_cubit.uid ?? '');
        final puzzle = room?.puzzle;
        final startAt = room?.startAt;
        if (room != null && me != null && room.status != RaceRoomStatus.lobby && puzzle != null && startAt != null) {
          return RaceGameScreen(
            key: ValueKey(room.round),
            room: room,
            myUid: me.uid,
            startAtMs: startAt,
            date: DateTime(RacePuzzle.year, puzzle.month, puzzle.day),
            solverLevel: widget.solverLevel,
          );
        }
        return RaceScaffold(
          title: S.current.raceRoomTitle,
          child: room == null || me == null || widget.solverLevel != null
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _RoomBody(room: room, me: me, isBusy: state.isBusy),
        );
      },
    ),
  );
}

class _RoomBody extends StatelessWidget {
  const _RoomBody({required this.room, required this.me, required this.isBusy});

  final RaceRoom room;
  final RacePlayer me;
  final bool isBusy;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final isMaterial = ScreenSpec.of(context).family != ChromeFamily.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoomCodeCard(code: room.code),
                const SizedBox(height: 28),
                InsetSection(
                  header: S.current.racePlayers,
                  footer: S.current.raceRulesLine,
                  children: [
                    for (final player in room.players)
                      _PlayerRow(player: player, isMe: player.uid == me.uid, isHost: player.uid == room.hostUid),
                    for (var i = room.players.length; i < room.maxPlayers; i++)
                      InsetRow(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isMaterial
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : colors.gridLine,
                          child: Icon(Icons.person_outline, size: 18, color: colors.textSecondary),
                        ),
                        title: S.current.raceWaitingOpponent,
                        titleColor: colors.textSecondary,
                      ),
                  ],
                ),
                const RaceStoreLinks(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LobbyFooter(room: room, me: me, isBusy: isBusy),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isMe, required this.isHost});

  final RacePlayer player;
  final bool isMe;
  final bool isHost;

  // Offline is shown in place of readiness, so the subtitle does not repeat it.
  String? get _subtitle {
    final roles = [if (isMe) S.current.raceYou, if (isHost) S.current.raceHost];
    if (roles.isNotEmpty) {
      return roles.join(' · ');
    }
    return player.online ? S.current.raceOnline : null;
  }

  String get _status {
    if (!player.online) {
      return S.current.raceOffline;
    }
    return player.ready ? S.current.raceReady : S.current.raceNotReady;
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final subtitle = _subtitle;
    final isReady = player.online && player.ready;
    final statusColor = !player.online
        ? colors.customConfig
        : isReady
        ? colors.ok
        : colors.textSecondary;
    return Semantics(
      label: [player.nickname, ?subtitle, _status].join(', '),
      excludeSemantics: true,
      child: InsetRow(
        leading: AccountAvatar(
          photoUrl: null,
          fallbackLabel: AccountDisplay.avatarInitials(player.nickname),
          radius: 16,
          backgroundColor: colors.player(player.colorIndex),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        title: player.nickname,
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!player.online || isReady) ...[
              Icon(player.online ? Icons.check : Icons.flag, size: 18, color: statusColor),
              const SizedBox(width: 6),
            ],
            Text(
              _status,
              style: ScreenSpec.of(context).family != ChromeFamily.glass
                  ? Theme.of(context).textTheme.labelLarge?.copyWith(color: statusColor)
                  : TextStyle(
                      fontSize: 14,
                      fontWeight: !player.online || isReady ? FontWeight.w600 : FontWeight.w400,
                      color: statusColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyFooter extends StatelessWidget {
  const _LobbyFooter({required this.room, required this.me, required this.isBusy});

  final RaceRoom room;
  final RacePlayer me;
  final bool isBusy;

  String? get _hint {
    if (room.players.length < 2) {
      return S.current.raceWaitingOpponent;
    }
    if (!me.ready) {
      return null;
    }
    if (room.hostUid != me.uid) {
      return S.current.raceWaitingHost;
    }
    return room.canStart ? null : S.current.raceWaitingReady;
  }

  @override
  Widget build(final BuildContext context) {
    final cubit = context.read<RaceRoomCubit>();
    final colors = GameColors.of(context);
    final theme = Theme.of(context);
    final isMaterial = ScreenSpec.of(context).family != ChromeFamily.glass;
    final gap = isMaterial ? 12.0 : 10.0;
    final isHost = room.hostUid == me.uid;
    final hint = _hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(
            hint,
            textAlign: TextAlign.center,
            style: isMaterial
                ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                : TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
          ),
          SizedBox(height: gap),
        ],
        if (!me.ready)
          AppButton(
            size: AppButtonSize.large,
            expand: true,
            label: S.current.raceImReady,
            onPressed: isBusy ? null : () => cubit.setReady(ready: true),
          )
        else ...[
          if (isHost) ...[
            AppButton(
              size: AppButtonSize.large,
              expand: true,
              label: S.current.raceStart,
              onPressed: room.canStart && !isBusy ? cubit.start : null,
            ),
            SizedBox(height: gap),
          ],
          AppButton(
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.large,
            expand: true,
            label: S.current.raceCancelReady,
            onPressed: isBusy ? null : () => cubit.setReady(ready: false),
          ),
        ],
      ],
    );
  }
}
