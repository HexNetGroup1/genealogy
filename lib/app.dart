import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/counter/counter_notifier.dart';
import 'features/counter/counter_screen.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterNotifier(),
        ),
      ],
      child: MaterialApp(
        title: 'Genealogy',
        theme: buildTheme(),
        home: const CounterScreen(),
      ),
    );
  }
}
