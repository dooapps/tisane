import 'package:test/test.dart';
import 'package:tisane/src/ports/logger_port.dart';

import '../contracts/logger_port_contract.dart';

void main() {
  defineLoggerPortContract(
      'PrintLogger', () => const PrintLogger(includeTimestamp: false));

  test('createDefaultLogger returns PrintLogger', () {
    expect(createDefaultLogger(), isA<PrintLogger>());
  });
}
