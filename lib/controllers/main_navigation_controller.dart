import 'package:flutter/foundation.dart';

class MainNavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void goToPage(int index) {
    if (_currentIndex == index) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }

  void openTasks() {
    goToPage(1);
  }

  void openAiAssistant() {
    goToPage(2);
  }

  void openMyPage() {
    goToPage(3);
  }
}
