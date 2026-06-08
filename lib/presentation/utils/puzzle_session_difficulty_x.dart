import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/generated/l10n.dart';

extension PuzzleSessionDifficultyX on PuzzleSessionDifficulty {
  String get label {
    switch (this) {
      case PuzzleSessionDifficulty.hard:
        return S.current.historyDifficultyHard;
      case PuzzleSessionDifficulty.medium:
        return S.current.historyDifficultyMedium;
      case PuzzleSessionDifficulty.easy:
        return S.current.historyDifficultyEasy;
    }
  }
}
