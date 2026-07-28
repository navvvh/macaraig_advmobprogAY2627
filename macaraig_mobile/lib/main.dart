import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    // nilagay ko yung ThemeModel sa taas ng buong app kasi need siya
    // makita ng home page pati ng theme settings page
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // get yung current state ng theme model para malaman po kung dark or light
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      // depende dito sa isDark magpapalit yung buong theme ng app
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(),
    );
  }
}

// separate class ito for state management, di siya widget
// gamit ChangeNotifier para pwede mag notify pag may update
class ThemeModel with ChangeNotifier {
  bool _isDark = false; // default light mode muna

  bool get isDark => _isDark;

  // pag pinindot yung switch ma ca-call po siya 
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners(); // rebuild 
  }
}

// first screen, dito lang muna yung counter (ephemeral state lang to
// pag nag navigate po tas bumalik ka mare-reset ulit siya)
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; 

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
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
            const SizedBox(height: 30),
            // papunta sa yung page ng theme toggle
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeSettingsPage(),
                  ),
                );
              },
              child: const Text('Go to Theme Settings'),
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

// second screen, dito na yung switch para sa dark/light mode
// app state to kasi kahit lumipat ka ng page di siya nawawala
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Toggle the theme below.'),
            const SizedBox(height: 20),
            Switch(
              value: themeModel.isDark,
              // tinawag na lang yung toggleTheme sa model, wala na
              // dapat isulat na logic dito, si model bahala mag manage
              onChanged: (_) => themeModel.toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}