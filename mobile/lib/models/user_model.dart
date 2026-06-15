import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String? _userId;
  String? _nickname;
  bool _isVip = false;
  int _freeCountToday = 1;
  
  String? get userId => _userId;
  String? get nickname => _nickname;
  bool get isVip => _isVip;
  int get freeCountToday => _freeCountToday;
  
  void setUser(String id, String name) {
    _userId = id;
    _nickname = name;
    notifyListeners();
  }
  
  void updateVipStatus(bool isVip) {
    _isVip = isVip;
    notifyListeners();
  }
}
