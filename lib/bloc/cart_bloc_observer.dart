
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);

    debugPrint(
      '[BLOC TRANSITION] '
      '${transition.currentState.runtimeType} '
      '-- ${transition.event.runtimeType} --> '
      '${transition.nextState.runtimeType}',
    );

    debugPrint('Event: ${transition.event}');
    debugPrint('Next state: ${transition.nextState}');
  }
}
