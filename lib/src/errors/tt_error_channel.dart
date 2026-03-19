import '../client/flow/tt_event.dart';
import 'tt_error_signal.dart';

class TTErrorChannel {
  TTErrorChannel({String name = 'tt.error.channel'})
    : onSignal = TTEvent(name: name);

  final TTEvent<TTErrorSignal, void, void> onSignal;

  TTErrorSignal emit(TTErrorSignal signal) {
    signal.validate();
    onSignal.trigger(signal);
    return signal;
  }
}
