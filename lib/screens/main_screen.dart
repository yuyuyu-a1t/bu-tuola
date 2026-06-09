import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/main_navigation_controller.dart';
import 'ai_assistant_screen.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'tree_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _navigationController = MainNavigationController();

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _navigationController,
      child: AnimatedBuilder(
        animation: _navigationController,
        builder: (context, _) {
          final currentIndex = _navigationController.currentIndex;

          return Scaffold(
            body: IndexedStack(
              index: currentIndex,
              children: const [
                HomeScreen(),
                TasksScreen(),
                AiAssistantScreen(),
                TreeScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              backgroundColor: colorScheme.surface,
              showUnselectedLabels: true,
              onTap: _navigationController.goToPage,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: '首页',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.checklist_outlined),
                  activeIcon: Icon(Icons.checklist),
                  label: '任务',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome),
                  label: 'AI助手',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.park_outlined),
                  activeIcon: Icon(Icons.park),
                  label: '我的',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
