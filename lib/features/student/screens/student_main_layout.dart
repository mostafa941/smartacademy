import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../providers/student_provider.dart';
import 'student_home_tab.dart';
import 'student_notes_tab.dart';
import 'student_attendance_history_tab.dart';
import 'student_settings_tab.dart';
import 'student_profile_tab.dart';
import 'notifications_screen.dart';
import '../providers/notifications_provider.dart';
import '../../../core/widgets/skeleton_loading.dart';

class StudentMainLayout extends StatefulWidget {
  final String userId;
  final String userName;

  const StudentMainLayout({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchStudentData(
        widget.userId,
        isParentPhone: false,
      );
    });
  }

  List<Widget> get _pages {
    return [
      StudentHomeTab(userId: widget.userId, userName: widget.userName),
      const StudentAttendanceHistoryTab(),
      const StudentNotesTab(),
      const StudentSettingsTab(),
      StudentProfileTab(
        userId: widget.userId,
        onBackToHome: () {
          setState(() => _currentIndex = 0);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? Colors.black : const Color(0xFFE6E6FA);
    final iconColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final navBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final unselectedColor =
        isDark ? Colors.white54 : const Color(0xFF2A1B38).withOpacity(0.5);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_currentIndex != 0) {
            // الرجوع للصفحة الرئيسية أولاً
            setState(() => _currentIndex = 0);
          } else {
            // الخروج من التطبيق للشاشة الرئيسية للهاتف بدون تسجيل خروج
            SystemNavigator.pop();
          }
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ChangeNotifierProvider(
          create: (_) => NotificationsProvider()..init(widget.userId),
          child: Consumer<StudentProvider>(
            builder: (context, provider, child) {
              // Global loading state
              if (provider.isLoading && provider.student == null) {
                return Scaffold(
                  backgroundColor: bgColor,
                  body: const SkeletonHomeLoading(),
                );
              }

              if (provider.errorMessage != null && provider.student == null) {
                return Scaffold(
                  backgroundColor: bgColor,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
                        const SizedBox(height: 15),
                        Text(
                          provider.errorMessage!,
                          style: TextStyle(fontSize: 16, color: iconColor),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            provider.fetchStudentData(
                              widget.userId,
                              isParentPhone: false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF724F96),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إعادة المحاولة',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Scaffold(
                backgroundColor: bgColor,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: bgColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: iconColor),
                  title: Text(
                    'SMART',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'smart_font',
                      letterSpacing: 2,
                    ),
                  ),
                  actions: [
                    Consumer<NotificationsProvider>(
                      builder: (context, notifProvider, child) {
                        final unread = notifProvider.unreadCount;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.bell_fill, size: 28),
                              color: iconColor,
                              onPressed: () {
                                final notifProvider = context.read<NotificationsProvider>();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider<NotificationsProvider>.value(
                                      value: notifProvider,
                                      child: const NotificationsScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (unread > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unread > 9 ? '9+' : unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SafeArea(
                  child: _pages[_currentIndex],
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: navBg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    backgroundColor: navBg,
                    selectedItemColor: const Color(0xFF724F96),
                    unselectedItemColor: unselectedColor,
                    showUnselectedLabels: true,
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: 'الرئيسية',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history_rounded),
                        label: 'السجل',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.menu_book_rounded),
                        label: 'الملاحظات',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.settings_rounded),
                        label: 'الإعدادات',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded),
                        label: 'البروفايل',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
