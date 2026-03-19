import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tisane/tisane.dart';

void main() {
  group('TTErrorSignal', () {
    test('serializes and parses a reported signal', () {
      final signal = TTErrorSignal.reported(
        signalId: 'sig-1',
        code: 'payment_failed',
        summary: 'Payment provider rejected the request',
        source: 'mellis',
        ownerUnitRef: 'meinn.app',
        severity: TTErrorSignalSeverity.error,
        occurredAt: DateTime.utc(2026, 3, 19, 12, 0, 0),
        correlationId: 'corr-1',
        subjectRef: 'checkout-1',
        detailRef: 'sealed:cid:abc123',
        metadata: const <String, dynamic>{'stage': 'confirm'},
      );

      final payload = signal.toPayloadJson();

      expect(payload['signal_id'], 'sig-1');
      expect(payload['status'], 'reported');
      expect(payload['severity'], 'error');
      expect(payload['owner_unit_ref'], 'meinn.app');

      final restored = TTErrorSignal.fromPayloadJson(payload);

      expect(restored.signalId, signal.signalId);
      expect(restored.code, signal.code);
      expect(restored.summary, signal.summary);
      expect(restored.source, signal.source);
      expect(restored.ownerUnitRef, signal.ownerUnitRef);
      expect(restored.severity, signal.severity);
      expect(restored.status, signal.status);
      expect(restored.correlationId, signal.correlationId);
      expect(restored.subjectRef, signal.subjectRef);
      expect(restored.detailRef, signal.detailRef);
      expect(restored.metadata['stage'], 'confirm');
    });

    test('rejects payload without code', () {
      expect(
        () => TTErrorSignal.fromPayloadJson(<String, dynamic>{
          'signal_id': 'sig-2',
          'summary': 'Missing code',
          'source': 'mellis',
          'owner_unit_ref': 'meinn.app',
          'severity': 'error',
          'status': 'reported',
          'occurred_at': DateTime.utc(2026, 3, 19).toIso8601String(),
        }),
        throwsA(isA<TTErrorSignalValidationException>()),
      );
    });

    test('rejects non-utc occurred_at on validate', () {
      final signal = TTErrorSignal(
        signalId: 'sig-3',
        code: 'bad_clock',
        summary: 'Occurred at is not in UTC',
        source: 'relay',
        ownerUnitRef: 'meinn.app',
        severity: TTErrorSignalSeverity.warning,
        status: TTErrorSignalStatus.reported,
        occurredAt: DateTime(2026, 3, 19, 9, 0, 0),
      );

      expect(signal.validate, throwsA(isA<TTErrorSignalValidationException>()));
    });
  });

  group('TTErrorChannel', () {
    test('emits signals to listeners', () async {
      final channel = TTErrorChannel();
      final completer = Completer<TTErrorSignal>();

      channel.onSignal.on((signal, [_, __]) {
        completer.complete(signal);
      });

      final signal = TTErrorSignal.reported(
        signalId: 'sig-4',
        code: 'relay_timeout',
        summary: 'Relay timed out',
        source: 'tisane-relay',
        ownerUnitRef: 'meinn.app',
        severity: TTErrorSignalSeverity.critical,
        occurredAt: DateTime.utc(2026, 3, 19, 12, 30, 0),
      );

      channel.emit(signal);

      final received = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      expect(received.code, 'relay_timeout');
      expect(received.severity, TTErrorSignalSeverity.critical);
    });
  });
}
