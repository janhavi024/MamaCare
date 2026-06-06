import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _adminData;

  User? get user => _user;
  Map<String, dynamic>? get adminData => _adminData;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadAdminData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(_user!.uid)
        .get();
    _adminData = doc.data();
    notifyListeners();
  }

  String get adminName => _adminData?['name'] ?? 'Admin';

  void clear() {
    _user = null;
    _adminData = null;
    notifyListeners();
  }
}
