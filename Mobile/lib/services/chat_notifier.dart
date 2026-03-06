import 'package:flutter/material.dart';

class ChatNotifier extends ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void setUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
    }
  }
}

final chatNotifier = ChatNotifier();