import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    _userData = doc.data();
    notifyListeners();
  }

  int get currentWeek {
    if (_userData == null) return 1;
    final dueDateRaw = _userData!['dueDate'];
    if (dueDateRaw == null) return 1;
    final dueDate = (dueDateRaw as Timestamp).toDate();
    final weeksLeft = dueDate.difference(DateTime.now()).inDays ~/ 7;
    return (40 - weeksLeft).clamp(1, 40);
  }

  String get motherName {
    return _userData?['name'] ?? 'Mama';
  }
}
