import 'package:flutter/foundation.dart';

class AppPrefs extends ChangeNotifier {
  bool showMapping = true;

  void setShowMapping(bool v) {
    if (v == showMapping) return;
    showMapping = v;
    notifyListeners();
  }
}
