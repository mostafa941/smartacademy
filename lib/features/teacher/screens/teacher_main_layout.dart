import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import 'teacher_home_tab.dart';
import 'categories_tab.dart';
import 'settings_tab.dart';
import 'notifications_screen.dart';
import 'teacher_profile_tab.dart';
import '../widgets/teacher_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TeacherMainLayout extends StatefulWidget {
  final String userId;
  final String userName;

  const TeacherMainLayout({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<TeacherMainLayout> createState() => _TeacherMainLayoutState();
}

class _TeacherMainLayoutState extends State<TeacherMainLayout> {
  int _currentIndex = 0;
  String? _filterCategory;
  int _unreadCount = 0;
  String? _avatarUrl;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _fetchAvatarUrl();

    if (!kIsWeb) {
      OneSignal.login(widget.userId);
    }

    _setupRealtimeNotifications();
  }

  void _setupRealtimeNotifications() {
    _notificationsChannel = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'teacher_id',
            value: widget.userId,
          ),
          callback: (payload) {
            debugPrint('🔔 New notification received via Realtime: $payload');
            _fetchUnreadCount();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await _supabase
          .from('notifications')
          .select('id')
          .eq('teacher_id', widget.userId)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          _unreadCount = (res as List).length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching unread notifications count: $e');
    }
  }

  Future<void> _fetchAvatarUrl() async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', widget.userId)
          .maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _avatarUrl = res['avatar_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching avatar url: $e');
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _filterCategory = category;
      _currentIndex = 0;
    });
  }

  List<Widget> get _pages {
    return [
      TeacherHomeTab(
        userId: widget.userId,
        userName: widget.userName,
        filterCategory: _filterCategory,
      ),
      CategoriesTab(
        userId: widget.userId,
        onCategorySelected: _onCategorySelected,
      ),
      const SettingsTab(),
      TeacherProfileTab(
        userId: widget.userId,
        onBackToHome: () {
          setState(() => _currentIndex = 0);
        },
        onAvatarUpdated: (newUrl) {
          if (mounted) {
            setState(() {
              _avatarUrl = newUrl;
            });
          }
        },
      ),
    ];
  }

  Widget _buildProfileIcon({required bool isActive}) {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: const Color(0xFF724F96), width: 2) : null,
        ),
        child: CircleAvatar(
          radius: 12, // match normal icon size
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(_avatarUrl!),
        ),
      );
    } else {
      return const Icon(Icons.person_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? Colors.black : const Color(0xFFE6E6FA);
    final iconColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final navBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final unselectedColor = isDark
        ? Colors.white54
        : const Color(0xFF2A1B38).withOpacity(0.5);

    return PopScope(
      canPop: false, // منع الرجوع للصفحات السابقة
      onPopInvoked: (didPop) {
        if (!didPop) {
          // إظهار dialog للخروج
          showDialog(
            context: context,
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('الخروج من التطبيق'),
                content: const Text('هل تريد الخروج من التطبيق؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Future.delayed(Duration.zero, () {
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      });
                    },
                    child: const Text('خروج', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
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
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.bell_fill, size: 28),
                  color: iconColor,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(
                              teacherId: widget.userId,
                              teacherName: widget.userName,
                            ),
                      ),
                    );
                    _fetchUnreadCount();
                  },
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: TeacherDrawer(
          userName: widget.userName, 
          userId: widget.userId,
          avatarUrl: _avatarUrl,
        ),
        body: SafeArea(child: _pages[_currentIndex]),
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
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_rounded),
                label: 'الفئات',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
              ),
              BottomNavigationBarItem(
                icon: _buildProfileIcon(isActive: _currentIndex == 3),
                label: 'البروفايل',
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
