import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_record_provider.dart';
import 'screens/main_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storageService),
        ChangeNotifierProvider(create: (_) => TaskProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => UserRecordProvider(storageService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
      ],
      child: const ClassBuddyLiteApp(),
    ),
  );
}

class ClassBuddyLiteApp extends StatelessWidget {
  const ClassBuddyLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: '不拖啦',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
