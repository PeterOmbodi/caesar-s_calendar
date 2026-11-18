import 'dart:async';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:caesar_puzzle/application/race/solver_level.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_room_screen.dart';
import 'package:caesar_puzzle/presentation/pages/race/solver_level_name.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_buttons.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_scaffold.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_store_links.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:caesar_puzzle/presentation/widgets/laurel_wreath.dart';
import 'package:caesar_puzzle/presentation/widgets/roman_head_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RaceLobbyScreen extends StatefulWidget {
  const RaceLobbyScreen({super.key, this.initialCode, this.linkCodes});

  final String? initialCode;

  /// Codes of room links opened while the race is open; taken only while the lobby is on screen.
  final Stream<String>? linkCodes;

  @override
  State<RaceLobbyScreen> createState() => _RaceLobbyScreenState();
}

class _RaceLobbyScreenState extends State<RaceLobbyScreen> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode);
  StreamSubscription<String>? _linkSubscription;
  String? _error;
  final _scroll = ScrollController();
  var _isEmblemShown = true;
  double _tail = 0;

  @override
  void initState() {
    super.initState();
    _linkSubscription = widget.linkCodes?.listen(_onLinkCode);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    _code.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isShown = _scroll.offset < _EmblemHeader.extent / 2;
    if (isShown != _isEmblemShown) {
      setState(() => _isEmblemShown = isShown);
    }
  }

  // The emblem is left whole or gone, never half folded.
  bool _onScrollEnd(final ScrollEndNotification notification) {
    final offset = notification.metrics.pixels;
    if (offset <= 0 || offset >= _EmblemHeader.extent) {
      return false;
    }
    // Unfolding with the keyboard open would push the focused field under it.
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
    final target = offset < _EmblemHeader.extent / 2 && !isTyping ? 0.0 : _EmblemHeader.extent;
    final isAnimated = !MediaQuery.disableAnimationsOf(context);
    unawaited(
      Future.microtask(() {
        if (!_scroll.hasClients) {
          return;
        }
        if (isAnimated) {
          unawaited(_scroll.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
        } else {
          _scroll.jumpTo(target);
        }
      }),
    );
    return false;
  }

  // A page that scrolls at all scrolls far enough to fold the emblem away.
  bool _onMetrics(final ScrollMetricsNotification notification) {
    final scrollable = notification.metrics.maxScrollExtent - _tail;
    final tail = scrollable > 0 && scrollable < _EmblemHeader.extent ? _EmblemHeader.extent - scrollable : 0.0;
    if (tail != _tail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _tail = tail);
        }
      });
    }
    return false;
  }

  // A link must not pull the player out of a room or a race.
  void _onLinkCode(final String code) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    setState(() {
      _code.text = code;
      _error = null;
    });
  }

  Future<void> _join() async {
    final code = RaceRoomCode.normalize(_code.text);
    if (code == null) {
      setState(() => _error = S.current.raceErrorBadCode);
      return;
    }
    await _openRoom(code);
  }

  // Without an account only the race against the solver is open.
  RaceProfile _profile() {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      return RaceProfile(nickname: S.current.raceYou, colorIndex: 0);
    }
    final showName = context.read<PublicProfileCubit>().state.showName;
    return RaceProfile(
      nickname: NicknameGenerator.nickname(
        uid: user.uid,
        displayName: showName ? AccountDisplay.bestDisplayName(user) : null,
      ),
      colorIndex: NicknameGenerator.colorIndex(user.uid),
    );
  }

  Future<void> _openRoom(final String? code, {final SolverLevel? solverLevel}) async {
    if (solverLevel == null && context.read<AuthCubit>().state.user == null) {
      return;
    }
    final profile = _profile();
    setState(() => _error = null);
    final error =
        await Navigator.of(
          context,
        ).push(
          MaterialPageRoute<String>(
            builder: (_) => RaceRoomScreen(profile: profile, code: code, solverLevel: solverLevel),
          ),
        );
    if (mounted) {
      setState(() => _error = error);
    }
  }

  Future<void> _raceSolver() async {
    final level = await _pickSolverLevel(context);
    if (level != null && mounted) {
      await _openRoom(null, solverLevel: level);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final isSignedIn = context.select<AuthCubit, bool>((final cubit) => cubit.state.user != null);
    return RaceScaffold(
      title: S.current.raceLobbyTitle,
      trailing: _TitleEmblem(isShown: !_isEmblemShown),
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: _onScrollEnd,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPersistentHeader(
                delegate: _EmblemHeader(laurel: colors.laurel, head: colors.icon, isShown: _isEmblemShown),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      S.current.raceLobbyHeadline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        height: 38 / 32,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.current.raceLobbyBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 23 / 16, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 40),
                    if (isSignedIn)
                      _EntryForm(
                        code: _code,
                        error: _error,
                        onCreate: () => _openRoom(null),
                        onJoin: _join,
                      )
                    else
                      const _SignInGate(),
                    const _OrDivider(),
                    RaceSecondaryButton(
                      label: S.current.raceVsSolver,
                      onPressed: () => unawaited(_raceSolver()),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.current.raceVsSolverHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
                    ),
                    const RaceStoreLinks(),
                    const Spacer(),
                    const SizedBox(height: 24),
                    Text(
                      S.current.raceNoEffectNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
                    ),
                    SizedBox(height: _tail),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shrinks away as the page scrolls, so that a short screen with the keyboard open still reaches the code field.
class _EmblemHeader extends SliverPersistentHeaderDelegate {
  const _EmblemHeader({required this.laurel, required this.head, required this.isShown});

  static const double _size = 140;
  static const double _gap = 16;
  static const double extent = _size + _gap * 2;

  final Color laurel;
  final Color head;
  final bool isShown;

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => 0;

  @override
  Widget build(final BuildContext context, final double shrinkOffset, final bool overlapsContent) {
    final shown = (1 - shrinkOffset / maxExtent).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: isShown ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: _gap * shown),
        child: FittedBox(
          child: LaurelWreathHero(
            size: _size,
            color: laurel,
            // A folded emblem has nothing to fly from.
            child: HeroMode(
              enabled: isShown,
              child: Hero(
                tag: raceHeadHeroTag,
                // The colour of the race button's head: the same cached picture, so the first flight does not blink.
                child: RomanHeadIcon(rank: RomanRank.centurion, color: head, size: _size * LaurelWreath.childShare),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(final _EmblemHeader oldDelegate) =>
      oldDelegate.laurel != laurel || oldDelegate.head != head || oldDelegate.isShown != isShown;
}

class _TitleEmblem extends StatelessWidget {
  const _TitleEmblem({required this.isShown});

  static const double _size = 32;

  final bool isShown;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
        transitionBuilder: (final child, final animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: isShown
            ? LaurelWreathHero(
                key: const ValueKey(true),
                size: _size,
                color: colors.laurel,
                child: RomanHeadIcon(
                  rank: RomanRank.centurion,
                  color: colors.icon,
                  size: _size * LaurelWreath.childShare,
                ),
              )
            : const SizedBox.shrink(key: ValueKey(false)),
      ),
    );
  }
}

class _EntryForm extends StatelessWidget {
  const _EntryForm({required this.code, required this.error, required this.onCreate, required this.onJoin});

  final TextEditingController code;
  final String? error;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final hint = TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RacePrimaryButton(label: S.current.raceCreate, onPressed: onCreate),
        const SizedBox(height: 12),
        Text(S.current.raceCreateHint, textAlign: TextAlign.center, style: hint),
        const _OrDivider(),
        _CodeField(controller: code, error: error, onSubmitted: onJoin),
        const SizedBox(height: 12),
        RaceSecondaryButton(label: S.current.raceJoin, onPressed: onJoin),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: colors.gridLine)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              S.current.raceOr,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
            ),
          ),
          Expanded(child: Divider(height: 1, color: colors.gridLine)),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.error, required this.onSubmitted});

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmitted;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final error = this.error;
    final style = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 12, color: colors.text);
    final formatters = [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))];
    if (ScreenSpec.of(context).family != ChromeFamily.glass) {
      return TextField(
        controller: controller,
        maxLength: RaceRoomCode.length,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: formatters,
        onSubmitted: (_) => onSubmitted(),
        style: style,
        decoration: InputDecoration(
          labelText: S.current.raceJoinLabel,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: '',
          errorText: error,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            S.current.raceJoinLabel,
            style: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: colors.text),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          maxLength: RaceRoomCode.length,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: formatters,
          onSubmitted: (_) => onSubmitted(),
          style: style,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.board,
            borderRadius: const BorderRadius.all(Radius.circular(InsetSection.radius)),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              error,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.bad),
            ),
          ),
      ],
    );
  }
}

class _SignInGate extends StatelessWidget {
  const _SignInGate();

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        S.current.raceSignInRequired,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, height: 20 / 15, color: GameColors.of(context).textSecondary),
      ),
      const SizedBox(height: 16),
      RacePrimaryButton(
        label: S.current.leaderboardSignIn,
        onPressed: () => unawaited(showAccountSectionSheet(context)),
      ),
    ],
  );
}

Future<SolverLevel?> _pickSolverLevel(final BuildContext context) => ScreenSpec.of(context).family == ChromeFamily.glass
    ? showCupertinoModalPopup<SolverLevel>(context: context, builder: (_) => const _SolverLevelActionSheet())
    : showModalBottomSheet<SolverLevel>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _SolverLevelBottomSheet(),
      );

class _SolverLevelActionSheet extends StatelessWidget {
  const _SolverLevelActionSheet();

  @override
  Widget build(final BuildContext context) => CupertinoActionSheet(
    title: Text(S.current.raceSolverLevelTitle),
    actions: [
      for (final level in SolverLevel.values)
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(level),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 24),
            child: Row(
              spacing: 16,
              children: [
                RomanHeadAvatar(rank: level.rank, radius: 22),
                Text(level.label),
              ],
            ),
          ),
        ),
    ],
    cancelButton: CupertinoActionSheetAction(
      isDefaultAction: true,
      onPressed: () => Navigator.of(context).pop(),
      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
    ),
  );
}

class _SolverLevelBottomSheet extends StatelessWidget {
  const _SolverLevelBottomSheet();

  @override
  Widget build(final BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text(S.current.raceSolverLevelTitle, style: Theme.of(context).textTheme.titleMedium)),
        for (final level in SolverLevel.values)
          ListTile(
            leading: RomanHeadAvatar(rank: level.rank, radius: 22),
            title: Text(level.label),
            onTap: () => Navigator.of(context).pop(level),
          ),
      ],
    ),
  );
}
