import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';
import '../../../core/widgets/skeleton_loading.dart';

class ComplaintsView extends StatefulWidget {
  final AdminProvider provider;
  const ComplaintsView({super.key, required this.provider});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  RealtimeChannel? _complaintsChannel;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _setupRealtime();
  }

  @override
  void dispose() {
    _complaintsChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final supabase = Supabase.instance.client;
    _complaintsChannel = supabase
        .channel('public:complaints')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            debugPrint('🔔 شكوى جديدة وصلت!');
            _fetchComplaints();
            
            // عرض إشعار في أعلى الشاشة
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📩 وصلتك شكوى جديدة!', textAlign: TextAlign.center),
                  backgroundColor: Color(0xFF724F96),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchComplaints() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('complaints')
          .select()
          .order('created_at', ascending: false);

      // حساب الشكاوى غير المقروءة
      int unreadCount = 0;
      for (var complaint in response) {
        if (complaint['is_read'] == false || complaint['is_read'] == null) {
          unreadCount++;
        }
      }

      if (mounted) {
        setState(() {
          _complaints = response;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب الشكاوي: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String complaintId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('complaints')
          .update({'is_read': true})
          .eq('id', complaintId);
      
      _fetchComplaints(); // تحديث القائمة
    } catch (e) {
      debugPrint('خطأ في تحديث حالة القراءة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SkeletonListLoading();
    }

    if (_complaints.isEmpty) {
      return const Center(
        child: Text('لا توجد شكاوي حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'قائمة الشكاوي والمساعدة',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_unreadCount جديد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _complaints.length,
              itemBuilder: (context, index) {
                final item = _complaints[index];
                final isRead = item['is_read'] == true;
                final complaintId = item['id'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isRead ? Colors.white : Colors.orange.shade50,
                  child: ListTile(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(complaintId);
                      }
                    },
                    contentPadding: const EdgeInsets.all(16),
                    leading: Stack(
                      children: [
                        Icon(
                          Icons.report_problem,
                          color: isRead ? Colors.grey : Colors.orange,
                          size: 32,
                        ),
                        if (!isRead)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? 'بدون اسم',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'جديد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text(
                              item['phone'] ?? 'غير متوفر',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['complaint'] ?? '',
                          style: const TextStyle(fontSize: 15),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(item['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'تعليم كمقروء',
                            onPressed: () => _markAsRead(complaintId),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
                );
              },
            ),
          ),
        ],
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
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
