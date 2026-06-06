import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaretakerProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _caretakerData;

  User? get user => _user;
  Map<String, dynamic>? get caretakerData => _caretakerData;

  String get caretakerName => _caretakerData?['name'] ?? 'Caretaker';
  String? get linkedPatientId => _caretakerData?['linkedPatientId'];

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadCaretakerData() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('caretakers')
          .doc(_user!.uid)
          .get();
      _caretakerData = doc.data();
      notifyListeners();
    } catch (e) {
      debugPrint('CaretakerProvider: loadCaretakerData error: $e');
    }
  }

  void clear() {
    _user = null;
    _caretakerData = null;
    notifyListeners();
  }
}
