import 'package:caesar_puzzle/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@injectableInit
GetIt configureInjection() => getIt.init();
