import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_provider.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import '../../core/widgets/connectivity_wrapper.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Academy – Admin',
        theme: ThemeData(
          colorSchemeSeed: const Color.fromRGBO(114, 79, 150, 0.993),
          scaffoldBackgroundColor: const Color.fromRGBO(230, 230, 250, 0.984),
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''), // Arabic
        ],
        locale: const Locale('ar', ''),
        home: ConnectivityWrapper(
          child: hasSession ? const AdminDashboardScreen() : const AdminLoginScreen(),
        ),
      ),
    );
  }
}
