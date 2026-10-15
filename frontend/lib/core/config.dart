import 'dart:io' show Platform;

/// Backend address.
/// * Android emulator -> the host machine is reachable at 10.0.2.2 (NOT localhost).
/// * iOS simulator / desktop -> localhost works.
/// * Physical phone -> pass your computer's LAN IP:
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
class AppConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    } catch (_) {}
    return 'http://localhost:8080';
  }
}
