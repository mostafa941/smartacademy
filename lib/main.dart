import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/admin/constants/supabase_constants.dart';
import 'features/splash/screens/splash_screen.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/theme_provider.dart';

// استخدام deferred as لتحميل شاشات الأدمن فقط عند الحاجة إليها
import 'features/admin/admin_app.dart' deferred as adminModule;

// ─────────────────────────────────────────────────────────────────────────────
// نقطة الدخول الرئيسية
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // إعداد OneSignal (Push Notifications)
  // يرجى استبدال YOUR_ONESIGNAL_APP_ID بمعرف التطبيق الحقيقي لاحقاً
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

// ─────────────────────────────────────────────────────────────────────────────
// تحديد نوع الشاشة الافتراحية بناءً على المنصة والمسار
// ─────────────────────────────────────────────────────────────────────────────

/// يُعيد true إذا كان التطبيق يُشغَّل عبر المتصفح وكان المسار يحتوي على /admin
bool get _isAdminRoute {
  if (!kIsWeb) return false;
  // Uri.base متاح فقط على الويب - في البيئات الأخرى يعود false من kIsWeb
  try {
    final path = Uri.base.path;
    return path.contains('/admin');
  } catch (_) {
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// التطبيق الرئيسي
// ─────────────────────────────────────────────────────────────────────────────

class SmartAcademyApp extends StatelessWidget {
  const SmartAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (_isAdminRoute) {
      return _buildAdminApp();
    }
    
    // إذا تم فتح التطبيق على الويب ولم يكن الرابط /admin، نعرض صفحة التحميل
    if (kIsWeb) {
      return _buildWebDownloadPage();
    }

    return _buildMobileApp(context);
  }

  // ── صفحة التحميل على الويب ───────────────────────────────────────────────────
  Widget _buildWebDownloadPage() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Academy',
      home: Scaffold(
        backgroundColor: const Color(0xFFE6E6FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SMART',
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'smart_font',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'تطبيق الطالب والمعلم متاح فقط على الهواتف الذكية.',
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى تحميل التطبيق وتثبيته على هاتفك للتمتع بكافة الميزات.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () async {
                    // قم بتغيير هذا الرابط برابط التحميل الفعلي لملف الـ APK
                    final Uri url = Uri.parse('https://your-domain.com/app-release.apk');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      debugPrint('Could not launch $url');
                    }
                  },
                  icon: const Icon(Icons.android, size: 28),
                  label: const Text('تحميل تطبيق الأندرويد (APK)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF724F96),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── تطبيق الأدمن (Web /admin) ──────────────────────────────────────────────
  Widget _buildAdminApp() {
    return FutureBuilder(
      future: adminModule.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // بمجرد التحميل، نعرض واجهة الأدمن
          return adminModule.AdminApp();
        }
        
        // أثناء التحميل نعرض شاشة بسيطة
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFFE6E6FA), // AppColors.bodyBg
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF724F96), // AppColors.sidebarBg
              ),
            ),
          ),
        );
      },
    );
  }

  // ── تطبيق الموبايل / PWA (الشاشة الافتراضية) ─────────────────────────────
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
        Locale('ar', ''), // Arabic
      ],
      locale: const Locale('ar', ''),
      // نبدأ دائماً من SplashScreen على الموبايل والويب العام
      home: const SplashScreen(),
    );
  }

  // ── Theme الموبايل ────────────────────────────────────────────────────────
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
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark navy
      useMaterial3: true,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white),
      ),
    );
  }
}
