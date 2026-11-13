import 'dart:async';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/race/race_player.dart';
import 'package:caesar_puzzle/application/race/race_room.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/pages/race/bloc/race_room_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_failure_text.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_buttons.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_scaffold.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/room_code_card.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pops with a message when the room could not be entered or is gone.
class RaceRoomScreen extends StatefulWidget {
  const RaceRoomScreen({super.key, required this.profile, this.code});

  final RaceProfile profile;

  /// Null to create a room.
  final String? code;

  @override
  State<RaceRoomScreen> createState() => _RaceRoomScreenState();
}

class _RaceRoomScreenState extends State<RaceRoomScreen> {
  late final RaceRoomCubit _cubit = RaceRoomCubit(getIt<RaceRoomRepository>());

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
        return RaceScaffold(
          title: S.current.raceRoomTitle,
          child: room == null || me == null
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
    final hint = TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoomCodeCard(code: room.code),
                const SizedBox(height: 20),
                Text(S.current.racePlayers, style: hint),
                const SizedBox(height: 8),
                _PlayersCard(room: room, myUid: me.uid),
                const SizedBox(height: 16),
                Text(S.current.raceRulesLine, textAlign: TextAlign.center, style: hint),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (room.status == RaceRoomStatus.lobby)
          _LobbyFooter(room: room, me: me, isBusy: isBusy)
        else
          _StartedPlaceholder(room: room, isHost: room.hostUid == me.uid, isBusy: isBusy),
      ],
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({required this.room, required this.myUid});

  final RaceRoom room;
  final String myUid;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final emptySeats = room.maxPlayers - room.players.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.board,
        border: Border.all(color: colors.boardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (final (index, player) in room.players.indexed) ...[
            if (index > 0) Divider(height: 1, color: colors.gridLine),
            _PlayerRow(player: player, isMe: player.uid == myUid, isHost: player.uid == room.hostUid),
          ],
          for (var i = 0; i < emptySeats; i++) ...[
            Divider(height: 1, color: colors.gridLine),
            const _EmptySeat(),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isMe, required this.isHost});

  final RacePlayer player;
  final bool isMe;
  final bool isHost;

  String get _initials {
    final words = player.nickname.split(RegExp(r'\s+')).where((final w) => w.isNotEmpty).take(2);
    return words.map((final w) => String.fromCharCode(w.runes.first).toUpperCase()).join();
  }

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
    final palette = colors.pieces.values.toList();
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
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: palette.isEmpty ? colors.accent : palette[player.colorIndex % palette.length],
                child: Text(
                  _initials,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, height: 21 / 16, fontWeight: FontWeight.w600, color: colors.text),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, height: 17 / 13, color: colors.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!player.online || isReady) ...[
                Icon(player.online ? Icons.check : Icons.flag, size: 18, color: statusColor),
                const SizedBox(width: 6),
              ],
              Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: !player.online || isReady ? FontWeight.w600 : FontWeight.w400,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat();

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.gridLine,
              child: Icon(Icons.person_outline, size: 20, color: colors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(S.current.raceWaitingOpponent, style: TextStyle(fontSize: 15, color: colors.textSecondary)),
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
    final isHost = room.hostUid == me.uid;
    final hint = _hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
        ],
        if (!me.ready)
          RacePrimaryButton(label: S.current.raceImReady, onPressed: isBusy ? null : () => cubit.setReady(ready: true))
        else ...[
          if (isHost) ...[
            RacePrimaryButton(label: S.current.raceStart, onPressed: room.canStart && !isBusy ? cubit.start : null),
            const SizedBox(height: 10),
          ],
          RaceSecondaryButton(
            label: S.current.raceCancelReady,
            onPressed: isBusy ? null : () => cubit.setReady(ready: false),
          ),
        ],
      ],
    );
  }
}

// Temporary, until the race screen exists: shows that the start reached both players.
class _StartedPlaceholder extends StatelessWidget {
  const _StartedPlaceholder({required this.room, required this.isHost, required this.isBusy});

  final RaceRoom room;
  final bool isHost;
  final bool isBusy;

  @override
  Widget build(final BuildContext context) {
    final puzzle = room.puzzle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Race started. Date: ${puzzle?.month}/${puzzle?.day}, start at ${room.startAt}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: GameColors.of(context).textSecondary),
        ),
        if (isHost) ...[
          const SizedBox(height: 10),
          RaceSecondaryButton(
            label: 'Back to the room',
            onPressed: isBusy ? null : context.read<RaceRoomCubit>().rematch,
          ),
        ],
      ],
    );
  }
}
