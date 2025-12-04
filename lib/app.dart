import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genealogy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeTabsScreen(),
    );
  }
}
