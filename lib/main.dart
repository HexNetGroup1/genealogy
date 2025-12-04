import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseInitializer.initialize();
  runApp(const App());
}
