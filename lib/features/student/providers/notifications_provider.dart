import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<NotificationModel> notifications = [];
  bool isLoading = false;
  String? studentId;
  RealtimeChannel? _notificationsChannel;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> init(String sId) async {
    studentId = sId;
    await fetchNotifications();
    _setupRealtime();
  }

  Future<void> fetchNotifications() async {
    if (studentId == null) return;
    
    isLoading = true;
    notifyListeners();

    try {
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('student_id', studentId!)
          .order('created_at', ascending: false);
      
      notifications = (res as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtime() {
    if (studentId == null) return;
    
    _notificationsChannel?.unsubscribe();
    _notificationsChannel = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('🔄 Notification changed. Refreshing list...');
            fetchNotifications();
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = notifications[index];
        notifications[index] = NotificationModel(
          id: old.id,
          studentId: old.studentId,
          title: old.title,
          body: old.body,
          isRead: true,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (studentId == null) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('student_id', studentId!)
          .eq('is_read', false);
      
      for (int i = 0; i < notifications.length; i++) {
        final old = notifications[i];
        if (!old.isRead) {
          notifications[i] = NotificationModel(
            id: old.id,
            studentId: old.studentId,
            title: old.title,
            body: old.body,
            isRead: true,
            createdAt: old.createdAt,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }
}
