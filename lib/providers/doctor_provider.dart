import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _doctorData;

  User? get user => _user;
  Map<String, dynamic>? get doctorData => _doctorData;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadDoctorData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(_user!.uid)
        .get();
    _doctorData = doc.data();
    notifyListeners();
  }

  String get doctorName => _doctorData?['name'] ?? 'Doctor';
  String get specialization => _doctorData?['specialization'] ?? '';
  bool get isProfileComplete => _doctorData?['profileComplete'] == true;

  void clear() {
    _user = null;
    _doctorData = null;
    notifyListeners();
  }
}
