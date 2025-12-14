import '/src/_internal_xxh3_util.dart';

class DataFormater {
  // Formata os dados brutos do Yahoo Finance
  static Map<String, dynamic> formatYahooData(
    Map<String, dynamic> rawData,
    String ticker,
    Map<String, String> fieldMappings,
  ) {
    // Converte ticker para hash numérico
    int assetId = generateXxh3Hash(ticker);

    // Extrai e mapeia os dados
    Map<String, dynamic> formattedData = _mapYahooData(rawData, fieldMappings);

    return {
      "asset_id": assetId,
      "data": formattedData,
    };
  }

  // Mapeia os dados do Yahoo Finance
  static Map<String, dynamic> _mapYahooData(
    Map<String, dynamic> rawData,
    Map<String, String> fieldMappings,
  ) {
    if (!rawData.containsKey('data') ||
        rawData['data'] == null ||
        rawData['data'].isEmpty) {
      return {"error": "No data found in response"};
    }

    var data = rawData['data'][0];
    if (data == null) {
      return {"error": "Invalid data structure"};
    }

    return {
      "meta": data[fieldMappings['meta']] ?? {},
      "timestamps": data[fieldMappings['timestamp']] ?? [],
      "indicators": _mapIndicators(data[fieldMappings['indicators']] ?? {}),
    };
  }

  // Mapeia os indicadores (OHLCV)
  static Map<String, List<dynamic>> _mapIndicators(
      Map<String, dynamic> indicators) {
    if (!indicators.containsKey('quote') ||
        indicators['quote'] == null ||
        indicators['quote'].isEmpty) {
      return {
        "open": [],
        "high": [],
        "low": [],
        "close": [],
        "volume": [],
        "error": ["No quote data found"], // Lista para consistência de tipo
      };
    }

    var quote = indicators['quote'][0];
    if (quote == null) {
      return {
        "open": [],
        "high": [],
        "low": [],
        "close": [],
        "volume": [],
        "error": ["Invalid quote structure"], // Lista para consistência
      };
    }

    return {
      "open": quote['open'] ?? [],
      "high": quote['high'] ?? [],
      "low": quote['low'] ?? [],
      "close": quote['close'] ?? [],
      "volume": quote['volume'] ?? [],
      "error": [], // Lista vazia quando não há erro
    };
  }
}
