import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_evaluation_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const NotificationsScreen({
    super.key,
    required this.teacherId,
    this.teacherName = '',
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  String _resolvedTeacherName = '';
  String? _teacherAvatarUrl;
  String _teacherSubject = 'غير محدد';

  @override
  void initState() {
    super.initState();
    _resolvedTeacherName = widget.teacherName;
    _fetchTeacherInfo();
    _fetchNotifications();
  }

  Future<void> _fetchTeacherInfo() async {
    try {
      final profileRes = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', widget.teacherId)
          .maybeSingle();

      final subjectRes = await _supabase
          .from('teacher_subjects')
          .select('subjects(name)')
          .eq('teacher_id', widget.teacherId);

      final List subjectList = subjectRes as List;
      final subjectNames = subjectList
          .map((s) => s['subjects']?['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          if (_resolvedTeacherName.isEmpty && profileRes != null) {
            _resolvedTeacherName = (profileRes['full_name'] as String?) ?? '';
          }
          _teacherAvatarUrl = profileRes?['avatar_url'] as String?;
          _teacherSubject =
              subjectNames.isNotEmpty ? subjectNames.join(', ') : 'غير محدد';
        });
      }
    } catch (e) {
      debugPrint('Error fetching teacher info in notifications: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('notifications')
          .select('*, students(full_name, age_group)')
          .eq('teacher_id', widget.teacherId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });

      // Mark all as read after fetching
      await _markAllAsRead();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final unreadIds = _notifications
          .where((n) => n['is_read'] == false)
          .map((n) => n['id'])
          .toList();

      if (unreadIds.isNotEmpty) {
        await _supabase
            .from('notifications')
            .update({'is_read': true})
            .inFilter('id', unreadIds);
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  String _formatTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);

      if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
      if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
      if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
      return 'الآن';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            color: Color(0xFF2A1B38),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A1B38)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] ?? true;
                    final studentInfo = notif['students'] as Map<String, dynamic>?;

                    return GestureDetector(
                      onTap: () {
                        if (notif['student_id'] != null) {
                          final studentName = studentInfo?['full_name'] ?? 'طالب مجهول';
                          final category = studentInfo?['age_group'] ?? '';
                          final initial = studentName.trim().isNotEmpty ? studentName.trim()[0].toUpperCase() : '?';
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentEvaluationScreen(
                                studentId: notif['student_id'].toString(),
                                teacherId: widget.teacherId,
                                studentName: studentName,
                                category: category,
                                initial: initial,
                                teacherName: _resolvedTeacherName,
                                teacherAvatarUrl: _teacherAvatarUrl,
                                teacherSubject: _teacherSubject,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFE6E6FA),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: isRead
                              ? null
                              : Border.all(color: const Color(0xFF724F96).withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A1B38).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Color(0xFF2A1B38),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notif['title'] ?? 'إشعار',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF2A1B38),
                                        ),
                                      ),
                                      Text(
                                        _formatTimeAgo(notif['created_at']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['body'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
