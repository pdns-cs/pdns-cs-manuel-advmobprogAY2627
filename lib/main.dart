import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Starts the app and provides ThemeModel to all screens.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const StateManagementActivity(),
    ),
  );
}

// Root widget that applies the selected app theme.
class StateManagementActivity extends StatelessWidget {
  const StateManagementActivity({super.key});

  // Builds the MaterialApp using the current theme state.
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(),
    ); // MaterialApp
  }
}

// Stores and updates the app-wide light/dark theme state.
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  // Returns true when dark mode is enabled.
  bool get isDark => _isDark;

  // Switches the theme and notifies listening widgets.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// Home screen that demonstrates ephemeral state with a counter.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // Creates the mutable state for the counter screen.
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Holds the counter value used only by MyHomePage.
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // Increases the counter using setState.
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // Builds the counter UI and theme navigation button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          IconButton(
            tooltip: 'Change theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsPage(),
                ),
              );
            },
          ),
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Text
          ], // <Widget>[]
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}

// Screen for changing the app-wide theme using Provider.
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  // Builds the modern light/dark mode selector.
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('App State Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                themeModel.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                themeModel.isDark ? 'Dark Mode' : 'Light Mode',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Container(
                width: 220,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeModeButton(
                        icon: Icons.light_mode_rounded,
                        label: 'Light',
                        selected: !themeModel.isDark,
                        onTap: themeModel.isDark
                            ? themeModel.toggleTheme
                            : null,
                      ),
                    ),
                    Expanded(
                      child: _ThemeModeButton(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark',
                        selected: themeModel.isDark,
                        onTap: themeModel.isDark
                            ? null
                            : themeModel.toggleTheme,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable button used by the light/dark selector.
class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  // Builds one selectable theme option.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
