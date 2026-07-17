import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/widgets/one_time_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuzzleAccountChip extends StatelessWidget {
  const PuzzleAccountChip({super.key});

  static const _introStorageKey = 'puzzle_account_chip_intro_seen';

  static double avatarRadiusForCellSize(final double cellSize) => cellSize * 0.4;

  static double placeholderIconSizeForRadius(final double radius) => radius * 1.1;

  static bool shouldRebuildForCellSize(final double previous, final double current) => previous != current;

  @override
  Widget build(final BuildContext context) => BlocBuilder<PuzzleBloc, PuzzleState>(
    buildWhen: (final previous, final current) =>
        shouldRebuildForCellSize(previous.gridConfig.cellSize, current.gridConfig.cellSize),
    builder: (final context, final state) => _PuzzleAccountChipContent(cellSize: state.gridConfig.cellSize),
  );
}

class _PuzzleAccountChipContent extends StatelessWidget {
  const _PuzzleAccountChipContent({required this.cellSize});

  final double cellSize;

  @override
  Widget build(final BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    buildWhen: (final p, final n) =>
        p.isAvailable != n.isAvailable ||
        p.user?.uid != n.user?.uid ||
        p.isLoading != n.isLoading ||
        p.errorMessage != n.errorMessage ||
        p.pendingCloudReplace != n.pendingCloudReplace,
    builder: (final context, final auth) {
      final user = auth.user;
      final displayName = AccountDisplay.bestDisplayName(user);
      final photoUrl = AccountDisplay.bestPhotoUrl(user);
      final avatarRadius = PuzzleAccountChip.avatarRadiusForCellSize(cellSize);
      final avatarPadding = cellSize * 0.06;

      return ConstrainedBox(
        constraints: BoxConstraints.tightFor(height: cellSize, width: cellSize),
        child: Padding(
          padding: EdgeInsets.all(avatarPadding),
          child: Tooltip(
            message: S.current.accountAndSyncTitle,
            child: Material(
              color: Colors.grey.shade200,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final shouldOpen = await OneTimeInfoDialog.show(
                    context: context,
                    storageKey: PuzzleAccountChip._introStorageKey,
                    title: S.current.accountAndSyncTitle,
                    message: S.current.accountAndSyncIntroMessage,
                    actionLabel: S.current.onboardingNext,
                  );
                  if (!shouldOpen || !context.mounted) {
                    return;
                  }
                  await showAccountSectionSheet(context);
                },
                child: Center(
                  child: AccountAvatar(
                    photoUrl: photoUrl,
                    fallbackLabel: AccountDisplay.avatarInitial(displayName),
                    radius: avatarRadius,
                    placeholderIcon: user == null ? Icons.person_outline : null,
                    placeholderIconSize: PuzzleAccountChip.placeholderIconSizeForRadius(avatarRadius),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
