/// Abstraction over time sources to unlock deterministic testing.
abstract class TTClock {
  const TTClock();

  DateTime now();

  int nowMillis() => now().millisecondsSinceEpoch;
}

/// Default wall-clock implementation using UTC time.
class SystemClock extends TTClock {
  const SystemClock() : super();

  @override
  DateTime now() => DateTime.now().toUtc();
}

TTClock createDefaultClock() => const SystemClock();
