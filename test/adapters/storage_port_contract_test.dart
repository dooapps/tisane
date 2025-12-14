import 'package:test/test.dart';
import 'package:tisane/src/ports/storage_port.dart';

import '../contracts/storage_port_contract.dart';

void main() {
  // The contract uses HiveStoragePort with injected initializer/checker.
  defineStoragePortContract(
      'HiveStoragePort', () => createDefaultStoragePort());

  test('createDefaultStoragePort returns HiveStoragePort', () {
    expect(createDefaultStoragePort(), isA<HiveStoragePort>());
  });
}
