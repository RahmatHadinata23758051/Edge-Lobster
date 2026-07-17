import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'core/services/gateway_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'modules/dashboard/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi MediaKit untuk pemutar video RTSP native
  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GatewayStateProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lobsense Edge Gateway',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const DashboardPage(),
    );
  }
}
