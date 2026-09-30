import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';

class HeaderWidget extends StatefulWidget {
  final AdminProvider provider;
  final String todayDate;

  const HeaderWidget({
    super.key,
    required this.provider,
    required this.todayDate,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final _supabase = Supabase.instance.client;
  int _unreadNotifications = 0;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _complaintsChannel; // قناة لمتابعة الشكاوى الجديدة

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _setupRealtime();
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    _complaintsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      // عدد الإشعارات غير المقروءة من admin_notifications
      final notifResult = await _supabase
          .from('admin_notifications')
          .select('id')
          .eq('is_read', false);

      // عدد الشكاوى غير المقروءة من complaints (احتياطي)
      final complaintResult = await _supabase
          .from('complaints')
          .select('id')
          .eq('is_read', false);

      // نأخذ الأكبر من الاثنين (في الغالب admin_notifications هو الصحيح)
      final notifCount = (notifResult as List).length;
      final complaintCount = (complaintResult as List).length;
      final total = notifCount > complaintCount ? notifCount : complaintCount;

      if (mounted) {
        setState(() {
          _unreadNotifications = total;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin notifications: $e');
    }
  }

  void _setupRealtime() {
    // قناة 1: متابعة إشعارات الأدمن
    _notificationsChannel = _supabase
        .channel('admin_notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_notifications',
          callback: (payload) {
            debugPrint('🔔 New admin notification received');
            _fetchUnreadCount();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📩 وصلك إشعار جديد!', textAlign: TextAlign.center),
                  backgroundColor: Color(0xFF724F96),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        )
        .subscribe();

    // قناة 2: متابعة الشكاوى الجديدة مباشرة
    _complaintsChannel = _supabase
        .channel('complaints_header_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaints',
          callback: (payload) async {
            debugPrint('🔔 New complaint received → updating bell');
            _fetchUnreadCount();
          },
        )
        .subscribe();
  }

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return 'لوحة التحكم الرئيسية';
      case 1:
        return 'إدارة الطلاب';
      case 2:
        return 'إدارة المدرسين';
      case 3:
        return 'الإعدادات';
      case 4:
        return 'الشكاوي';
      default:
        return 'لوحة التحكم';
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
      
      _fetchUnreadCount();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإشعارات', style: TextStyle(fontSize: 18)),
              if (_unreadNotifications > 0)
                TextButton(
                  onPressed: () {
                    _markAllAsRead();
                    Navigator.pop(context);
                  },
                  child: const Text('تعليم الكل كمقروء', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          content: SizedBox(
            width: 450,
            height: 350,
            child: FutureBuilder(
              future: _supabase
                  .from('admin_notifications')
                  .select()
                  .order('created_at', ascending: false)
                  .limit(15),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF724F96)),
                  );
                }

                if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('لا توجد إشعارات', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data as List;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['is_read'] == true;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRead ? Colors.grey.shade300 : Colors.orange.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: isRead ? Colors.grey : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  notif['title'] ?? 'إشعار',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif['message'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(notif['created_at']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inHours < 1) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inDays < 1) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return 'منذ ${difference.inDays} يوم';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTitleByIndex(widget.provider.selectedNavIndex),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              Text(
                'التاريخ: ${widget.todayDate}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 20),
              // Notifications Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 26),
                    color: Colors.black87,
                    tooltip: 'الإشعارات',
                    onPressed: () => _showNotificationsDialog(context),
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}