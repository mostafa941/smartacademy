import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';
import '../constants/app_strings.dart';
import '../../../core/widgets/skeleton_loading.dart';

class ComplaintsView extends StatefulWidget {
  final AdminProvider provider;
  const ComplaintsView({super.key, required this.provider});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    try {
      final data = await _supabase
          .from('complaints')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('complaints_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            if (mounted) {
              setState(() {
                _complaints.insert(0, Map<String, dynamic>.from(payload.newRecord));
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            if (mounted) {
              final updated = Map<String, dynamic>.from(payload.newRecord);
              setState(() {
                final idx = _complaints.indexWhere((c) => c['id'] == updated['id']);
                if (idx != -1) _complaints[idx] = updated;
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead(String complaintId) async {
    // تحديث فوري في الـ UI
    setState(() {
      final idx = _complaints.indexWhere((c) => c['id'] == complaintId);
      if (idx != -1) _complaints[idx] = {..._complaints[idx], 'is_read': true};
    });
    try {
      await _supabase.from('complaints').update({'is_read': true}).eq('id', complaintId);
    } catch (e) {
      // rollback
      setState(() {
        final idx = _complaints.indexWhere((c) => c['id'] == complaintId);
        if (idx != -1) _complaints[idx] = {..._complaints[idx], 'is_read': false};
      });
    }
  }

  Future<void> _deleteComplaint(String complaintId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('حذف الشكوى', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الشكوى نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف نهائي'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ حذف فوري من الـ UI بدون انتظار Supabase
    final removedIndex = _complaints.indexWhere((c) => c['id'] == complaintId);
    final removedItem = removedIndex != -1 ? _complaints[removedIndex] : null;

    if (removedIndex != -1) {
      setState(() => _complaints.removeAt(removedIndex));
    }

    try {
      await _supabase.from('complaints').delete().eq('id', complaintId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الشكوى بنجاح'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // rollback لو فشل الحذف
      if (removedItem != null && mounted) {
        setState(() => _complaints.insert(removedIndex, removedItem));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  int get _unreadCount => _complaints.where((c) => c['is_read'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 768 ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  AppStrings.complaintsAndHelp,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_unreadCount ${AppStrings.newComplaint}',
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
            child: _isLoading
                ? const SkeletonListLoading()
                : _complaints.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              AppStrings.noComplaintsFound,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final item = _complaints[index];
                          final isRead = item['is_read'] == true;
                          final complaintId = item['id'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isRead ? Colors.white : Colors.orange.shade50,
                            elevation: isRead ? 1 : 3,
                            child: ListTile(
                              onTap: () {
                                if (!isRead) _markAsRead(complaintId);
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
                                      child: Text(
                                        AppStrings.newComplaint,
                                        style: const TextStyle(
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
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isRead)
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      tooltip: AppStrings.markAsRead,
                                      onPressed: () => _markAsRead(complaintId),
                                    )
                                  else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    tooltip: 'حذف الشكوى نهائياً',
                                    onPressed: () => _deleteComplaint(complaintId),
                                  ),
                                ],
                              ),
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
