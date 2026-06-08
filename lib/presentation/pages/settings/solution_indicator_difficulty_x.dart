import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';

extension SolutionIndicatorDifficultyX on SolutionIndicator {
  PuzzleSessionDifficulty get sessionDifficulty {
    switch (this) {
      case SolutionIndicator.none:
        return PuzzleSessionDifficulty.hard;
      case SolutionIndicator.solvability:
        return PuzzleSessionDifficulty.medium;
      case SolutionIndicator.countSolutions:
        return PuzzleSessionDifficulty.easy;
    }
  }
}

extension PuzzleSessionDifficultySolutionIndicatorX on PuzzleSessionDifficulty {
  SolutionIndicator get solutionIndicator {
    switch (this) {
      case PuzzleSessionDifficulty.hard:
        return SolutionIndicator.none;
      case PuzzleSessionDifficulty.medium:
        return SolutionIndicator.solvability;
      case PuzzleSessionDifficulty.easy:
        return SolutionIndicator.countSolutions;
    }
  }
}
