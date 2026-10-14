import 'dart:async';
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
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _subscribeRealtime();

    // فحص دوري كل دقيقة لحذف أي شكاوى مر عليها 24 ساعة من الواجهة وقاعدة البيانات
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _purgeExpiredComplaints();
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  /// هل مر على الشكوى 24 ساعة أو أكثر؟
  bool _isOlderThan24Hours(dynamic dateStr) {
    if (dateStr == null) return false;
    try {
      final date = DateTime.parse(dateStr.toString()).toUtc();
      final now = DateTime.now().toUtc();
      return now.difference(date).inHours >= 24;
    } catch (_) {
      return false;
    }
  }

  /// حساب الوقت المتبقي قبل الحذف التلقائي (24 ساعة)
  String _remainingTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr.toString()).toUtc();
      final expiresAt = date.add(const Duration(hours: 24));
      final diff = expiresAt.difference(DateTime.now().toUtc());

      if (diff.isNegative) {
        return 'منتهية الصلاحية';
      } else if (diff.inHours > 0) {
        return 'تُحذف تلقائياً خلال ${diff.inHours} س و ${diff.inMinutes % 60} د';
      } else {
        return 'تُحذف تلقائياً خلال ${diff.inMinutes} دقيقة';
      }
    } catch (_) {
      return '';
    }
  }

  /// حذف الشكاوى المنتهية (أقدم من 24 ساعة) من قاعدة البيانات والواجهة
  Future<void> _purgeExpiredComplaints() async {
    final cutoff24h =
        DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();

    // 1. مسح من الواجهة فوراً
    if (mounted) {
      final hasExpired =
          _complaints.any((c) => _isOlderThan24Hours(c['created_at']));
      if (hasExpired) {
        setState(() {
          _complaints.removeWhere((c) => _isOlderThan24Hours(c['created_at']));
        });
      }
    }

    // 2. مسح من قاعدة البيانات
    try {
      await _supabase.from('complaints').delete().lt('created_at', cutoff24h);
      await _supabase
          .from('admin_notifications')
          .delete()
          .eq('type', 'complaint')
          .lt('created_at', cutoff24h);
    } catch (e) {
      debugPrint('⚠️ Error purging expired complaints: $e');
    }
  }

  Future<void> _loadComplaints() async {
    try {
      // حذف أي شكاوى تجاوزت 24 ساعة من قاعدة البيانات أولاً
      final cutoff24h =
          DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
      try {
        await _supabase.from('complaints').delete().lt('created_at', cutoff24h);
        await _supabase
            .from('admin_notifications')
            .delete()
            .eq('type', 'complaint')
            .lt('created_at', cutoff24h);
      } catch (e) {
        debugPrint('⚠️ Auto-delete on load error: $e');
      }

      // جلب الشكاوى التي تم إنشاؤها خلال آخر 24 ساعة فقط
      final data = await _supabase
          .from('complaints')
          .select()
          .gte('created_at', cutoff24h)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          // فلترة إضافية في الذاكرة لضمان عدم ظهور أي شكوى أقدم من 24 ساعة
          _complaints = List<Map<String, dynamic>>.from(data)
              .where((c) => !_isOlderThan24Hours(c['created_at']))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading complaints: $e');
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
              final newRecord = Map<String, dynamic>.from(payload.newRecord);
              // إضافتها فقط إذا كانت خلال الـ 24 ساعة الماضية
              if (!_isOlderThan24Hours(newRecord['created_at'])) {
                setState(() {
                  _complaints.insert(0, newRecord);
                });
              }
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
                final idx = _complaints.indexWhere(
                    (c) => c['id']?.toString() == updated['id']?.toString());
                if (idx != -1) _complaints[idx] = updated;
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            if (mounted) {
              final deletedId = payload.oldRecord['id']?.toString();
              if (deletedId != null) {
                setState(() {
                  _complaints.removeWhere(
                      (c) => c['id']?.toString() == deletedId);
                });
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead(dynamic complaintId) async {
    // تحديث فوري في الـ UI
    setState(() {
      final idx = _complaints.indexWhere(
          (c) => c['id']?.toString() == complaintId.toString());
      if (idx != -1) _complaints[idx] = {..._complaints[idx], 'is_read': true};
    });
    try {
      await _supabase
          .from('complaints')
          .update({'is_read': true})
          .eq('id', complaintId);
    } catch (e) {
      // rollback
      if (mounted) {
        setState(() {
          final idx = _complaints.indexWhere(
              (c) => c['id']?.toString() == complaintId.toString());
          if (idx != -1) _complaints[idx] = {..._complaints[idx], 'is_read': false};
        });
      }
    }
  }

  Future<void> _deleteComplaint(dynamic complaintId, [String? complaintText]) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('حذف الشكوى نهائياً', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الشكوى؟\nسيتم مسحها بالكامل ونهائياً من الواجهة وقاعدة البيانات.',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

    // ✅ 1. حذف فوري من الواجهة (Front-end)
    final removedIndex = _complaints
        .indexWhere((c) => c['id']?.toString() == complaintId.toString());
    final removedItem = removedIndex != -1 ? _complaints[removedIndex] : null;

    if (removedIndex != -1) {
      setState(() => _complaints.removeAt(removedIndex));
    }

    try {
      // ✅ 2. حذف نهائي من جدول complaints في قاعدة البيانات (Database)
      await _supabase.from('complaints').delete().eq('id', complaintId);

      // مسح الإشعار المرتبط بها إن وُجد في admin_notifications
      if (complaintText != null && complaintText.isNotEmpty) {
        try {
          await _supabase
              .from('admin_notifications')
              .delete()
              .eq('type', 'complaint')
              .eq('message', complaintText);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الشكوى بنجاح من الواجهة وقاعدة البيانات'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error deleting complaint from database: $e');
      // rollback لو فشل الحذف
      if (removedItem != null && mounted) {
        setState(() => _complaints.insert(removedIndex, removedItem));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف من قاعدة البيانات: $e')),
        );
      }
    }
  }

  int get _unreadCount => _complaints.where((c) => c['is_read'] != true).length;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              const Text(
                AppStrings.complaintsAndHelp,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_delete_outlined, size: 16, color: Colors.blueGrey),
                        SizedBox(width: 4),
                        Text(
                          'حذف تلقائي بعد 24 ساعة',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
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
                ],
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'الشكاوى يتم حذفها تلقائياً بعد مرور 24 ساعة من إرسالها',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final item = _complaints[index];
                          final isRead = item['is_read'] == true;
                          final complaintId = item['id'];
                          final complaintText = item['complaint'] ?? '';
                          final remainingText = _remainingTime(item['created_at']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isRead ? Colors.grey.shade200 : Colors.orange.shade200,
                                width: 1,
                              ),
                            ),
                            color: isRead ? Colors.white : Colors.orange.shade50,
                            elevation: isRead ? 1 : 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // السطر العلوي: اسم المرسل + شارة جديد/مقروء + شارة الوقت المتبقي + أزرار الإجراءات
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Icon(
                                            Icons.report_problem_rounded,
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
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  item['name'] ?? 'بدون اسم',
                                                  style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(10),
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
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone,
                                                    size: 15, color: Colors.blueGrey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  item['phone'] ?? 'غير متوفر',
                                                  style: const TextStyle(
                                                    color: Colors.blueGrey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // زر تعليم كمقروء + زرار الحذف
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isRead)
                                            IconButton(
                                              icon: const Icon(Icons.done_all,
                                                  color: Colors.green, size: 22),
                                              tooltip: AppStrings.markAsRead,
                                              onPressed: () => _markAsRead(complaintId),
                                            )
                                          else
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                              child: Icon(Icons.check_circle,
                                                  color: Colors.green, size: 20),
                                            ),
                                          const SizedBox(width: 4),
                                          // زرار الحذف المطلوب
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade50,
                                              foregroundColor: Colors.red.shade700,
                                              elevation: 0,
                                              side: BorderSide(
                                                  color: Colors.red.shade200, width: 1),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(Icons.delete_forever,
                                                color: Colors.red, size: 18),
                                            label: const Text(
                                              'حذف',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            onPressed: () => _deleteComplaint(
                                                complaintId, complaintText),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // نص الشكوى
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.grey.shade50
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isRead
                                            ? Colors.grey.shade200
                                            : Colors.orange.shade100,
                                      ),
                                    ),
                                    child: SelectableText(
                                      complaintText,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.4,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // السطر السفلي: تاريخ الإرسال + عداد الـ 24 ساعة المتبقي
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(item['created_at']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (remainingText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.amber.shade300),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer_outlined,
                                                  size: 13,
                                                  color: Colors.amber.shade900),
                                              const SizedBox(width: 4),
                                              Text(
                                                remainingText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.amber.shade900,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
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

