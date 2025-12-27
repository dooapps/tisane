import 'package:flutter/material.dart';
import 'package:tisane/tisane.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TisaneApp());
}

class TisaneApp extends StatelessWidget {
  const TisaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tisane',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late final Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    await InfusionManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tisane')),
      body: Center(
        child: FutureBuilder<void>(
          future: _bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _StatusView(
                title: 'Starting up',
                subtitle: 'Preparing the secure vault',
                showSpinner: true,
              );
            }
            if (snapshot.hasError) {
              return _StatusView(
                title: 'Startup failed',
                subtitle: snapshot.error.toString(),
                showSpinner: false,
                isError: true,
              );
            }
            return const _StatusView(
              title: 'Ready',
              subtitle: 'Infusion initialized',
              showSpinner: false,
            );
          },
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.title,
    required this.subtitle,
    required this.showSpinner,
    this.isError = false,
  });

  final String title;
  final String subtitle;
  final bool showSpinner;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(color: color),
            ),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
