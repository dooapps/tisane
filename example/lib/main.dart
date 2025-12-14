import 'package:flutter/material.dart';
import 'package:tisane/tisane.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Infusion Manager (Vault/FFI)
  await InfusionManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Tisane Example')),
        body: const TisaneDemo(),
      ),
    );
  }
}

class TisaneDemo extends StatefulWidget {
  const TisaneDemo({super.key});

  @override
  State<TisaneDemo> createState() => _TisaneDemoState();
}

class _TisaneDemoState extends State<TisaneDemo> {
  String _status = 'Initializing...';
  String _mnemonic = '';
  String _hiveKeyStart = '';

  @override
  void initState() {
    super.initState();
    _runDemo();
  }

  Future<void> _runDemo() async {
    try {
      // 1. Generate Mnemonic
      final mnemonic = await InfusionManager.generateMnemonic();

      // 2. Derive Hive Key
      final hiveKey = await InfusionManager.getHiveKey();

      // 3. Setup TTClient (Data Mesh)
      // Note: In a real app, you would add peers here.
      final client = TTClient();

      // Simple write to graph (offline)
      client.get('app/status').put({'alive': true});

      if (mounted) {
        setState(() {
          _status = 'Tisane Initialized Successfully';
          _mnemonic = mnemonic;
          _hiveKeyStart = hiveKey.sublist(0, 5).toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: $_status',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Generated Mnemonic (Secure FFI):'),
          SelectableText(_mnemonic.isNotEmpty ? _mnemonic : 'Generating...'),
          const SizedBox(height: 20),
          Text('Derived Hive Key (First 5 bytes): $_hiveKeyStart'),
          const SizedBox(height: 20),
          const Text('TTClient instantiated and graph node written.'),
        ],
      ),
    );
  }
}
