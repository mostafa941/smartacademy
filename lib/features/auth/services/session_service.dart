import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة جلسة المستخدم باستخدام SharedPreferences
/// تحفظ بيانات المستخدم محليًا لتذكر تسجيل الدخول بين الجلسات
class SessionService {
  static const String _keyUserId = 'session_user_id';
  static const String _keyUserName = 'session_user_name';
  static const String _keyRole = 'session_role';
  static const String _keyPhone = 'session_phone';
  static const String _keyIsLoggedIn = 'session_is_logged_in';

  /// حفظ بيانات المستخدم بعد تسجيل الدخول الناجح
  static Future<void> saveSession({
    required String userId,
    required String userName,
    required String role,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyPhone, phone);
  }

  /// التحقق من وجود جلسة نشطة
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// جلب بيانات الجلسة الحالية (تُعيد null إذا لم توجد جلسة)
  static Future<SessionData?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userId = prefs.getString(_keyUserId);
    final userName = prefs.getString(_keyUserName);
    final role = prefs.getString(_keyRole);
    final phone = prefs.getString(_keyPhone);

    if (userId == null || userName == null || role == null || phone == null) return null;

    return SessionData(userId: userId, userName: userName, role: role, phone: phone);
  }

  /// حذف الجلسة (تسجيل الخروج)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyPhone);
  }
}

/// نموذج بيانات الجلسة
class SessionData {
  final String userId;
  final String userName;
  final String role;
  final String phone;

  const SessionData({
    required this.userId,
    required this.userName,
    required this.role,
    required this.phone,
  });
}
