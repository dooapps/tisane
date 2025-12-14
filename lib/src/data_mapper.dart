import '_internal_utils.dart';

class DataMapper {
  final Map<String, String> fieldMappings;

  DataMapper(this.fieldMappings);

  /// Normaliza os dados para garantir que lidamos corretamente com listas e objetos individuais
  List<Map<String, dynamic>> normalizeRawData(dynamic rawData) {
    if (rawData is List) {
      return rawData.whereType<Map<String, dynamic>>().toList();
    } else if (rawData is Map<String, dynamic>) {
      return [rawData];
    } else {
      throw Exception("Format not supported");
    }
  }

  /// Método principal para mapear e extrair dados de forma segura
  List<Map<String, dynamic>> processRawData(dynamic rawData) {
    List<Map<String, dynamic>> normalizedData = normalizeRawData(rawData);
    List<Map<String, dynamic>> processedData = [];

    for (var item in normalizedData) {
      Map<String, dynamic> mappedData = {};

      fieldMappings.forEach((expectedField, actualField) {
        if (item.containsKey(actualField)) {
          dynamic value = item[actualField];

          // Convertendo valores numéricos que vêm como string
          if (value is String && isNumeric(value)) {
            value = double.parse(value);
          }

          // Convertendo listas de números
          if (value is List) {
            value = value.map((e) => toDouble(e)).toList();
          }

          mappedData[expectedField] = value;
        }
      });

      processedData.add(mappedData);
    }

    return processedData;
  }
}
