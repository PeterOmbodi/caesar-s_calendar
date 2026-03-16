// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart'
    as _i735;
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart'
    as _i196;
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart' as _i470;
import 'package:caesar_puzzle/core/services/timer_service.dart' as _i60;
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart'
    as _i138;
import 'package:caesar_puzzle/infrastructure/dancing_links/dancing_links_solver_impl.dart'
    as _i1051;
import 'package:caesar_puzzle/infrastructure/persistence/drift/app_database.dart'
    as _i616;
import 'package:caesar_puzzle/infrastructure/persistence/drift/daos/puzzle_history_dao.dart'
    as _i947;
import 'package:caesar_puzzle/infrastructure/persistence/drift/drift_module.dart'
    as _i145;
import 'package:caesar_puzzle/infrastructure/persistence/puzzle_history_repository_impl.dart'
    as _i388;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final driftModule = _$DriftModule();
    gh.lazySingleton<_i60.TimerService>(() => _i60.TimerService());
    gh.lazySingleton<_i616.AppDatabase>(() => driftModule.database);
    gh.factory<_i138.PuzzleSolverService>(
      () => _i1051.DancingLinksSolverImpl(),
    );
    gh.lazySingleton<_i947.PuzzleHistoryDao>(
      () => driftModule.puzzleHistoryDao(gh<_i616.AppDatabase>()),
    );
    gh.lazySingleton<_i735.PuzzleHistoryRepository>(
      () => _i388.PuzzleHistoryRepositoryImpl(gh<_i947.PuzzleHistoryDao>()),
    );
    gh.factory<_i470.SolvePuzzleUseCase>(
      () => _i470.SolvePuzzleUseCase(gh<_i138.PuzzleSolverService>()),
    );
    gh.lazySingleton<_i196.PuzzleHistoryUseCase>(
      () => _i196.PuzzleHistoryUseCase(gh<_i735.PuzzleHistoryRepository>()),
    );
    return this;
  }
}

class _$DriftModule extends _i145.DriftModule {}
