import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section.dart';
import 'package:caesar_puzzle/presentation/widgets/game_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAccountSectionSheet(
  final BuildContext context, {
  final bool closeDrawerFirst = false,
}) async {
  final authCubit = context.read<AuthCubit>();
  final publicProfileCubit = context.read<PublicProfileCubit>();
  final navigator = Navigator.of(context, rootNavigator: true);

  if (closeDrawerFirst && (Scaffold.maybeOf(context)?.isEndDrawerOpen ?? false)) {
    navigator.pop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  if (!navigator.mounted) {
    return;
  }

  await showGameSheet<void>(
    navigator.context,
    title: S.current.accountAndSyncTitle,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PublicProfileCubit>.value(value: publicProfileCubit),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (final p, final n) =>
            p.isAvailable != n.isAvailable ||
            p.user?.uid != n.user?.uid ||
            p.isLoading != n.isLoading ||
            p.errorMessage != n.errorMessage ||
            p.pendingCloudReplace != n.pendingCloudReplace,
        builder: (final context, final auth) => AccountSection(auth: auth),
      ),
    ),
  );
}
