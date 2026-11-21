import 'package:caesar_puzzle/presentation/theme/game_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// The head that flies from the race button to the emblem of the race lobby.
const Object raceHeadHeroTag = 'raceHead';

enum RomanRank {
  recruit('assets/icons/head_recruit.svg'),
  legionary('assets/icons/head_legionary.svg'),
  centurion('assets/icons/head_centurion.svg');

  const RomanRank(this.asset);

  final String asset;
}

/// The head takes [color]; the crest keeps the colours of the app icon.
class RomanHeadIcon extends StatelessWidget {
  const RomanHeadIcon({super.key, required this.rank, required this.color, this.size = 24});

  final RomanRank rank;
  final Color color;
  final double size;

  @override
  Widget build(final BuildContext context) => SvgPicture.asset(
    rank.asset,
    width: size,
    height: size,
    theme: SvgTheme(currentColor: color),
  );
}

class RomanHeadAvatar extends StatelessWidget {
  const RomanHeadAvatar({super.key, required this.rank, required this.radius});

  /// As on the race button: a 36 pt head in a 44 pt circle.
  static const double _headShare = 36 / 44;

  final RomanRank rank;
  final double radius;

  @override
  Widget build(final BuildContext context) {
    final colors = GameColors.of(context);
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.background, shape: BoxShape.circle),
      child: RomanHeadIcon(rank: rank, color: colors.text, size: radius * 2 * _headShare),
    );
  }
}
