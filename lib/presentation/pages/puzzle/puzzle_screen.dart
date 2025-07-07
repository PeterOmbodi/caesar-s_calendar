import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/puzzle_bloc.dart';

class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PuzzleBloc(),
      child: const _PuzzleScreenWithSize(),
    );
  }
}

class _PuzzleScreenWithSize extends StatefulWidget {
  const _PuzzleScreenWithSize();

  @override
  State<_PuzzleScreenWithSize> createState() => _PuzzleScreenWithSizeState();
}

class _PuzzleScreenWithSizeState extends State<_PuzzleScreenWithSize> {
  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    if (_lastSize != size && size.width > 0 && size.height > 0) {
      context.read<PuzzleBloc>().add(PuzzleEvent.setScreenSize(size));
      _lastSize = size;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PuzzleView();
  }
}
