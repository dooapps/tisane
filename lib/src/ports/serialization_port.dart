import '../types/tt.dart';

/// Generic serialization contract for TipTool domain objects.
abstract class TTSerializationPort<T> {
  Map<String, dynamic> toJson(T value);

  T fromJson(Map<String, dynamic> json);
}

class TTNodeSerializationPort implements TTSerializationPort<TTNode> {
  const TTNodeSerializationPort();

  @override
  Map<String, dynamic> toJson(TTNode value) {
    return value.toJson();
  }

  @override
  TTNode fromJson(Map<String, dynamic> json) {
    return TTNode.fromJson(json);
  }
}

TTSerializationPort<TTNode> createDefaultNodeSerializationPort() =>
    const TTNodeSerializationPort();
