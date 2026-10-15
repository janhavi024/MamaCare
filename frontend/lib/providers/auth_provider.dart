import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/notification_service.dart';
import '../models/models.dart';
import '../services/services.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final Services services;
  AuthProvider(this.services) {
    services.api.onUnauthorized = _expired;
  }

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? verificationStatus;
  String? verificationNotes;
  String? notice; // shown on the login screen (e.g. "session expired")

  ApiClient get _api => services.api;

  /// Called by the splash screen: restores a saved session if the server still accepts the token.
  Future<void> restore() async {
    final token = await _api.loadStoredToken();
    if (token == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      await refresh();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _api.setToken(null);
      }
      status = AuthStatus.signedOut;
      user = null;
      if (!e.isUnauthorized) notice = e.message;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final me = await services.auth.me();
    user = AppUser.fromJson(me['user']);
    verificationStatus = me['verificationStatus'];
    verificationNotes = me['verificationNotes'];
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await services.auth.login(email.trim(), password);
    await _accept(res);
  }

  Future<void> register(Json body) async {
    final res = await services.auth.register(body);
    await _accept(res);
  }

  Future<void> _accept(Json res) async {
    await _api.setToken(res['token']);
    notice = null;
    await refresh();
  }

  Future<void> updateProfile(String name, String? phone) async {
    await services.auth.updateMe(name, phone);
    await refresh();
  }

  Future<void> logout() async {
    try {
      await services.auth.logout(); // invalidates the token server-side
    } catch (_) {}
    await _clear();
  }

  void _expired() {
    if (status != AuthStatus.signedIn) return;
    _clear(message: 'Your session has expired. Please sign in again.');
  }

  Future<void> _clear({String? message}) async {
    await _api.setToken(null);
    await NotificationService.cancelAll();
    user = null;
    verificationStatus = null;
    notice = message;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
