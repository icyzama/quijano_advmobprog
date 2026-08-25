import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const CombinedApp(),
    ),
  );
}

class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class CombinedApp extends StatelessWidget {
  const CombinedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const CombinedHomePage(),
    );
  }
}

class CombinedHomePage extends StatefulWidget {
  const CombinedHomePage({super.key});

  @override
  State<CombinedHomePage> createState() => _CombinedHomePageState();
}

class _CombinedHomePageState extends State<CombinedHomePage> {
  // Ephemeral State
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // App State Access
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combined State Management'),
        actions: [
          Row(
            children: [
              Icon(themeModel.isDark ? Icons.dark_mode : Icons.light_mode),
              Switch(
                value: themeModel.isDark,
                onChanged: (_) => themeModel.toggleTheme(),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
