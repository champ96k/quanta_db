import 'package:flutter/material.dart';
import 'package:quanta_db/quanta_db.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantaDB Web Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'QuantaDB Web Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  String? _retrievedValue;
  String? _error;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await QuantaDB.instance.open();
      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize database: $e';
      });
    }
  }

  Future<void> _storeValue() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'Database not initialized';
      });
      return;
    }

    final key = _keyController.text;
    final value = _valueController.text;

    if (key.isEmpty || value.isEmpty) {
      setState(() {
        _error = 'Key and value cannot be empty';
      });
      return;
    }

    try {
      await QuantaDB.instance.put(key, value);
      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to store value: $e';
      });
    }
  }

  Future<void> _retrieveValue() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'Database not initialized';
      });
      return;
    }

    final key = _keyController.text;

    if (key.isEmpty) {
      setState(() {
        _error = 'Key cannot be empty';
      });
      return;
    }

    try {
      final value = await QuantaDB.instance.get<String>(key);
      setState(() {
        _retrievedValue = value;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to retrieve value: $e';
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    QuantaDB.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red.shade100,
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _storeValue : null,
                    child: const Text('Store Value'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _retrieveValue : null,
                    child: const Text('Retrieve Value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_retrievedValue != null)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retrieved Value:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_retrievedValue!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
