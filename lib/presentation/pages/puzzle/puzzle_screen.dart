import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleScreen extends StatelessWidget {

  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return BlocProvider(
      create: (_) => PuzzleBloc(screenSize),
      child: const PuzzleView(),
    );
  }
}

