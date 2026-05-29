import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/public_profile_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section.dart';
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

  await showModalBottomSheet<void>(
    context: navigator.context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (final sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<PublicProfileCubit>.value(value: publicProfileCubit),
      ],
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: SingleChildScrollView(
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
        ),
      ),
    ),
  );
}
