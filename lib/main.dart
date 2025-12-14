import 'package:flutter/material.dart';
// import 'package:infusion_ffi/api.dart'; // Temporarily disabled until docs are updated

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tisane - Infusion FFI Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const InfusionTestScreen(),
    );
  }
}

class InfusionTestScreen extends StatefulWidget {
  const InfusionTestScreen({super.key});

  @override
  State<InfusionTestScreen> createState() => _InfusionTestScreenState();
}

class _InfusionTestScreenState extends State<InfusionTestScreen> {
  String _logs = '';

  void _log(String message) {
    setState(() {
      _logs +=
          "[\${DateTime.now().toIso8601String().split('T').last}] \$message\n";
    });
  }

  Future<void> _testInitialize() async {
    try {
      _log('Testing Initialize...');
      // Waiting for documentation update on new API signature.
      _log('Library loaded: \$lib');

      // Placeholder for new API call:
      // await lib.initialize(...);
      _log('⚠️ API pending update. Check docs.');
    } catch (e) {
      _log('Error Initialize: \$e');
    }
  }

  Future<void> _testGenerateNumericHash() async {
    _log('Feature pending API update.');
    // try {
    //   final result = await FbblApi.fbblGenerateNumericHash(input: "test_input");
    //   _log('Hash Result: \$result');
    // } catch (e) {
    //   _log('Error: \$e');
    // }
  }

  Future<void> _testEncryptDecryptId() async {
    _log('Feature pending API update.');
    // try {
    //   final id = BigInt.from(12345);
    //   final nonce = List<int>.filled(12, 0);
    //   final encrypted = await FbblApi.fbblEncryptId(id: id, nonce: nonce);
    //   _log('Encrypted: \$encrypted');
    // } catch (e) {
    //   _log('Error: \$e');
    // }
  }

  Future<void> _testCreateAndParseFrame() async {
    _log('Feature pending API update.');
    // try {
    //   final frame = await FbblApi.fbblCreateFrame(...);
    //   _log('Frame: \$frame');
    // } catch (e) {
    //   _log('Error: \$e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Infusion FFI Tester')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _testInitialize,
                  child: const Text('1. Initialize'),
                ),
                ElevatedButton(
                  onPressed: _testGenerateNumericHash,
                  child: const Text('2. Generate Numeric Hash'),
                ),
                ElevatedButton(
                  onPressed: _testEncryptDecryptId,
                  child: const Text('3. Encrypt / Decrypt ID'),
                ),
                ElevatedButton(
                  onPressed: _testCreateAndParseFrame,
                  child: const Text('4. Create, Parse & Verify Frame'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text(
                  _logs,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
