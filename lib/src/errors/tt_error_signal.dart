import 'package:meta/meta.dart';

const ttErrorSignalEventType = 'signal.error';

enum TTErrorSignalSeverity { info, warning, error, critical }

enum TTErrorSignalStatus { reported, acknowledged, resolved }

@immutable
class TTErrorSignal {
  const TTErrorSignal({
    required this.signalId,
    required this.code,
    required this.summary,
    required this.source,
    required this.ownerUnitRef,
    required this.severity,
    required this.status,
    required this.occurredAt,
    this.correlationId,
    this.subjectRef,
    this.detailRef,
    this.metadata = const <String, dynamic>{},
  });

  factory TTErrorSignal.reported({
    required String signalId,
    required String code,
    required String summary,
    required String source,
    required String ownerUnitRef,
    required TTErrorSignalSeverity severity,
    DateTime? occurredAt,
    String? correlationId,
    String? subjectRef,
    String? detailRef,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return TTErrorSignal(
      signalId: signalId,
      code: code,
      summary: summary,
      source: source,
      ownerUnitRef: ownerUnitRef,
      severity: severity,
      status: TTErrorSignalStatus.reported,
      occurredAt: occurredAt ?? DateTime.now().toUtc(),
      correlationId: correlationId,
      subjectRef: subjectRef,
      detailRef: detailRef,
      metadata: metadata,
    )..validate();
  }

  factory TTErrorSignal.fromPayloadJson(Map<String, dynamic> json) {
    final signal = TTErrorSignal(
      signalId: _requiredText(json, 'signal_id'),
      code: _requiredText(json, 'code'),
      summary: _requiredText(json, 'summary'),
      source: _requiredText(json, 'source'),
      ownerUnitRef: _requiredText(json, 'owner_unit_ref'),
      severity: _parseSeverity(_requiredText(json, 'severity')),
      status: _parseStatus(_requiredText(json, 'status')),
      occurredAt: _parseOccurredAt(json['occurred_at']),
      correlationId: _optionalText(json, 'correlation_id'),
      subjectRef: _optionalText(json, 'subject_ref'),
      detailRef: _optionalText(json, 'detail_ref'),
      metadata: _parseMetadata(json['metadata']),
    );
    signal.validate();
    return signal;
  }

  final String signalId;
  final String code;
  final String summary;
  final String source;
  final String ownerUnitRef;
  final TTErrorSignalSeverity severity;
  final TTErrorSignalStatus status;
  final DateTime occurredAt;
  final String? correlationId;
  final String? subjectRef;
  final String? detailRef;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toPayloadJson() {
    validate();
    return <String, dynamic>{
      'signal_id': signalId,
      'code': code,
      'summary': summary,
      'source': source,
      'owner_unit_ref': ownerUnitRef,
      'severity': severity.name,
      'status': status.name,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (_hasText(correlationId)) 'correlation_id': correlationId,
      if (_hasText(subjectRef)) 'subject_ref': subjectRef,
      if (_hasText(detailRef)) 'detail_ref': detailRef,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  TTErrorSignal copyWith({
    String? signalId,
    String? code,
    String? summary,
    String? source,
    String? ownerUnitRef,
    TTErrorSignalSeverity? severity,
    TTErrorSignalStatus? status,
    DateTime? occurredAt,
    String? correlationId,
    String? subjectRef,
    String? detailRef,
    Map<String, dynamic>? metadata,
  }) {
    return TTErrorSignal(
      signalId: signalId ?? this.signalId,
      code: code ?? this.code,
      summary: summary ?? this.summary,
      source: source ?? this.source,
      ownerUnitRef: ownerUnitRef ?? this.ownerUnitRef,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      occurredAt: occurredAt ?? this.occurredAt,
      correlationId: correlationId ?? this.correlationId,
      subjectRef: subjectRef ?? this.subjectRef,
      detailRef: detailRef ?? this.detailRef,
      metadata: metadata ?? this.metadata,
    )..validate();
  }

  void validate() {
    if (!_hasText(signalId)) {
      throw const TTErrorSignalValidationException(
        'signal_id must be a non-empty string',
      );
    }
    if (!_hasText(code)) {
      throw const TTErrorSignalValidationException(
        'code must be a non-empty string',
      );
    }
    if (!_hasText(summary)) {
      throw const TTErrorSignalValidationException(
        'summary must be a non-empty string',
      );
    }
    if (!_hasText(source)) {
      throw const TTErrorSignalValidationException(
        'source must be a non-empty string',
      );
    }
    if (!_hasText(ownerUnitRef)) {
      throw const TTErrorSignalValidationException(
        'owner_unit_ref must be a non-empty string',
      );
    }
    if (occurredAt.isUtc == false) {
      throw const TTErrorSignalValidationException(
        'occurred_at must be in UTC',
      );
    }
  }
}

class TTErrorSignalValidationException implements Exception {
  const TTErrorSignalValidationException(this.message);

  final String message;

  @override
  String toString() => 'TTErrorSignalValidationException: $message';
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = _optionalText(json, key);
  if (_hasText(value)) {
    return value!;
  }
  throw TTErrorSignalValidationException('$key must be a non-empty string');
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

TTErrorSignalSeverity _parseSeverity(String value) {
  return TTErrorSignalSeverity.values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () {
      throw TTErrorSignalValidationException(
        'severity must be one of ${TTErrorSignalSeverity.values.map((it) => it.name).join(', ')}',
      );
    },
  );
}

TTErrorSignalStatus _parseStatus(String value) {
  return TTErrorSignalStatus.values.firstWhere(
    (candidate) => candidate.name == value,
    orElse: () {
      throw TTErrorSignalValidationException(
        'status must be one of ${TTErrorSignalStatus.values.map((it) => it.name).join(', ')}',
      );
    },
  );
}

DateTime _parseOccurredAt(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const TTErrorSignalValidationException(
      'occurred_at must be a non-empty ISO-8601 string',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const TTErrorSignalValidationException(
      'occurred_at must be a valid ISO-8601 string',
    );
  }
  return parsed.toUtc();
}

Map<String, dynamic> _parseMetadata(Object? value) {
  if (value == null) {
    return const <String, dynamic>{};
  }
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(value);
  }
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  }
  throw const TTErrorSignalValidationException(
    'metadata must be a JSON object when present',
  );
}
