import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'counter_notifier.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.watch<CounterNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Counter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${counter.count}',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: counter.increment,
                  icon: const Icon(Icons.add),
                  label: const Text('Increment'),
                ),
                OutlinedButton.icon(
                  onPressed: counter.decrement,
                  icon: const Icon(Icons.remove),
                  label: const Text('Decrement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
