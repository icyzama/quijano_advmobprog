import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

// Enhancement 3: Settings page that hosts the dark/light mode switch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: Dark/light mode switch moved here from the home AppBar.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(text: 'Settings', fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const CustomText(text: 'Dark Mode', fontSize: 16),
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
}
