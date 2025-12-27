import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

class InfusionPolicy {
  static const int privateId = 0;
  static const int sharedId = 1;
  static const int publicId = 2;

  final int id;
  final String name;
  final bool requiresCapToken;

  const InfusionPolicy({
    required this.id,
    required this.name,
    this.requiresCapToken = false,
  });

  static const InfusionPolicy private = InfusionPolicy(
    id: privateId,
    name: 'private',
    requiresCapToken: false,
  );

  static const InfusionPolicy shared = InfusionPolicy(
    id: sharedId,
    name: 'shared',
    requiresCapToken: true,
  );

  static const InfusionPolicy public = InfusionPolicy(
    id: publicId,
    name: 'public',
    requiresCapToken: false,
  );
}

class InfusionPolicyCatalog {
  final Map<int, InfusionPolicy> policies;

  const InfusionPolicyCatalog(this.policies);

  static const InfusionPolicyCatalog defaults = InfusionPolicyCatalog({
    InfusionPolicy.privateId: InfusionPolicy.private,
    InfusionPolicy.sharedId: InfusionPolicy.shared,
    InfusionPolicy.publicId: InfusionPolicy.public,
  });

  InfusionPolicy resolve(int policyId) {
    return policies[policyId] ?? InfusionPolicy.private;
  }
}

class InfusionAadContext {
  final String soul;
  final String field;
  final int policyId;
  final int schemaVersion;

  const InfusionAadContext({
    required this.soul,
    required this.field,
    required this.policyId,
    required this.schemaVersion,
  });
}

class InfusionAad {
  final int version;
  final int policyId;
  final String soul;
  final String field;

  const InfusionAad({
    required this.version,
    required this.policyId,
    required this.soul,
    required this.field,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'v': version,
      'policy_id': policyId,
      'soul': soul,
      'field': field,
    };
  }

  Uint8List toBytes() {
    return Uint8List.fromList(utf8.encode(jsonEncode(toJson())));
  }

  static InfusionAad? tryParse(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) return null;
      return InfusionAad(
        version: decoded['v'] is int ? decoded['v'] as int : 1,
        policyId: decoded['policy_id'] as int? ?? InfusionPolicy.privateId,
        soul: decoded['soul']?.toString() ?? '',
        field: decoded['field']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static InfusionAad defaultBuilder(InfusionAadContext ctx) {
    return InfusionAad(
      version: ctx.schemaVersion,
      policyId: ctx.policyId,
      soul: ctx.soul,
      field: ctx.field,
    );
  }
}

typedef InfusionAadBuilder = InfusionAad Function(InfusionAadContext context);

class InfusionPolicyContext {
  final String soul;
  final String field;
  final Object? value;
  final Map<String, dynamic>? nodeMeta;

  const InfusionPolicyContext({
    required this.soul,
    required this.field,
    required this.value,
    this.nodeMeta,
  });
}

typedef InfusionPolicyResolver = int Function(InfusionPolicyContext context);

class InfusionCapContext {
  final String soul;
  final String field;
  final int policyId;
  final Uint8List? aad;
  final Object? value;

  const InfusionCapContext({
    required this.soul,
    required this.field,
    required this.policyId,
    required this.aad,
    required this.value,
  });
}

typedef InfusionCapTokenProvider =
    FutureOr<Uint8List?> Function(InfusionCapContext context);
typedef InfusionRequesterProvider =
    FutureOr<Uint8List?> Function(InfusionCapContext context);

class InfusionConfig {
  final String alg;
  final String? authorPubHex;
  final String? ownerPubHex;
  final String? requesterPubHex;
  final int defaultPolicyId;
  final int aadSchemaVersion;
  final InfusionPolicyCatalog policyCatalog;
  final InfusionPolicyResolver? policyResolver;
  final InfusionAadBuilder aadBuilder;
  final InfusionCapTokenProvider? capTokenProvider;
  final InfusionRequesterProvider? requesterProvider;
  final bool embedCapToken;
  final bool verifyFrameBeforeOpen;
  final bool enforceAadContext;

  const InfusionConfig({
    this.alg = 'ChaCha20',
    this.authorPubHex,
    this.ownerPubHex,
    this.requesterPubHex,
    this.defaultPolicyId = InfusionPolicy.privateId,
    this.aadSchemaVersion = 1,
    this.policyCatalog = InfusionPolicyCatalog.defaults,
    this.policyResolver,
    this.aadBuilder = InfusionAad.defaultBuilder,
    this.capTokenProvider,
    this.requesterProvider,
    this.embedCapToken = false,
    this.verifyFrameBeforeOpen = true,
    this.enforceAadContext = true,
  });
}

class InfusionEnvelope {
  static const String legacyPrefix = 'INF:';
  static const String jsonPrefix = 'INFJ:';

  final int version;
  final int policyId;
  final Uint8List frame;
  final Uint8List? aad;
  final Uint8List? capToken;
  final bool legacy;

  const InfusionEnvelope({
    required this.version,
    required this.policyId,
    required this.frame,
    this.aad,
    this.capToken,
    this.legacy = false,
  });

  String encode() {
    final payload = <String, dynamic>{
      'v': version,
      'policy_id': policyId,
      'frame_b64': base64Encode(frame),
    };
    if (aad != null && aad!.isNotEmpty) {
      payload['aad_b64'] = base64Encode(aad!);
    }
    if (capToken != null && capToken!.isNotEmpty) {
      payload['cap_b64'] = base64Encode(capToken!);
    }
    return '$jsonPrefix${jsonEncode(payload)}';
  }

  static InfusionEnvelope? tryParse(
    String value, {
    required int defaultPolicyId,
  }) {
    if (value.startsWith(jsonPrefix)) {
      final jsonStr = value.substring(jsonPrefix.length);
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is! Map) return null;
        final frameB64 = decoded['frame_b64']?.toString();
        if (frameB64 == null || frameB64.isEmpty) return null;
        final frame = base64Decode(frameB64);
        final aadB64 = decoded['aad_b64']?.toString();
        final capB64 = decoded['cap_b64']?.toString();
        return InfusionEnvelope(
          version: decoded['v'] is int ? decoded['v'] as int : 1,
          policyId: decoded['policy_id'] as int? ?? defaultPolicyId,
          frame: frame,
          aad: (aadB64 == null || aadB64.isEmpty)
              ? null
              : base64Decode(aadB64),
          capToken: (capB64 == null || capB64.isEmpty)
              ? null
              : base64Decode(capB64),
        );
      } catch (_) {
        return null;
      }
    }

    if (value.startsWith(legacyPrefix)) {
      final hexStr = value.substring(legacyPrefix.length);
      try {
        return InfusionEnvelope(
          version: 0,
          policyId: defaultPolicyId,
          frame: Uint8List.fromList(hex.decode(hexStr)),
          legacy: true,
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
