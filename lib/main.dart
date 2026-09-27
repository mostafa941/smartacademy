import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/device/device_platform.dart';
import 'features/admin/constants/supabase_constants.dart';
import 'features/splash/screens/splash_screen.dart';

import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

// استخدام deferred as لتحميل شاشات الأدمن عند الحاجة إليها على الويب
import 'features/admin/admin_app.dart' deferred as adminModule;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // إعداد الإشعارات للموبايل فقط
  if (!kIsWeb) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("YOUR_ONESIGNAL_APP_ID");
    OneSignal.Notifications.requestPermission(true);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartAcademyApp(),
    ),
  );
}

class SmartAcademyApp extends StatelessWidget {
  const SmartAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الويب من كمبيوتر/لابتوب → لوحة الأدمن. الويب من موبايل → تطبيق الطالب/المعلم.
    if (kIsWeb && shouldShowAdminPanel()) {
      return _buildAdminApp();
    }

    return _buildMobileApp(context);
  }

  // ── واجهة الأدمن (للويب) ───────────────────────────────────────────────────
  Widget _buildAdminApp() {
    return FutureBuilder(
      future: adminModule.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return adminModule.AdminApp();
        }
        
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFFE6E6FA),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF724F96),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── واجهة الموبايل (طالب / معلم) ──────────────────────────────────────────
  Widget _buildMobileApp(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Academy',
      theme: _mobileTheme(),
      darkTheme: _darkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      locale: const Locale('ar', ''),
      home: const SplashScreen(),
    );
  }

  ThemeData _mobileTheme() {
    return ThemeData(
      colorSchemeSeed: const Color.fromRGBO(114, 79, 150, 0.993),
      scaffoldBackgroundColor: const Color.fromRGBO(230, 230, 250, 0.984),
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      colorSchemeSeed: const Color.fromRGBO(114, 79, 150, 0.993),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }
}