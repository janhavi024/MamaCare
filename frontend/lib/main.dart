import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/notification_service.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_gate.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final services = Services(ApiClient(TokenStorage()));
  runApp(MultiProvider(
    providers: [
      Provider<Services>.value(value: services),
      ChangeNotifierProvider(create: (_) => AuthProvider(services)),
    ],
    child: const MamaCareApp(),
  ));
}

class MamaCareApp extends StatelessWidget {
  const MamaCareApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MamaCare',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      );
}
