import 'dart:async';

import 'package:caesar_puzzle/application/contracts/race_room_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:caesar_puzzle/application/race/race_room_code.dart';
import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/pages/race/race_room_screen.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_buttons.dart';
import 'package:caesar_puzzle/presentation/pages/race/widgets/race_scaffold.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/store_links.dart';
import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:caesar_puzzle/presentation/widgets/inset_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RaceLobbyScreen extends StatefulWidget {
  const RaceLobbyScreen({super.key, this.initialCode});

  /// Code from a room link.
  final String? initialCode;

  @override
  State<RaceLobbyScreen> createState() => _RaceLobbyScreenState();
}

class _RaceLobbyScreenState extends State<RaceLobbyScreen> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode);
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = RaceRoomCode.normalize(_code.text);
    if (code == null) {
      setState(() => _error = S.current.raceErrorBadCode);
      return;
    }
    await _openRoom(code);
  }

  Future<void> _openRoom(final String? code) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      return;
    }
    final showName = context.read<PublicProfileCubit>().state.showName;
    final profile = RaceProfile(
      nickname: NicknameGenerator.nickname(
        uid: user.uid,
        displayName: showName ? AccountDisplay.bestDisplayName(user) : null,
      ),
      colorIndex: NicknameGenerator.colorIndex(user.uid),
    );
    setState(() => _error = null);
    final error =
        await Navigator.of(
          context,
        ).push(
          MaterialPageRoute<String>(
            builder: (_) => RaceRoomScreen(profile: profile, code: code),
          ),
        );
    if (mounted) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    final isSignedIn = context.select<AuthCubit, bool>((final cubit) => cubit.state.user != null);
    return RaceScaffold(
      title: S.current.raceTitle,
      child: LayoutBuilder(
        builder: (final context, final constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    S.current.raceLobbyHeadline,
                    style: TextStyle(fontSize: 32, height: 38 / 32, fontWeight: FontWeight.w700, color: colors.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    S.current.raceLobbyBody,
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
                  const _StoreLinks(),
                  const Spacer(),
                  const SizedBox(height: 24),
                  Text(
                    S.current.raceNoEffectNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Row(
            children: [
              Expanded(child: Divider(height: 1, color: colors.gridLine)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(S.current.raceOr, style: hint),
              ),
              Expanded(child: Divider(height: 1, color: colors.gridLine)),
            ],
          ),
        ),
        _CodeField(controller: code, error: error, onSubmitted: onJoin),
        const SizedBox(height: 12),
        RaceSecondaryButton(label: S.current.raceJoin, onPressed: onJoin),
      ],
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

/// Web only: a phone visitor who came by a room link may prefer the app.
class _StoreLinks extends StatelessWidget {
  const _StoreLinks();

  @override
  Widget build(final BuildContext context) {
    final links = webStoreLinks().where((final link) => link.url != null).toList();
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final link in links)
            TextButton.icon(onPressed: () => openStoreLink(link), icon: Icon(link.icon), label: Text(link.title)),
        ],
      ),
    );
  }
}
