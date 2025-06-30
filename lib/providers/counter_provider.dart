import 'package:asatex_compensation/utils/logger.dart';
import 'package:flutter/foundation.dart';

class CounterProvider with ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    logger.d('Counter incremented to: $_count');
    notifyListeners();
  }
} 