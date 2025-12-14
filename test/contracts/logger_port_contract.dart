import 'package:test/test.dart';
import 'package:tisane/src/ports/logger_port.dart';

/// Contract tests for TTLogger: methods should not throw
/// and accept arbitrary messages/contexts.
void defineLoggerPortContract(
  String name,
  TTLogger Function() create,
) {
  group('TTLogger contract: $name', () {
    test('does not throw on any level', () {
      final logger = create();
      expect(() => logger.debug('hello', context: {'k': 1}), returnsNormally);
      expect(() => logger.info('info'), returnsNormally);
      expect(() => logger.warn('warn', error: Exception('e')), returnsNormally);
      expect(
          () => logger.error('error', error: Exception('e')), returnsNormally);
    });
  });
}
