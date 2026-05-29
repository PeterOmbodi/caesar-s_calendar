import 'package:caesar_puzzle/presentation/auth/bloc/auth_cubit.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_display.dart';
import 'package:caesar_puzzle/presentation/pages/settings/widgets/account_section_sheet.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PuzzleAccountChip extends StatelessWidget {
  const PuzzleAccountChip({super.key});

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
      final cellSize = context.read<PuzzleBloc>().state.gridConfig.cellSize;
      final avatarRadius = (cellSize - 16) / 2;

      return ConstrainedBox(
        constraints: context.read<PuzzleBloc>().state.gridConfig.cellConstraints(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Tooltip(
            message: 'Account & Sync',
            child: Material(
              color: Colors.grey.shade200,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showAccountSectionSheet(context),
                child: Center(
                  child: AccountAvatar(
                    photoUrl: photoUrl,
                    fallbackLabel: AccountDisplay.avatarInitial(displayName),
                    radius: avatarRadius,
                    placeholderIcon: user == null ? Icons.person_outline : null,
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
