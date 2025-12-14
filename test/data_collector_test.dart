import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:tisane/src/data_collector.dart';

final _runRealApiTests = Platform.environment['RUN_REAL_API_TESTS'] == 'true';

void main() {
  final skipRealApiTests =
      _runRealApiTests ? null : 'Requires RUN_REAL_API_TESTS=true';
  group('DataCollector.fetchStockData Yahoo API - Teste com API real', () {
    test('Deve retornar dados válidos da API real', () async {
      final String urlCollector =
          "https://yahoo-finance-api-data.p.rapidapi.com/chart/simple-chart";

      final Map<String, dynamic> params = {
        "symbol": "PETR3.SA",
        "limit": "10",
        "range": "1d"
      };

      final Map<String, String> headers = {
        "x-rapidapi-host": "yahoo-finance-api-data.p.rapidapi.com",
        "x-rapidapi-key": "e0e6d6264dmsh2f3884c1cd7b529p1a29efjsnb7cdc6ac30ce",
      };

      Map<String, String> fieldMappings = {
        "meta": "meta",
        "timestamp": "timestamp",
        "indicators": "indicators"
      };

      try {
        final response = await DataCollector.fetchStockData(
          "public_key",
          urlCollector,
          params,
          headers,
          fieldMappings,
        );
        print(jsonEncode(response["body"]["data"]));
        expect(response["statusCode"], equals(200));
      } catch (e) {
        print("Error message: $e");
        fail("Error from API: $e");
      }
    }, skip: skipRealApiTests);
  });
  group('DataCollector.fetchStockData Wallet Finbo API - Teste com API real',
      () {
    test('Deve retornar dados válidos da API real', () async {
      final String urlCollector =
          "https://itva-crypto-ia-2405334676d1.herokuapp.com/v1/wallet/66cf9db3a7940580210770f7";

      final Map<String, dynamic> params = {};

      final Map<String, String> headers = {
        "Content-Type": "application/json",
        "x-api-key": "",
      };

      Map<String, String> fieldMappings = {
        "id": "id",
        "name": "name",
        "startDate": "startDate",
        "baseInvestment": "baseInvestment",
        "balance": "balance",
        "lastBtcPrice": "lastBtcPrice"
      };

      try {
        final response = await DataCollector.fetchStockData(
          "public_key",
          urlCollector,
          params,
          headers,
          fieldMappings,
        );

        print(jsonEncode(response["body"]["id"]));

        expect(response["statusCode"], equals(200));
      } catch (e) {
        print("Error message: $e");
        fail("Error from API: $e");
      }
    }, skip: skipRealApiTests);
  });

  group('DataCollector.fetchStockData B3 Finbo API - Teste com API real', () {
    test('Deve retornar dados válidos da API B3', () async {
      final String urlCollector =
          "https://itva-crypto-ia-2405334676d1.herokuapp.com/v1/b3/data";

      final Map<String, dynamic> params = {"query": "PETR4"};

      final Map<String, String> headers = {
        "Content-Type": "application/json",
        "x-api-key": "6b77b8ee-9790-427a-a27f-601b0cde0d53",
      };

      Map<String, String> fieldMappings = {
        "symbol": "symbol",
        "price": "price",
        "longName": "longName",
        "shortName": "shortName",
        "currency": "currency",
        "last_updated": "last_updated",
        "high": "high",
        "low": "low",
        "openPrice": "openPrice",
        "previousClose": "previousClose",
        "volume": "volume",
        "marketVariation.absolut": "marketVariation.absolut",
        "marketVariation.percent": "marketVariation.percent"
      };

      try {
        final response = await DataCollector.fetchStockData(
          "public_key",
          urlCollector,
          params,
          headers,
          fieldMappings,
        );

        final body = response["body"];
        expect(response["statusCode"], equals(200));

        print("Retorno da ação: ${jsonEncode(body)}");

        // Checa se o primeiro item da lista possui os campos esperados
        expect(body, isA<List>());
        expect(body.first["symbol"], isNotNull);
        expect(body.first["price"], isA<num>());
        expect(body.first["longName"], isA<String>());
      } catch (e) {
        print("Erro ao chamar API B3: $e");
        fail("Erro na chamada da API B3: $e");
      }
    }, skip: skipRealApiTests);
  });
}
