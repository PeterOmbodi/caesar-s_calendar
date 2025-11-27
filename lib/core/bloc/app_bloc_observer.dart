import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class AppBlocObserver extends BlocObserver {
  AppBlocObserver();

  String _lastEvent = '';

  @override
  void onChange(final BlocBase<dynamic> bloc, final Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Cubit && change.nextState != change.currentState) {
      debugPrint('AppBlocObserver, ${bloc.runtimeType} state changed: ${change.nextState}');
    }
  }

  @override
  void onTransition(final Bloc<dynamic, dynamic> bloc, final Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    if (transition.nextState != transition.currentState) {
      // debugPrint('AppBlocObserver, ${bloc.runtimeType} state changed by ${(transition.event as Object).runtimeType}: ${transition.nextState}');
      final event = (transition.event as Object).runtimeType.toString();
      if (event == _lastEvent && _lastEvent == '_OnPanUpdate') {
        //reducing noise
        return;
      }
      debugPrint('AppBlocObserver, ${bloc.runtimeType} state changed by $event');
      _lastEvent = (transition.event as Object).runtimeType.toString();
    }
  }
}
